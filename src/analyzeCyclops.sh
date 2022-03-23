#!/bin/bash

oldDir=$(pwd)

#Orig 16 Thread Partition Mapping
#TODO: Get this from the build logs/script
#partitionCPU=(12 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31)

#partitionCPU=(12 12 13 14 15 16 17 18 19 20 21 16 23 24 25 26 27 28 29 30)

#Remapping split EQ
#partitionCPU=(27 27 12 13 14 15 16 17 18 20 19 21 22 24 25 28 29 26 23)

#Remapping split EQ - corrected for Ryzen 3000 (Old BIOS)
#partitionCPU=(27 27 9 10 11 12 13 14 15 20 16 21 22 24 25 28 29 26 23)

#Remapping split EQ - corrected for Ryzen 3000 (New BIOS)
partitionCPU=(27 27 12 13 14 15 16 17 18 20 19 21 22 24 25 28 29 26 23)

#Epyc 7002
#From lscpu
#cpuL3=(0 0 0 0
#       1 1 1 1
#       2 2 2 2
#       3 3 3 3
#       4 4 4 4
#       5 5 5 5
#       6 6 6 6
#       7 7 7 7
#       8 8 8 8
#       9 9 9 9
#       10 10 10 10
#       11 11 11 11
#       12 12 12 12
#       13 13 13 13
#       14 14 14 14
#       15 15 15 15)
#lscpu and AMDuProf both don't give which cores are on which die, will assume groups of 8
#See https://developer.amd.com/wp-content/resources/56782_1.0.pdf for a diagram which may suggest this
#However, it is implied that there is not as much advantage going from CCX-CCX on a single die since
#they both involve the interconnect which involves the I/O die.  There is some discussion of latency differences
#depending on the location of the home node for a piece of memory
#l3Die=(0 0 1 1 2 2 3 3 4 4 5 5 6 6 7 7)

##!NOTE: The CPU mapping on the Ryzen 3000 Series (Old BIOS) is different from the other CPUs we have seen!
## L3 0 is comprised of CPUs 0, 17, 18, 19!
# From lsCPU
#cpuL3=(0 1 1 1
#       1 2 2 2
#       2 3 3 3
#       3 4 4 4
#       4 0 0 0
#       5 5 5 5
#       6 6 6 6
#       7 7 7 7)

#Ryzen 3000 (New BIOS)
cpuL3=(0 0 0 0
       1 1 1 1
       2 2 2 2
       3 3 3 3
       4 4 4 4
       5 5 5 5
       6 6 6 6
       7 7 7 7)

#Version with AGC Settling
#partNames=("RRC" "AGC Pwr. Avg." "AGC Correct. Loop" "AGC Settled" "TR Var. Delay" "TR Golay Corr." "TR Golay Peak" "TR Control" "TR Symbol Clk." "TR Early/Late" "TR Freq. Est" "TR Delay Accum" "Coarse CFO" "EQ" "CFO/Demod/Hdr Parse" "Data Packer" "Pkt. & Freeze Ctrl")

#Version without AGC Settling
#partNames=("RRC" "AGC Pwr. Avg." "AGC Correct. Loop" "TR Var. Delay" "TR Golay Corr." "TR Golay Peak" "TR Control" "TR Symbol Clk." "TR Early/Late" "TR Freq. Est" "TR Delay Accum" "Coarse CFO" "EQ" "CFO/Demod/Hdr Parse" "Data Packer" "Pkt. & Freeze Ctrl")

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

#Version with TR Freq Est and TR Delay Accum Combined
#partNames=("RRC" "AGC Pwr. Avg." "AGC Correct. Loop" "TR Var. Delay" "TR Golay Corr." "TR Golay Peak" "TR Control" "TR Symbol Clk." "TR Early/Late" "TR Freq. Est & Delay Accum" "Coarse CFO" "EQ" "CFO/Demod/Hdr Parse" "Data Packer" "Pkt. & Freeze Ctrl")

#Version with TR Early/Late TR Freq Est and TR Delay Accum Combined
#partNames=("RRC" "AGC Pwr. Avg." "AGC Correct. Loop" "TR Var. Delay" "TR Golay Corr." "TR Golay Peak" "TR Control" "TR Symbol Clk." "TR Early/Late, Freq. Est, Delay Accum" "Coarse CFO" "EQ" "CFO/Demod/Hdr Parse" "Data Packer" "Pkt. & Freeze Ctrl")

#Version with TR Early/Late TR Freq Est and TR Delay Accum Combined, Split Symbol Domain With FSM Isolated
#partNames=("RRC" "AGC Pwr. Avg." "AGC Correct. Loop" "TR Var. Delay" "TR Golay Corr." "TR Golay Peak" "TR Control" "TR Symbol Clk." "TR Early/Late, Freq. Est, Delay Accum" "Coarse CFO" "EQ" "CFO/Demod" "Hdr Parse" "Data Packer" "Pkt. & Freeze Ctrl")

