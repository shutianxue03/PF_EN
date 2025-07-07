
function basicFxn_drawBars(med_allSubj, ref, colors, x_ticks, y_ticks, y_ticklabels, flag_plotIdvd, flag_plotDiff, text_title)

% Inputs:
%    med_allSubj: nsubj x nLoc, median of boostrapping
%    ref: one reference line, ylines
%    colors: nLoc x 3, each rows indicates a location
%    x_ticks: cell, containing strings indicating location names
%    y_ticks: vector, containing 3 values
%    y_ticklabels: vector, containing 3 value
%    flag_plotIdvd: 1=plot idvd data; 0=NOT
%    flag_plotDiff: ~isnan=plot SEM of difference
%    text_title

%% define sizes
sz_marker_ave = 20; %20
sz_marker_idvd = 8; %15
fsz_ticks = 12;%30
fsz_title = 12; % font size of title, 10
wd = 2; % line width of axis, 5
wd_bar = .5; % the width of the bar (not the bar edge!!)
wd_ref = 2; % line width of the reference line
markers_allSubj = {'o', 's', 'd', '^','v',  '<', '+','p', 'h', 'x', '>', '>', 'o', 's', 'd', '^','v',  '<', '+','p', 'h', 'x', '>', '>', 'o', 's', 'd', '^','v',  '<', '+','p', 'h', 'x', '>', '>'};

%% extract nsubj and nLoc and make assertion
[nsubj, nLoc] = size(med_allSubj);
assert(length(markers_allSubj) >= nsubj)
assert(length(x_ticks) == nLoc)

%% get ave/SEM
[ave, ~, ~, sem] = getCI(med_allSubj, 2, 1);

% if flag_plotIdvd, figure('Position', [0 200 300 400])
% else, figure('Position', [0 200 300 400])
% end
hold on

%% idvd data
if flag_plotIdvd
    if nLoc == 2 % for nLoc=2, plot idvd data between two bars
        buffer = .3;
        for isubj = 1:nsubj
            plot([1+buffer, 2-buffer], med_allSubj(isubj, :), [markers_allSubj{isubj}, '-'], ...
                'color',ones(1,3)*.7, 'markerfacecolor', 'w', 'markeredgecolor', ones(1,3)*.7, ...
                'markersize', sz_marker_idvd, 'linewidth', 1)
        end
    else % for nLoc>2, plot idvd data at the center of each bar
        for isubj = 1:nsubj
            plot(1:nLoc, med_allSubj(isubj, :), [markers_allSubj{isubj}, '-'], 'color', ones(1,3)*.5, 'markersize', sz_marker_idvd)
%             plot(1:nLoc, med_allSubj(isubj, :), '-', 'color', ones(1,3)*.5, 'markersize', sz_marker_idvd)
        end
    end
end

%% plot bars/disks and errorbars
for iLoc = 1:nLoc
%     plot(iLoc, ave(iLoc), 'o', 'MarkerEdgeColor', colors(iLoc, :), 'MarkerSize', sz_marker_ave, 'linewidth', wd)
    bar(iLoc, ave(iLoc), 'FaceColor', colors(iLoc, :),  'EdgeColor', colors(iLoc, :), 'barwidth', wd_bar)
    errorbar(iLoc, ave(iLoc), sem(iLoc), '.', 'color', colors(iLoc, :), 'CapSize', 0, 'linewidth', wd)
end % end of iiLoc

%% draw ref and compare bars with ref (print in command window)
if ~isnan(ref)
    if length(ref)>1; error('ALERT: there are more than one REF!!!'), end
    yline(ref, 'color', ones(1,3)/2, 'linewidth', wd_ref);
    for iLoc = 1:nLoc
        [~, p, ~, stats] = ttest(med_allSubj(:, iLoc)-ref);
        fprintf('   %s (%.2f) vs. ref (%d): t=%.2f, p=%.3f (%d/%d)\n', x_ticks{iLoc}, mean(med_allSubj(:, iLoc)), ref, stats.tstat, p, sum(med_allSubj(:, iLoc)> ref), nsubj);
    end
end

%% conduct ANOVA (regardless of nLoc)
indLoc = repmat(1:nLoc, nsubj, 1);
text_ANOVA = print_nANOVA({'Loc'}, med_allSubj(:), {indLoc(:)}, 0);

%% if nLoc>2, compare (every) pair
text_testPairs = '';
if nLoc>2
    indPairs = [1,2;2,3;1,3]; % to modify
    npairs = size(indPairs , 1);
    for ipair = 1:npairs
        x1 = med_allSubj(:, indPairs(ipair, 1));
        x2 = med_allSubj(:, indPairs(ipair, 2));
        [~, p,~, stats] = ttest(x1, x2);
        cohenD = fxn_getES(x1, x2);
        text_testPairs = [text_testPairs, sprintf('%s vs. %s: t=%.2f, p=%.3f, d=%.2f (%d/%d)\n', ...
            x_ticks{indPairs(ipair, 1)}, x_ticks{indPairs(ipair, 2)}, stats.tstat, p, cohenD, sum(med_allSubj(:, iLoc)> ref), nsubj)];
    end

elseif nLoc==2
    x1 = med_allSubj(:, 1);
    x2 = med_allSubj(:, 2);
    [~, p,~, stats] = ttest(x1, x2);
    cohenD = fxn_getES(x1, x2);
    flag_sig='ns'; if p<.05, flag_sig='sig'; end
    text_testPairs = sprintf('%s vs. %s: t=%.2f, p=%.3f, d=%.2f (%d/%d)\n', ...
        x_ticks{1}, x_ticks{2}, stats.tstat, p, cohenD, sum(med_allSubj(:, 1)> med_allSubj(:, 2)), nsubj);

    if flag_plotDiff
        yDiffSEM = y_ticks(end) - (y_ticks(end) - y_ticks(1))/6;
        diff_sem = std(x1 - x2)/sqrt(nsubj);
        errorbar(1.5, yDiffSEM, diff_sem, 'k', 'CapSize', 0, 'linewidth', wd)
        plot([1,2], [yDiffSEM, yDiffSEM], 'k-', 'linewidth', wd)
        %     string_s = getString_starts(p);
    end
end

%% ticks, limits and labels
if ~isnan(y_ticks), yticks(y_ticks), ylim(y_ticks([1, end])), end
if ~isnan(y_ticklabels), yticklabels(y_ticklabels), end
xticks(1:nLoc), xticklabels([]) % manually add tick labels /symbols on the slide
% if ~isnan(x_label), xlabel(x_label), end
% if ~isnan(y_label), ylabel(y_label), end

% if plot idvd data, leave more space for the middle
if flag_plotIdvd, buffer = 1; else, buffer = 1; end
xlim([1-buffer, nLoc+buffer])

%% size
ax = gca;
ax.XAxis.FontSize = fsz_ticks;
ax.YAxis.FontSize = fsz_ticks;
ax.LineWidth = wd;

%% title
title(sprintf('%s\n%s\n%s', text_title, text_ANOVA, text_testPairs), 'fontsize', fsz_title)

% title(sprintf('%s\n%s', text_title, text_ANOVA), 'fontsize', fsz_title)


