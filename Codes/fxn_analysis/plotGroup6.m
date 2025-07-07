% ratio = pse of any perf level / pse of the highest perf level
close all
nPair = nPerf-1;
ratio_allSubj = nan(nsubj, nLocSingle, nNoise, nPair);
for isubj = 1:nsubj
    %     figure('Position', [0 0 2e3 2e3])
    
    for iLoc = 1:nLocSingle
        %         if nLoc==9, subplot(5,5,iplots9(iLoc))
        %         else, subplot(3,3,iplots5(iLoc))
        %         end
        %         hold on, grid on
        %         legends = {};
        for iPair = 1:nPair
            thresh_log1 = squeeze(thresh_log_allSubj(isubj, iLoc, :, iPair)).';
            thresh_log2 = squeeze(thresh_log_allSubj(isubj, iLoc, :, end)).';
            thresh_log1(thresh_log1==0)=-eps;
            thresh_log2(thresh_log2==0)=-eps;
            ratio= thresh_log1./thresh_log2;
            ratio_allSubj(isubj, iLoc, :, iPair) = ratio;
            %             plot(1:nNoise, ratio, 'o-', 'color', colors_single(iLoc,:) * iperf/nPair)
            %             legends{iperf} = sprintf('%d vs. %d', perfThresh_all(iperf), perfThresh_all(end));
        end % iperf
        %         xticks(1:nNoise), xticklabels(round(noiseLvl_all*100)), xlim([0, nNoise+1])
        %         ylim([.8, 1.5]), yline(1, 'k-', 'linewidth', 1.5);
        %         legend(legends, 'Location', 'northwest')
    end % iLoc
    
    %     sgtitle(sprintf('Thresh ratio between perf levels - %s', subjList{isubj}))
    %     saveas(gcf, sprintf('%sthreshRatio.jpg', nameFolder_fig_allSubj))
    
end % isubj

close all

% plot
indLoc_ANOVA = nan(size(ratio_allSubj));indNoise_ANOVA = indLoc_ANOVA; indPair_ANOVA = indLoc_ANOVA;
for isubj = 1:nsubj
    indLoc_ANOVA(isubj, :, :, :) = repmat((1:nLocSingle)', [1, nNoise, nPair]);
    indNoise_ANOVA(isubj, :, :, :) = repmat(1:nNoise, [nLocSingle, 1, nPair]);
    for iLoc = 1:nLocSingle
        indPair_ANOVA(isubj, iLoc, :, :) = repmat(1:nPair, [nNoise, 1]);
    end
end
text_ANOVA = print_nANOVA({'Loc', 'Noise', 'Pair'}, ratio_allSubj(:), {indLoc_ANOVA(:), indNoise_ANOVA(:), indPair_ANOVA(:)}, nsubj);

[ratio_ave, ~, ~, ratio_SEM] = getCI(ratio_allSubj, 2, 1);
figure('Position', [0 0 2e3 2e3])

for iLoc = 1:nLocSingle
    if nLocSingle==9, subplot(5,5,iplots9(iLoc))
    else, subplot(3,3,iplots5(iLoc))
    end
    hold on, grid on
    legends = {};
    for iPerf_plot = 1:nPair
        errorbar(1:nNoise, ratio_ave(iLoc, :, iPerf_plot), ratio_SEM(iLoc, :, iPerf_plot), '.-', 'color', colors_single(iLoc,:) * iPerf_plot/nPerf, 'CapSize', 0, 'HandleVisibility', 'off')
        plot(1:nNoise, ratio_ave(iLoc, :, iPerf_plot), 'o-', 'color', colors_single(iLoc,:) * iPerf_plot/nPair, 'MarkerFaceColor', 'w')
        legends{iPerf_plot} = sprintf('%d vs. %d', perfThresh_all(iPerf_plot), perfThresh_all(end));
    end % iperf
    xticks(1:nNoise), xticklabels(round(noiseSD_full*100)), xlim([0, nNoise+1])
    %     if any(iLoc==[7,9]), ylim([1, 1e14]), else,
    ylim([.95, 1.4]),
    %     end
    yline(1, 'k-', 'linewidth', 1.5);
    legend(legends, 'Location', 'northwest')
end % iLoc

sgtitle(sprintf('[SF%d n=%d] Thresh ratio between perf levels', SF, nsubj))
saveas(gcf, sprintf('%s/threshRatio_group.jpg', nameFolder_fig_allSubj))

close all