#Version with TR Early/Late TR Freq Est and TR Delay Accum Combined, Split Symbol Domain With FSM Combined with Demod
#partNames=("RRC" "AGC Pwr. Avg." "AGC Correct. Loop" "TR Var. Delay" "TR Golay Corr." "TR Golay Peak" "TR Control" "TR Symbol Clk." "TR Early/Late, Freq. Est, Delay Accum" "Coarse CFO" "EQ" "CFO" "Demod/Hdr Parse" "Data Packer" "Pkt. & Freeze Ctrl")

#Version with TR Early/Late TR Freq Est and TR Delay Accum Combined, Reogrganized Header Parse, Split Symbol Domain With FSM Isolated
#partNames=("RRC" "AGC Pwr. Avg." "AGC Correct. Loop" "TR Var. Delay" "TR Golay Corr." "TR Golay Peak" "TR Control" "TR Symbol Clk." "TR Early/Late, Freq. Est, Delay Accum" "Coarse CFO" "EQ" "Hdr Parse" "CFO/Demod" "Data Packer" "Pkt. & Freeze Ctrl")

#Version with TR Early/Late TR Freq Est and TR Delay Accum Combined, Reogrganized Header Parse, Split Symbol Domain 3 Way
#partNames=("RRC" "AGC Pwr. Avg." "AGC Correct. Loop" "TR Var. Delay" "TR Golay Corr." "TR Golay Peak" "TR Control" "TR Symbol Clk." "TR Early/Late, Freq. Est, Delay Accum" "Coarse CFO" "EQ" "Hdr Parse" "CFO" "Demod" "Data Packer" "Pkt. & Freeze Ctrl")

#Coarse/Fine TR With Fine Grain Partitioning
#partNames=("RRC"  # RxRRCPartition = 1;
#           "AGC"       # RxAGCPwrAvgPartition = 2;
#                  # RxAGCCorrectionLoopPartition = 2;
#           "TR Golay Corr"       # RxTimingRecoveryGolayCorrelatorPartition = 3;
#           "TR Golay Peak"       # RxTimingRecoveryGolayPeakDetectPartition = 4;
#           "TR Control"      # RxTimingRecoveryControlPartition = 5;
#           "TR Error Calc & Freq Est"       # RxTimingRecoveryCalcDelayError = 6;
#                  # RxTimingRecoveryFreqEstPartition = 6;
#           "TR Delay Accum"       # RxTimingRecoveryDelayAccumPartition = 7;
#           "TR Var Delay & Symb Clk"       # RxTimingRecoveryVariableDelayPartition = 8;
#                  # RxTimingRecoverySymbolClockPartition = 8;
#           "TR Early/Late"       # RxTimingRecoveryEarlyLatePartition = 9;
#           "Symb Golay Corr"       # RxSymbGolayCorrelatorPartition = 10;
#           "Symb Golay Peak"       # RxSymbGolayPeakDetectPartition = 11;
#           "Coarse CFO"       # RxCoarseCFOPartition = 12;
#           "EQ"       # RxEQPartition = 13;
#           "Fine CFO"       # RxFineCFOPartition = 14;
#           "Demod"       # RxDemodPartition = 15;
#           "Hdr Demod"      # RxHeaderDemodPartition = 16;
#           "Hdr Parse"       # RxHeaderParsePartition = 17;
#           "Packer"       # RxPackerPartition = 18;
#           "Pkt Control"       # RxPacketControllerPartition = 19;
#                  # RxFreezeControllerPartition = 19;
#           )

#Coarse/Fine TR Repartitioned
#partNames=("RRC"  # RxRRCPartition = 1;
#           "AGC"       # RxAGCPwrAvgPartition = 2;
#                  # RxAGCCorrectionLoopPartition = 2;
#           "TR Golay Corr"       # RxTimingRecoveryGolayCorrelatorPartition = 3;
#           "TR Golay Peak"       # RxTimingRecoveryGolayPeakDetectPartition = 4;
#           "TR Control"      # RxTimingRecoveryControlPartition = 5;
#           "TR Error Calc & Freq Est & Delay Accum"       # RxTimingRecoveryCalcDelayError = 6;
#                  # RxTimingRecoveryFreqEstPartition = 6;
#                  # RxTimingRecoveryDelayAccumPartition = 6;
#           "TR Var Delay"       # RxTimingRecoveryVariableDelayPartition = 7;
#           "TR Symb Clk"       # RxTimingRecoverySymbolClockPartition = 8;
#           "TR Early/Late"       # RxTimingRecoveryEarlyLatePartition = 9;
#           "Symb Golay Corr & Peak"       # RxSymbGolayCorrelatorPartition = 10;
#                  # RxSymbGolayPeakDetectPartition = 10;
#           "Coarse CFO"       # RxCoarseCFOPartition = 11;
#           "EQ"       # RxEQPartition = 12;
#           "Fine CFO"       # RxFineCFOPartition = 13;
#           "Hdr Demod & Parse"      # RxHeaderDemodPartition = 14;
#                  # RxHeaderParsePartition = 14;
#           "Demod & Packer"       # RxDemodPartition = 15;
#                  # RxPackerPartition = 15;
#           "Pkt Control"       # RxPacketControllerPartition = 16;
#                  # RxFreezeControllerPartition = 16;
#           )

