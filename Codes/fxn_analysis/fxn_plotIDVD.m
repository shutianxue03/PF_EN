
close all
nstairs = 6;
sz_marker_scale = 15;
flag_fitThreshMode = 1; % 1=threshold is estimated from fitting PMF; 2=from staircase endpoints

nameFolder_fig_PMF = sprintf('%s/PMF', nameFolder_fig_save); if isempty(dir(nameFolder_fig_PMF)), mkdir(nameFolder_fig_PMF), end
nameFolder_fig_TvC = sprintf('%s/TvC_weighted%d', nameFolder_fig_save, flag_weightedFitting); if isempty(dir(nameFolder_fig_TvC)), mkdir(nameFolder_fig_TvC), end

threshEnergy = (10.^thresh_log).^2;

%% Figure 1: plot PMF in one figure
for iNoise = 1:nNoise

    figure('Position', [0 0 2e3 2e3])
    for iLoc = 1:nLocSingle

        if ~isempty(cst_log_unik_all{iLoc, iNoise})

            if nLocSingle==9, subplot(5,5, iplots9(iLoc))
            elseif nLocSingle==5, subplot(3,3, iplots5(iLoc))
            else, error('wrong nLoc')
            end
            hold on
            scaling=1/2;
            %-----------------------%
            fxn_plotPMF_singlePanel
            %-----------------------%
        end
    end % iLoc_tgt

    set(findall(gcf, '-property', 'fontsize'), 'fontsize',10)
    set(findall(gcf, '-property', 'LineWidth'), 'LineWidth',1.5)
    sgtitle(sprintf('%s (SF=%d, NoiseSD=%.3f)  %.0f%% [Bin%dFilter%d] [Constim=%d]', ...
        subjName, SF, noiseSD_full(iNoise), perfThresh_plot*100, flag_binData, flag_filterData, fit.nBins))

    saveas(gcf, sprintf('%s/PMF_N%.0f.jpg', nameFolder_fig_PMF, noiseSD_full(iNoise)*100))

end % iNoise

if nNoise <= 2
    set(findall(gcf, '-property', 'fontsize'), 'fontsize',12)
    set(findall(gcf, '-property', 'LineWidth'), 'LineWidth',1.5)
    sgtitle(sprintf('%s (SF=%d)  [%s]', subjName, SF, folderName_extraAnalysis))
    saveas(gcf, sprintf('%s/PMF/PMF.jpg', nameFolder_fig_PMF))
end


%% Fig 2. replot TvC and fitting by single location (5x5)
% y_log_1k_LAM = log10(sqrt(threshEnergy_LAM_pred_allPerf));
% y_log_1k_PTM = log10(sqrt(threshEnergy_PTM_pred_allPerf));

% Not show estP and pred yet
y_log_1k_LAM = nan(nLocSingle, nPerf, length(noiseSD_log_all));
y_log_1k_PTM = y_log_1k_LAM;

