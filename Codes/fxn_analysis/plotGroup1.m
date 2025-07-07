clc, close all
x_min = -1.6;
sz_markerIDVD = 8;
sz_markerAVE = 10;
wd_AVE = 2;

figure('Position', [0 0 2e3 2e3]), hold on

for iLoc = iLoc_tgt_all
    subplot(5,5, iplots9(find(iLoc==iLoc_tgt_all))), hold on, grid on
    
    % idvd data
    for isubj = 1:nsubj
        subjName = subjList{isubj};
        %         if any(strcmp(subjName, subjList_SX)), noiseLvl_all = noiseLvl_SX; MarkerFaceColor =  'w';
        %         elseif any(strcmp(subjName, subjList_AB)), noiseLvl_all = noiseLvl_AB; MarkerFaceColor = 'w';
        %         elseif any(strcmp(subjName, subjList_JA)), noiseLvl_all = noiseLvl_JA; MarkerFaceColor = ones(1,3)/2;
        %         end
        %         x_noise = [x_min, log10(noiseLvl_all(2:end))];
        plot(noiseSD_log_all, squeeze(thresh_log_allSubj(isubj, iLoc, :, iPerf_plot)), ['-', markers_allSubj{isubj}], 'Color', ones(1,3)/2, 'MarkerSize', sz_markerIDVD, 'MarkerFaceColor', 'w')
    end
    
    %   get mean and SEM
    if flag_combineMode
        x_noise = [x_min, log10(noiseLvl_SX(2:end))];
        %         x_noise1 = [x_min, log10(noiseLvl_SX(2:end))];
        %         x_noise2 = [x_min, log10(noiseLvl_JA(2:end))];
        
        % get group ave for diff types of noise spectrum used
        %         [thresh_ave1, ~, ~, thresh_sem1] = getCI(thresh_log_allSubj(1:nsubj1, iLoc, :, iPerf), 2,1);
        %         [thresh_ave2, ~, ~, thresh_sem2] = getCI(thresh_log_allSubj(nsubj1+1:end, iLoc, :, iPerf), 2,1);
        %         errorbar(x_noise1, thresh_ave1', thresh_sem1', '.-', 'Color', colors_single(iLoc, :), 'MarkerSize', sz_markerAVE, 'MarkerFaceColor', 'w', 'CapSize', 0, 'LineWidth', wd_AVE)
        %         errorbar(x_noise2, thresh_ave2', thresh_sem2', '.-', 'Color', colors_single(iLoc, :), 'MarkerSize', sz_markerAVE, 'MarkerFaceColor', 'w', 'CapSize', 0, 'LineWidth', wd_AVE)
        
        [thresh_ave, ~, ~, thresh_sem] = getCI(thresh_log_allSubj(:, iLoc, :, iPerf_plot), 2,1);
        errorbar(x_noise, thresh_ave', thresh_sem', '.-', 'Color', colors_single(iLoc, :), 'MarkerSize', sz_markerAVE, 'MarkerFaceColor', 'w', 'CapSize', 0, 'LineWidth', wd_AVE)
        
        xticks(x_noise), xticklabels(round(noiseLvl_SXABJA*100,1)), xlim(x_noise([1,end]))
        xlim([x_noise(1)-.1, x_noise(end)+.1])
    else
        [thresh_ave, ~, ~, thresh_sem] = getCI(thresh_log_allSubj(:, iLoc, :, iPerf_plot), 2,1);
        errorbar(noiseSD_log_all, thresh_ave', thresh_sem', '.-', 'Color', colors_single(iLoc, :), 'MarkerSize', sz_markerAVE, 'MarkerFaceColor', 'w', 'CapSize', 0, 'LineWidth', wd_AVE)
    end
    xticks(noiseSD_log_all), xticklabels(noiseSD_full)
    xlim([noiseSD_log_all(1)-.1, noiseSD_log_all(end)+.1])
    
    % plot group-averaged fits
    %     if flag_plotLAM
    %         plot(log10(sqrt(curveX_energy)), squeeze(log10(sqrt(mean(TvC_energy_LAM_allSubj(:, iLoc, iPerf_plot, :), 1)))), 'color', colors_single(iLoc, :), 'LineWidth', wd_AVE*1.5);
    %         plot(log10(sqrt(curveX_energy)), squeeze(log10(sqrt(TvC_energy_LAM_aveSubj(iLoc, iPerf_plot, :)))), 'color', ones(1,3)/2, 'LineWidth', wd_AVE*1.5);
    %     end
    
    xtickangle(90)
    ylim(cst_log_ticks([1, end]))
    yticks(cst_log_ticks)
    yticklabels(cst_ln_ticks)
    ylabel(sprintf('Threshold (%.d%%)', perfThresh_all(iPerf_plot)))
    title(namesLoc9{iLoc})
    
    if iLoc==1
        switch flag_plotLAM +flag_plotPTM
            case 0, legends = [subjList, 'ave'];
            case 2, legends = [subjList, 'ave', 'ave LAM fits', 'ave PTM fits'];
            case 1
                if flag_plotLAM
                    legends = [subjList, 'ave', 'ave LAM fits'];
                elseif flag_plotPTM
                    legends = [subjList, 'ave', 'ave PTM fits'];
                end
        end
        %         legend(legends, 'NumColumns', ceil(nsubj/2), 'Location', 'best')
    end
    
end % iLoc
legend(subjList, 'NumColumns', ceil(nsubj/2), 'Location', 'best')
% legend(subjList, 'Location', 'best')
sgtitle(sprintf('SF%d n=%d (%d%%) [collapse HM=%d]', SF, nsubj, perfThresh_all(iPerf_plot), flag_collapseHM))

if nLocSingle==5, set(findall(gcf, '-property', 'fontsize'), 'fontsize', 15),
else, set(findall(gcf, '-property', 'fontsize'), 'fontsize', 10),
end

% saveas(gcf, sprintf('%s/TvC_%d.jpg', nameFolder_fig_allSubj, perfThresh_all(iPerf_plot)))
% close all