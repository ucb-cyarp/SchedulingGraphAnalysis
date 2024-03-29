#!/usr/bin/python3

import networkx as nx
import matplotlib.cm as cm
import argparse
import copy
import GraphAnalysisCommon as gac

# NodeName: instance_name
# NodeLbl: block_label
# NodePartition: block_partition_num

# ArcLbl: arc_disp_label
# ArcDataType: arc_datatype
# ArcComplex: arc_complex
# ArcDim: arc_dimension
# Specifically from
# ArcInitStateBlks: partition_crossing_init_state_count_blocks
# ArcBytesPerBlock: partition_crossing_bytes_per_block
# ArcBytesPerSample:partition_crossing_bytes_per_sample
# ArcSamplesPerBlock: ArcBytesPerBlock/ArcBytesPerSample

def init():
    # Parse CLI Arguments for Config File Location
    parser = argparse.ArgumentParser(description='Analyzes a communications graphml file for cycles')
    parser.add_argument('graphmlFile', type=str, help='Path to the scheduling/communications graphml file')
    parser.add_argument('--dblBuffer', type=str, choices=gac.DoubleBufferType.options(), default='none', help='What form of double buffering is in use')
    parser.add_argument('-o', type=str, default='', help='The output for the graph eps file')
    parser.add_argument('--plotAllNodes', action='store_true', help='Plot all nodes in the unified plot')
    parser.add_argument('--partition-names', nargs='+', type=str, required=False, help='List of human readable names corresponding to each partition (in ascending order of partitions)')

    args = parser.parse_args()

    dblBufferType = gac.DoubleBufferType.parse(args.dblBuffer)

    G = gac.importGraph(args.graphmlFile, args.partition_names, [], [], [])

    return G, dblBufferType, args.o, args.plotAllNodes

def getCycles(G: nx.MultiDiGraph):
    # Get the simple cycles of the directed graph

    # We will remove the I/O node from the graph so that we see only design cycles
    # I/O is handled differently and does not block on input or output.  We may also split I and O some day

    G_noIO = G.copy()

    ioID = ''
    for node, data in G_noIO.nodes(data=True):
        if data:
            if data['block_partition_num'] == -2:
                ioID = node

    if not ioID:
        print('Error, could not find I/O Node')
        exit(1)

    G_noIO.remove_node(ioID)

    cycles = nx.simple_cycles(G_noIO)

    # For each of the cycles, get the number of blocks of initial conditions
    # This can be a multigraph so there can be parallel edges.  We will take the min of the edges
    # See https://networkx.org/documentation/stable/reference/classes/generated/networkx.MultiDiGraph.edges.html#networkx.MultiDiGraph.edges
    # and https://networkx.org/documentation/stable/reference/classes/multidigraph.html?highlight=multidigraph
    # and https://networkx.org/documentation/stable/tutorial.html#accessing-edges-and-neighbors
    # for some access tricks.  Note that we can access the edges by using G[src][dst] - it returns a list of tuples with the edge index being the first argument and the properties being the second
    # G[node] gives the nodes (and arcs) adjacent to node.  It does this by returning a dictionary of adjacent ve
    if cycles:
        cycleInitConds = []
        cyclesNodeLists = []

        for cycle in cycles:
            initBlocks = 0

            cycleList = list(cycle)
            cyclesNodeLists.append(cycleList)

            # The cycle returned from networkx only lists each node once, we need to handle the final loop back from
            # the node at the end of the list to the src.  We can do that by simply appending the first node to to the
            # list
            cycleListDupNode = cycleList.copy()
            cycleListDupNode.append(cycleListDupNode[0])

            for idx, node in enumerate(cycleListDupNode):
                if idx == 0:
                    prevNode = node
                else:
                    arcs = G[prevNode][node] # There may be multiple

                    arcInitConds = []
                    for arcID, data in arcs.items():
                        if data:
                            arcInitConds.append(int(data['partition_crossing_init_state_count_blocks']))

                    if arcInitConds:
                        initBlocks += min(arcInitConds)

                    prevNode = node

            cycleInitConds.append(initBlocks)

        return (cyclesNodeLists, cycleInitConds)

    return (None, None)

