
if ~flag_combineEcc4
    if nLocSingle==5, figure('Position', [0 0 2e3 500])
    else, figure('Position', [0 0 2e3 2e3])
    end
    
    nasym = length(namesAsym);
    
    for iasym = 1:nasym
        
        [thresh_asym_ave, ~, ~, thresh_asym_sem] = getCI(thresh_asym_allSubj(:, :, iasym), 2, 1);
        
        if nasym<=4, subplot(1,nasym ,iasym)
        else, subplot(2,4 ,iasym),
        end
        hold on
        
        % idvd data
        if nsubj>1
            for isubj=1:nsubj%, plot(1:4, HVA_allSubj(isubj, :), '-'),
                plot(1:nNoise, squeeze(thresh_asym_allSubj(isubj, :, iasym)), ['-', markers_allSubj{isubj}], 'Color', ones(1,3)/2, 'MarkerSize', 10, 'MarkerFaceColor', 'w')
            end
        end
        % group ave
        errorbar(1:nNoise, thresh_asym_ave, thresh_asym_sem, 'ok', 'CapSize', 0, 'LineWidth', 2, 'HandleVisibility', 'off')
        
        % x tick labels
        xticklabels_ = cell(nNoise, 1);
        for iNoise = 1:nNoise
            [~, p, ~, stats] = ttest(squeeze(thresh_asym_allSubj(:, iNoise, iasym)));
            p = p*nNoise;
            pstar=''; if p<.001, pstar='***'; elseif p<.01, pstar = '**'; elseif p<.05, pstar='*';end
            xticklabels_{iNoise} = sprintf('%.3f%s', noiseSD_full(iNoise), pstar);
        end
        xticks(1:nNoise), xticklabels(xticklabels_),xlim([.5,nNoise+.5]), xtickangle(90)
        
        yline(0, 'color', [.5, .5, .5] ,'linewidth', 2);
        ylim(y_ticks_asym([1, end]))
        yticks(y_ticks_asym)
        xlabel('Noise SD')
        ylabel('Asymmetry (%)')
        title(namesAsym{iasym})
        
        if iasym == 1, legend(subjList, 'NumColumns', ceil(nsubj/3), 'Location', 'best'), end
    end
    
    sgtitle(sprintf('SF%d n=%d (%d%%) [collapse HM=%d]', SF, nsubj, perfThresh_all(iPerf_plot), flag_collapseHM))
    
    set(findall(gcf, '-property', 'fontsize'), 'fontsize',12)
    
    saveas(gcf, sprintf('%s/asym_%d.jpg', nameFolder_fig_allSubj, perfThresh_all(iPerf_plot)))
end