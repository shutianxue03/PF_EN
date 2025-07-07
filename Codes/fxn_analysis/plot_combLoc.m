 
% plot group average of TvC an fitting line, and group-averaged limiting factors
 
% 1{'Fov'}    2{'ecc4'}    3{'ecc8'}
% 4{'HM4'}    5{'VM4'}    6{'LVM4'}    7{'UVM4'}
% 8{'HM8'}    9{'VM8'}   10{'LVM8'}    11{'UVM8'}
 
% indLoc = [1, 2, 3]; % fov - ecc4 (HM+VM) - ecc8 (HM+VM)
% indLoc = [1, 4, 8]; % fov - ecc4 (HM4) - ecc8 (HM8)
% indLoc = [1, 5, 9]; % fov - ecc4 (VM4) - ecc8 (VM8)
% indLoc = [4, 5]; % 4 deg: HM, VM
% indLoc = [6, 7]; % 4 deg: LVM, UVM
% indLoc = [8, 9]; % 8 deg: HM, VM
% indLoc = [10, 11]; % 8 deg: LVM, UVM
 
clc
 
nLocComb = 11;
nNoiseIntp = nIntp;
alpha = .2;
 
sz_ticklabel = 15;
sz_ticks = 15;
sz_title = 12;
 
nLoc = length(indLoc);
text_loc = []; for iL = 1:nLoc, text_loc = [text_loc, sprintf('%s', namesCombLoc{indLoc(iL)})]; end
 
switch iTvCModel
    case 1
        pred_log_allSubj = log10(sqrt(threshEnergy_LAM_pred_allSubj));
        pred_log_aveSubj = log10(sqrt(TvC_energy_LAM_aveSubj));
        R2_allSubj = R2_LAM_allSubj;
        R2_aveSubj = R2_LAM_aveSubj;
        namesLF = namesLF_LAM;
    case 2
        pred_log_allSubj = log10(sqrt(threshEnergy_PTM_pred_allSubj));
        pred_log_aveSubj = log10(sqrt(TvC_energy_PTM_aveSubj));
        R2_allSubj = R2_PTM_allSubj;
        R2_aveSubj = R2_PTM_aveSubj;
        namesLF = namesLF_PTM;
end
 
nLF = length(namesLF);
nPlots = 4; % to make comparing LAM vs. PTM convenient
 
figure('Position', [0 200 2e3 400])
 
%% [left panel] TvC (thresh and fitting)
subplot(1,nPlots+1,1), hold on
 
y_label = 'Contrast threshold (%)';
x_label = 'External noise SD';
 
% Convert single loc values to combined loc values
thresh_log_combLoc_allSubj = nan(nsubj, nLocComb, nNoise);
pred_log_combLoc_allSubj = nan(nsubj, nLocComb, nNoiseIntp);
pred_log_combLoc_aveSubj = nan(nLocComb, nNoiseIntp);
 
% all subj
for isubj = 1:nsubj
    for iNoise = 1:nNoise
        thresh_log_combLoc_allSubj(isubj, :, iNoise) = cell2mat(fxn_extractAsym(squeeze(thresh_log_allSubj(isubj, :, iNoise, iPerf_plot))));
    end
    parfor ii=1:nNoiseIntp
        pred_log_combLoc_allSubj(isubj, :, ii) = cell2mat(fxn_extractAsym(squeeze(pred_log_allSubj(isubj, :, iPerf_plot, ii))));
    end
end
 
R2_combLoc_allSubj = fxn_extractAsym(squeeze(R2_allSubj(:, :, iPerf_plot)));
 
% group averages
parfor ii=1:nNoiseIntp
    pred_log_combLoc_aveSubj(:, ii) = cell2mat(fxn_extractAsym(squeeze(pred_log_aveSubj(:, iPerf_plot, ii))));
end
 
% get ave and sem
[thresh_log_combLoc_ave, ~, ~,  thresh_log_combLoc_SEM] = getCI(thresh_log_combLoc_allSubj, 2, 1);
[pred_log_combLoc_ave, ~, ~, pred_log_combLoc_SEM] = getCI(pred_log_combLoc_allSubj, 2, 1);
 
