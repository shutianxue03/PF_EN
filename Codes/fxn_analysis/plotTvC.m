% function plotTvC(indLoc_all, colors, namesCombLoc, iperf, PSE_ave, PSE_SEM, TvC_pred_ave, TvC_pred_lb, TvC_pred_ub)
close all
clc
%%%%%%
nIndLoc = length(indLoc_all); assert(length(colors) == nIndLoc)
sz_marker = 20;
sz_title = 10;

%% plot TvC
figure('Position', [0 0 1.2e3 7e2]), hold on
for iiLoc = 1:nIndLoc
    
    indLoc = indLoc_all{iiLoc};
    if length(indLoc) ==1
        PSE_sq_ave_plot = squeeze(PSE_sq_ave(indLoc, :, iperf));
        PSE_sq_SEM_plot = squeeze(PSE_sq_SEM(indLoc, :, iperf));
        TvC_R2_ave_plot = squeeze(TvC_R2_ave(indLoc, iperf, iFIT));
        TvC_R2_SEM_plot = squeeze(TvC_R2_SEM(indLoc, iperf, iFIT));
        TvC_pred_sq_1K_ave_plot = squeeze(TvC_pred_sq_1K_ave(indLoc, iperf, :, iFIT));
        TvC_pred_sq_1K_lb_plot = squeeze(TvC_pred_sq_1K_lb(indLoc, iperf, :, iFIT));
        TvC_pred_sq_1K_ub_plot = squeeze(TvC_pred_sq_1K_ub(indLoc, iperf, :, iFIT));
    else
        PSE_sq_ave_plot = squeeze(mean(PSE_sq_ave(indLoc, :, iperf)));
        PSE_sq_SEM_plot = squeeze(mean(PSE_sq_SEM(indLoc, :, iperf)));
        TvC_R2_ave_plot = squeeze(mean(TvC_R2_ave(indLoc, iperf, iFIT)));
        TvC_R2_SEM_plot = squeeze(mean(TvC_R2_SEM(indLoc, iperf, iFIT)));
        TvC_pred_sq_1K_ave_plot = squeeze(mean(TvC_pred_sq_1K_ave(indLoc, iperf, :, iFIT)));
        TvC_pred_sq_1K_lb_plot = squeeze(mean(TvC_pred_sq_1K_lb(indLoc, iperf, :, iFIT)));
        TvC_pred_sq_1K_ub_plot = squeeze(mean(TvC_pred_sq_1K_ub(indLoc, iperf, :, iFIT)));
    end
    
    x_sq_plot = [x1_sq_pseudo, x_sq(2:end)];
    switch plotMode
        case 1 % x and y and c^2
            % raw data
            errorbar(x_sq_plot, PSE_sq_ave_plot, PSE_sq_SEM_plot, '.', 'color', colors{iiLoc}, 'capsize', 0, 'handlevisibility', 'off')
            loglog(x_sq_plot, PSE_sq_ave_plot, 'o', 'color', colors{iiLoc}, 'markersize', sz_marker, 'markerfacecolor', 'w')
            % fitted data
            loglog(x_sq_1K, TvC_pred_sq_1K_ave_plot, '-', 'color', colors{iiLoc}, 'handlevisibility', 'off')
            patch([x_sq_1K, flip(x_sq_1K)], [TvC_pred_sq_1K_lb_plot', flip(TvC_pred_sq_1K_ub_plot')], ...
                colors{iiLoc}, 'FaceAlpha', .3, 'linestyle', 'none', 'handlevisibility', 'off')
        case 2 % x and y are log10(c^2)
            % raw data
            errorbar(log10(x_sq_plot), log10(PSE_sq_ave_plot), log10(PSE_sq_SEM_plot), '.', 'color', colors{iiLoc}, 'capsize', 0, 'handlevisibility', 'off')
            plot(log10(x_sq_plot), log10(PSE_sq_ave_plot), 'o', 'color', colors{iiLoc}, 'markersize', sz_marker, 'markerfacecolor', 'w')
            % fitted data
            plot(log10(x_sq_1K), log10(TvC_pred_sq_1K_ave_plot), '-', 'color', colors{iiLoc}, 'handlevisibility', 'off')
            patch(log10([x_sq_1K, flip(x_sq_1K)]), log10([TvC_pred_sq_1K_lb_plot', flip(TvC_pred_sq_1K_ub_plot')]), ...
                colors{iiLoc}, 'FaceAlpha', .3, 'linestyle', 'none', 'handlevisibility', 'off')
    end
    %     xticks(x)
    %     xticklabels(round(params.extNoiseLvl*100))
    %     xlim([-1.6, -.3])
    %     ylim([0, .4])
    fprintf('%s: R^2=%d%% (%d%%)\n', namesCombLoc{iiLoc}, round(100*TvC_R2_ave_plot), round(100*TvC_R2_SEM_plot))
end % iiLoc

% set(gca,'Layer','top','XScale','log','YScale','log','Linewidth',3,'Box','off','PlotBoxAspectRatio',[1,1,1],'TickDir','out','TickLength',[1,1]*0.02/max(1,1));
% set(gca,'Layer','top','XScale','log','YScale','log')

