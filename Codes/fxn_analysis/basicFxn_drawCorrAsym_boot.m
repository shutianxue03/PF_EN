function text_corr_all = basicFxn_drawCorrAsym_boot(x_allBoot, y_allBoot, SF_allBoot, flag_control, str_tail, x_ticks, y_ticks, x_ticklabels, y_ticklabels, text_title, color_regression, marker, wd_border)
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
[nBoot, nsubj] = size(x_allBoot);
corrResults_allB = nan(nBoot, 18);  % 18 metrics × nBoot iterations

x_plot = nan(size(x_allBoot));
y_plot = x_plot;

for iBoot=1:nBoot
    % fprintf('\nBoot%d/%d', iBoot, nBoot)
    % extract x, y, and IV to control for (SF for now)
    x_allSubj = x_allBoot(iBoot, :); x_allSubj = x_allSubj(:); % convert to a column vector
    y_allSubj = y_allBoot(iBoot, :); y_allSubj = y_allSubj(:); % convert to a column vector
    SF_allSubj = SF_allBoot(iBoot, :); SF_allSubj = SF_allSubj(:); % convert to a column vector

    % Conduct corr analysis for each boot
    switch flag_control
        case 0
            % Use raw data
            x_plot(iBoot, :) = x_allSubj;
            y_plot(iBoot, :) = y_allSubj;

            [r2, p_pearson2] = corr(x_allSubj, y_allSubj);
            [rL, p_pearsonL] = corr(x_allSubj, y_allSubj, 'Tail', 'left');
            [rR, p_pearsonR] = corr(x_allSubj, y_allSubj, 'Tail', 'right');

            [rho2, p_spearman2] = corr(x_allSubj, y_allSubj, 'Type', 'Spearman');
            [rhoL, p_spearmanL] = corr(x_allSubj, y_allSubj, 'Type', 'Spearman', 'Tail', 'left');
            [rhoR, p_spearmanR] = corr(x_allSubj, y_allSubj, 'Type', 'Spearman', 'Tail', 'right');

            [tau2, p_kendall2] = corr(x_allSubj, y_allSubj, 'Type', 'Kendall');
            [tauL, p_kendallL] = corr(x_allSubj, y_allSubj, 'Type', 'Kendall', 'Tail', 'left');
            [tauR, p_kendallR] = corr(x_allSubj, y_allSubj, 'Type', 'Kendall', 'Tail', 'right');

        case 1
            % Adjust data by centering within groups
            SF_unik = unique(SF_allSubj)';
            % x_plot = zeros(size(x_allSubj));
            % y_plot = zeros(size(y_allSubj));
            for iSF_unik = SF_unik
                indSF = SF_allSubj == iSF_unik;
                x_plot(iBoot, indSF) = x_allSubj(indSF) - mean(x_allSubj(indSF));
                y_plot(iBoot, indSF) = y_allSubj(indSF) - mean(y_allSubj(indSF));
            end

            [r2, p_pearson2] = partialcorr(x_allSubj, y_allSubj, SF_allSubj);
            [rL, p_pearsonL] = partialcorr(x_allSubj, y_allSubj, SF_allSubj, 'Tail', 'left');
            [rR, p_pearsonR] = partialcorr(x_allSubj, y_allSubj, SF_allSubj, 'Tail', 'right');

            [rho2, p_spearman2] = partialcorr(x_allSubj, y_allSubj, SF_allSubj, 'Type', 'Spearman');
            [rhoL, p_spearmanL] = partialcorr(x_allSubj, y_allSubj, SF_allSubj, 'Type', 'Spearman', 'Tail', 'left');
            [rhoR, p_spearmanR] = partialcorr(x_allSubj, y_allSubj, SF_allSubj, 'Type', 'Spearman', 'Tail', 'right');

            % Kendall's tau cannot be calculated for partial correlation in MATLAB
            tau2 = nan; p_kendall2 = nan; tauL = nan; tauR = nan; p_kendallL = nan; p_kendallR = nan;

    end % switch flag_control
    corrResults_allB(iBoot, :) = [ ...
        r2, p_pearson2, ...
        rL, p_pearsonL, ...
        rR, p_pearsonR, ...
        rho2, p_spearman2, ...
        rhoL, p_spearmanL, ...
        rhoR, p_spearmanR, ...
        tau2, p_kendall2, ...
        tauL, p_kendallL, ...
        tauR, p_kendallR];
end % iBoot

[corr_med, corr_lb, corr_ub] = getCI(corrResults_allB, 1, 1);

% Create a summary string for all correlation statistics
text_corr_all = sprintf(['r=%.2f (%.2f [%.2f, %.2f]) | %.2f (%.2f [%.2f, %.2f]) | %.2f (%.2f [%.2f, %.2f])\n' ...
    'rho=%.2f (%.2f [%.2f, %.2f]) | %.2f (%.2f [%.2f, %.2f]) | %.2f (%.2f [%.2f, %.2f])\n' ...
    'tau=%.2f (%.2f [%.2f, %.2f]) | %.2f (%.2f [%.2f, %.2f]) | %.2f (%.2f [%.2f, %.2f])\n'], ...
    corr_med(1), corr_med(2), corr_lb(2), corr_ub(2), ...
    corr_med(3), corr_med(4), corr_lb(4), corr_ub(4), ...
    corr_med(5), corr_med(6), corr_lb(6), corr_ub(6), ...
    corr_med(7), corr_med(8), corr_lb(8), corr_ub(8), ...
    corr_med(9), corr_med(10), corr_lb(10), corr_ub(10), ...
    corr_med(11), corr_med(12), corr_lb(12), corr_ub(1), ...
    corr_med(13), corr_med(14), corr_lb(14), corr_ub(14), ...
    corr_med(15), corr_med(16), corr_lb(16), corr_ub(16), ...
    corr_med(17), corr_med(18), corr_lb(18), corr_ub(18));

% Get CI of idvd data
x_plot_med = getCI(x_plot, 1, 1);
y_plot_med = getCI(y_plot, 1, 1);

%% Plot setup
hold on;
box on;
% grid on;

%% Draw reference lines at zero
xline(0, 'color', [0.5, 0.5, 0.5], 'linewidth', wd_ref); % Vertical reference line
yline(0, 'color', [0.5, 0.5, 0.5], 'linewidth', wd_ref); % Horizontal reference line

%% Perform and plot linear regression
lm = polyfit(x_plot_med, y_plot_med, 1); % Linear model fit
x_lm2 = linspace(min(x_plot_med), max(x_plot_med), 2); % X-axis range for regression line
yfit = polyval(lm, x_lm2); % Y-values for regression line

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
    switch SF_allSubj(isubj)
        case 4, marker = 's';
        case 5, marker = 'p';
        case 6, marker = 'h';
    end
    plot(x_plot_med(isubj), y_plot_med(isubj), marker, ...
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
title(sprintf('%s\n%s', text_title, text_corr_all));

end