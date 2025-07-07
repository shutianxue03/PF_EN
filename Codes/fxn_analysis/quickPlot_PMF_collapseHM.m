
iPerf_plot = 3;
perfPSE_plot = perfPSE_all(iPerf_plot)/100;

%% plot pC as a fxn of log cst
if ~exist('scaling', 'var'), scaling = 1; end
for icst_unik = 1: length(cst_log_unik)
    if iLocHM<3 % left and right HM
        plot(cst_log_unik(icst_unik), nCorr(icst_unik)/nData(icst_unik), ['s', colorHM], 'MarkerSize',1+round(nData(icst_unik))/3*scaling,'Linewidth',1, 'HandleVisibility', 'off');
    else % collapsed HM 
        plot(cst_log_unik(icst_unik), nCorr(icst_unik)/nData(icst_unik), ['o', colorHM], 'MarkerSize',1+round(nData(icst_unik))/3*scaling,'Linewidth',2, 'HandleVisibility', 'off');
    end
end
curveX_log = log10(fit.curveX).';

LL_med = getCI(LL_allB, 1, 1);
LL_med_delta = LL_med - max(LL_med);

for iModel = 1:nModels
    
    if iModel==4, x = 10.^cst_log_unik; X = 10.^curveX_log; % weibull fit to linear values
    else, x = cst_log_unik; X = curveX_log;
    end
    
    %% extract medians and CIs
    [yfit_med, yfit_lb, yfit_ub] = getCI(yfit_allB(:, iModel, :), 1, 1);
    [PSE_med, PSE_lb, PSE_ub] = getCI(PSE_allB(:, iModel, iPerf_plot), 1, 1);
    %%%%%%%%%%%%
    
    % plot the median of predicted pC
    plot(curveX_log, yfit_med,[ '-', colorHM]) % do NOT change curveX to X!!
    % plot the 68% CI of predicted pC
    patch([curveX_log; flip(curveX_log)], [yfit_lb; flip(yfit_ub)], colorHM, 'facealpha', .1, 'EdgeColor', 'none', 'HandleVisibility', 'off')
    % plot the median of PSE
    plot([-3, PSE_med], [perfPSE_plot, perfPSE_plot], '-', 'color', ones(1,3)/2, 'HandleVisibility', 'off')
    plot([-3, 0], [perfPSE_plot, perfPSE_plot], '-', 'color', ones(1,3)/2, 'HandleVisibility', 'off')
    plot([PSE_med, PSE_med], [0, perfPSE_plot], ['-', colorHM], 'HandleVisibility', 'off')
    yline(.75, '-', 'color', ones(1,3)*.7, 'HandleVisibility', 'off'); % 75%, which should converge with threshold estimated from titration
    
    %CHANGE BACK AFTER PLOTTING PILOT DATA
%     legends_models{iModel} = sprintf('%s (%.1f) %.1f%%', PMF_models{iModel}, LL_med_delta(iModel), 100*10^PSE_med);
end % im=1:nModels

%%

xticks_log = -3:.5:0;
yticks([0, .5,  perfPSE_all/100, 1])

xlim(xticks_log([1,end]))
xticks(xticks_log)%, xtickangle(90)
xticklabels(round(10.^xticks_log*100, 1))
ylim([0, 1])

yline(.5, 'color', ones(1,3)*.5, 'HandleVisibility', 'off');
set(gca, 'XGrid', 'on', 'YGrid', 'off') % grid on

%CHANGE BACK AFTER PLOTTING PILOT DATA
% legend(legends_models, 'Location', 'south', 'NumColumns', 2)
% legend({'Left HM', 'Right HM', 'Collapsed'}, 'Location', 'northwest')



