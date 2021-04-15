#!/bin/bash

oldDir=$(pwd)

#Orig 16 Thread Partition Mapping
#TODO: Get this from the build logs/script
partitionCPU=(12 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30)
#partitionCPU=(12 12 13 14 15 16 17 18 19 20 21 16 23 24 25 26 27 28 29 30)

#Epyc 7002
#From lscpu
cpuL3=(0 0 0 0 1 1 1 1 2 2 2 2 3 3 3 3 4 4 4 4 5 5 5 5 6 6 6 6 7 7 7 7 8 8 8 8 9 9 9 9 10 10 10 10 11 11 11 11 12 12 12 12 13 13 13 13 14 14 14 14 15 15 15 15)
#lscpu and AMDuProf both don't give which cores are on which die, will assume groups of 8
#See https://developer.amd.com/wp-content/resources/56782_1.0.pdf for a diagram which may suggest this
#However, it is implied that there is not as much advantage going from CCX-CCX on a single die since
#they both involve the interconnect which involves the I/O die.  There is some discussion of latency differences
#depending on the location of the home node for a piece of memory
#l3Die=(0 0 1 1 2 2 3 3 4 4 5 5 6 6 7 7)

#Version with AGC Settling
#partNames=("RRC" "AGC Pwr. Avg." "AGC Correct. Loop" "AGC Settled" "TR Var. Delay" "TR Golay Corr." "TR Golay Peak" "TR Control" "TR Symbol Clk." "TR Early/Late" "TR Freq. Est" "TR Delay Accum" "Coarse CFO" "EQ" "CFO/Demod/Hdr Parse" "Data Packer" "Pkt. & Freeze Ctrl")

#Version without AGC Settling
partNames=("RRC" "AGC Pwr. Avg." "AGC Correct. Loop" "TR Var. Delay" "TR Golay Corr." "TR Golay Peak" "TR Control" "TR Symbol Clk." "TR Early/Late" "TR Freq. Est" "TR Delay Accum" "Coarse CFO" "EQ" "CFO/Demod/Hdr Parse" "Data Packer" "Pkt. & Freeze Ctrl")

#1Part
#partNames=("All")
#2 Parts
#partNames=("Sample Domain" "Symbol Domain")
#partNames=("RRC, AGC Pwr. Avg., AGC Correct. Loop, TR Var. Delay, TR Golay Corr., TR Golay Peak, TR Control" "TR Symbol Clk., TR Early/Late, TR Freq. Est, TR Delay Accum, Coarse CFO, EQ, CFO/Demod/Hdr Parse, Data Packer, Pkt. & Freeze Ctrl")
#3 Parts
#partNames=("RRC, AGC Pwr. Avg., AGC Correct. Loop, TR Var. Delay, TR Golay Corr." "TR Golay Peak, TR Control, TR Symbol Clk., TR Early/Late, TR Freq. Est, TR Delay Accum" "Coarse CFO, EQ, CFO/Demod/Hdr Parse, Data Packer, Pkt. & Freeze Ctrl")
#4 Parts
#partNames=("RRC, AGC Pwr. Avg., AGC Correct. Loop, TR Var. Delay" "TR Golay Corr., TR Golay Peak, TR Control, TR Symbol Clk." "TR Early/Late, TR Freq. Est, TR Delay Accum, Coarse CFO, Pkt. & Freeze Ctrl" "EQ, CFO/Demod/Hdr Parse, Data Packer")
#partNames=("RRC, AGC Pwr. Avg., AGC Correct. Loop, TR Var. Delay" "TR Golay Corr., TR Golay Peak, TR Control" "TR Symbol Clk., TR Early/Late, TR Freq. Est, TR Delay Accum, Coarse CFO, Pkt. & Freeze Ctrl" "EQ, CFO/Demod/Hdr Parse, Data Packer")

#Get build dir
scriptSrc=$(dirname "${BASH_SOURCE[0]}")
cd "$scriptSrc"
scriptSrc=$(pwd)

cd ${oldDir}

if [[ ! (-d cycles) ]]; then
  mkdir cycles
fi

if [[ ! (-d comm) ]]; then
  mkdir comm
fi

python3 ${scriptSrc}/FindCycles.py ./genSrc/cOut_rev1BB_receiver/rx_demo_communicationInitCondGraph.graphml --dblBuffer none -o cycles/cycles --partition-names "${partNames[@]}"
python3 ${scriptSrc}/ReportCommunication.py ./genSrc/cOut_rev1BB_receiver/rx_demo_communicationInitCondGraph.graphml -o comm/comm --partition-names "${partNames[@]}" --partitionCPUMapping "${partitionCPU[@]}" --cpuL3Mapping "${cpuL3[@]}"