def printCycles(G: nx.MultiDiGraph, cycles, cycleInitConds, dblBufType: gac.DoubleBufferType, printAll: bool):
    for cycleIdx, cycle in enumerate(cycles):

        # The cycle returned from networkx only lists each node once, we need to handle the final loop back from
        # the node at the end of the list to the src.  We can do that by simply appending the first node to to the
        # list
        origCycle = list(cycle) # In case the cycle iterator was returned

        # Check if the number of initial conditions will cause deadlock
        effInitConditions = cycleInitConds[cycleIdx]
        nodesInCycles = len(origCycle)
        if dblBufType == gac.DoubleBufferType.PRODUCER or dblBufType == gac.DoubleBufferType.CONSUMER:
            effInitConditions -= nodesInCycles # Each node needs 1 initial condition to prime it
        elif dblBufType == gac.DoubleBufferType.PRODUCER_CONSUMER:
            effInitConditions -= nodesInCycles*2 # Each node needs 2 initial conditions to prime it

        if effInitConditions <= 0 or printAll:
            cycleListDupNode = origCycle.copy()
            cycleListDupNode.append(cycleListDupNode[0])

            cycleLbl = ''

            for nodeIdx, node in enumerate(cycleListDupNode):
                if nodeIdx == 0:
                    cycleLbl += G.nodes[node]['label']
                    src = node
                else:
                    arcs = G[src][node]

                    cycleLbl += '-('

                    for arcNum, (arcID, arcData) in enumerate(arcs.items()):
                        if arcNum != 0:
                            cycleLbl += ', '

                        cycleLbl += str(arcData['partition_crossing_init_state_count_blocks'])

                    cycleLbl += ')->' + G.nodes[node]['label']

                    src = node

            if printAll:
                print('Nodes: {:>2}, InitCond: {:>2}, EffInitCond: {:>3}, EffInitCondPerCore: {:>5.2f}, Cycle: {}'.format(nodesInCycles, cycleInitConds[cycleIdx], effInitConditions, effInitConditions/nodesInCycles, cycleLbl))
            else:
                print('Nodes: {:>2}, InitCond: {:>2}, Cycle: {}'.format(nodesInCycles, cycleInitConds[cycleIdx], cycleLbl))

def printNodeStats(G: nx.MultiDiGraph, cycles, cycleInitConds, dblBufType: gac.DoubleBufferType):
    nodeCycleCount = {}
    nodeEffInitCondPerNodeMin = {}

    maxLblLen = len('Name')

    for cycleIdx, cycle in enumerate(cycles):

        # The cycle returned from networkx only lists each node once, we need to handle the final loop back from
        # the node at the end of the list to the src.  We can do that by simply appending the first node to to the
        # list
        origCycle = list(cycle) # In case the cycle iterator was returned

        # Check if the number of initial conditions will cause deadlock
        effInitConditions = cycleInitConds[cycleIdx]
        nodesInCycles = len(origCycle)
        if dblBufType == gac.DoubleBufferType.PRODUCER or dblBufType == gac.DoubleBufferType.CONSUMER:
            effInitConditions -= nodesInCycles # Each node needs 1 initial condition to prime it
        elif dblBufType == gac.DoubleBufferType.PRODUCER_CONSUMER:
            effInitConditions -= nodesInCycles*2 # Each node needs 2 initial conditions to prime it
        effInitConditionsPerNode = effInitConditions/nodesInCycles

        for node in origCycle:
            if node not in nodeCycleCount.keys():
                nodeCycleCount[node] = 1
                nodeEffInitCondPerNodeMin[node] = effInitConditionsPerNode
            else:
                nodeCycleCount[node] += 1
                nodeEffInitCondPerNodeMin[node] = min(nodeEffInitCondPerNodeMin[node], effInitConditionsPerNode)

    partitions = {}
    for node, data in G.nodes(data=True):
        if data:
            maxLblLen = max(len(G.nodes[node]['label']), maxLblLen)
            partitions[int(G.nodes[node]['block_partition_num'])] = node

    partitionNums = sorted(partitions.keys())

    headerFormat = 'Part# | {:' + str(maxLblLen) + 's} | Cycles (Omit IO) | Min Eff Init Conds / Node | Input Arcs | Output Arcs'
    print(headerFormat.format('Name'))
    for partition in partitionNums:
        node = partitions[partition]
        name = G.nodes[node]['label']
        if node in nodeCycleCount:
            cycleCount = nodeCycleCount[node]
            effInitCondPerNodeMin = nodeEffInitCondPerNodeMin[node]
        else:
            cycleCount = 0
            effInitCondPerNodeMin = float('NaN')

        numInputArcs = len(list(G.in_edges(node, keys=True))) # TODO: Check if keys=True is required to ensure seperate entries for each parallel arc
        numOutputArcs = len(list(G.out_edges(node, keys=True))) # TODO: Check if keys=True is required to ensure seperate entries for each parallel arc

        rowFormat = '{:5d} | {:' + str(maxLblLen) + 's} | {:16d} | {:25.2f} | {:10d} | {:11d}'
        print(rowFormat.format(partition, name, cycleCount, effInitCondPerNodeMin, numInputArcs, numOutputArcs))