#Coarse/Fine TR Repartitioned, Split Fine CFO
#partNames=("RRC"  # RxRRCPartition = 1;
#           "AGC"       # RxAGCPwrAvgPartition = 2;
#                  # RxAGCCorrectionLoopPartition = 2;
#           "TR Golay Corr"       # RxTimingRecoveryGolayCorrelatorPartition = 3;
#           "TR Golay Peak"       # RxTimingRecoveryGolayPeakDetectPartition = 4;
#           "TR Control"      # RxTimingRecoveryControlPartition = 5;
#           "TR Error Calc & Freq Est & Delay Accum"       # RxTimingRecoveryCalcDelayError = 6;
#                  # RxTimingRecoveryFreqEstPartition = 6;
#                  # RxTimingRecoveryDelayAccumPartition = 6;
#           "TR Var Delay"       # RxTimingRecoveryVariableDelayPartition = 7;
#           "TR Symb Clk"       # RxTimingRecoverySymbolClockPartition = 8;
#           "TR Early/Late"       # RxTimingRecoveryEarlyLatePartition = 9;
#           "Symb Golay Corr & Peak"       # RxSymbGolayCorrelatorPartition = 10;
#                  # RxSymbGolayPeakDetectPartition = 10;
#           "Coarse CFO"       # RxCoarseCFOPartition = 11;
#           "EQ"       # RxEQPartition = 12;
#           "Fine CFO"       # RxFineCFOPartition = 13;
#           "Fine CFO Correct"       # RxFineCFOPartition = 14;
#           "Hdr Demod & Parse"      # RxHeaderDemodPartition = 15;
#                  # RxHeaderParsePartition = 15;
#           "Demod & Packer"       # RxDemodPartition = 16;
#                  # RxPackerPartition = 16;
#           "Pkt Control"       # RxPacketControllerPartition = 17;
#                  # RxFreezeControllerPartition = 17;
#           )

#Rev 1.4 Block LMS Manually Unrolled
#partNames=(
#"RRC"                                    #VITIS_PARTITION directive of 1 under RootRaisedCosine
#"AGC"                                    #VITIS_PARTITION directive of 2 under AGC/AGCPwrAvg
#                                         #VITIS_PARTITION directive of 2 under AGC/AGCLoopAndCorrect
#                                         #VITIS_PARTITION directive of 2 under Subsystem
#"TR Golay Corr"                          #VITIS_PARTITION directive of 3 under TimingRecoveryAndCorrelator/GolayCorrelatorAndPeakDetectOuter/GolayPeakDetect/GolayCorrelator
#                                         #VITIS_PARTITION directive of 3 under TimingRecoveryAndCorrelator/GolayCorrelatorAndPeakDetectOuter
#"TR Golay Peak"                          #VITIS_PARTITION directive of 4 under TimingRecoveryAndCorrelator/GolayCorrelatorAndPeakDetectOuter/GolayPeakDetect
#"TR Control"                             #VITIS_PARTITION directive of 5 under TimingRecoveryAndCorrelator/TRControl
#                                         #VITIS_PARTITION directive of 5 under TimingRecoveryAndCorrelator/TrControlIntermediateOutputs
#                                         #VITIS_PARTITION directive of 5 under ResetFeedbackAndPipelining
#"TR Error Calc & Freq Est & Delay Accum" #VITIS_PARTITION directive of 6 under TimingRecoveryAndCorrelator/DelayAccum
#                                         #VITIS_PARTITION directive of 6 under TimingRecoveryAndCorrelator/TRFreqEst
#                                         #VITIS_PARTITION directive of 6 under TimingRecoveryAndCorrelator/CalcDelayError
#"TR Var Delay"                           #VITIS_PARTITION directive of 7 under TimingRecoveryAndCorrelator/VarDelayWithSampleAlignment
#"TR Symb Clk & Downsample"               #VITIS_PARTITION directive of 8 under TimingRecoveryAndCorrelator/VarDelayDecimSync
#                                         #VITIS_PARTITION directive of 8 under TimingRecoveryAndCorrelator/SymbolClock
#                                         #VITIS_PARTITION directive of 8 under SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/DownsampleSymbol
#"TR Early/Late"                          #VITIS_PARTITION directive of 9 under TimingRecoveryAndCorrelator/EarlyLate
#"Symb Golay Corr & Peak"                 #VITIS_PARTITION directive of 10 under SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/GolayPeakDetectSymbolDomain/GolayPeakDetectSymbDomain
#                                         #VITIS_PARTITION directive of 10 under SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/GolayPeakDetectSymbolDomain/GolayPeakDetectSymbDomain/GolayCorrelator
#                                         #VITIS_PARTITION directive of 10 under SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/GolayPeakDetectSymbolDomain
#"Coarse CFO"                             #VITIS_PARTITION directive of 11 under SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/CoarseCFOCorrect
#                                         #VITIS_PARTITION directive of 11 under SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/dummyNode
#"EQ & Demod"                             #VITIS_PARTITION directive of 12 under SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/EQ
#"Data Packer"                            #VITIS_PARTITION directive of 16 under SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/DataPacker
#"Pkt Control"                            #VITIS_PARTITION directive of 17 under SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/PacketRxController
#                                         #VITIS_PARTITION directive of 17 under SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/PacketRxControllerUpsample
#                                         #VITIS_PARTITION directive of 17 under SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/FreezeController
#                                         #VITIS_PARTITION directive of 17 under SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/FreezeControllerUpsample
#                                         #VITIS_PARTITION directive of 17 under SymbolDomainOuter
#           )

