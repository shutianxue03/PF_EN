#!/bin/bash

nBoot=1000
flag_estimateThresh=0
flag_binData=1
flag_filterData=1

nNoise=9
SF=4
for isubj in $(seq 1 9)
do
    sbatch shell_fitPMF.sh $isubj $nNoise $SF $nBoot $flag_estimateThresh $flag_binData $flag_filterData
done

SF=6
for isubj in $(seq 1 12)
do
    sbatch shell_fitPMF.sh $isubj $nNoise $SF $nBoot $flag_estimateThresh $flag_binData $flag_filterData
done

nNoise=7
SF=5
for isubj in $(seq 1 6)
do
    sbatch shell_fitPMF.sh $isubj $nNoise $SF $nBoot $flag_estimateThresh $flag_binData $flag_filterData
done

SF=51
for isubj in $(seq 1 4)
do
    sbatch shell_fitPMF.sh $isubj $nNoise $SF $nBoot $flag_estimateThresh $flag_binData $flag_filterData
done