xlim([x1_sq_1K_pseudo*.9, 10^0])
ylim([10^-4, 10^0]);
set(gca, 'XScale','log','YScale','log','Linewidth',3,'Box','off');

set(findall(gcf, '-property', 'fontsize'), 'fontsize',60)
set(findall(gcf, '-property', 'LineWidth'), 'LineWidth',4)

saveas(gcf,sprintf('%s/TvC_%s.jpg', nameFolder_fig_group, nameFile_fig))

%% compare Neq & Eff
for ii = 1:2
    if ii == 1, ave = Neq_sq_ave(:, iperf); SEM = Neq_sq_SEM(:, iperf); idvd = squeeze(Neq_sq_allSubj(:, :, iperf));
    else, ave = Eff_ave(:, iperf); SEM = Eff_SEM(:, iperf); idvd = squeeze(Eff_allSubj(:, :, iperf));
    end
    
    idvd_plot = nan(nsubj, nIndLoc);
    figure('Position', [0 0 1.2e3 7e2]), hold on
    for iiLoc = 1:nIndLoc
        indLoc = indLoc_all{iiLoc};
        if length(indLoc) ==1
            idvd_plot(:, iiLoc) = squeeze(idvd(:, indLoc));
            ave_plot = ave(indLoc);
            SEM_plot = SEM(indLoc);
        else
            idvd_plot(:, iiLoc) = squeeze(mean(idvd(:, indLoc), 2));
            ave_plot = mean(ave(indLoc));
            SEM_plot = mean(SEM(indLoc));
        end
        
        % group ave
        bar(iiLoc, ave_plot(iperf), 'barwidth', .5, 'edgecolor', colors{iiLoc}, 'facecolor', colors{iiLoc})
        % SEM
        errorbar(iiLoc, ave_plot(iperf), SEM_plot(iperf), '.', 'color', colors{iiLoc}, 'capsize', 0)
        xticks(1:nIndLoc)
        xticklabels(namesCombLoc)
        xlim([0, nIndLoc+1])
    end % iiLoc
    
    % idvd data
    if nIndLoc==2, x_idvd = [1.3, 1.7]; else, x_idvd = (1:nIndLoc)+.3; end
    for isubj = 1:nsubj
        plot(x_idvd, squeeze(idvd_plot(isubj, :, iperf)), [markers_allSubj{isubj}, '-'], 'color', ones(1,3)*.5, 'markerfacecolor', 'w', 'markeredgecolor', ones(1,3)*.5, 'markersize', sz_marker)
    end
    
    %%%%%%%%%%%%%%%%%%%
    % stats
    if nIndLoc==2
        [~, p, ~, stats] = ttest(squeeze(idvd_plot(:, 1, iperf)), squeeze(idvd_plot(:, 2, iperf)));
        %         title_stats =
        title_stats = sprintf('\n\n\n%s vs. %s: t(%d)=%.3f, p=%.3f\n', namesCombLoc{1}, namesCombLoc{2}, stats.df, stats.tstat, p);
        fprintf(title_stats)
    else
        idvd = squeeze(idvd_plot(:, :, iperf));
        ind_Loc = repmat(1:nIndLoc, nsubj, 1);
        text_ANOVA = print_nANOVA({'Loc'}, idvd(:), ind_Loc(:), nsubj, 1);
        title_stats = text_ANOVA;
        fprintf(text_ANOVA)
        iLoc_comp = {[1,2], [2,3], [3,1]};
        %         title_stats = cell(1,3);
        for icomp = 1:3
            [~, p, ~, stats] = ttest(squeeze(idvd_plot(:, iLoc_comp{icomp}(1), iperf)), squeeze(idvd_plot(:, iLoc_comp{icomp}(2), iperf)));
            %             title_stats{icomp} =
            text_ttest_ = sprintf('%s vs. %s: t(%d)=%.2f, p=%.3f\n', namesCombLoc{iLoc_comp{icomp}(1)}, namesCombLoc{iLoc_comp{icomp}(2)}, ...
                stats.df, stats.tstat, p);
            fprintf(text_ttest_)
            title_stats = [title_stats, text_ttest_];
        end % icmp
    end % if nLoc=2
    
    %%%%%%%%%%%%%%%%%%%
    if ii == 1
        ylabel('Internal noise')
        yticks(0:.15:.3)
        ylim([0, .3])
    else
        ylabel('Efficiency')
        yticks(0:.2:.4)
        ylim([0, .4])
    end
    
    set(findall(gcf, '-property', 'fontsize'), 'fontsize',60)
    set(findall(gcf, '-property', 'LineWidth'), 'LineWidth',4)
    title(title_stats, 'fontsize', sz_title)
    if ii==1, saveas(gcf,sprintf('%s/Neq_%s.jpg', nameFolder_fig_group, nameFile_fig))
    else, saveas(gcf,sprintf('%s/Eff_%s.jpg', nameFolder_fig_group, nameFile_fig))
    end
    
end % ii (1=Neq, 2=Eff)

