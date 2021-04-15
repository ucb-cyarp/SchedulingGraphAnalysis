#!/usr/bin/python3

import networkx as nx
import matplotlib.cm as cm
import argparse
import copy
from enum import Enum

from typing import List


class DoubleBufferType(Enum):
    NONE = 0
    PRODUCER = 1
    CONSUMER = 2
    PRODUCER_CONSUMER = 3

    @staticmethod
    def parse(dblBufType: str):
        if dblBufType.lower() == 'none':
            return DoubleBufferType.NONE
        elif dblBufType.lower() == 'producer':
            return DoubleBufferType.PRODUCER
        elif dblBufType.lower() == 'consumer':
            return DoubleBufferType.CONSUMER
        elif dblBufType.lower() == 'producer_consumer':
            return DoubleBufferType.PRODUCER_CONSUMER
        else:
            raise ValueError('Unknown DoubleBufferType: ' + dblBufType)

    @staticmethod
    def options():
        return ['none', 'producer', 'consumer', 'producer_consumer']

def printNodes(G: nx.MultiDiGraph):
    for node, data in G.nodes(data=True):
        print('Node: {}'.format(node))
        if(data):
            for key, val in data.items():
                print('\t{}: {}'.format(key, val))

def printArcs(G: nx.MultiDiGraph):
    for src, dst, data in G.edges(data=True):
        print('Arc: {}->{}'.format(src, dst))
        if (data):
            for key, val in data.items():
                print('\t{}: {}'.format(key, val))

def importGraph(graphmlFile : str, partition_names : str, partitionCPUList : List[int], cpuL3List : List[int],
                l3DieList : List[int]):
    try:
        G = nx.read_graphml(graphmlFile, force_multigraph=True) # type: nx.Graph
    except FileNotFoundError:
        print('File not found: {}'.format(graphmlFile))
        exit(1)

    # Remove Partition -1 if it exists
    partN1ID = ''
    ioID = ''
    for node, data in G.nodes(data=True):
        if data:
            if data['block_partition_num'] == -1:
                partN1ID = node
            if data['block_partition_num'] == -2:
                ioID = node

    if partN1ID:
        n1Neighbors = list(G.neighbors(partN1ID))
        if n1Neighbors:
            print('Error, Partition -1 node is connected to other nodes')
            exit(1)
        else:
            print('Removing Partition -1 node')
            G.remove_node(partN1ID)

    numOfNonIONodes = G.number_of_nodes()
    if ioID:
        numOfNonIONodes -= 1

    print('Imported graph {}\nNodes: {}\nArcs: {}'.format(graphmlFile, G.number_of_nodes(), G.number_of_edges()))

    partitionSet = set()

    partitionCPUMap = dict()
    partitionL3Map = dict()
    partitionDieMap = dict()

    if partitionCPUList:
        partitionCPUMap[-2] = partitionCPUList[0]
        for i in range(1, len(partitionCPUList)):
            partitionCPUMap[i-1] = partitionCPUList[i]

        if cpuL3List:
            for partition, cpu in partitionCPUMap.items():
                if cpu >= len(cpuL3List):
                    print('L3 mapping not provided for CPU {}'.format(cpu))
                    exit(1)
                partitionL3Map[partition] = cpuL3List[cpu]

            if l3DieList:
                for partition, cpu in partitionCPUMap.items():
                    l3 = cpuL3List[cpu]

                    if l3 >= len(l3DieList):
                        print('Die mapping not provided for L3 {}'.format(l3))
                        exit(1)
                    partitionDieMap[partition] = l3DieList[l3]

    if partition_names:
        # Set the node labels (and check for duplicate partitions)

        if len(partition_names) != numOfNonIONodes: #+1 is for the I/O partition
            print('Number of provided labels ({}) does not match number of non-I/O partitions ({})'.format(len(partition_names), numOfNonIONodes))
            exit(1)

        #Create a mapping of partition numbers to labels (excluding negative partition numbers)
        #Labels are assumed to be in ascending partition number order
        partitionsInDesign = set()
        for node, data in G.nodes(data=True):
            if data:
                partition = int(data['block_partition_num'])
                if partition >= 0:
                    partitionsInDesign.add(partition)

        sortedPartitions = sorted(list(partitionsInDesign))
        partitionNameMap = {}
        for idx, partNum in enumerate(sortedPartitions):
            partitionNameMap[partNum] = partition_names[idx]

        #Set the names based on the partition number/name mapping above
        for node, data in G.nodes(data=True):
            if data:
                partition = int(data['block_partition_num'])
                if partition in partitionSet:
                    print('Error, Partition {} appeared more than once'.format(partition))
                    exit(1)

                partitionSet.add(partition)

                if partition == -2:
                    data['label'] = 'I/O'
                elif partition == -1:
                    data['label'] = 'Unassigned Partition'
                else:
                    data['label'] = partitionNameMap[partition]

    else:
        # Just use the given instance names
        for node, data in G.nodes(data=True):
            if data:
                partition = int(data['block_partition_num'])
                if partition in partitionSet:
                    print('Error, Partition {} appeared more than once'.format(partition))
                    exit(1)
                partitionSet.add(partition)

                data['label'] = data['instance_name']

    #Set CPU, L3, and Die properties
    for node, data in G.nodes(data=True):
        if data:
            partition = int(data['block_partition_num'])

            if partitionCPUMap:
                data['cpu'] = partitionCPUMap[partition]

                if partitionL3Map:
                    data['l3'] = partitionL3Map[partition]

                    if partitionDieMap:
                        data['die'] = partitionDieMap[partition]

    return G

def removeDummyNodes(G: nx.MultiDiGraph):
    # Remove the Dummy I/O Nodes from the graph.  These are not real nodes in the scheduling graph and area a
    # side effect of using the existing graph export functions
    nodesToRemove = []
    for node, data in G.nodes(data=True):
        if 'block_node_type' in data:
            if data['block_node_type'] == 'Master':
                nodesToRemove.append(node)

    for node in nodesToRemove:
        G.remove_node(node)

def colorMapRGBStr(cmap, val):
    colorRGBA = cmap(val)
    colorRGBAByte = (
        int(colorRGBA[0] * 255), int(colorRGBA[1] * 255), int(colorRGBA[2] * 255),
        int(colorRGBA[3] * 255))

    colorStr = '#{:02x}{:02x}{:02x}{:02x}'.format(colorRGBAByte[0], colorRGBAByte[1],
                                                  colorRGBAByte[2], colorRGBAByte[3])

    return colorStr