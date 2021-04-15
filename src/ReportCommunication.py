#!/usr/bin/python3

import networkx as nx
import matplotlib.cm as cm
import argparse
import copy
import GraphAnalysisCommon as gac
import html

def init():
    # Parse CLI Arguments for Config File Location
    parser = argparse.ArgumentParser(description='Analyzes a scheduling/communications graphml file')
    parser.add_argument('graphmlFile', type=str, help='Path to the scheduling/communications graphml file')
    parser.add_argument('-o', type=str, default='', help='The output for the graph eps file')
    parser.add_argument('--max-line-width', type=float, default=4.0, help='Width of the largest edge in the plot')
    parser.add_argument('--partition-names', nargs='+', type=str, required=False, help='List of human readable names corresponding to each partition (in ascending order of partitions)')
    parser.add_argument('--partitionCPUMapping', nargs="+", type=int, required=False, help='List of Partition to CPU mappings, the first entry is for the I/O partition (-2), the subsequent entries are for partitions starting from partition 0')
    parser.add_argument('--cpuL3Mapping', nargs="+", type=int, required=False, help='A array of CPU to L3 caches, one entry per CPU starting from CPU0')
    parser.add_argument('--l3DieMapping', nargs="+", type=int, required=False, help='A array of L3s to dies, one entry per L3 starting from L3_0')

    args = parser.parse_args()

    G = gac.importGraph(args.graphmlFile, args.partition_names, args.partitionCPUMapping, args.cpuL3Mapping, args.l3DieMapping)

    return G, args.o, args.max_line_width, args.cpuL3Mapping is not None, args.l3DieMapping is not None