#Rev 1.5 Split Block LMS
#partNames=(
#"RRC"                                    #VITIS_PARTITION directive of 1 under rx/SampDomain/RootRaisedCosine
#"AGC"                                    #VITIS_PARTITION directive of 2 under rx/SampDomain/AGC/AGCPwrAvg
#                                         #VITIS_PARTITION directive of 2 under rx/SampDomain/AGC/AGCLoopAndCorrect
#                                         #VITIS_PARTITION directive of 2 under rx/Subsystem
#"TR Golay Corr"                          #VITIS_PARTITION directive of 3 under rx/SampDomain/TimingRecoveryAndCorrelator/GolayCorrelatorAndPeakDetectOuter/GolayPeakDetect/GolayCorrelator
#                                         #VITIS_PARTITION directive of 3 under rx/SampDomain/TimingRecoveryAndCorrelator/GolayCorrelatorAndPeakDetectOuter
#"TR Golay Peak"                          #VITIS_PARTITION directive of 4 under rx/SampDomain/TimingRecoveryAndCorrelator/GolayCorrelatorAndPeakDetectOuter/GolayPeakDetect
#"TR Control"                             #VITIS_PARTITION directive of 5 under rx/SampDomain/TimingRecoveryAndCorrelator/TRControl
#                                         #VITIS_PARTITION directive of 5 under rx/SampDomain/TimingRecoveryAndCorrelator/TrControlIntermediateOutputs
#                                         #VITIS_PARTITION directive of 5 under rx/ResetFeedbackAndPipelining
#"TR Error Calc & Freq Est & Delay Accum" #VITIS_PARTITION directive of 6 under rx/SampDomain/TimingRecoveryAndCorrelator/TRFreqEst
#                                         #VITIS_PARTITION directive of 6 under rx/SampDomain/TimingRecoveryAndCorrelator/DelayAccum
#                                         #VITIS_PARTITION directive of 6 under rx/SampDomain/TimingRecoveryAndCorrelator/CalcDelayError
#"TR Var Delay"                           #VITIS_PARTITION directive of 7 under rx/SampDomain/TimingRecoveryAndCorrelator/VarDelayWithSampleAlignment
#"TR Symb Clk & Downsample"               #VITIS_PARTITION directive of 8 under rx/SampDomain/TimingRecoveryAndCorrelator/VarDelayDecimSync
#                                         #VITIS_PARTITION directive of 8 under rx/SampDomain/TimingRecoveryAndCorrelator/SymbolClock
#                                         #VITIS_PARTITION directive of 8 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/DownsampleSymbol
#                                         #VITIS_PARTITION directive of 8 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/dummyNode
#"TR Early/Late"                          #VITIS_PARTITION directive of 9 under rx/SampDomain/TimingRecoveryAndCorrelator/EarlyLate
#"Symb Golay Corr & Peak"                 #VITIS_PARTITION directive of 10 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/GolayPeakDetectSymbolDomain/GolayPeakDetectSymbDomain/GolayCorrelator
#                                         #VITIS_PARTITION directive of 10 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/GolayPeakDetectSymbolDomain/GolayPeakDetectSymbDomain
#                                         #VITIS_PARTITION directive of 10 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/GolayPeakDetectSymbolDomain
#"Coarse CFO"                             #VITIS_PARTITION directive of 11 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/CoarseCFOCorrect
#"EQ & Demod"                             #VITIS_PARTITION directive of 12 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/EQ/BlockLMS/AdaptCoefs/CoefUpdate/VITIS_CLOCK_DOMAIN_UpdateCoefsEveryN/ToCorrection
#                                         #VITIS_PARTITION directive of 12 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/EQ/BlockLMS/AdaptCoefs/CoefUpdate/BreakComboLoop
#                                         #VITIS_PARTITION directive of 12 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/EQ
#"EQ Adapt"                               #VITIS_PARTITION directive of 13 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/EQ/BlockLMS/AdaptCoefs
#                                         #VITIS_PARTITION directive of 13 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/EQ/LMSStepAdaptCtrl/LMSStep
#"Data Packer"                            #VITIS_PARTITION directive of 16 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/DataPacker
#"Pkt Control"                            #VITIS_PARTITION directive of 17 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/PacketRxController
#                                         #VITIS_PARTITION directive of 17 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/PacketRxControllerUpsample
#                                         #VITIS_PARTITION directive of 17 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/FreezeController
#                                         #VITIS_PARTITION directive of 17 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/FreezeControllerUpsample
#                                         #VITIS_PARTITION directive of 17 under rx/SymbolDomainOuter
#           )

