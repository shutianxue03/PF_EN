
if ~flag_combineMode
    if nNoise==2, figure('Position', [0 0 nNoise*400 300]) % nNoise=2, n=5
    elseif nNoise>=7, figure('Position', [0 0 2e3 2e3])
    end
    hold on
    
    for iNoise=1:nNoise
        if nNoise==2, subplot(1, nNoise, iNoise)
        elseif nNoise>=7, subplot(3,3, iNoise)
        end
        hold on, grid on
        
        % idvd data
        for isubj=1:nsubj
            plot((1:nLoc) + randn(1, nLoc)/8, squeeze(thresh_log_allSubj(isubj, indLoc, iNoise, iPerf_plot)), ['-', markers_allSubj{isubj}], ...
                'Color', ones(1,3)/2, 'MarkerSize', 8, 'MarkerFaceColor', 'w')
        end
        
        % get mean and SEM
        [thresh_ave, ~, ~, thresh_sem] = getCI(thresh_log_allSubj(:, :, iNoise, iPerf_plot), 2,1);
        for iLoc = indLoc
            %             bar(find(iLoc == indLoc), thresh_ave(iLoc), 'FaceColor', 'w', 'EdgeColor', colors_allLoc(iLoc, :), 'LineWidth', 2, 'BarWidth', .5, 'HandleVisibility', 'off')
            plot(find(iLoc == indLoc), thresh_ave(iLoc), 'o', 'MarkerFaceColor', colors_allLoc(iLoc, :), 'MarkerEdgeColor', 'w', 'HandleVisibility', 'off', 'MarkerSize', 6)
            errorbar(find(iLoc == indLoc), thresh_ave(iLoc), thresh_sem(iLoc), '.', 'color', colors_allLoc(iLoc, :), 'CapSize', 0, 'LineWidth', 2, 'HandleVisibility', 'off')
        end
        
        xticks(1:nLoc), xticklabels(names_allLoc(indLoc)),xlim([.5,nLoc+.5]), xtickangle(90)
        ylim(cst_log_ticks([1, end]))
        yticks(cst_log_ticks)
        yticklabels(cst_ln_ticks)
        ylabel(sprintf('Threshold (%.d%%)', perfThresh_all(iPerf_plot)))
        title(sprintf('noise=%.3f', noiseSD_full(iNoise)))
    end
    legend(subjList, 'Location', 'best','NumColumns', round(nsubj/2))
    sgtitle(sprintf('SF%d n=%d (%d%%) [collapse HM=%d]', SF, nsubj, perfThresh_all(iPerf_plot), flag_collapseHM))
    
    set(findall(gcf, '-property', 'fontsize'), 'fontsize',12)
    saveas(gcf, sprintf('%s/threshPerLoc_%d.jpg', nameFolder_fig_allSubj, perfThresh_all(iPerf_plot)))
end