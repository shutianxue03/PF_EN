% README
% Created by Shutian Xue on Jan 14, 2023
% Updated on Jul 7, 2025

%% Research Goal
% Investigate the system-level computations underlying visual field 
% heterogeneity, including eccentricity effects and polar angle asymmetries.

%% Requirements
% - MATLAB R2020b or higher
% - Psychtoolbox v3.0.18 or higher (MATLAB)
% - R packages: lme4, lmerTest, emmeans, MuMIn, partR2 (see Rscripts)
% - Included MATLAB toolboxes: Palamedes, BADS, GPML

%% Folder Structure
% ├── Codes/
% │   ├── fxn_exp_v2/         % Main experimental scripts
% │   ├── fxn_analysis/       % Data analysis and model fitting
% │   ├── Rscripts/           % Statistical modeling in R
% │   ├── SX_toolbox/         % Helper functions: stimuli, sound, plotting
% │   ├── fxn_IO/             % Ideal observer simulation
% ├── Data/
% │   ├── Data/               % Raw data (per session/block)
% │   ├── Data_OOD/           % Bootstrapped PMF and PTM fitting results
% │   ├── R_DataTable/        % Long-format CSVs for R analysis
% │   ├── Data_old/           % Legacy data (e.g., from Jared & Antoine, SF=5)
% │   ├── eyedata/            % Eye tracking data
% └── Figures/                % Plots and figures for publication

%% Running the Experiment
% Entry point: SX_runExp_v2.m
% - Uses helper functions in fxn_exp_v2/ and SX_toolbox/
% - Eye tracking is optional (Eyelink setup included)

%% Simulating the Ideal Observer
% Entry point: SX_IOxx.m
% - Scripts simulate performance under noise-based observer models

%% Fitting PMFs and PTMs on HPC
% Entry point: OOD_boot_withMC.m
% - Submit jobs using shell_all_fitPMF_full on any HPC (originally run on NYU’s Greene HPC cluster)
% - Alternatively, scripts can be run locally

%% Compile estimated parameters 
% SX_compileOOD_V2.m

%% Statistical Analysis in R
% Location: Codes/Rscripts/Codes
% - R_runAnalysis.R: master script for statistical modeling

% Output:
% - Fixed/random effect results from LMMs and ANOVAs saved as .txt files in:
%     Codes/Rscripts/Outputs/
% - Plots saved in: 
%     Figures/acrossSFs/SF46/R_Figures/ (folders generated automatically)

%% Contact
% Shutian Xue (sx2626@nyu.edu)  
% Carrasco Lab, Department of Psychology, New York University