#Rev 1.13 Combine Symbol Domain Corr and Coarse CFO
#partNames=(
#"RRC"                                    #VITIS_PARTITION directive of 1 under rx/SampDomain/RootRaisedCosine
#"AGC"                                    #VITIS_PARTITION directive of 2 under rx/SampDomain/AGC/AGCPwrAvg
#                                         #VITIS_PARTITION directive of 2 under rx/SampDomain/AGC/AGCLoopAndCorrect
#                                         #VITIS_PARTITION directive of 2 under rx/Subsystem
#"TR Golay Corr"                          #VITIS_PARTITION directive of 3 under rx/SampDomain/TimingRecoveryAndCorrelator/GolayCorrelatorAndPeakDetectOuter/GolayPeakDetect/GolayCorrelator
#                                         #VITIS_PARTITION directive of 3 under rx/SampDomain/TimingRecoveryAndCorrelator/GolayCorrelatorAndPeakDetectOuter
#"TR Golay Peak"                          #VITIS_PARTITION directive of 4 under rx/SampDomain/TimingRecoveryAndCorrelator/GolayCorrelatorAndPeakDetectOuter/GolayPeakDetect
#"TR Control"                             #VITIS_PARTITION directive of 5 under rx/SampDomain/TimingRecoveryAndCorrelator/TRControl
#                                         #VITIS_PARTITION directive of 5 under rx/SampDomain/TimingRecoveryAndCorrelator/TrControlIntermediateOutputs
#                                         #VITIS_PARTITION directive of 5 under rx/ResetFeedbackAndPipelining
#"TR Error Calc & Freq Est & Delay Accum" #VITIS_PARTITION directive of 6 under rx/SampDomain/TimingRecoveryAndCorrelator/TRFreqEst
#                                         #VITIS_PARTITION directive of 6 under rx/SampDomain/TimingRecoveryAndCorrelator/DelayAccum
#                                         #VITIS_PARTITION directive of 6 under rx/SampDomain/TimingRecoveryAndCorrelator/CalcDelayError
#"TR Var Delay"                           #VITIS_PARTITION directive of 7 under rx/SampDomain/TimingRecoveryAndCorrelator/VarDelayWithSampleAlignment
#"TR Symb Clk & Downsample"               #VITIS_PARTITION directive of 8 under rx/SampDomain/TimingRecoveryAndCorrelator/VarDelayDecimSync
#                                         #VITIS_PARTITION directive of 8 under rx/SampDomain/TimingRecoveryAndCorrelator/SymbolClock
#                                         #VITIS_PARTITION directive of 8 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/DownsampleSymbol
#                                         #VITIS_PARTITION directive of 8 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/dummyNode
#"TR Early/Late"                          #VITIS_PARTITION directive of 9 under rx/SampDomain/TimingRecoveryAndCorrelator/EarlyLate
#"Symb Golay Corr & Peak & Coarse CFO"    #VITIS_PARTITION directive of 10 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/GolayPeakDetectSymbolDomain/GolayPeakDetectSymbDomain/GolayCorrelator
#                                         #VITIS_PARTITION directive of 10 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/GolayPeakDetectSymbolDomain/GolayPeakDetectSymbDomain
#                                         #VITIS_PARTITION directive of 10 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/GolayPeakDetectSymbolDomain
#                                         #VITIS_PARTITION directive of 10 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/CoarseCFOCorrect
#"EQ & Demod"                             #VITIS_PARTITION directive of 12 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/EQ/BlockLMS/AdaptCoefs/CoefUpdate/VITIS_CLOCK_DOMAIN_UpdateCoefsEveryN/ToCorrection
#                                         #VITIS_PARTITION directive of 12 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/EQ/BlockLMS/AdaptCoefs/CoefUpdate/BreakComboLoop
#                                         #VITIS_PARTITION directive of 12 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/EQ
#"EQ Adapt"                               #VITIS_PARTITION directive of 13 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/EQ/BlockLMS/AdaptCoefs
#                                         #VITIS_PARTITION directive of 13 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/EQ/LMSStepAdaptCtrl/LMSStep
#"Data Packer"                            #VITIS_PARTITION directive of 16 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/DataPacker
#"Pkt Control"                            #VITIS_PARTITION directive of 17 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/PacketRxController
#                                         #VITIS_PARTITION directive of 17 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/PacketRxControllerUpsample
#                                         #VITIS_PARTITION directive of 17 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/FreezeController
#                                         #VITIS_PARTITION directive of 17 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/FreezeControllerUpsample
#                                         #VITIS_PARTITION directive of 17 under rx/SymbolDomainOuter
#           )