for iYAxis = 1:2 % 1= the yticks depends on the min and max at each loc; 2=yticks fixed across locations
    for iPerf = 1:nPerf

        figure('Position', [0 0 2e3 2e3])
        for iLocSingle = 1:nLocSingle

            subplot(5,5, iplots9(iLocSingle)), hold on
            a = squeeze(thresh_log(iLocSingle, :, :)); a = a(:);
            % b = squeeze(y_log_1k_LAM(iLoc, :, :)); b = b(:); b(b==Inf)=nan;
            % c = squeeze(y_log_1k_PTM(iLoc, :, :)); c = real(c(:));c(c==Inf)=nan;
            % max_ = max([a;b;c]); if max_>0, max_ = 0; end
            % min_ = min([a;b;c]); 

            max_log = max(a);
            min_log = min(a);

            if max_log>log10(gaborCST_ub), max_log = log10(gaborCST_ub); end
            if min_log == -Inf, min_log = -3; end
            if min_log == max_log, min_log = -1; end % when max=min=100%

            switch iYAxis
                case 1, cst_log_ticks_perLoc = linspace(min_log, max_log, 5); yticks_str = 'Diff'; % based on the min and max at each loc
                case 2, cst_log_ticks_perLoc = linspace(-2, 0, 5); yticks_str = 'Fixed';
            end

            cst_ln_ticks_perLoc = round(10.^(cst_log_ticks_perLoc)*100);
            for iNoise=1:nNoise
                plot(noiseSD_log_all(iNoise), squeeze(thresh_log(iLocSingle, iNoise, iPerf)), markers_allSubj{isubj}, ...
                    'color', colors_allLoc(iLocSingle, :), 'MarkerSize', nData_perLoc(iLocSingle, iNoise)/sz_marker_scale)
            end
            % plot(noiseSD_intp_log_true, squeeze(y_log_1k_LAM(iLoc, iPerf, :)).', '-', 'color', colors_allLoc(iLoc, :), 'HandleVisibility', 'off')
            % plot(noiseSD_intp_log_true, squeeze(y_log_1k_PTM(iLoc, iPerf, :)).', '--', 'color', colors_allLoc(iLoc, :), 'HandleVisibility', 'off')

            % plot Neq
            % xline(est_LAM_allPerf(iLoc, iPerf, 1), '-', 'color', colors_allLoc(iLoc, :));

            xlim(noiseSD_log_all([1, end]) + [-.1, .1])
            xticks(noiseSD_log_all)
            xticklabels(noiseSD_full)
            xtickangle(90)

            yticks(cst_log_ticks_perLoc)
            yticklabels(cst_ln_ticks_perLoc)
            ylim(cst_log_ticks_perLoc([1, end]))

            grid on, box on
            % title(sprintf('L%d R^2=%.0f%% // %.0f%%', iLoc, R2_LAM_allPerf(iLoc, iPerf)*100, R2_PTM_allPerf(iLoc, iPerf)*100))
        end % iLoc


%         indOrder= [1,2,4,5,3,6,8,9,7];
%         % =========== plot LAM parameters at 9 locations ========== %
%         indiPlot_LAM = {[16,17], [21, 22]};
%         for iLF=1:nLF_LAM
%             subplot(5,5, indiPlot_LAM{iLF}), hold on
%             for iLoc=1:nLoc
%                 plot(iLoc, est_LAM_allPerf(indOrder(iLoc), iPerf, iLF), 'o', 'MarkerEdgeColor', colors_allLoc(indOrder(iLoc), :), 'MarkerSize', sum(nData_perLoc(indOrder(iLoc), :))/sz_marker_scale/nLoc)
%             end
% %             yticks(linspace(min_ln_LAM(iLF), max_ln_LAM(iLF), nTicks))
%             yticks(ticks_LAM{iLF}), ylim(ticks_LAM{iLF}([1, end])),yticklabels(ticklabels_LAM{iLF})
%             xline(1.5, '--k'); xline(5.5, '--k');
%             xticklabels(names_allLoc(indOrder)), xlim([.5, nLoc+.5])
%             title(sprintf('%s [LAM]', namesLF_LAM{iLF}))
%         end
% 
%         % =========== plot PTM parameters at 9 locations ========== %
%         indiPlot_PTM = {[4,5], [9,10], [19,20], [24,25]};
%         for iLF=1:nLF_PTM
%             subplot(5,5, indiPlot_PTM{iLF}), hold on
%             for iLoc=1:nLoc
%                 plot(iLoc, est_PTM_allPerf(indOrder(iLoc), iLF), 'o', 'MarkerEdgeColor',colors_allLoc(indOrder(iLoc), :), 'MarkerSize', sum(nData_perLoc(indOrder(iLoc), :))/sz_marker_scale/nLoc)
%             end
%             xline(1.5, '--k'); xline(5.5, '--k');
%             yticks(ticks_PTM{iLF}), ylim(ticks_PTM{iLF}([1, end])),yticklabels(ticklabels_PTM{iLF})
%             xticklabels(names_allLoc(indOrder)), xlim([.5, nLoc+.5])
%             title(sprintf('%s [PTM]', namesLF_PTM{iLF}))
%         end

        set(findall(gcf, '-property', 'fontsize'), 'fontsize',10)
        set(findall(gcf, '-property', 'LineWidth'), 'LineWidth',1)

        sgtitle(sprintf('%s [SF=%d]  [Bin%dFilter%d] %d%%', subjName, SF, flag_binData, flag_filterData, perfThresh_all(iPerf)))
        saveas(gcf, sprintf('%s/TvC_yticks%s_%d.jpg', nameFolder_fig_TvC, yticks_str, perfThresh_all(iPerf)))
    end % iPerf
end % iYAxis

close all

%% Fig 2a: fit LAM to TvC (PMF/stair derived) and estimate Neq and Eff
% threshEnergy_LAM_pred_allPerf does NOT exist!!!

% clc, close all
% 
% %-----------------%
% SX_fitTvC_setting
% %-----------------%
% iTvCModel = 1; % here, fit LAM
% namesLF = namesLF_LAM;
% 
% % LAM prediction
% threshEnergy_LAM_pred_allPerf = nan(size(nLoc, nPerf, nIntp));
% 
% for iiLoc=1:nLoc
%     est_BestSimplest_allLoc
%     for iPerf=1:nPerf
%     threshEnergy_LAM_pred_allPerf(iiLoc, iPerf, :) = fxn_LAM
%     threshEnergy_LAM_pred_allPerf(iLoc, iPerf, :) = fxn_LAM(params_full, noiseEnergy);
% 
%     end
% end
% 
% for iPerf = 1:nPerf
% 
%     figure('Position', [0 0 2e3 500]), hold on
% 
%     for flag_plotEnergy = 0%[0,1] % 1=plot energy (i.e., cst^2); 0=plot cst
% 
%         switch flag_plotEnergy
%             case 1 % plot threshEnergy as a fxn of noise Energy
%                 x_label = 'External noise energy (c^2)';
%                 y_label = 'Threshold energy (c^2)';
% 
%                 x = noiseEnergy_true;
%                 y = threshEnergy; % nLoc11 x nNoise x nPerf
% 
%                 x_1k = noiseEnergy_intp_true;
%                 switch iTvCModel
%                     case 1, y_1k = threshEnergy_LAM_pred_allPerf;
%                     case 2, y_1k = threshEnergy_PTM_pred_allPerf;
%                 end
% 
%                 x_ticks = noiseEnergy_true;
%                 x_tickslabels = noiseEnergy_true;
%                 y_ticks = cstEnergy_ticks;
%                 y_ticklabels = round(y_ticks,2);
% 
%             case 0 % plot log thresh as a fxn of log noise SD
%                 y_label = 'Contrast threshold (%)';
%                 x_label = 'External noise SD';
%                 x = noiseSD_log_all;
%                 y = thresh_log;
% 
%                 x_1k = noiseSD_intp_log_true;
%                 switch iTvCModel
%                     case 1, y_1k = log10(sqrt(threshEnergy_LAM_pred_allPerf));
%                     case 2, y_1k = log10(sqrt(threshEnergy_PTM_pred_allPerf));
%                 end
% 
%                 x_ticks = noiseSD_log_all;
%                 x_ticklabels = noiseSD_full;
%                 y_ticks = cst_log_ticks;
%                 y_ticklabels = round(cst_ln_ticks);
%         end
% 
%         % plot TvC and model prediction
%         iLoc_notNan = ~isnan(threshEnergy(:, 1, 1));
%         str_R2 = cell(sum(iLoc_notNan), 1);
%         iiLoc = 1;
%         subplot(2, 3, [1,4]+flag_plotEnergy), hold on
%         xlim(x_ticks([1, end]))
%         xticks(x_ticks)
%         xticklabels(x_ticklabels), xtickangle(90)
%         xlabel(x_label)
% 
%         ylim(y_ticks([1, end]))
%         yticks(y_ticks)
%         yticklabels(y_ticklabels)
%         ylabel(y_label)
% 
%         for iLoc = 1:nLoc
%             if iLoc_notNan(iLoc)
%                 plot(x, squeeze(y(iLoc, :, iPerf)), '--', 'color', colors_allLoc(iLoc, :), 'HandleVisibility', 'off')
%                 for iNoise=1:nNoise
%                     plot(x(iNoise), squeeze(y(iLoc, iNoise, iPerf)), 'o', 'color', colors_allLoc(iLoc, :), 'MarkerSize', nData_perLoc(iLoc, iNoise)/sz_marker_scale)
%                 end
%                 plot(x_1k, squeeze(y_1k(iLoc, iPerf, :)).', '-', 'color', colors_allLoc(iLoc, :))
%                 str_R2{iiLoc} = sprintf('%s [%.0f%%]\n', names_allLoc{iLoc}, R2_LAM_allPerf(iLoc, iPerf)*100);
%                 iiLoc = iiLoc+1;
%             end
%             if ~flag_plotEnergy
%                 xline(est_LAM_allPerf(iLoc, iPerf, 1), 'color', colors_allLoc(iLoc, :));
%             end
%         end
% 
%     end % flag_plotEnergy
% 
%     for iLF = 1:nLF_LAM % Limiting Factor
%         LF_allLoc = est_LAM_allPerf(:, iPerf, iLF);
%         subplot(2,3,iLF*3), hold on
%         [LF_CombLoc, namesCombLoc, LF_asym, namesAsym] = fxn_extractAsym(LF_allLoc);
% 
%         if nLoc == 5 %any(strcmp(subjName, sub_LAMjList_SX))
%             x=[1:2, (3:4)+.5, (5:6)+1]; % fov, ecc4, // HM4, VM4, LVM4, UVM4
%             x_color = [colors_comb([1, 2, 4, 5], :); colors_allLoc([5,3], :)];
%             xline(2.75, 'color', ones(1,3)/2);
%             xline(5.25, 'color', ones(1,3)/2);
%         else
%             x=[1:3, (4:7)+.5, (8:11)+1]; % fov, ecc4, ecc8, // HM4, VM4, LVM4, UVM4, // HM8, VM8, LVM8, UVM8
%             x_color = [colors_comb(1:5, :); colors_allLoc([5,3], :); colors_comb(6:7, :); colors_allLoc([9, 7], :)];
%             xline(3.75, 'color', ones(1,3)/2);
%             xline(8.25, 'color', ones(1,3)/2);
%         end
% 
%         nLocComb = length(x);
%         for iLocComb = 1:nLocComb
%             plot(x(iLocComb), LF_CombLoc{iLocComb}, 'o', 'markerfacecolor', x_color(iLocComb, :),'MarkerEdgeColor', 'w', 'MarkerSize', sz_marker_scale)
%         end
%         xticks(sort(x))
%         xticklabels(namesCombLoc), xtickangle(45)
% 
%         xlim([min(x)-.5, max(x)+.5])
%         ax = gca;ax.YGrid = 'on';
%         title(namesLF_LAM{iLF})
%         yticks(ticks_LAM{iLF}), ylim(ticks_LAM{iLF}([1, end])),yticklabels(ticklabels_LAM{iLF})
% 
%     end % iLF
% 
%     % title
%     title_ = sprintf('%s [SF%d] [Bin%dFilter%d] collapseHM=%d', subjName, SF, flag_binData, flag_filterData, flag_collapseHM);
%     if flag_fitThreshMode==1 % thresh is from fitting PMF
%         sgtitle(sprintf('%s [PMF%d%% - %s]', title_, perfThresh_all(iPerf), namesTvCModel{iTvCModel}))
%     else % thresh is from staircase
%         sgtitle(sprintf('%s [Staircase-%s]', title_, namesTvCModel{iTvCModel}))
%     end
% 
%     set(findall(gcf, '-property', 'fontsize'), 'fontsize',12)
%     set(findall(gcf, '-property', 'LineWidth'), 'LineWidth',2)
% 
%     %     save
%     if flag_fitThreshMode == 1 % thresh is from fitting PMF
%         saveas(gcf, sprintf('%s/TvC_%s_%d.jpg', nameFolder_fig_TvC, namesTvCModel{iTvCModel}, perfThresh_all(iPerf)))
%     else % thresh is from staircase
%         saveas(gcf, sprintf('%s/TvC_%s_stair.jpg', nameFolder_fig_TvC, namesTvCModel{iTvCModel}))
%     end
% end % iPerf
% close all
% 
%% Fig 2b: plot PTM
% iTvCModel = 2;
% namesLF = namesLF_PTM;
% 
% % Make prediction
% threshEnergy_PTM_pred_allPerf = [];
% 
% % est_BestSimplest_allLoc(iiIndLoc_s, 1:nLoc_s, :) = params_est_mat;
% 
% 
% for iPerf = 1:nPerf
% 
%     figure('Position', [0 0 1320 1e3]), hold on
% 
%     for flag_plotEnergy = [0,1] % 1=plot energy (i.e., cst^2); 0=plot cst
% 
%         switch flag_plotEnergy
%             case 1 % plot threshEnergy as a fxn of noise Energy
%                 x_label = 'External noise energy (c^2)';
%                 y_label = 'Threshold energy (c^2)';
% 
%                 x = noiseEnergy_true;
%                 y = threshEnergy;
% 
%                 x_1k = noiseEnergy_intp_true;
%                 switch iTvCModel
%                     case 1, y_1k = threshEnergy_LAM_pred_allPerf;
%                     case 2, y_1k = threshEnergy_PTM_pred_allPerf;
%                 end
% 
%                 x_ticks = noiseEnergy_true;
%                 x_tickslabels = noiseEnergy_true;
%                 y_ticks = cstEnergy_ticks;
%                 y_ticklabels = round(y_ticks,2);
% 
%             case 0 % plot log thresh as a fxn of log noise SD
%                 y_label = 'Contrast threshold (%)';
%                 x_label = 'External noise SD';
%                 x = noiseSD_log_all;
%                 y = thresh_log;
% 
%                 x_1k = noiseSD_intp_log_true;
%                 switch iTvCModel
%                     case 1, y_1k = log10(sqrt(threshEnergy_LAM_pred_allPerf));
%                     case 2, y_1k = log10(sqrt(threshEnergy_PTM_pred_allPerf));
%                 end
% 
%                 x_ticks = noiseSD_log_all;
%                 x_ticklabels = noiseSD_full;
%                 y_ticks = cst_log_ticks;
%                 y_ticklabels = round(cst_ln_ticks);
%         end
% 
%         % plot TvC and fitted model
%         iLoc_notNan = ~isnan(threshEnergy(:, 1, 1));
%         iiLoc = 1;
%         str_R2 = cell(nLoc, 1);
%         subplot(nLF_PTM, 3, [1:3:10]+flag_plotEnergy), hold on
%         for iLoc = 1:nLoc
%             if iLoc_notNan(iLoc)
% 
%                 plot(x, squeeze(y(iLoc, :, iPerf)), '--', 'color', colors_allLoc(iLoc, :), 'HandleVisibility', 'off')
%                 for iNoise=1:nNoise
%                     plot(x(iNoise), squeeze(y(iLoc, iNoise, iPerf)), 'o', 'color', colors_allLoc(iLoc, :), 'MarkerSize', nData_perLoc(iLoc, iNoise)/sz_marker_scale, 'HandleVisibility', 'off')
%                 end
%                 plot(x_1k, squeeze(y_1k(iLoc, iPerf, :)).', '-', 'color', colors_allLoc(iLoc, :))
% 
%                 str_R2{iiLoc} = sprintf('%s [%.0f%%]\n', names_allLoc{iLoc}, R2_PTM_allPerf(iLoc, iPerf)*100);
%                 iiLoc = iiLoc+1;
%             end
%         end
% 
%         xlim(x_ticks([1, end]))
%         xticks(x_ticks)
%         xticklabels(x_ticklabels), xtickangle(90)
%         xlabel(x_label)
% 
%         ylim(y_ticks([1, end]))
%         yticks(y_ticks)
%         yticklabels(y_ticklabels)
%         ylabel(y_label)
% 
%         if flag_plotEnergy, legend(str_R2(1:nLoc), 'Location', 'best', 'NumColumns', 3), end
% 
%     end % flag_plotEnergy
% 
%     %%%%%%%%%%%%%%%%%%%%%
%     % plot PTM estimated params
%     %%%%%%%%%%%%%%%%%%%%%
%     for iLF = 1:nLF_PTM % N-mul and SD-add
%         LF_allLoc = est_PTM_allPerf(:, iLF);
% %         y_ticks = linspace(ticks_min_PTM(iLF), ticks_max_PTM(iLF), nTicks);
% 
%         subplot(nLF_PTM,3, iLF*3), hold on
%         [LF_CombLoc, namesCombLoc, LF_asym, namesAsym] = fxn_extractAsym(LF_allLoc);
% 
%         if nLoc == 5 %any(strcmp(subjName, sub_LAMjList_SX))
%             x=[1:2, (3:4)+.5, (5:6)+1]; % fov, ecc4, // HM4, VM4, LVM4, UVM4
%             x_color = [colors_comb([1, 2, 4, 5], :); colors_allLoc([5,3], :)];
%             xline(2.75, 'color', ones(1,3)/2);
%             xline(5.25, 'color', ones(1,3)/2);
%         else
%             x=[1:3, (4:7)+.5, (8:11)+1]; % fov, ecc4, ecc8, // HM4, VM4, LVM4, UVM4, // HM8, VM8, LVM8, UVM8
%             x_color = [colors_comb(1:5, :); colors_allLoc([5,3], :); colors_comb(6:7, :); colors_allLoc([9, 7], :)];
%             xline(3.75, 'color', ones(1,3)/2);
%             xline(8.25, 'color', ones(1,3)/2);
%         end
% 
%         nLocComb = length(x);
%         for iLocComb = 1:nLocComb
%             plot(x(iLocComb), LF_CombLoc{iLocComb}, 'o', 'markerfacecolor', x_color(iLocComb, :),'MarkerEdgeColor', 'w', 'MarkerSize', sz_marker_scale)
%         end
%         xticks(sort(x))
%         xticklabels(namesCombLoc), xtickangle(45)
% 
%         xlim([min(x)-.5, max(x)+.5])
%         ax = gca;ax.YGrid = 'on';
%         title(namesLF_PTM{iLF})
%         yticks(ticks_PTM{iLF}), ylim(ticks_PTM{iLF}([1, end])),yticklabels(ticklabels_PTM{iLF})
%         %             switch iLF, case 1, yticklabels(round(10.^y_ticks*100, 1)), case 2, yticklabels(round(y_ticks_log, 1)), end
% 
%     end % iLF
%     %%%%%%%
%     % title
%     title_ = sprintf('%s [SF%d] [Bin%dFilter%d] collapseHM=%d', subjName, SF, flag_binData, flag_filterData, flag_collapseHM);
%     sgtitle(sprintf('%s [PMF%d%% - %s]', title_, perfThresh_all(iPerf), namesTvCModel{iTvCModel}))
% 
%     set(findall(gcf, '-property', 'fontsize'), 'fontsize',12)
%     set(findall(gcf, '-property', 'LineWidth'), 'LineWidth',2)
% 
%     % save
%     saveas(gcf, sprintf('%s/TvC_%s_%d.jpg', nameFolder_fig_TvC, namesTvCModel{iTvCModel}, perfThresh_all(iPerf)))
% end % iPerf
% close all


%% Figure 4. Weighted R-squared for PMF fitting (for sure, weighted)
% % R2_weighted_allB: nBoot x nLoc x nNoise x nModel
% % 1. R2 per location, averaged across noise levels
% close all
% R2_criterion = .8; % above this value is considered as good fitting
% 
% figure('Position', [0 0 1e3 800])
% for iModel = 1:nModels
%     subplot(2, 2, iModel), hold on
%     R2 = getCI(R2_weighted_allB(:, :, :, iModel ), 1, 1);
% 
%     % average across noise levels
%     [R2_ave, ~, ~, R2_SEM] = getCI(R2, 2, 2);
%     R2_SD = R2_SEM*sqrt(nNoise);
%     for iLoc = 1:nLoc
%         bar(iLoc, R2_ave(iLoc), 'FaceColor', colors_allLoc(iLoc, :), 'EdgeColor', 'none')
%         errorbar(iLoc, R2_ave(iLoc), R2_SD(iLoc), '.', 'color', colors_allLoc(iLoc, :), 'CapSize', 0)
%     end
%     % idvd data
%     for iNoise=1:nNoise
%         plot(1:nLoc, R2(:, iNoise), 'color', ones(1, 3)*iNoise/nNoise)
%     end
% 
%     yline(R2_criterion, 'k-');
%     xticks(1:nLoc), xticklabels(names_allLoc), xtickangle(45)
%     ylim([0, 1]), yticks(linspace(0, 1, 6)), ylabel('Weighted R2')
%     title(PMF_models{iModel})
% end
% set(findall(gcf, '-property', 'LineWidth'), 'LineWidth',1)
% sgtitle(sprintf('Weighted R^2 for PMF fitting\n%s [SF=%d]  [Bin%dFilter%d] [constim%d]', subjName, SF, flag_binData, flag_filterData, fit.nBins))
% saveas(gcf, sprintf('%s/PMF_R2_perLoc.jpg', nameFolder_fig_PMF))
% 
% % 2. R2 per noise level, averaged across locations
% figure('Position', [0 0 1e3 800])
% for iModel = 1:nModels
%     subplot(2, 2, iModel), hold on
%     R2 = getCI(R2_weighted_allB(:, :, :, iModel ), 1, 1);
% 
%     % average across noise levels
%     [R2_ave, ~, ~, R2_SEM] = getCI(R2, 2, 1);
%     R2_SD = R2_SEM*sqrt(nLoc);
%     for iNoise = 1:nNoise
%         bar(iNoise, R2_ave(iNoise), 'FaceColor', ones(1, 3)*iNoise/nNoise, 'EdgeColor', [0 0 0])
%         errorbar(iNoise, R2_ave(iNoise), R2_SD(iNoise), '.', 'color', ones(1, 3)*iNoise/nNoise, 'CapSize', 0)
%     end
%     % idvd data
%     for iLoc=1:nLoc
%         plot(1:nNoise, R2(iLoc, :).', 'color', colors_allLoc(iLoc, :))
%     end
% 
%     yline(R2_criterion, 'k-');
%     xticks(1:nNoise), xticklabels(noiseSD_full)%, xtickangle(45)
%     ylim([0, 1]), yticks(linspace(0, 1, 6)), ylabel('Weighted R2')
%     title(PMF_models{iModel})
% end
% set(findall(gcf, '-property', 'LineWidth'), 'LineWidth',1)
% sgtitle(sprintf('Weighted R^2 for PMF fitting\n%s [SF=%d]  [Bin%dFilter%d] [constim%d]', subjName, SF, flag_binData, flag_filterData, fit.nBins))
% saveas(gcf, sprintf('%s/PMF_R2_perNoise.jpg', nameFolder_fig_PMF))
% close all
% 
%% Figure 5. (Weighted) R-squared for TvC fitting (LAM and PTM are plotted together)
% % R2_weighted_allB: nBoot x nLoc x nNoise x nModel
% % R2 per location
% buffer = .3;
% 
% figure('Position', [0 0 2e3 400])
% for iPerf = 1:nPerf
%     subplot(1, nPerf, iPerf), hold on
% 
%     for iLoc = 1:nLoc
%         bar(iLoc-buffer/2, R2_LAM_allPerf(iLoc, iPerf), 'FaceColor', colors_allLoc(iLoc, :), 'EdgeColor', colors_allLoc(iLoc, :), 'BarWidth', buffer)
%         bar(iLoc+buffer/2, R2_PTM_allPerf(iLoc, iPerf), 'FaceColor', 'w', 'EdgeColor', colors_allLoc(iLoc, :), 'BarWidth', buffer)
%     end
% 
%     yline(mean(R2_LAM_allPerf(:, iPerf)), 'k-');
%     yline(mean(R2_PTM_allPerf(:, iPerf)), 'k--');
%     xticks(1:nLoc), xticklabels(names_allLoc), xtickangle(45)
%     ylim([0, 1]), yticks(linspace(0, 1, 6)), ylabel('R^2')
%     title(sprintf('Perf=%d%%', perfThresh_all(iPerf)))
% end
% set(findall(gcf, '-property', 'LineWidth'), 'LineWidth',1)
% set(findall(gcf, '-property', 'fontsize'), 'fontsize',15)
% 
% sgtitle(sprintf('R^2 for TvC fitting [Weighted = %d]\n%s [SF=%d]  [Bin%dFilter%d] [constim%d]\nLAM: filled bars & solid lines | PTM: empty bars & dashed lines', ...
%     flag_weightedFitting, subjName, SF, flag_binData, flag_filterData, fit.nBins))
% saveas(gcf, sprintf('%s/TvC_R2_perLoc_weighted%d.jpg', nameFolder_fig_TvC, flag_weightedFitting))
% 
% close all