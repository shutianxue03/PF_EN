# PF_EN

Created by Shutian Xue on Jan 14, 2023  
Updated on Apr 25, 2026

## Repository Overview

This repository is used to generate all figures and statistics in the paper: Xue, S., Barbot, A., Abrams, J., Chen, Q. and Carrasco, M. Distinct system-level computations underlie perceptual variation across the visual field. Proc. Natl. Acad. Sci. U. S. A. 123 (2026).

## Research Goal

Investigate the system-level computations underlying visual-field heterogeneity, including eccentricity effects and polar-angle asymmetries.

## Requirements

- MATLAB R2020b or higher
- Psychtoolbox v3.0.18 or higher for MATLAB
- R packages: `lme4`, `lmerTest`, `emmeans`, `MuMIn`, `partR2`
- Included MATLAB toolboxes: Palamedes, BADS, GPML

## Repository Structure

```text
PF_EN/
├── README.md
└── Codes/
    ├── fxn_exp_v2/         Main experimental functions
    ├── fxn_exp/            Earlier experimental functions and utilities
    ├── fxn_analysis/       Analysis, fitting, and plotting functions
    ├── Rscripts/           Statistical analyses in R
    ├── SX_toolbox/         Helper functions for stimuli, sound, and plotting
    ├── Palamedes/          Psychometric-function toolbox code
    └── SX_IO*.m            Ideal-observer simulation scripts
```

## Data Availability

This repository contains the analysis code. The compressed anonymized data files needed to regenerate the manuscript figures and statistics are deposited in Zenodo: <https://doi.org/10.5281/zenodo.17674399>.

For raw data, please contact Shutian Xue (shutian.xue@nyu.edu).

The three deposited `.mat` files that are directly needed for the figure and statistics pipeline are:

- `params.mat`
- `n12_fitTvN curves_B1000_constim10_Bin1Filter1_collapseHM1_combLoc.mat`
- `n9_fitTvN curves_B1000_constim10_Bin1Filter1_collapseHM1_combLoc.mat`

These files should be placed in the locations expected by the MATLAB scripts:

- `params.mat` is loaded by `Codes/SX_compileOOD_v2.m` from `Data/Data/params.mat` and provides shared experiment and analysis parameters.
- `n12_fitTvN curves_B1000_constim10_Bin1Filter1_collapseHM1_combLoc.mat` and `n9_fitTvN curves_B1000_constim10_Bin1Filter1_collapseHM1_combLoc.mat` are compiled group TvN curves output files used to generate the manuscript-level figures and downstream statistics.

## Recommended Workflow

### 1. Run the experiment

Entry point: `Codes/SX_runExp_v2.m`

- Uses helper functions in `Codes/fxn_exp_v2/` and `Codes/SX_toolbox/`
- Eye tracking is optional; Eyelink setup is included

### 2. Simulate the ideal observer

Entry points:

- `Codes/SX_IO.m`
- `Codes/SX_IO_OnEachTrial.m`
- `Codes/SX_IO_PTM.m`

These scripts simulate performance under ideal-observer and noise-based models.

### 3. Fit PMFs and PTMs

Entry point: `Codes/OOD_boot_withMC.m`

- For each subject, bootstrap fitting saves per-subject TvN curves outputs named like `*_fitTvN curves_B1000_constim10_Bin1Filter1_combLoc.mat`.
- Jobs can be submitted with `Codes/shell_all_fitPMF_full.sh` on an HPC system, or run locally.
- To save and plot PMFs for a selected observer, see `Codes/save_PMFstruct.m` and `Codes/plot_PMFstruct.m`.

### 4. Compile group-level fitting outputs

Entry point: `Codes/SX_compileOOD_v2.m`

This script loads `params.mat`, then gathers the per-subject bootstrap outputs produced by `Codes/OOD_boot_withMC.m` and writes compiled group TvN curves files using the naming pattern:

- `n*_fitTvN curves_B1000_constim10_Bin1Filter1_collapseHM1_combLoc.mat`

The Zenodo files `n12_fitTvN curves_B1000_constim10_Bin1Filter1_collapseHM1_combLoc.mat` and `n9_fitTvN curves_B1000_constim10_Bin1Filter1_collapseHM1_combLoc.mat` are examples of these compiled outputs and are the key inputs for reproducing the manuscript figures and statistics without rerunning the full bootstrap pipeline.

### 5. Run the statistical analyses in R

Location: `Codes/Rscripts/Codes`

Run `R_runAnalysis.R` as the master script for statistical modeling and figure generation.

- The R analysis scripts generate the statistical results reported in the paper.
- They operate on the compiled MATLAB outputs produced in the previous step, including the deposited `n12_...` and `n9_...` TvN curves files.
- Output folders and figures are created automatically by the analysis scripts as needed.

## Contact

Shutian Xue (shutian.xue@nyu.edu)  
Carrasco Lab, Department of Psychology, New York University