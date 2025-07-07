%% test removing which data has the smallest cost

%     close all
    %     iperf = 3;
    %     R2_allSubj_ = nan(size(R2_allSubj));
    %     indBestFitting_all=[];
    %     indWorstFitting_all=indBestFitting_all;
    %     indMostSimilar_all=indBestFitting_all;
    %     indLeastSimilar_all=indBestFitting_all;
    %     for isubj = 1:nsubj
    %         figure('Position', [0 0 2e3 1e3])
    %         for iLoc = 1:5%iLoc_tgt_all
    %
    %             iiLoc = find(iLoc == iLoc_tgt_all);
    %             subplot(5,5, iplots9(iiLoc)), hold on
    %
    %             PSE_log = squeeze(PSE_best_allSubj(isubj, iLoc, :, iperf)).';
    %             thresh_energy = (10.^PSE_log).^2; % threshold energy
    %
    %             % visualize
    %             R2_all = nan(1,nNoise);
    %             % raw data
    %             plot(noise_energy, thresh_energy, 'ko')
    %             % original fitting
    %             plot(curveX_energy, TvC_allSubj{isubj, iiLoc}, 'k-', 'LineWidth', 3)
    %
    %             for indRemove = 1:nNoise
    %                 [D_est, Neq_est, ~, R2]= lam_tvcFit([1 2], noise_energy(noise_energy~=noise_energy(indRemove)), thresh_energy(noise_energy~=noise_energy(indRemove)));
    %                 TvC = lam_tvc([D_est Neq_est], curveX_energy);
    %                 R2_all(indRemove) = R2;
    %                 R2_allSubj_(isubj, iLoc, indRemove) = R2;
    %                 % fitting after removing a data
    %                 plot(curveX_energy, lam_tvc([D_est Neq_est], curveX_energy), '-', 'LineWidth', 1)
    %             end
    %             [~, indBestFitting] = max(R2_all);
    %             [~, indWorstFitting] = min(R2_all);
    %             [~, indMostSimilar] = min(abs(R2_all - R2_allSubj(isubj, iiLoc)));
    %             [~, indLeastSimilar] = max(abs(R2_all - R2_allSubj(isubj, iiLoc)));
    %             title(sprintf('best fitting: N%.0f; worst fitting: N%.0f\nmost similar: N%.0f; least similar: N%.0f', ...
    %                 noiseLvl_all(indBestFitting)*100, noiseLvl_all(indWorstFitting)*100, ...
    %                 noiseLvl_all(indMostSimilar)*100, noiseLvl_all(indLeastSimilar)*100))
    %
    %             indBestFitting_all(isubj, iLoc) = indBestFitting;
    %             indWorstFitting_all(isubj, iLoc) = indWorstFitting;
    %             indMostSimilar_all(isubj, iLoc) = indMostSimilar;
    %             indLeastSimilar_all(isubj, iLoc) = indLeastSimilar;
    %         end % iLoc
    %         sgtitle(subjList{isubj})
    %     end % isubj
    %
    %     for iNoise = 1:nNoise
    %         for  isubj = 1:nsubj
    %             freq_allSubj(1, isubj, iNoise) = mean(indBestFitting_all(isubj, :) == iNoise);
    %             freq_allSubj(2, isubj, iNoise) = mean(indWorstFitting_all(isubj, :) == iNoise);
    %             freq_allSubj(3, isubj, iNoise) = mean(indMostSimilar_all(isubj, :) == iNoise);
    %             freq_allSubj(4, isubj, iNoise) = mean(indLeastSimilar_all(isubj, :) == iNoise);
    %         end
    %     end
    %
    %
    %     titles = {'BestFitting', 'WorstFitting', 'MostSimilar', 'LeastSimilar'};
    %     figure('Position', [0 0 1.5e3 1.5e3])
    %     for iff = 1:4
    %         freq_allS = squeeze(freq_allSubj(iff, :, :));
    %         [freq_ave, ~, ~, freq_sem] = getCI(freq_allS, 2,1);
    %         subplot(2,2,iff), hold on
    %         errorbar(1:nNoise, freq_ave, freq_sem, 'or', 'MarkerFaceColor', 'w', 'CapSize', 0, 'LineWidth', 2, 'HandleVisibility', 'off', 'MarkerSize', 20);
    %         for isubj = 1:nsubj, plot(1:nNoise, freq_allS(isubj, :), ['-', markers_allSubj{isubj}], 'Color', ones(1,3)/2,  'MarkerFaceColor', 'w', 'MarkerSize', 15), end
    %         ylabel('Frequency')
    %         ylim([0,1])
    %         title(titles{iff})
    %         xticks(1:nNoise)
    %         xticklabels(round(noiseLvl_all*100))
    %         if iff==1, legend(subjList, 'Location', 'best', 'NumColumns', 2), end
    %     end
    %     set(findall(gcf, '-property', 'fontsize'), 'fontsize',20)
    %
    %     %% TvC (each panel is one subj, all loc)
    %     flagEnergy =1;
    %     figure('Position', [0 0 2e3 300]), hold on
    %     for isubj = 1:nsubj
    %         subplot(1,nsubj,isubj), hold on
    %
    %         for iLoc = 1:nLoc
    %             for iperf = 3%1:nPerf
    %                 PSE_log = squeeze(PSE_best_allSubj(isubj, iLoc, :, iperf)).';
    %                 if flagEnergy
    %                     x = noise_energy; y = (10.^PSE_log).^2; X = curveX_energy; ypred = TvC_allSubj{isubj, iLoc, iperf};  ylim([0, .1])
    %                 else
    %                     x = [-3, log10(noiseLvl_all(2:end))]; y = PSE_log; X = log10(sqrt(curveX_energy)); ypred = log10(sqrt(TvC_allSubj{isubj, iLoc, iperf}));         ylim([-2, -.2])
    %                 end
    %                 plot(x, y, 'o-', 'color', colors9(iLoc,:))
    %                 plot(X, ypred, '-', 'color', colors9(iLoc,:), 'LineWidth', 2)
    %             end
    %         end % iLoc
    %         title(subjList{isubj})
    %     end % isubj
    %