def plotCyclesUnified(G: nx.MultiDiGraph, cycles, cycleInitConds, dblBufType: gac.DoubleBufferType, plotAll: bool, plotAllNodes: bool, filename: str):
    # Plot all the cycles in one graph but
    plotGraph = copy.deepcopy(G)  # Create a deep copy since we will be changing the dictionaries

    cmap = cm.get_cmap(name='tab20')
    numColors = 20

    if (len(cycles) > numColors):
        print('Warning: More cycles than colors! Re-using some')

    # Traverse the cycles and append the color of the cycle to each edge in the cycle.
    # Edges can be in multiple cycles

    plotGraph.graph['label'] = 'Communication Cycles'  # Graph property

    gac.removeDummyNodes(plotGraph)

    cyclesToPrint = 0

    nodesInCyclesSet = set()

    for cycleIdx, cycle in enumerate(cycles):
        origCycle = list(cycle)  # In case the cycle iterator was returned

        # Check if the number of initial conditions will cause deadlock
        effInitConditions = cycleInitConds[cycleIdx]
        nodesInCycles = len(origCycle)
        if dblBufType == gac.DoubleBufferType.PRODUCER or dblBufType == gac.DoubleBufferType.CONSUMER:
            effInitConditions -= nodesInCycles  # Each node needs 1 initial condition to prime it
        elif dblBufType == gac.DoubleBufferType.PRODUCER_CONSUMER:
            effInitConditions -= nodesInCycles * 2  # Each node needs 2 initial conditions to prime it

        # Only plot failing cycles unless plotAll
        if effInitConditions <= 0 or plotAll:
            cycleListDupNode = origCycle.copy()
            cycleListDupNode.append(cycleListDupNode[0])

            cycleColorRGBA = cmap(cyclesToPrint % numColors)
            cycleColorRGBAByte = (
            int(cycleColorRGBA[0] * 255), int(cycleColorRGBA[1] * 255), int(cycleColorRGBA[2] * 255),
            int(cycleColorRGBA[3] * 255))

            colorStr = '#{:02x}{:02x}{:02x}{:02x}'.format(cycleColorRGBAByte[0], cycleColorRGBAByte[1],
                                                          cycleColorRGBAByte[2], cycleColorRGBAByte[3])

            for idx, node in enumerate(cycleListDupNode):
                nodesInCyclesSet.add(node)

                if idx == 0:
                    src = node
                else:
                    arcs = plotGraph[src][node]
                    for arcNum, (arcID, arcData) in enumerate(arcs.items()):
                        # Append the color to the edge
                        if 'color' in arcData:
                            edgeColors = arcData['color']
                        else:
                            edgeColors = ''

                        if (edgeColors):
                            edgeColors += ':'

                        edgeColors += colorStr
                        arcData['color'] = edgeColors
                    src = node

            cyclesToPrint += 1

    # Set arc labels to be initial conditon.  Also set arcs with no color to be black
    for src, dst, data in plotGraph.edges(data=True):
        edgeInitCondCount = data['partition_crossing_init_state_count_blocks']
        if edgeInitCondCount:
            data['label'] = edgeInitCondCount
            data['style'] = 'bold'

        if 'color' not in data:
            data['color'] = '#000000'

    if not plotAllNodes:
        plotSubGraph = plotGraph.subgraph(nodesInCyclesSet)
        aGraph = nx.nx_agraph.to_agraph(plotSubGraph)
    else:
        aGraph = nx.nx_agraph.to_agraph(plotGraph)

    aGraph.layout(prog='dot')
    # aGraph.layout()
    aGraph.draw(filename + '.pdf')

