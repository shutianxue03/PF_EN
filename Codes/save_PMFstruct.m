% --- Build minimal struct for sharing (one subj, one location: fovea) ---

% Goal:
% Export the minimal data needed to plot psychometric functions for
% ONE subject at the FOVEA across all noise levels, in a small .mat file
% (pmf struct) that can be used by a separate plotting script (e.g. Marc.m).
%
% Pipeline (run in this order):
%
% 1) Choose subject
% - Inspect their fits in:
% Shutian_server/PF_EN/Figures/nNoise9/SF4/<subjID>/
% - Decide which subject you want to export.
%
% 2) Set up OOD_boot_withMC
% - Open: OOD_boot_withMC.m
% - Set a breakpoint at: quickPlot_debug (or just before it).
%
% 3) Run OOD_boot_withMC with the following inputs:
% isubj = <index of chosen subject> % see subject list in OOD_boot_withMC
% nNoise = 9;
% SF = 4;
% nBoot = 1;
% flag_estimateThresh = 1;
% flag_binData = 1;
% flag_filterData = 1;
%
% - Let the code run until it hits the breakpoint.
% - At that point, the following variables must exist in the workspace:
% subjName, SF, noiseSD_full, nNoise
% cst_log_unik_all, nCorr_all, nData_all
% yfit_all, thresh_log_allSingle
% fit, iModel, perfThresh_all, iPerf_plot
%
% 4) Run THIS script
% - It will build the `pmf` struct for:
% location = fovea (iLoc = 1)
% - It will save a file:
% PMF_<subjName>_SF<4>_Fovea.mat
%
% 5) Plot (for Marc / collaborators)
% - Run Marc.m (or any clean plotting script) that:
% load('PMF_<subjName>_SF4_Fovea.mat', 'pmf');
% % and then plots pmf.raw, pmf.yFit, pmf.threshLog, etc.

%
pmf = struct();

% Meta info
pmf.subjName = subjName; % e.g. 'SX'
pmf.SF = SF; % e.g. 4
pmf.iLoc = 1; % Fovea
pmf.locationName = 'Fovea'; % hard-code or set appropriately
pmf.noiseSD = noiseSD_full(:)'; % row vector of noise SDs

% Performance levels used in fitting (e.g., 65/70/75%)
pmf.perfLevels = perfThresh_all(:)'/100; % convert to proportion (0–1)
pmf.iPerf_plot = iPerf_plot; % which perf level to plot

% X-grid for fitted PMF
pmf.curveX_log = fit.curveX_log; % log10 contrast grid

% Preallocate containers for each noise level
pmf.raw = cell(1, nNoise); % each cell: raw data for one noise
pmf.yFit = nan(nNoise, numel(pmf.curveX_log));
pmf.threshLog = nan(1, nNoise);

for iNoise = 1:nNoise
 % Raw data
 d = struct();
 d.logContrast = cst_log_unik_all{pmf.iLoc, iNoise}; % log10 contrast values
 d.nCorr = nCorr_all{pmf.iLoc, iNoise}; % # correct
 d.nTotal = nData_all{pmf.iLoc, iNoise}; % # total

 pmf.raw{iNoise} = d;

 % Fitted curve for this noise level
 pmf.yFit(iNoise, :) = yfit_all{pmf.iLoc, iNoise}(iModel, :);

 % Threshold (log10 contrast) at chosen perf level
 pmf.threshLog(iNoise) = ...
 thresh_log_allSingle{pmf.iLoc, iNoise}(iModel, iPerf_plot);
end

% Save to a small, shareable .mat file
outFileName = sprintf('PMF_%s_SF%d_%s.mat', subjName, SF, pmf.locationName);
save(outFileName, 'pmf');
fprintf('Saved minimal PMF file: %s\n', outFileName);