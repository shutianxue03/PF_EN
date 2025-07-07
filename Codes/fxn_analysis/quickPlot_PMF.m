
iPerf_plot = 1;
perfThresh_plot = perfThresh_all(iPerf_plot)/100;

cst_ln_min = 1/100; % Minimum contrast threshold in linear scale (1% contrast)
cst_ln_max = gaborCST_ub; % Maximum contrast threshold in linear scale (100% contrast)
% Logarithmic contrast threshold settings
ncst_log = 5; % Number of logarithmic contrast threshold ticks
% Convert contrast thresholds from linear to logarithmic scale
cst_log_min = log10(cst_ln_min); % Logarithm of minimum contrast (1%)
cst_log_max = log10(cst_ln_max); % Logarithm of maximum contrast (100%)
% Generate logarithmic contrast threshold ticks
cst_log_ticks = linspace(cst_log_min, cst_log_max, ncst_log);
cst_ln_ticks = round(10.^cst_log_ticks * 100); % Convert back to linear scale and round

figure, hold on

% plot pC as a fxn of log cst
if ~exist('scaling', 'var'), scaling = 1; end
for icst_unik = 1: length(cst_log_unik)
    plot(cst_log_unik(icst_unik), nCorr(icst_unik)/nData(icst_unik), 'ok','MarkerSize',1+round(nData(icst_unik))/3*scaling,'Linewidth',1, 'HandleVisibility', 'off');
end
curveX_log = fit.curveX_log.';

LL_med = getCI(LL_allB, 1, 1);
LL_med_delta = LL_med - max(LL_med);

for iModel = 1:nModels
    
    if iModel==4, x = 10.^cst_log_unik; X = 10.^curveX_log; % weibull fit to linear values
    else, x = cst_log_unik; X = curveX_log;
    end
    
    %% extract medians and CIs
    [yfit_med, yfit_lb, yfit_ub] = getCI(pC_pred_allB(:, iModel, :), 1, 1);
    [thresh_log_med, thresh_log_lb, thresh_log_ub] = getCI(thresh_log_allB(:, iModel, iPerf_plot), 1, 1);
    R2_med = getCI(R2_weighted_allB(:, iModel), 1, 1);
    %%%%%%%%%%%%)
    
    % plot the median of predicted pC
    plot(curveX_log, yfit_med,[ '-', colors_allM{iModel}]) % do NOT change curveX to X!!
    % plot the 68% CI of predicted pC
    patch([curveX_log; flip(curveX_log)], [yfit_lb; flip(yfit_ub)], colors_allM{iModel}, 'facealpha', .1, 'EdgeColor', 'none', 'HandleVisibility', 'off')
    % plot the median of PSE
    plot([-3, thresh_log_med], [perfThresh_plot, perfThresh_plot], '-', 'color', ones(1,3)/2, 'HandleVisibility', 'off')
    plot([-3, 0], [perfThresh_plot, perfThresh_plot], '-', 'color', ones(1,3)/2, 'HandleVisibility', 'off')
    plot([thresh_log_med, thresh_log_med], [0, perfThresh_plot], ['-', colors_allM{iModel}], 'HandleVisibility', 'off')
%     yline(.75, '-', 'color', ones(1,3)*.7, 'HandleVisibility', 'off'); % 75%, which should converge with threshold estimated from titration
    
    %CHANGE BACK AFTER PLOTTING PILOT DATA
    legends_models{iModel} = sprintf('%s (%.1f) T%.1f%% R2%.2f', PMF_models{iModel}, LL_med_delta(iModel), 100*10^thresh_log_med, R2_med);
end % im=1:nModels

xlim(cst_log_ticks([1,end]))
xticks(cst_log_ticks)%, xtickangle(90)
xticklabels(cst_ln_ticks)

ylim([.5, 1])
yticks([.5,  perfThresh_plot, 1])
yline(.5, 'color', ones(1,3)*.5);
set(gca, 'XGrid', 'on', 'YGrid', 'off') % grid on

%CHANGE BACK AFTER PLOTTING PILOT DATA
legend(legends_models, 'Location', 'northwest', 'NumColumns', 2)