def plotCyclesSeperate(G: nx.MultiDiGraph, cycles, cycleInitConds, dblBufType: gac.DoubleBufferType, plotAll: bool, plotAllNodes: bool, filename: str):
    nodeNum = 0

    plotGraph = nx.MultiDiGraph()
    plotGraph.graph['label'] = 'Communication Cycles'  # Graph property

    cycleNum = 0

    for cycleIdx, cycle in enumerate(cycles):
        origCycle = list(cycle)  # In case the cycle iterator was returned

        # Check if the number of initial conditions will cause deadlock
        effInitConditions = cycleInitConds[cycleIdx]
        nodesInCycles = len(origCycle)
        if dblBufType == gac.DoubleBufferType.PRODUCER or dblBufType == gac.DoubleBufferType.CONSUMER:
            effInitConditions -= nodesInCycles  # Each node needs 1 initial condition to prime it
        elif dblBufType == gac.DoubleBufferType.PRODUCER_CONSUMER:
            effInitConditions -= nodesInCycles * 2  # Each node needs 2 initial conditions to prime it

        # Only plot failing cycles unless plotAll
        if effInitConditions <= 0 or plotAll:
            cycleListDupNode = origCycle.copy()
            cycleListDupNode.append(cycleListDupNode[0])

            subGraph = nx.MultiDiGraph()
            subGraph.graph['label'] = 'Nodes In Cycle: {}, Init Conds: {}, Eff Init Conds: {}, Eff Init Conds Per Core: {:.2f}'.format(len(origCycle), cycleInitConds[cycleIdx], effInitConditions, effInitConditions/len(origCycle))

            nodeToPlotNode = {}

            #Add nodes from this cycle to the subgraph
            for node in origCycle:
                nodeLbl = G.nodes[node]['label']
                subGraph.add_nodes_from([(nodeNum, {'label' : nodeLbl})])
                nodeToPlotNode[node] = nodeNum
                nodeNum+=1

            for idx, node in enumerate(cycleListDupNode):
                if idx == 0:
                    src = node
                else:
                    arcs = G[src][node]
                    for arcNum, (arcID, arcData) in enumerate(arcs.items()):
                        #Copy edge
                        edgeInitConds = int(arcData['partition_crossing_init_state_count_blocks'])
                        edgeParams = {'partition_crossing_init_state_count_blocks' : edgeInitConds}
                        if edgeInitConds>0:
                            edgeParams['label'] = str(edgeInitConds)
                            edgeParams['style'] = 'bold'
                        subGraph.add_edges_from([(nodeToPlotNode[src], nodeToPlotNode[node], edgeParams)])

                    src = node

            plotGraph.add_node(subGraph)
            cycleNum += 1

            aGraph = nx.nx_agraph.to_agraph(subGraph)

            aGraph.layout(prog='circo')
            # aGraph.layout()
            aGraph.draw(filename + '_' + str(cycleNum) + '.pdf')

    # aGraph = nx.nx_agraph.to_agraph(plotGraph)
    #
    # aGraph.layout(prog='dot')
    # # aGraph.layout()
    # aGraph.draw(filename + '.pdf')

