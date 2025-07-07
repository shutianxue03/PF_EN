
perfThresh_plot = perfThresh_all(iPerf_plot)/100;

%% extract raw data
cst_log_unik = cst_log_unik_all{iLoc, iNoise};
nCorr = nCorr_all{iLoc, iNoise};
nData = nData_all{iLoc, iNoise};
yfit_allB = yfit_all{iLoc, iNoise};
thresh_log_allB = thresh_log_all{iLoc, iNoise};

%% plot pC as a fxn of log cst
if ~exist('scaling', 'var'), scaling = 1; end
for icst_unik = 1: length(cst_log_unik)
    plot(cst_log_unik(icst_unik), nCorr(icst_unik)/nData(icst_unik), 'ok',...
        'MarkerSize',1+round(nData(icst_unik))/3*scaling,'Linewidth',1, 'HandleVisibility', 'off');
end

%% plot PMF and extract thresh
nModels = 4;
legends_models = {};

LL_med = getCI(LL_allB(:, iLoc, iNoise, :), 1, 1);
LL_med_delta = LL_med - max(LL_med);

for iModel = 1:nModels

    % Extract medians and CIs
    [yfit_med, yfit_lb, yfit_ub] = getCI(yfit_allB(:, iModel, :), 1, 1);
    [thresh_med, thresh_lb, thresh_ub] = getCI(thresh_log_allB(:, iModel, iPerf_plot), 1, 1);

    % plot the median of predicted pC
    plot(fit.curveX_log, yfit_med,[ '-', colors_allM{iModel}]) % do NOT change curveX to X!!
    % plot the 68% CI of predicted pC
    patch([fit.curveX_log, flip(fit.curveX_log)], [yfit_lb(:); flip(yfit_ub(:))], colors_allM{iModel}, 'facealpha', .1, 'EdgeColor', 'none', 'HandleVisibility', 'off')
    % plot the median of thresh
    plot([-3, thresh_med], [perfThresh_plot, perfThresh_plot], '-', 'color', ones(1,3)/2, 'HandleVisibility', 'off')
    plot([-3, log10(2)], [perfThresh_plot, perfThresh_plot], '-', 'color', ones(1,3)/2, 'HandleVisibility', 'off')
    plot([thresh_med, thresh_med], [log10(2), perfThresh_plot], ['-', colors_allM{iModel}], 'HandleVisibility', 'off')

    %CHANGE BACK AFTER PLOTTING PILOT DATA
    legends_models{iModel} = sprintf('%s (%.1f) T%.1f R%.0f%%', ...
        PMF_models{iModel}(1), LL_med_delta(iModel), 10^thresh_med*100, ...
        getCI(R2_weighted_allB(:, iLoc, iNoise, iModel), 1, 1)*100);
end % im=1:nModels


%%
if nNoise>2
    yticks([0, .5,  perfThresh_all/100, 1])
    if nLocSingle==9, xticks_log = -2:.25:0;
    elseif nLocSingle==5, xticks_log = -3:.2:0;
    end
else
    xticks_log = -2:.1:.6;
    yticks([0, .4, .5, .6, .7, perfThresh_all/100, .9, 1])
end

xlim(cst_log_ticks([1,end]))
xticks(cst_log_ticks), xtickangle(90)
xticklabels(cst_ln_ticks)
ylim([0, 1])

yline(.5, 'color', ones(1,3)*.5);
set(gca, 'XGrid', 'on', 'YGrid', 'off') % grid on

%CHANGE BACK AFTER PLOTTING PILOT DATA
legend(legends_models, 'Location', 'south', 'NumColumns', 2)
title(sprintf('L%d N%d (constim=%d) (%d trials)', iLoc, iNoise, length(nData), sum(nData)))
% iplot = iplot + 1;


