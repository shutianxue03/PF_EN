

for iTvC=1:2
    
    switch iTvC
        case 1 % LAM
            namesLF = namesLF_LAM;
            nLF = nLF_LAM;
            LF_allSubj = squeeze(est_LAM_allSubj(:, :, iPerf_plot, :));
            LF_aveSubj = squeeze(est_LAM_aveSubj(:, iPerf_plot, :));
            ticks = ticks_LAM;
            ticklabels = ticklabels_LAM;
        case 2 % PTM
            namesLF = namesLF_PTM;
            nLF = nLF_PTM;
            LF_allSubj = est_PTM_allSubj;
            LF_aveSubj = est_PTM_aveSubj;
            ticks = ticks_PTM;
            ticklabels = ticklabels_PTM;
    end
    
    %%%%% plot across locations %%%%%
%     figure('Position', [0 0 2e3 400]), hold on
%     for iLF=1:nParams
%         
%         LF_allSubj_ = LF_allSubj(:, indLoc, iLF);
%         LF_aveSubj_ = LF_aveSubj(indLoc, iLF);
%         subplot(1, 4, iLF), hold on
%         
%         % IDVD data
%         for isubj = 1:nsubj
%             subjName = subjList{isubj};
%             MarkerFaceColor = 'w';
%             plot(1:nLocSingle, LF_allSubj_(isubj, :), ['-', markers_allSubj{isubj}], 'Color', ones(1,3)/2, 'MarkerSize', 10, 'MarkerFaceColor', MarkerFaceColor)
%         end
%         
%         % LF averaged across observers
%         for iLoc = 1:nLocSingle
%             [data_ave, ~, ~, data_sem] = getCI(LF_allSubj_(:, iLoc), 2, 1);
%             errorbar(iLoc, data_ave, data_sem, 'o', 'Color', colors_single(indLoc(iLoc), :),'CapSize', 0, 'LineWidth', 3)
%         end
%         % LF derived from averaged threshold
%         for iLoc = 1:nLocSingle
%             plot(iLoc+.3, LF_aveSubj_(iLoc), 's', 'Color', colors_single(indLoc(iLoc), :),'LineWidth', 3)
%         end
%         
%         xticks(1:nLocSingle), xticklabels(namesLoc(indLoc)), xtickangle(90), xlim([0, nLocSingle+1])
%         yticks(ticks{iLF}), ylim(ticks{iLF}([1, end])),yticklabels(ticklabels{iLF})
%         if iLF==1, legend(subjList, 'NumColumns', 3, 'Location', 'best'), end
%         title(namesLF{iLF})
%     end % iLF
%     sgtitle(sprintf('%s parameters (SF=%d n=%d)', namesTvCModel{iTvC}, SF, nsubj))
%     set(findall(gcf, '-property', 'fontsize'), 'fontsize',15)
%     saveas(gcf, sprintf('%s/LF_%s_perLoc.jpg', nameFolder_fig_allSubj, namesTvCModel{iTvC}))
    
    %%%%% compare across locations %%%%%
    for iLF=1:nLF
        nameFolder_fig_allSubj_ = sprintf('%s/%s%d', nameFolder_fig_allSubj, namesTvCModel{iTvC}, iLF); if isempty(dir(nameFolder_fig_allSubj_)), mkdir(nameFolder_fig_allSubj_), end
        
        %---------------------------------------------------------------------------------------------------------%
        [LF_CombLoc_allSubj, namesCombLoc, LF_asym_allSubj, namesAsym] = fxn_extractAsym(squeeze(LF_allSubj(:, :, iLF)));
        [LF_CombLoc_aveSubj, namesCombLoc, LF_asym_aveSubj, namesAsym] = fxn_extractAsym(LF_aveSubj(:, iLF));
        %---------------------------------------------------------------------------------------------------------%
        nasym = length(namesAsym);
        [LF_asym_ave, ~, ~, LF_asym_sem] = getCI(LF_asym_allSubj, 2, 1);
        
        %% 1. Plot three asymmetries (ecc effect, HVA, VMA)
        %----------%
        plot1_asym
        %----------%
        
        %% 2. Plot Neq and Eff according to location (like AB's slide)
        ticks_ = ticks{iLF};
        ticklabels_ = ticklabels{iLF};
        title_ = sprintf('%s [collapseHM=%d]', namesLF{iLF}, flag_collapseHM);
        %----------%
%         plot2_compLoc % not needed
        %----------%
        close all
        
        %% 3. Correlate limiting factor and thresh (noise=0) across locations
        %----------%
        plot3_corr
        %----------%
        
        %% 4. Correlate between asymmetry in thresh (noise=0) and in internal noise/effeciency
        %----------%
        plot4_corrAsym
        %----------%
    end % iLF
    
end % iTvC