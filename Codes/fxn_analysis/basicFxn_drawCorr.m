function  flag_sig = basicFxn_drawCorr(x_med_allSubj, y_med_allSubj, colors, namesGroup, x_ticks, y_ticks, x_ticklabels, y_ticklabels, flag_zeroMean, type_corr, type_tail, text_title)

% to plot and compare two values across locations for (1) performance and (2) tuning characteristics
% and assess partial correlation while controlling for location
% Inputs:
%    x_med_allSubj: nsubj x nLoc, median of boostrapping, to plot on the x-axis
%    y_med_allSubj: nsubj x nLoc, median of boostrapping, to plot on the y-axis
%    colors: nLoc x 3, each rows indicates a location
%    x_ticks: vector, containing 5 values
%    y_ticks: vector, containing 5 values
%    x_ticklabels: vector, containing 5 values
%    y_ticklabels: vector, containing 5 values
%    flag_zeroMean: 1=subtract mean; 0=NOT
%    typeCorr: string, 'pearson'=Pearson's r; 'spearman'=spearman's rho, 'kendall'=Kendall's tau
%    type_tail: nan (two tail), 'left', 'right'

%% figure setting
wd_border = 1;
sz_ticks = 15; % 30
sz_marker = 10;

%-----------------
SX_analysis_setting
%-----------------

%% extract nsubj and nLoc and make assertion
[nsubj, nLoc] = size(x_med_allSubj);
% assert(length(markers_allSubj) >= nsubj)

%% zero-mean
if flag_zeroMean
    x_med_0mean_allSubj = x_med_allSubj - mean(x_med_allSubj, 1);
    y_med_0mean_allSubj = y_med_allSubj - mean(y_med_allSubj, 1);
    text_zeroMean = '(zero-meaned)';
else
    x_med_0mean_allSubj = x_med_allSubj;
    y_med_0mean_allSubj = y_med_allSubj;
    text_zeroMean = '';
end

% %% get ave and SEM of x and y
% [x_ave, ~, ~, x_sem] = getCI(x_med_0mean_allSubj, 2, 1);
% [y_ave, ~, ~, y_sem] = getCI(y_med_0mean_allSubj, 2, 1);

%%
hold on, box on

%% idvd data
for iLoc = 1:nLoc
    for isubj = 1:nsubj
        plot(x_med_0mean_allSubj(isubj, iLoc), y_med_0mean_allSubj(isubj, iLoc),  markers_allSubj{isubj}, 'markerfacecolor', 'w', ...
            'markeredgecolor', colors(iLoc, :), 'markersize', sz_marker, 'linewidth', wd_border)
    end % isubj
end % iLoc

%% get partial corr
ANOVA_indLoc = repmat(1:nLoc, nsubj, 1);
[r_partial, p_partial] = partialcorr(x_med_allSubj(:), y_med_allSubj(:), ANOVA_indLoc(:), ...
    'type', type_corr, 'tail', type_tail);
flag_sig=''; if p_partial<.05, flag_sig='_sig'; end

%% corr and linear regression for each loc
text_corr_perL = [];
for iLoc = 1:nLoc
    [r, p] = corr(x_med_allSubj(:, iLoc), y_med_allSubj(:, iLoc));
    if p<.1
        text_corr_perL = [text_corr_perL, sprintf('%s: r=%.2f, p=%.3f\n', namesGroup{iLoc}, r, p)];
    end
    lm = polyfit(x_med_0mean_allSubj(:, iLoc), y_med_0mean_allSubj(:, iLoc), 1);
    x_lm2 = linspace(min(x_med_0mean_allSubj(:, iLoc)), max(x_med_0mean_allSubj(:, iLoc)), 2);
    yfit = polyval(lm, x_lm2);
%     eta2 = var(polyval(lm, x_med_allSubj(:, iLoc), y_med_allSubj(:, iLoc));
    
    if p<.05, plot(x_lm2, yfit,'-', 'color', colors(iLoc, :), 'handlevisibility', 'off', 'linewidth', wd_border);
    elseif p<.1, plot(x_lm2, yfit,'--', 'color', colors(iLoc, :), 'handlevisibility', 'off', 'linewidth', wd_border);
    end
    
end

%% linear regression
lm = polyfit(x_med_0mean_allSubj(:), y_med_0mean_allSubj(:), 1);
x_lm2 = linspace(min(x_med_0mean_allSubj(:)), max(x_med_0mean_allSubj(:)), 2);
yfit = polyval(lm, x_lm2);
eta2 = var(polyval(lm, x_med_0mean_allSubj(:)))/var(y_med_0mean_allSubj(:));

if p_partial<.05, plot(x_lm2, yfit,'-', 'color', ones(1,3)*.5, 'handlevisibility', 'off', 'linewidth', wd_border * 3);
elseif p_partial<.1, plot(x_lm2, yfit,'--', 'color', ones(1,3)*.5, 'handlevisibility', 'off', 'linewidth', wd_border * 3);
end

%% ticks and limits
if ~isnan(x_ticks), xticks(x_ticks), xlim(x_ticks([1, end])), end
if ~isnan(y_ticks), yticks(y_ticks), ylim(y_ticks([1, end])), end
if ~isnan(x_ticklabels), xticks(x_ticklabels),  end
if ~isnan(y_ticklabels), yticks(y_ticklabels),  end

%% figure format
axis square
ax = gca;
ax.XAxis.FontSize = sz_ticks;
ax.YAxis.FontSize = sz_ticks;
ax.LineWidth = wd_border;

%% title
xlabel(sprintf('CST Threshold %s', text_zeroMean))
title(sprintf('%s\nPartial r = %.2f (p = %.3f) eta^2=%.2f\n%s', ...
    text_title, r_partial, p_partial, eta2, text_corr_perL))



