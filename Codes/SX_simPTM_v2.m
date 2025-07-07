% Clear all figures and the command window
close all; clc;
%------------------%
% Load analysis settings
SX_analysis_setting;
%------------------%
SF_fit = 1;
perfThresh_all = [75]; nPerf = length(perfThresh_all);
dprimes = 2*norminv(perfThresh_all/100); % matching LuDosher2008
ub_PTM = [log10(sqrt(2)/max(dprimes)), 5, log10(1), 5/SF_fit];

% Parameter: reference, changed version, and when this param is turned off
Nmul0 = log10(.02); Nmul1 = log10(.01); Nmul_null = -10; assert(max([Nmul0, Nmul1, Nmul_null])<=ub_PTM(1), 'ALERT: Nmul is too high')
% Gamma0 = 4; Gamma1 = 1.5; Gamma_null = 1;
% Nadd0 = log10(0.08); Nadd1 = log10(0.01); Nadd_null = -10;
% Gain0 = 3; Gain1 = 1.5; Gain_null = 1;
%------The Play Zone ------
indParamExist = [0, 1, 1, 1];  % Indices for active parameters
paramsA = {[nan, nan, nan, nan], ...
    [2, -2, 2.28], ... % show change in Gain
    [2, -3, 2.28], ...% show change in Nadd
    [2, -2, 2.28]};% show change in Gamma
paramsB = {[nan, nan, nan, nan], ...
    [2, -2, 1.36], ... % show change in Gain
    [2, -2, 2.28], ...% show change in Nadd
    [4, -2, 2.28]};% show change in Gamma
%--------------------------

% paramsA = [Nmul0, Gamma0, Nadd0, Gain0];
% params_change = [Nmul1, Gamma1, Nadd1, Gain1];
% params_null = [Nmul_null, Gamma_null, Nadd_null, Gain_null];
colors_allLines = [0, 0, 0; 0, .5, 0];  % blue for ref, red for change, gray for turned off
nLines = size(colors_allLines, 1);

% Define noise standard deviation values
% noiseSD_full = [0, 0.055, 0.11, 0.165, 0.22, 0.33, 0.44, 0.66, 0.88] / 2;  % Original scaling
noiseSD_full = 10.^linspace(-1.8, log10(.44) , 5);  % Uniform scaling for fitting

%------------------%
% Load settings for TvC fitting
SX_fitTvC_setting;
%------------------%

% Define y-axis (contrast sensitivity threshold, "cst")
cstEnergy_max = max(noiseSD_full)^2;  % Maximum cst energy based on noise SD
cstEnergy_ticks = linspace(cstEnergy_min, cstEnergy_max, ncst_log);  % Ticks for y-axis

% Define x-axis (noise standard deviation in log scale)
noiseSD_log_min_fake = -1.8;  % Placeholder for plotting
noiseSD_log_all = [noiseSD_log_min_fake, log10(noiseSD_full(2:end))];  % Log scale for noise SD
noiseSD_intp_log_true = linspace(noiseSD_log_all(1), noiseSD_log_all(end), nIntp);  % Interpolated values for fitting
noiseEnergy_true = noiseSD_full.^2;  % Convert to noise energy
noiseEnergy_intp_true = (10.^noiseSD_intp_log_true).^2;  % Interpolated noise energy

% Threshold range in natural log scale
cst_ln_min = 1 / 100;  % Minimum threshold (natural log)
cst_ln_max = 100/100;        % Maximum threshold (natural log)
cst_log_min = log10(cst_ln_min);  % Logarithmic minimum
cst_log_max = log10(cst_ln_max);  % Logarithmic maximum
cst_log_ticks = linspace(cst_log_min, cst_log_max, ncst_log);  % Tick values in log scale
cst_ln_ticks = round(10.^cst_log_ticks * 100);  % Convert to percentage

% Initialize parameters for fitting
nParams = nLF_PTM;  % Number of parameters in the model
namesLF = {'Nmul', 'Gain', 'Nadd', 'NonL'};%namesLF_PTM;  % Names of parameterl