def plotGraph(G: nx.MultiDiGraph, filename: str, max_line_width : float ):
    cmap = cm.get_cmap(name='viridis')

    plotGraph = copy.deepcopy(G)  # Create a deep copy since we will be changing the dictionaries

    plotGraph.graph['label'] = 'Inter-Partition Communication'  # Graph property

    gac.removeDummyNodes(plotGraph)

    #The nodes had their labels set on import
    #Set the width of the arcs based on the bytes communicated + add labels
    maxBytesPerBlock = 1
    for src, dst, data in plotGraph.edges(data=True):
        bytesPerBlock = int(data['partition_crossing_bytes_per_block'])

        if bytesPerBlock > maxBytesPerBlock:
            maxBytesPerBlock = bytesPerBlock

    for src, dst, data in plotGraph.edges(data=True):
        bytesPerBlock = int(data['partition_crossing_bytes_per_block'])
        data['label'] = str(bytesPerBlock)
        data['penwidth'] = float(bytesPerBlock)*max_line_width/maxBytesPerBlock

        colorStr = gac.colorMapRGBStr(cmap, float(bytesPerBlock)/maxBytesPerBlock)
        data['color'] = colorStr

    #Color the nodes according to their communication load
    maxCommBytes = 1
    commBytesIn = {}
    commBytesOut = {}
    commArcsIn = {}
    commArcsOut = {}
    maxCommArcs = 1
    l3NodesMap = {}

    for node, data in plotGraph.nodes(data=True):
        inputArcs = list(G.in_edges(node, keys=True, data=True))
        outputArcs = list(G.out_edges(node, keys=True, data=True))
        inBytes = 0
        for src, dst, key, in_arc_data in inputArcs:
            bytesPerBlock = int(in_arc_data['partition_crossing_bytes_per_block'])
            inBytes += bytesPerBlock

        outBytes = 0
        for src, dst, key, out_arc_data in outputArcs:
            bytesPerBlock = int(out_arc_data['partition_crossing_bytes_per_block'])
            outBytes += bytesPerBlock

        if 'l3' in data:
            l3 = int(data['l3'])

            if l3 not in l3NodesMap:
                l3NodesMap[l3] = [node]
            else:
                l3NodesMap[l3].append(node)

        commBytesIn[node] = inBytes
        commBytesOut[node] = outBytes
        numInputArcs = len(inputArcs)
        numOutputArcs = len(outputArcs)
        commArcsIn[node] = numInputArcs
        commArcsOut[node] = numOutputArcs
        maxCommBytes = max(maxCommBytes, inBytes, outBytes)
        maxCommArcs = max(maxCommArcs, numInputArcs, numOutputArcs)

    for node, data in plotGraph.nodes(data=True):
        colorStrIn = gac.colorMapRGBStr(cmap, float(commBytesIn[node]) / maxCommBytes)
        colorStrOut = gac.colorMapRGBStr(cmap, float(commBytesOut[node]) / maxCommBytes)
        colorStrArcsIn = gac.colorMapRGBStr(cmap, float(commArcsIn[node]) / maxCommArcs)
        colorStrArcsOut = gac.colorMapRGBStr(cmap, float(commArcsOut[node]) / maxCommArcs)

        #Set the label to contain this info (in html mode)
        #See https://stackoverflow.com/questions/17765301/graphviz-dot-how-to-change-the-colour-of-one-record-in-multi-record-shape
        #https://graphviz.org/doc/info/shapes.html#html
        oldLbl = data['label']
        oldLbl = html.escape(oldLbl, quote=True)
        newLbl = '<<table border=\"0\" cellborder=\"1\" cellspacing=\"0\" bgcolor=\"#ffffffff\">' \
                 '<tr><td colspan=\"3\">' + oldLbl + '</td></tr>' \
                 '<tr><td></td><td>Arcs</td><td>Bytes</td></tr>' \
                 '<tr><td>In</td><td bgcolor=\"' + colorStrArcsIn + '\">' + str(commArcsIn[node]) + '</td><td bgcolor=\"' + colorStrIn + '\">' + str(commBytesIn[node]) + '</td></tr>' \
                 '<tr><td>Out</td><td bgcolor=\"' + colorStrArcsOut + '\">' + str(commArcsOut[node]) + '</td><td bgcolor=\"' + colorStrOut + '\">' + str(commBytesOut[node]) + '</td></tr>' \
                 '</table>>'

        data['label'] = newLbl
        data['shape'] = 'plain'

    #Add a node to act as a color scale:
    colorScaleStr = ''
    for c in range(0, 100, 2):
        colorStr = gac.colorMapRGBStr(cmap, float(c)/100)

        if colorScaleStr:
            colorScaleStr += (':' + colorStr)
        else:
            colorScaleStr = colorStr

    data = {}
    data['shape'] = 'box'
    data['fillcolor'] = colorScaleStr
    data['style'] = 'striped'
    data['label'] = '{0, 0, 0} -> {Node Bytes/Blk, #Arcs, Arc Bytes/Blk} Color Scale -> {' + str(maxCommBytes) + ', ' + str(maxCommArcs) + ', ' + str(maxBytesPerBlock) + '}'
    plotGraph.add_nodes_from([('ColorScale', data)])

    aGraph = nx.nx_agraph.to_agraph(plotGraph)

    #NetworkX does not appear tp handle subgraphs for plotting but pygraphviz does and we are using it to send the graph to graphviz anyway
    if l3NodesMap:
        for l3, nodesInL3 in l3NodesMap.items():
            l3Name = 'L3_'+str(l3)
            l3Cluster = 'cluster_'+str(l3) #This needs to be prefixed with cluster_ for graphviz to cluster the nodes within
            aGraph.add_subgraph(nodesInL3, name=l3Cluster, label=l3Name, style='filled', color='lightgrey')

    #TODO: Cluster of Clusters for dies

    aGraph.layout(prog='dot')
    # aGraph.layout()
    aGraph.draw(filename + '.pdf')