#Rev 1.15 Combine Symbol Domain Corr and Coarse CFO, Pkt Ctrl and Data Packer
#partNames=(
#"RRC"                                    #VITIS_PARTITION directive of 1 under rx/SampDomain/RootRaisedCosine
#"AGC"                                    #VITIS_PARTITION directive of 2 under rx/SampDomain/AGC/AGCPwrAvg
#                                         #VITIS_PARTITION directive of 2 under rx/SampDomain/AGC/AGCLoopAndCorrect
#                                         #VITIS_PARTITION directive of 2 under rx/Subsystem
#"TR Golay Corr"                          #VITIS_PARTITION directive of 3 under rx/SampDomain/TimingRecoveryAndCorrelator/GolayCorrelatorAndPeakDetectOuter/GolayPeakDetect/GolayCorrelator
#                                         #VITIS_PARTITION directive of 3 under rx/SampDomain/TimingRecoveryAndCorrelator/GolayCorrelatorAndPeakDetectOuter
#"TR Golay Peak"                          #VITIS_PARTITION directive of 4 under rx/SampDomain/TimingRecoveryAndCorrelator/GolayCorrelatorAndPeakDetectOuter/GolayPeakDetect
#"TR Control"                             #VITIS_PARTITION directive of 5 under rx/SampDomain/TimingRecoveryAndCorrelator/TRControl
#                                         #VITIS_PARTITION directive of 5 under rx/SampDomain/TimingRecoveryAndCorrelator/TrControlIntermediateOutputs
#                                         #VITIS_PARTITION directive of 5 under rx/ResetFeedbackAndPipelining
#"TR Error Calc & Freq Est & Delay Accum" #VITIS_PARTITION directive of 6 under rx/SampDomain/TimingRecoveryAndCorrelator/TRFreqEst
#                                         #VITIS_PARTITION directive of 6 under rx/SampDomain/TimingRecoveryAndCorrelator/DelayAccum
#                                         #VITIS_PARTITION directive of 6 under rx/SampDomain/TimingRecoveryAndCorrelator/CalcDelayError
#"TR Var Delay"                           #VITIS_PARTITION directive of 7 under rx/SampDomain/TimingRecoveryAndCorrelator/VarDelayWithSampleAlignment
#"TR Symb Clk & Downsample"               #VITIS_PARTITION directive of 8 under rx/SampDomain/TimingRecoveryAndCorrelator/VarDelayDecimSync
#                                         #VITIS_PARTITION directive of 8 under rx/SampDomain/TimingRecoveryAndCorrelator/SymbolClock
#                                         #VITIS_PARTITION directive of 8 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/DownsampleSymbol
#                                         #VITIS_PARTITION directive of 8 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/dummyNode
#"TR Early/Late"                          #VITIS_PARTITION directive of 9 under rx/SampDomain/TimingRecoveryAndCorrelator/EarlyLate
#"Symb Golay Corr & Peak & Coarse CFO"    #VITIS_PARTITION directive of 10 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/GolayPeakDetectSymbolDomain/GolayPeakDetectSymbDomain/GolayCorrelator
#                                         #VITIS_PARTITION directive of 10 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/GolayPeakDetectSymbolDomain/GolayPeakDetectSymbDomain
#                                         #VITIS_PARTITION directive of 10 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/GolayPeakDetectSymbolDomain
#                                         #VITIS_PARTITION directive of 10 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/CoarseCFOCorrect
#"EQ & Demod"                             #VITIS_PARTITION directive of 12 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/EQ/BlockLMS/AdaptCoefs/CoefUpdate/VITIS_CLOCK_DOMAIN_UpdateCoefsEveryN/ToCorrection
#                                         #VITIS_PARTITION directive of 12 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/EQ/BlockLMS/AdaptCoefs/CoefUpdate/BreakComboLoop
#                                         #VITIS_PARTITION directive of 12 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/EQ
#"EQ Adapt"                               #VITIS_PARTITION directive of 13 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/EQ/BlockLMS/AdaptCoefs
#                                         #VITIS_PARTITION directive of 13 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/EQ/LMSStepAdaptCtrl/LMSStep
#"Pkt Control & Data Packer"              #VITIS_PARTITION directive of 16 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/DataPacker
#                                         #VITIS_PARTITION directive of 16 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/PacketRxController
#                                         #VITIS_PARTITION directive of 16 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/PacketRxControllerUpsample
#                                         #VITIS_PARTITION directive of 16 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/FreezeController
#                                         #VITIS_PARTITION directive of 16 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/FreezeControllerUpsample
#                                         #VITIS_PARTITION directive of 16 under rx/SymbolDomainOuter
#           )

