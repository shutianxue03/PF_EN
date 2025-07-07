#!/bin/bash
#
#SBATCH --nodes=1
#SBATCH --cpus-per-task=12
#SBATCH --mem=32G
#SBATCH --time=02:00:00
#SBATCH --output=zzz_PMFTvC_%j.out
#SBATCH --mail-user=vivanxuest@gmail.com
#SBATCH --mail-type=END

#########performance evaluation########
wk_dir=$(pwd)
bash $wk_dir/evaluation-performance/evaluation-performance.sh $wk_dir/evaluation-performance/
############end########################

module purge
module load matlab/2020b
 export MATLAB_PREFDIR=$(mktemp -d -t matlab-XXXX)

echo
echo "job name: $SLURM_JOB_NAME"

cat<<EOF | srun matlab -nodisplay

%===============
isubj=$1;
nNoise=$2;
SF=$3;
nBoot=$4;
flag_estimateThresh=$5;
flag_binData=$6;
flag_filterData=$7;

OOD_boot_v2(isubj, nNoise, SF, nBoot, flag_estimateThresh, flag_binData, flag_filterData)

%===============
exit
EOF
 
rm -rf $MATLAB_PREFDIR
exit
