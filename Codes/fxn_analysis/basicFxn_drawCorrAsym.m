function text_corr_all = basicFxn_drawCorrAsym(asymX_med_allSubj, asymY_med_allSubj, flag_control, indIV, str_tail, x_ticks, y_ticks, x_ticklabels, y_ticklabels, text_title, color_regression, marker, wd_border)
% Function to plot and compare asymmetries between two measurements.
%
% Inputs:
%    asymX_med_allSubj: nsubj x 1 array, median of bootstrapping, to plot on the x-axis.
%    asymY_med_allSubj: nsubj x 1 array, median of bootstrapping, to plot on the y-axis.
%    flag_control: binary flag; 0 for raw data, 1 for adjusted data by controlling for indIV.
%    indIV: grouping variable for partial correlation (vector of same size as input arrays).
%    x_ticks, y_ticks: vectors specifying the axis tick positions.
%    x_ticklabels, y_ticklabels: vectors specifying the axis tick labels.
%    text_title: string for the plot title.
%    color_regression: RGB triplet or color name for regression line.
%    marker: marker style for individual data points.
%
% Output:
%    text_corr_all: formatted string summarizing the correlation statistics.

%% Figure settings
fsz_ticks = 10; % Font size for tick labels
sz_marker = wd_border*10;  % Marker size; 30 for pre3, 8 for others
wd_ref = 1;   % Line width for reference lines, 3 for pre3, 1.5 for others
%------------------%
SX_analysis_setting;
%------------------%

%% Validate inputs
nsubj = length(asymX_med_allSubj); % Number of subjects
assert(nsubj == length(asymY_med_allSubj), 'Input arrays must have the same length.');

%% Handle data adjustment based on flag_control
switch flag_control
    case 0
        % Use raw data
        x_asym_plot = asymX_med_allSubj;
        y_asym_plot = asymY_med_allSubj;
        indIV = nan; % Not needed when flag_control is 0
    case 1
        % Adjust data by centering within groups
        indIV_unik = unique(indIV)';
        x_asym_plot = zeros(size(asymX_med_allSubj));
        y_asym_plot = zeros(size(asymY_med_allSubj));
        for ind = indIV_unik
            idx = indIV == ind;
            x_asym_plot(idx) = asymX_med_allSubj(idx) - mean(asymX_med_allSubj(idx));
            y_asym_plot(idx) = asymY_med_allSubj(idx) - mean(asymY_med_allSubj(idx));
        end
end

%% Plot setup
hold on;
box on;
% grid on;

%% Draw reference lines at zero
xline(0, 'color', [0.5, 0.5, 0.5], 'linewidth', wd_ref); % Vertical reference line
yline(0, 'color', [0.5, 0.5, 0.5], 'linewidth', wd_ref); % Horizontal reference line

%% Calculate correlations

if flag_control % Partial correlations controlling for an IV
    [r2, p_pearson2] = partialcorr(asymX_med_allSubj, asymY_med_allSubj, indIV);
    [rL, p_pearsonL] = partialcorr(asymX_med_allSubj, asymY_med_allSubj, indIV, 'Tail', 'left');
    [rR, p_pearsonR] = partialcorr(asymX_med_allSubj, asymY_med_allSubj, indIV, 'Tail', 'right');
    
    [rho2, p_spearman2] = partialcorr(asymX_med_allSubj, asymY_med_allSubj, indIV, 'Type', 'Spearman');
    [rhoL, p_spearmanL] = partialcorr(asymX_med_allSubj, asymY_med_allSubj, indIV, 'Type', 'Spearman', 'Tail', 'left');
    [rhoR, p_spearmanR] = partialcorr(asymX_med_allSubj, asymY_med_allSubj, indIV, 'Type', 'Spearman', 'Tail', 'right');
    
    % Kendall's tau cannot be calculated for partial correlation in MATLAB
    tau2 = nan; p_kendall2 = nan; tauL = nan; tauR = nan; p_kendallL = nan; p_kendallR = nan;