##Rev 1.22 Combine GolayCorr and Golay Peak, Symbol Domain Corr and Coarse CFO, Pkt Ctrl and Data Packer
#partNames=(
#"RRC"                                    #VITIS_PARTITION directive of 1 under rx/SampDomain/RootRaisedCosine
#"AGC"                                    #VITIS_PARTITION directive of 2 under rx/SampDomain/AGC/AGCPwrAvg
#                                         #VITIS_PARTITION directive of 2 under rx/SampDomain/AGC/AGCLoopAndCorrect
#                                         #VITIS_PARTITION directive of 2 under rx/Subsystem
#"TR Golay Corr & Peak"                   #VITIS_PARTITION directive of 3 under rx/SampDomain/TimingRecoveryAndCorrelator/GolayCorrelatorAndPeakDetectOuter/GolayPeakDetect/GolayCorrelator
#                                         #VITIS_PARTITION directive of 3 under rx/SampDomain/TimingRecoveryAndCorrelator/GolayCorrelatorAndPeakDetectOuter
#                                         #VITIS_PARTITION directive of 3 under rx/SampDomain/TimingRecoveryAndCorrelator/GolayCorrelatorAndPeakDetectOuter/GolayPeakDetect
#"TR Control"                             #VITIS_PARTITION directive of 5 under rx/SampDomain/TimingRecoveryAndCorrelator/TRControl
#                                         #VITIS_PARTITION directive of 5 under rx/SampDomain/TimingRecoveryAndCorrelator/TrControlIntermediateOutputs
#                                         #VITIS_PARTITION directive of 5 under rx/ResetFeedbackAndPipelining
#"TR Error Calc & Freq Est & Delay Accum" #VITIS_PARTITION directive of 6 under rx/SampDomain/TimingRecoveryAndCorrelator/TRFreqEst
#                                         #VITIS_PARTITION directive of 6 under rx/SampDomain/TimingRecoveryAndCorrelator/DelayAccum
#                                         #VITIS_PARTITION directive of 6 under rx/SampDomain/TimingRecoveryAndCorrelator/CalcDelayError
#"TR Var Delay"                           #VITIS_PARTITION directive of 7 under rx/SampDomain/TimingRecoveryAndCorrelator/VarDelayWithSampleAlignment
#"TR Symb Clk & Downsample"               #VITIS_PARTITION directive of 8 under rx/SampDomain/TimingRecoveryAndCorrelator/VarDelayDecimSync
#                                         #VITIS_PARTITION directive of 8 under rx/SampDomain/TimingRecoveryAndCorrelator/SymbolClock
#                                         #VITIS_PARTITION directive of 8 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/DownsampleSymbol
#                                         #VITIS_PARTITION directive of 8 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/dummyNode
#"TR Early/Late"                          #VITIS_PARTITION directive of 9 under rx/SampDomain/TimingRecoveryAndCorrelator/EarlyLate
#"Symb Golay Corr & Peak & Coarse CFO"    #VITIS_PARTITION directive of 10 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/GolayPeakDetectSymbolDomain/GolayPeakDetectSymbDomain/GolayCorrelator
#                                         #VITIS_PARTITION directive of 10 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/GolayPeakDetectSymbolDomain/GolayPeakDetectSymbDomain
#                                         #VITIS_PARTITION directive of 10 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/GolayPeakDetectSymbolDomain
#                                         #VITIS_PARTITION directive of 10 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/CoarseCFOCorrect
#"EQ & Demod"                             #VITIS_PARTITION directive of 12 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/EQ/BlockLMS/AdaptCoefs/CoefUpdate/VITIS_CLOCK_DOMAIN_UpdateCoefsEveryN/ToCorrection
#                                         #VITIS_PARTITION directive of 12 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/EQ/BlockLMS/AdaptCoefs/CoefUpdate/BreakComboLoop
#                                         #VITIS_PARTITION directive of 12 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/EQ
#"EQ Adapt"                               #VITIS_PARTITION directive of 13 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/EQ/BlockLMS/AdaptCoefs
#                                         #VITIS_PARTITION directive of 13 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/EQ/LMSStepAdaptCtrl/LMSStep
#"Pkt Control & Data Packer"              #VITIS_PARTITION directive of 16 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/DataPacker
#                                         #VITIS_PARTITION directive of 16 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/PacketRxController
#                                         #VITIS_PARTITION directive of 16 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/PacketRxControllerUpsample
#                                         #VITIS_PARTITION directive of 16 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/FreezeController
#                                         #VITIS_PARTITION directive of 16 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/FreezeControllerUpsample
#                                         #VITIS_PARTITION directive of 16 under rx/SymbolDomainOuter
#           )