text_R2 = sprintf('R2 [%s]', namesTvCModel{iTvCModel});
for iLoc = indLoc
    %         if any(iLoc==indLoc(1:2)), color_ = ones(1,3)*.8;
    %         else,
    color_ = colors_asym(iLoc, :);
    %         end
    % SEM
    errorbar(noiseSD_log_all, thresh_log_combLoc_ave(iLoc, :), thresh_log_combLoc_SEM(iLoc, :), '.', 'color', color_, 'CapSize', 0)
    % group average
    plot(noiseSD_log_all, thresh_log_combLoc_ave(iLoc, :), 'o--', 'color', color_, 'MarkerFaceColor', color_, 'MarkerEdgeColor', 'w', 'MarkerSize', 10)
    % group ave of fitting line
    plot(noiseSD_intp_log_true, pred_log_combLoc_ave(iLoc, :).', '-', 'color', color_, 'HandleVisibility', 'off')
    % CI of fitting line
    patch([noiseSD_intp_log_true, flip(noiseSD_intp_log_true)], [pred_log_combLoc_ave(iLoc, :)-pred_log_combLoc_SEM(iLoc, :), flip(pred_log_combLoc_ave(iLoc, :)+pred_log_combLoc_SEM(iLoc, :))], color_, 'FaceAlpha', alpha, 'linestyle', 'none')
    % fitting line of group-averaged thresh
    %         plot(noiseSD_intp_log_true, pred_log_combLoc_aveSubj(iLoc, :), '--', 'color', color_, 'HandleVisibility', 'off')
    
    % equivalent noise
%     [Neq_log_ave, ~, ~, Neq_log_SEM] = getCI(Neq_CombLoc_allSubj{iLoc}, 2);
%     [~,y_Neq_ave] = min(abs(Neq_log_ave-noiseSD_intp_log_true));
%     plot([Neq_log_ave, Neq_log_ave], [-3, pred_log_combLoc_ave(iLoc, y_Neq_ave)], '--', 'color', color_);

    Neq_log_asym = fxn_extractAsym(squeeze(est_LAM_allSubj(:, :, iPerf_plot, 1)));
    [Neq_log_ave, ~, ~, Neq_log_SEM] = getCI(Neq_log_asym{iLoc});
%     xline(Neq_log_ave, '--', 'color', color_);
    [~,y_Neq_ave] = min(abs(Neq_log_ave-noiseSD_intp_log_true));
    plot([Neq_log_ave, Neq_log_ave], [-3, pred_log_combLoc_ave(iLoc, y_Neq_ave)], '--', 'color', color_);
    
    % plot R2
    [R2_ave, ~, ~, R2_SEM] = getCI(R2_combLoc_allSubj{iLoc});
    text_R2 = sprintf('%s\n%s: %.0f%% (%.0f%%)', text_R2, namesCombLoc{iLoc}, R2_ave*100, R2_SEM*100);
end % iLoc
 
%     if nLoc ==4, xline(2.5, 'color', ones(1,3)/2); end
 
ax = gca; ax.YGrid = 'on';
ax.XAxis.FontSize = sz_ticklabel;
ax.YAxis.FontSize = sz_ticklabel;
 
x_ticks = noiseSD_log_all;
x_ticklabels = round(noiseSD_full, 2);
ticks = cst_log_ticks;
ticklabels = round(cst_ln_ticks);
 
xlim(x_ticks([1, end])+ [-.1, .1])
xticks(x_ticks)
xticklabels(x_ticklabels), xtickangle(90)
%     xlabel(x_label)
 
ylim(ticks([1, end]))
yticks(ticks)
yticklabels(ticklabels)
%     ylabel(y_label)
 
title(sprintf('%s\n', text_R2), 'fontsize', sz_title)
 
%% [Right panels] Neq and Eff
for iLF = 1:nLF % Limiting Factor
    subplot(1,nPlots+1,iLF+1), hold on
    switch iTvCModel
        case 1% LAM
            
            LF_allLoc = est_LAM_allSubj(:, :, iPerf_plot, iLF);
            LF_aveSubj = est_LAM_aveSubj(:, iPerf_plot, iLF);
            ticks = ticks_LAM{iLF};
            ticklabels = ticklabels_LAM{iLF};
        case 2
            LF_allLoc = est_PTM_allSubj(:, :, iLF);
            LF_aveSubj = est_PTM_aveSubj(:, iLF);
            ticks = ticks_PTM{iLF};
            ticklabels = ticklabels_PTM{iLF};
    end
    
    LF_CombLoc = cell2mat(fxn_extractAsym(LF_allLoc));
    LF_CombLoc_aveSubj = cell2mat(fxn_extractAsym(LF_aveSubj'));
    
    [LF_CombLoc_ave, ~, ~, LF_CombLoc_SEM] = getCI(LF_CombLoc, 2);
    
    % plot idvd data
    if flag_plotIDVD
        for isubj = 1:nsubj
            plot((1:nLoc)+randn/15, LF_CombLoc(isubj, indLoc), ['-', markers_allSubj{isubj}], 'color', ones(1,3)*.7, 'MarkerFaceColor', 'w', 'MarkerSize', 10)
            %             plot(x+randn/15, LF_CombLoc(isubj, indLoc), '-', 'color', ones(1,3)*.7, 'MarkerFaceColor', 'w')
        end
    end
    for iLocComb = indLoc
        % group-averaged estimates
        errorbar(find(iLocComb == indLoc), LF_CombLoc_ave(iLocComb), LF_CombLoc_SEM(iLocComb), '.', 'color', colors_asym(iLocComb, :), 'CapSize', 0)
        plot(find(iLocComb == indLoc), LF_CombLoc_ave(iLocComb), 'o', 'markerfacecolor', colors_asym(iLocComb, :),'MarkerEdgeColor', 'w', 'MarkerSize', 15)
        
        % estimates derived from fitting to group ave
        %             plot(find(iLocComb == indLoc)+.3, LF_CombLoc_ave(iLocComb), 'o', 'markerfacecolor', colors_asym(iLocComb, :),'MarkerEdgeColor', 'w', 'MarkerSize', 10)
    end
    
    xticks(1:nLoc), xticklabels(namesCombLoc(indLoc))
    xlim([0, nLoc+1])
    if ~isnan(ticks)
        yticks(ticks), ylim(ticks([1, end])), yticklabels(ticklabels)
    end
    ax = gca;
    ax.XAxis.FontSize = sz_ticklabel;
    ax.YAxis.FontSize = sz_ticklabel;
    
    %%%% conduct ANOVA (regardless of nLoc)
    indBar = repmat(1:nLoc, nsubj, 1);
    b=LF_CombLoc(:, indLoc);
    text_ANOVA = print_nANOVA({'Loc'}, b(:), {indBar(:)}, nsubj, 1);
    
    %%%% if nLoc > 2, compare every pair
    if nLoc<4
        text_ttest = '';
        names = namesCombLoc(indLoc);
        %         if nLoc>2 %&& flag_pairwiseComp
        indPairs = nchoosek(1:nLoc, 2); % all possible pairs across columns
        npairs = size(indPairs , 1);
        for ipair = 1:npairs
            x1 = b(:, indPairs(ipair, 1));
            x2 = b(:, indPairs(ipair, 2));
            %                 [~, p,~, stats] = ttest(x1, x2, 'tail', 'left'); % right: x1>x2
            [~, p,~, stats] = ttest(x1, x2); % right: x1>x2
            if flag_Bcorrect
                p=p*npairs;
            end
            cohenD = fxn_getES(x1, x2);
            text_ttest = [text_ttest, sprintf('%s|%s: t=%.2f, p=%.3f, d=%.2f (%d/%d)\n', ...
                names{indPairs(ipair, 1)}, names{indPairs(ipair, 2)}, stats.tstat, p, cohenD, sum(b(:, indPairs(ipair, 1))> b(:, indPairs(ipair, 2))), nsubj)];
        end
        
        if isnan(ticks), yDiffSEM=0;
        else
            yDiffSEM = ticks(end) - (ticks(end)-ticks(1))/10;
        end
        if nLoc==2 % pairwise comp
            xDiffSEM = 1.5;
            x1=b(:, 1);
            x2=b(:, 2);
            diff_sem = std(x1 - x2)/sqrt(nsubj);
            errorbar(xDiffSEM, yDiffSEM, diff_sem, 'k', 'CapSize', 0, 'linewidth', 2)
            plot(1:nLoc, ones(1,nLoc)*yDiffSEM, 'k-', 'linewidth', 2)
        end
        
        
    end % if nLoc<4
    
    %%%% compare two loc (ttest, draw sem of diff)
    %         if nLoc == 2
    %             x1 = med_allSubj(:, 1);
    %             x2 = med_allSubj(:, 2);
    %             [~, p,~, stats] = ttest(x1, x2);
    %             cohenD = fxn_getES(x1, x2);
    %             flag_sig=''; if p<.05, flag_sig='_sig'; elseif p<.1, flag_sig='_mg'; end
    %             text_ttest = sprintf('%s vs. %s: t=%.2f, p=%.3f, d=%.2f (%d/%d)\n', ...
    %                 x_ticks{1}, x_ticks{2}, stats.tstat, p, cohenD, sum(med_allSubj(:, 1)> med_allSubj(:, 2)), nsubj);
    
    %             if flag_plotDiff
    %                 yDiffSEM = y_ticks(end) - (y_ticks(end) - y_ticks(1))/6;
    %                 diff_sem = std(x1 - x2)/sqrt(nsubj);
    %                 errorbar(1.5, yDiffSEM, diff_sem, 'k', 'CapSize', 0, 'linewidth', wd)
    %                 plot([1,2], [yDiffSEM, yDiffSEM], 'k-', 'linewidth', wd)
    %                 %     string_s = getString_starts(p);
    %             end
    %         end
    
    % title
    if flag_plotTitle
        title(sprintf('%s\n%s\n%s', namesLF{iLF}, text_ANOVA, text_ttest), 'fontsize', sz_title)
    end
    fprintf('%s\n%s\n%s\n\n', namesLF{iLF}, text_ANOVA, text_ttest)
    
    if iLF==1, legend(subjList, 'Location', 'best'), end
end % iLF
 
if flag_plotTitle
    sgtitle(sprintf('SF%d n=%d [Bin%dFilter%d] collapseHM=%d', SF, nsubj, flag_binData, flag_filterData, flag_collapseHM));
end
 
if ~flag_plotTitle
    set(findall(gcf, '-property', 'fontsize'), 'fontsize', sz_ticks)
end
 
set(findall(gcf, '-property', 'LineWidth'), 'LineWidth',1.5)
 
% save
saveas(gcf, sprintf('%s/%d_%s_%s.jpg', nameFolder_fig_allSubj_, perfThresh_all(iPerf_plot), text_loc, namesTvCModel{iTvCModel}))
 

