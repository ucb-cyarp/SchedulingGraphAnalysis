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

    args = parser.parse_args()

    G = gac.importGraph(args.graphmlFile, args.partition_names)

    return G, args.o, args.max_line_width

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
    for node, data in plotGraph.nodes(data=True):
        inputArcs = list(G.in_edges(node, keys=True, data=True))
        outputArcs = list(G.out_edges(node, keys=True, data=True))
        inBytes = 0
        for src, dst, key, data in inputArcs:
            bytesPerBlock = int(data['partition_crossing_bytes_per_block'])
            inBytes += bytesPerBlock

        outBytes = 0
        for src, dst, key, data in outputArcs:
            bytesPerBlock = int(data['partition_crossing_bytes_per_block'])
            outBytes += bytesPerBlock

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
        newLbl = '<<table border=\"0\" cellborder=\"1\" cellspacing=\"0\">' \
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

if __name__ == '__main__':
    G, outputName, max_line_width = init()

    reportNodeStats(G)

    if outputName:
        plotGraph(G, outputName, max_line_width)