##Current fastest partitioning
#Rev 1.22 / 1.32 / 1.34 / 1.40 Combine GolayCorr and Golay Peak, Symbol Domain Corr and Coarse CFO, Pkt Ctrl and Data Packer
partNames=(
"RRC"                                    #VITIS_PARTITION directive of 1 under rx/SampDomain/RootRaisedCosine
"AGC"                                    #VITIS_PARTITION directive of 2 under rx/SampDomain/AGC/AGCPwrAvg
                                         #VITIS_PARTITION directive of 2 under rx/SampDomain/AGC/AGCLoopAndCorrect
                                         #VITIS_PARTITION directive of 2 under rx/Subsystem
"TR Golay Corr & Peak"                   #VITIS_PARTITION directive of 3 under rx/SampDomain/TimingRecoveryAndCorrelator/GolayCorrelatorAndPeakDetectOuter/GolayPeakDetect/GolayCorrelator
                                         #VITIS_PARTITION directive of 3 under rx/SampDomain/TimingRecoveryAndCorrelator/GolayCorrelatorAndPeakDetectOuter
                                         #VITIS_PARTITION directive of 3 under rx/SampDomain/TimingRecoveryAndCorrelator/GolayCorrelatorAndPeakDetectOuter/GolayPeakDetect
"TR Control"                             #VITIS_PARTITION directive of 5 under rx/SampDomain/TimingRecoveryAndCorrelator/TRControl
                                         #VITIS_PARTITION directive of 5 under rx/SampDomain/TimingRecoveryAndCorrelator/TrControlIntermediateOutputs
                                         #VITIS_PARTITION directive of 5 under rx/ResetFeedbackAndPipelining
"TR Error Calc & Freq Est & Delay Accum" #VITIS_PARTITION directive of 6 under rx/SampDomain/TimingRecoveryAndCorrelator/TRFreqEst
                                         #VITIS_PARTITION directive of 6 under rx/SampDomain/TimingRecoveryAndCorrelator/DelayAccum
                                         #VITIS_PARTITION directive of 6 under rx/SampDomain/TimingRecoveryAndCorrelator/CalcDelayError
"TR Var Delay"                           #VITIS_PARTITION directive of 7 under rx/SampDomain/TimingRecoveryAndCorrelator/VarDelayWithSampleAlignment
"TR Symb Clk & Downsample"               #VITIS_PARTITION directive of 8 under rx/SampDomain/TimingRecoveryAndCorrelator/VarDelayDecimSync
                                         #VITIS_PARTITION directive of 8 under rx/SampDomain/TimingRecoveryAndCorrelator/SymbolClock
                                         #VITIS_PARTITION directive of 8 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/DownsampleSymbol
                                         #VITIS_PARTITION directive of 8 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/dummyNode
"TR Early/Late"                          #VITIS_PARTITION directive of 9 under rx/SampDomain/TimingRecoveryAndCorrelator/EarlyLate
"Symb Golay Corr & Peak & Coarse CFO"    #VITIS_PARTITION directive of 10 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/GolayPeakDetectSymbolDomain/GolayPeakDetectSymbDomain/GolayCorrelator
                                         #VITIS_PARTITION directive of 10 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/GolayPeakDetectSymbolDomain/GolayPeakDetectSymbDomain
                                         #VITIS_PARTITION directive of 10 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/GolayPeakDetectSymbolDomain
                                         #VITIS_PARTITION directive of 10 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/CoarseCFOCorrect
"EQ & Demod"                             #VITIS_PARTITION directive of 12 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/EQ/BlockLMS/AdaptCoefs/CoefUpdate/VITIS_CLOCK_DOMAIN_UpdateCoefsEveryN/ToCorrection
                                         #VITIS_PARTITION directive of 12 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/EQ/BlockLMS/AdaptCoefs/CoefUpdate/BreakComboLoop
                                         #VITIS_PARTITION directive of 12 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/EQ
"EQ Adapt"                               #VITIS_PARTITION directive of 13 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/EQ/BlockLMS/AdaptCoefs
                                         #VITIS_PARTITION directive of 13 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/EQ/LMSStepAdaptCtrl/LMSStep
"Pkt Control & Data Packer"              #VITIS_PARTITION directive of 16 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/DataPacker
                                         #VITIS_PARTITION directive of 16 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/PacketRxController
                                         #VITIS_PARTITION directive of 16 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/PacketRxControllerUpsample
                                         #VITIS_PARTITION directive of 16 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/FreezeController
                                         #VITIS_PARTITION directive of 16 under rx/SymbolDomainOuter/VITIS_CLOCK_DOMAIN_SymbolDomain/FreezeControllerUpsample
                                         #VITIS_PARTITION directive of 16 under rx/SymbolDomainOuter
           )

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