% d-prime values for performance levels
% if 1/max(dprimes)^2-Nmul1^2<=0, error('ERROR: Max dprime or Nmul should be lowered'), end
if Nmul1>sqrt(2)/max(dprimes), error('ERROR: Max dprime or Nmul should be lowered'), end
lines_allPerf = {'-', '--', '-.', '-', '--'};  % Line styles for performance levels
assert(length(lines_allPerf) >= nPerf);

% Define x-axis ticks and labels
x_ticks = noiseSD_log_all;
x_ticklabels = round(noiseSD_full, 3);

% Define y-axis ticks and labels
ticks = cst_log_ticks;
ticklabels = round(cst_ln_ticks);

% Plotting


% iplots = [0, 4,3,2];
for iParam = 2:4
    figure('Position', [0, 0, 500, 500]);  hold on % Large figure size
    % Create subplot for each parameter
    % subplot(1, 3, iParam-1); hold on%; grid on;

    % Initialize legend
    str_legends = cell(nLines*nPerf, 1);

    iline = 1;

    for iPerf = 1:nPerf
        dprime = dprimes(iPerf);
        line_style = lines_allPerf{iPerf};

        % Compute and plot TvN prediction

        % Reference
        %------------------------------------------------------------------------%
        TvN_pred_ref = fxn_PTM(indParamExist, paramsA{iParam}, noiseEnergy_intp_true, dprime, SF_fit);
        %------------------------------------------------------------------------%
        TvN_pred_ref_log = log10(sqrt(TvN_pred_ref));
        plot(noiseSD_intp_log_true, TvN_pred_ref_log, line_style, 'Color', colors_allLines(1, :), 'LineWidth', 1.2);
        % if any(iParam==[1,3])
        %     str_legends{iline} = sprintf('%s=%.2f (d''=%.1f)', namesLF{iParam}, 10.^paramsA(iParam), dprime);
        % else
        %     str_legends{iline} = sprintf('%s=%.2f (d''=%.1f)', namesLF{iParam}, paramsA(iParam), dprime);
        % end
        iline = iline+1;

        % Changed
        % paramsB = paramsA; paramsB(iParam) = params_change(iParam);
        %------------------------------------------------------------------------%
        TvN_pred_change = fxn_PTM(indParamExist, paramsB{iParam}, noiseEnergy_intp_true, dprime, SF_fit);
        %------------------------------------------------------------------------%
        TvN_pred_change_log = log10(sqrt(TvN_pred_change));
        plot(noiseSD_intp_log_true, TvN_pred_change_log, line_style, 'Color', colors_allLines(2, :), 'LineWidth', 1.2);
        % if any(iParam==[1,3])
        %     str_legends{iline} = sprintf('%s=%.2f (d''=%.1f)', namesLF{iParam}, 10.^paramsB(iParam), dprime);
        % else
        %     str_legends{iline} = sprintf('%s=%.2f (d''=%.1f)', namesLF{iParam}, paramsB(iParam), dprime);
        % end
        iline = iline+1;

    end % iPerf

    % Configure subplot
    % legend(str_legends, 'NumColumns', nPerf, 'Location', 'south', 'FontSize', 12);
    xlim([x_ticks(1) - 0.1, log10(sqrt(cstEnergy_ticks(end))) + 0.1]);
    xticks(x_ticks);
    xticklabels(x_ticklabels); xtickangle(90);
    xlabel('Noise SD');

    ylim(ticks([1, end]));
    yticks(ticks);
    yticklabels(ticklabels);
    ylabel('Contrast Threshold');

    ax = gca;
    ax.FontSize = 18;
    title(sprintf('Change in %s', namesLF{iParam}), 'FontSize', 15);
    axis off

    % Adjust font size for all plots
    % set(findall(gcf, '-property', 'FontSize'), 'FontSize', 20);
    set(findall(gcf, '-property', 'linewidth'), 'linewidth', 4)

    saveas(gcf, sprintf('PTM_sim_%s.jpg', namesLF{iParam}))
end % iParam


close all