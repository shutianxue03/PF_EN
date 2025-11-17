
% plot_PMF_oneSubject_oneLocation.m
%
% Usage:
% 1. Place this script and the .mat file (containing `pmf`) in the same folder.
% 2. Edit `dataFile` below if needed.
% 3. Run the script. It will generate one figure with psychometric curves
% across selected noise levels.

clear; close all; clc;

%% ---- User settings ----

% Name of the data file
dataFile = 'PMF_SX_SF4_Fovea.mat'; % change if needed

% Which noise levels to plot (indices into pmf.noiseSD)
% Example: plot 5 out of 9 noise levels
indNoise_toPlot = [1 3 5 7 9];

% Marker base size (will be scaled by # of trials)
sz_markerBase = 30;

%% ---- Load data ---
S = load(dataFile);
pmf = S.pmf; % struct described above

nNoise_total = numel(pmf.noiseSD);
assert(all(ismember(indNoise_toPlot, 1:nNoise_total)), ...
    'noiseIdxToPlot must be indices between 1 and %d.', nNoise_total);

% Performance level for threshold visualization
iPerf_plot = pmf.iPerf_plot;
perfLevel = pmf.perfLevels(iPerf_plot); % e.g. 0.75 for 75%

%% ---- Plot psychometric functions ----

figure('Color', 'w'); hold on;

nCurves = numel(indNoise_toPlot);
color_all = lines(nCurves); % distinct colors

str_legends = cell(1, nCurves);

for iCurve = 1:nCurves
    iNoise = indNoise_toPlot(iCurve);

    % Raw data
    y = pmf.raw{iNoise};
    x = y.logContrast(:); % log10 contrast
    pC = y.nCorr(:) ./ y.nTotal(:); % proportion correct

    % Scale marker size by # of trials (for visibility)
    nTrialsMax = max(y.nTotal);
    sz_marker = sz_markerBase + 20 * (y.nTotal / nTrialsMax);

    % Plot raw points
    scatter(x, pC, sz_marker, ...
        'MarkerEdgeColor', color_all(iCurve, :), ...
        'MarkerFaceColor', 'none', ...
        'LineWidth', 1.0, 'HandleVisibility','off');

    % Fitted PMF
    yFit = pmf.yFit(iNoise, :);
    plot(pmf.curveX_log, yFit, 'Color', color_all(iCurve, :), 'LineWidth', 1.5);

    % Threshold line at chosen performance level
    xThresh = pmf.threshLog(iNoise);
    plot([xThresh xThresh], [0.5 perfLevel], '--', ...
        'Color', color_all(iCurve, :), 'LineWidth', 1.0, 'HandleVisibility','off');

    str_legends{iCurve} = sprintf('\\sigma_{noise} = %.3f', pmf.noiseSD(iNoise));
end % end of iCurve

% Horizontal lines at chance and threshold performance level
yline(0.5, 'k--', 'LineWidth', 1.0); % chance
yline(perfLevel, 'k:', 'LineWidth', 1.0); % chosen perf level

% Axis labels & title
xlabel('log_{10} contrast');
ylabel('Proportion correct');

title(sprintf('Subject %s | %s | SF = %.1f cpd', ...
    pmf.subjName, pmf.locationName, pmf.SF));

legend(str_legends, 'Location', 'SouthEast');

ylim([0.4 1.02]);
box off; grid on;

set(gca, 'FontSize', 12);