def reportNodeStats(G: nx.MultiDiGraph):
    maxLblLen = len('Name')

    partitions = {}
    for node, data in G.nodes(data=True):
        if data:
            maxLblLen = max(len(G.nodes[node]['label']), maxLblLen)
            partitions[int(G.nodes[node]['block_partition_num'])] = node

    partitionNums = sorted(partitions.keys())

    headerFormat = 'Part# | {:' + str(maxLblLen) + 's} | Input Arcs | Output Arcs | Total Arcs | Bytes In / Blk | Bytes Out / Blk | Total Bytes / Blk'
    print(headerFormat.format('Name'))
    for partition in partitionNums:
        node = partitions[partition]
        name = G.nodes[node]['label']

        inputArcs = list(G.in_edges(node, keys=True, data=True))
        outputArcs = list(G.out_edges(node, keys=True, data=True))
        numInputArcs = len(inputArcs)
        numOutputArcs = len(outputArcs)

        inBytes = 0
        for src, dst, key, data in inputArcs:
            bytesPerBlock = int(data['partition_crossing_bytes_per_block'])
            inBytes += bytesPerBlock

        outBytes = 0
        for src, dst, key, data in outputArcs:
            bytesPerBlock = int(data['partition_crossing_bytes_per_block'])
            outBytes += bytesPerBlock

        rowFormat = '{:5d} | {:' + str(maxLblLen) + 's} | {:10d} | {:11d} | {:10d} | {:14d} | {:15d} | {:17d}'
        print(rowFormat.format(partition, name, numInputArcs, numOutputArcs, numInputArcs+numOutputArcs, inBytes, outBytes, inBytes+outBytes))

def reportGroupedStats(G: nx.MultiDiGraph, grouping : str): #grouping can be l3 or die
    l3InArcs = dict()
    l3OutArcs = dict()
    l3InBytes = dict()
    l3OutBytes = dict()

    l3InnerArcs = dict()
    l3InnerBytes = dict()

    l3s = set()

    for src, dst, data in G.edges(data=True):
        srcL3 = G.nodes[src][grouping]
        dstL3 = G.nodes[dst][grouping]

        l3s.add(srcL3)
        l3s.add(dstL3)

        #Report if src and dst L3 are different
        if data and srcL3 != dstL3:
            #Handle Out of Src Partition
            if srcL3 not in l3OutArcs:
                l3OutArcs[srcL3] = 1
                l3OutBytes[srcL3] = int(data['partition_crossing_bytes_per_block'])
            else:
                l3OutArcs[srcL3] += 1
                l3OutBytes[srcL3] += int(data['partition_crossing_bytes_per_block'])

            #Handle Into Dst Partition
            if dstL3 not in l3InArcs:
                l3InArcs[dstL3] = 1
                l3InBytes[dstL3] = int(data['partition_crossing_bytes_per_block'])
            else:
                l3InArcs[dstL3] += 1
                l3InBytes[dstL3] += int(data['partition_crossing_bytes_per_block'])

        elif data:
            #If srcL3 == dstL3
            if srcL3 not in l3InnerArcs:
                l3InnerArcs[srcL3] = 1
                l3InnerBytes[srcL3] = int(data['partition_crossing_bytes_per_block'])
            else:
                l3InnerArcs[srcL3] += 1
                l3InnerBytes[srcL3] += int(data['partition_crossing_bytes_per_block'])

    l3List = sorted(l3s)

    headerFormat = '{} | Input Arcs | Output Arcs | Ext Arcs | Bytes In / Blk | Bytes Out / Blk | Total Ext Bytes / Blk | Internal Arcs | Internal Bytes / Blk'
    print(headerFormat.format(grouping.upper()))

    for l3 in l3List:
        internalArcs = l3InnerArcs[l3]
        internalBytes = l3InnerBytes[l3]

        inputArcs = l3InArcs[l3]
        outputArcs = l3OutArcs[l3]
        inputBytes = l3InBytes[l3]
        outputBytes = l3OutBytes[l3]

        rowFormat = '{:' + str(len(grouping)) + 'd} | {:10d} | {:11d} | {:8d} | {:14d} | {:15d} | {:21d} | {:13d} | {:20d}'
        print(rowFormat.format(l3, inputArcs, outputArcs, inputArcs + outputArcs, inputBytes, outputBytes,
                               inputBytes + outputBytes, internalArcs, internalBytes))

if __name__ == '__main__':
    G, outputName, max_line_width, analyzeL3, analyzeDie = init()

    print('Node Stats:')
    reportNodeStats(G)

    if analyzeL3:
        print('')
        print('L3 Stats:')
        reportGroupedStats(G, 'l3')

    if analyzeDie:
        print('')
        print('Die Stats:')
        reportGroupedStats(G, 'die')

    if outputName:
        plotGraph(G, outputName, max_line_width)
