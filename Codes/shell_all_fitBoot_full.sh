#!/bin/bash

nBoot=1
flag_estimateThresh=0
flag_binData=1
flag_filterData=1

nNoise=9
SF=6
for isubj in $(seq 1 12)
do
    sbatch shell_fitPMF_v2.sh $isubj $nNoise $SF $nBoot $flag_estimateThresh $flag_binData $flag_filterData
done

SF=4
for isubj in $(seq 1 9)
do
    sbatch shell_fitPMF_v2.sh $isubj $nNoise $SF $nBoot $flag_estimateThresh $flag_binData $flag_filterData
done