else % Standard correlations
    [r2, p_pearson2] = corr(asymX_med_allSubj, asymY_med_allSubj);
    [rL, p_pearsonL] = corr(asymX_med_allSubj, asymY_med_allSubj, 'Tail', 'left');
    [rR, p_pearsonR] = corr(asymX_med_allSubj, asymY_med_allSubj, 'Tail', 'right');
    
    [rho2, p_spearman2] = corr(asymX_med_allSubj, asymY_med_allSubj, 'Type', 'Spearman');
    [rhoL, p_spearmanL] = corr(asymX_med_allSubj, asymY_med_allSubj, 'Type', 'Spearman', 'Tail', 'left');
    [rhoR, p_spearmanR] = corr(asymX_med_allSubj, asymY_med_allSubj, 'Type', 'Spearman', 'Tail', 'right');
    
    [tau2, p_kendall2] = corr(asymX_med_allSubj, asymY_med_allSubj, 'Type', 'Kendall');
    [tauL, p_kendallL] = corr(asymX_med_allSubj, asymY_med_allSubj, 'Type', 'Kendall', 'Tail', 'left');
    [tauR, p_kendallR] = corr(asymX_med_allSubj, asymY_med_allSubj, 'Type', 'Kendall', 'Tail', 'right');
end

% Create a summary string for all correlation statistics
text_corr_all = sprintf(['r=%.2f (%.3f) | %.2f (%.3f) | %.2f (%.3f)\n' ...
                                 'rho=%.2f (%.3f) | %.2f (%.3f) | %.2f (%.3f)\n' ...
                                 'tau=%.2f (%.3f) | %.2f (%.3f) | %.2f (%.3f)\n'], ...
                         r2, p_pearson2, rL, p_pearsonL, rR, p_pearsonR, ...
                         rho2, p_spearman2, rhoL, p_spearmanL, rhoR, p_spearmanR, ...
                         tau2, p_kendall2, tauL, p_kendallL, tauR, p_kendallR);

%% Perform and plot linear regression
lm = polyfit(x_asym_plot, y_asym_plot, 1); % Linear model fit
x_lm2 = linspace(min(x_asym_plot), max(x_asym_plot), 2); % X-axis range for regression line
yfit = polyval(lm, x_lm2); % Y-values for regression line
eta2 = var(polyval(lm, x_asym_plot)) / var(x_asym_plot); % Effect size (optional)

% Customize regression line appearance
marker_facecolor = 'w';
marker_edgecolor = 'k';
switch str_tail
    case 'left', p = p_spearmanL;
    case 'right', p = p_spearmanR;
    case 'two', p= p_spearman2;
end
if p < 0.05
    plot(x_lm2, yfit, '-', 'color', color_regression, 'linewidth', wd_border * 2);
    marker_facecolor = 'k'; % Highlight markers for significance
elseif p < 0.1
    plot(x_lm2, yfit, '--', 'color', color_regression, 'linewidth', wd_border * 2);
    marker_facecolor = [0.5, 0.5, 0.5];
end

%% Plot individual data points
for isubj = 1:nsubj
    plot(x_asym_plot(isubj), y_asym_plot(isubj), marker, ...
        'markerfacecolor', marker_facecolor, 'markeredgecolor', marker_edgecolor, 'markersize', sz_marker, 'linewidth', wd_border);
end

%% Set axis ticks and limits
if ~isnan(x_ticks), xticks(x_ticks); xlim([x_ticks(1), x_ticks(end)]); end
if ~isnan(y_ticks), yticks(y_ticks); ylim([y_ticks(1), y_ticks(end)]); end

%% Configure plot aesthetics
axis square;
ax = gca;
ax.XAxis.FontSize = fsz_ticks;
ax.YAxis.FontSize = fsz_ticks;
ax.LineWidth = wd_border;

%% Add title
% title(sprintf('%s\n%s', text_title, text_corr_all));

end