def plotCycles(G: nx.MultiDiGraph, cycles, cycleInitConds, dblBufType: gac.DoubleBufferType, plotAll: bool, plotSeperate: bool, plotAllNodes: bool, filename: str):
    # To use networkx with matplotlib, it is probably a good idea to follow he example from
    # https://networkx.org/documentation/stable/auto_examples/drawing/plot_giant_component.html#sphx-glr-auto-examples-drawing-plot-giant-component-py
    # with help from https://stackoverflow.com/questions/15548506/node-labels-using-networkx
    # and https://stackoverflow.com/questions/49340520/matplotlib-and-networkx-drawing-a-self-loop-node for plotting
    # This would involve plotting subgraphs with either the nodes being plotted once (unified plot) or multiple times in
    # subfigures (separate)

    # There is an alternative which was recommended by forum posts: using graphviz.  This was mainly because the layout
    # and drawing in graphviz has been refined over a long time.  I have had several collaborators suggest I use grpahviz
    # before.  One of the most important things to me is that the design and communications graphs can have multiple
    # parallel arcs (a Multigraph in networkx) which graphvis apparently handles gracefully (see
    # https://stackoverflow.com/questions/14943439/how-to-draw-multigraph-in-networkx-using-matplotlib-or-graphviz).
    # Using graphviz is covered in the networkx tutorial (at the end of
    # https://networkx.org/documentation/stable/tutorial.html#directed-graphs).  It uses pygraphviz to provide the python
    # connection to graphviz.  The main method involves converting the networkx graph to a pygraphviz AGraph class.
    # See https://networkx.org/documentation/stable/reference/drawing.html#module-networkx.drawing.nx_agraph
    # there is also an alternative scheme which uses pydot.
    #
    # One example of using pygraphviz with multigraphs is
    # https://networkx.org/documentation/stable/auto_examples/pygraphviz/plot_pygraphviz_draw.html#sphx-glr-auto-examples-pygraphviz-plot-pygraphviz-draw-py
    # with another example at https://stackoverflow.com/questions/49340520/matplotlib-and-networkx-drawing-a-self-loop-node
    #
    # The documentation for pygraphviz can be found at https://pygraphviz.github.io/documentation/stable
    # For a tutorial, see https://pygraphviz.github.io/documentation/stable/tutorial.html
    # Specifically look at https://pygraphviz.github.io/documentation/stable/tutorial.html#attributes
    # and https://pygraphviz.github.io/documentation/stable/tutorial.html#layout-and-drawing
    # For layout options, see https://pygraphviz.github.io/documentation/stable/reference/agraph.html#pygraphviz.AGraph.layout

    # When plotting separate cycles, it is worth creating subgraphs which will have their own labels
    # For an example, see http://www.graphviz.org/Gallery/directed/Genetic_Programming.html
    #
    # Graphviz can also cluster nodes together (subgraphs) http://www.graphviz.org/Gallery/directed/cluster.html
    # It is also capable of having arcs between nodes in different subgraphs
    #
    # Graphviz dot attributes http://www.graphviz.org/doc/info/attrs.html.  Also see
    # https://networkx.org/documentation/stable/auto_examples/pygraphviz/plot_pygraphviz_attributes.html
    #
    # Note that draw is capable of several different file formats:
    # https://pygraphviz.github.io/documentation/stable/reference/agraph.html#pygraphviz.AGraph.draw

    # If plotting separately, I plan on getting subgraphs for each cycle and creating a new graph with new node IDs
    # If plotting together, I plan to make a copy of the existing graph, add graphviz parameters, and export

    # Node lables are going to be their names.
    # Arc labels will be the number of initial conditions (if any)
    # Arc colors will be unique so that different cycles can be distinguished

    #Some important attributes
    #style = can change node or line style
    #penwidth = Line width (double)
    #label = label text
    #color = the line color.  Can be an RGB value in this format: "#%2x%2x%2x".  Can also be a color name
    #        Can also be a colorlist (a colon seperated list of colors) which

    # Will use matplotlib's colormap function for this.
    # See https://matplotlib.org/3.3.3/tutorials/colors/colormaps.html and
    # https://stackoverflow.com/questions/25408393/getting-individual-colors-from-a-color-map-in-matplotlib


    #For setting graph, node, and edge properties in networkx, see
    # https://networkx.org/documentation/stable/tutorial.html#adding-attributes-to-graphs-nodes-and-edges

    if plotSeperate:
        # Plot the cycles seperatly
        plotCyclesSeperate(G, cycles, cycleInitConds, dblBufType, plotAll, plotAllNodes, filename)
    else:
        plotCyclesUnified(G, cycles, cycleInitConds, dblBufType, plotAll, plotAllNodes, filename)

if __name__ == '__main__':
    G, dblBufferType, outputName, plotAllNodes = init()
    # print('==== Nodes  =====')
    # printNodes(G)
    # print('==== Arcs   =====')
    # printArcs(G)
    print('==== Cycles =====')
    cycles, cycleInitConds = getCycles(G)
    printCycles(G, cycles, cycleInitConds, dblBufferType, True)
    print('==== Failing Cycles =====')
    printCycles(G, cycles, cycleInitConds, dblBufferType, False)
    print('==== Node Cycle Stats ====')
    printNodeStats(G, cycles, cycleInitConds, dblBufferType)

    if outputName:
        plotCycles(G, cycles, cycleInitConds, dblBufferType, True, False, plotAllNodes, outputName)
        plotCycles(G, cycles, cycleInitConds, dblBufferType, False, False, plotAllNodes, outputName+'_fail')
        plotCycles(G, cycles, cycleInitConds, dblBufferType, True, True, plotAllNodes, outputName)
        plotCycles(G, cycles, cycleInitConds, dblBufferType, False, True, plotAllNodes, outputName+'_fail')

# For the standard scheduling graph - omit cycles that are in all in a single partition
# Get the initial conditions by looking at FIFO initial conditions and delay nodes
#     Can filter out delays