
str_note = sprintf('nB%d_%s_B%d', fit.nBoot_PMF, str_PMF_fittingMethod, iBoot);

for iNoise = 1:nNoise

    figure('Position', [0 0 2e3 2e3])
    iplot=1;
    for iLoc = 1:nLocSingle
        subplot(5,5, iplots9(iLoc)), hold on
        perfThresh_plot = perfThresh_all(iPerf_plot)/100;

        % extract raw data
        cst_log_unik = cst_log_unik_all{iLoc, iNoise};
        nCorr = nCorr_all{iLoc, iNoise};
        nData = nData_all{iLoc, iNoise};
        estP = estP_all{iLoc, iNoise};
        yfit_allM = yfit_all{iLoc, iNoise};
        thresh_log = thresh_log_allSingle{iLoc, iNoise};
        LL = LL_allSingle(iLoc, iNoise, :);  % Log-likelihood values for bootstrap iterations
        R2 = R2_weighted_allSingle(iLoc, iNoise, :);  % Weighted R² values for bootstrap iterations

        % plot pC as a fxn of log cst
        for icst_unik = 1: length(cst_log_unik)
            plot(cst_log_unik(icst_unik), nCorr(icst_unik)/nData(icst_unik), 'ok',...
                'MarkerSize',1+round(nData(icst_unik))/6,'Linewidth',1, 'HandleVisibility', 'off');
        end

        % Plot PMF and extract thresh
        for iModel = 1:nModels

            % plot predicted pC
            plot(fit.curveX_log, yfit_allM(iModel, :), [ '-', colors_allM{iModel}]) % do NOT change curveX to X!!

            % Plot estimated thresh
            plot([-3, thresh_log(iModel, iPerf_plot)], [perfThresh_plot, perfThresh_plot], '-', 'color', ones(1,3)/2, 'HandleVisibility', 'off')
            plot([-3, log10(2)], [perfThresh_plot, perfThresh_plot], '-', 'color', ones(1,3)/2, 'HandleVisibility', 'off')
            plot([thresh_log(iModel, iPerf_plot), thresh_log(iModel, iPerf_plot)], [log10(2), perfThresh_plot], ['-', colors_allM{iModel}], 'HandleVisibility', 'off')

            % CHANGE BACK AFTER PLOTTING PILOT DATA
            legends_models{iModel} = sprintf('%s (%.1f) T%.1f R%.0f%%', ...
                PMF_models{iModel}(1), LL(iModel), 10^thresh_log(iModel, iPerf_plot)*100, ...
                R2(iModel)*100);
        end % im=1:nModels

        yticks([0, .5,  perfThresh_all/100, 1])
        xticks_log = -2:.25:0;
        xlim(cst_log_ticks([1,end]))
        xticks(cst_log_ticks), xtickangle(90)
        xticklabels(cst_ln_ticks)
        ylim([0, 1])

        yline(.5, 'color', ones(1,3)*.5);
        set(gca, 'XGrid', 'on', 'YGrid', 'off') % grid on

        %CHANGE BACK AFTER PLOTTING PILOT DATA
        legend(legends_models, 'Location', 'south', 'NumColumns', 2)
        title(sprintf('L%d N%d (constim=%d) (%d trials)', iLoc, iNoise, length(nData), sum(nData)))

    end % iLoc

    set(findall(gcf, '-property', 'fontsize'), 'fontsize',10)
    set(findall(gcf, '-property', 'LineWidth'), 'LineWidth',1.5)
    sgtitle(sprintf('%s [%s] (SF=%d, NoiseSD=%.3f)  %.0f%% [Bin%dFilter%d] [Constim=%d]', ...
        subjName, str_PMF_fittingMethod, SF, noiseSD_full(iNoise), perfThresh_plot*100, flag_binData, flag_filterData, fit.nBins))

    % saveas(gcf, sprintf('PMF_%s/N%d_%s.jpg', subjName, iNoise, str_note))
end % iNoise
