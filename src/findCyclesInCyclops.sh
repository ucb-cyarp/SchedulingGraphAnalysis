#!/bin/bash

oldDir=$(pwd)

#Version with AGC Settling
#partNames=("RRC" "AGC Pwr. Avg." "AGC Correct. Loop" "AGC Settled" "TR Var. Delay" "TR Golay Corr." "TR Golay Peak" "TR Control" "TR Symbol Clk." "TR Early/Late" "TR Freq. Est" "TR Delay Accum" "Coarse CFO" "EQ" "CFO/Demod/Hdr Parse" "Data Packer" "Pkt. & Freeze Ctrl")

#Version without AGC Settling
partNames=("RRC" "AGC Pwr. Avg." "AGC Correct. Loop" "TR Var. Delay" "TR Golay Corr." "TR Golay Peak" "TR Control" "TR Symbol Clk." "TR Early/Late" "TR Freq. Est" "TR Delay Accum" "Coarse CFO" "EQ" "CFO/Demod/Hdr Parse" "Data Packer" "Pkt. & Freeze Ctrl")

#Get build dir
scriptSrc=$(dirname "${BASH_SOURCE[0]}")
cd "$scriptSrc"
scriptSrc=$(pwd)

cd ${oldDir}

if [[ ! (-d cycles) ]]; then
  mkdir cycles
fi

python3 ${scriptSrc}/FindCycles.py ./genSrc/cOut_rev1BB_receiver/rx_demo_communicationInitCondGraph.graphml --dblBuffer none -o cycles/cycles --partition-names "${partNames[@]}"