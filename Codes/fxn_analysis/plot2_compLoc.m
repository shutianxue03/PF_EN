

% subjList_AB=[];
% ecc0, ecc4
fxn_compLoc([1,2], colors_comb(1:2, :), {'Ecc0', 'Ecc4'}, subjList,  LF_CombLoc_allSubj, LF_CombLoc_aveSubj, markers_allSubj, nameFolder_fig_allSubj_, title_, ticks_, ticklabels_)
% HM4 vs. VM4 vs. LVM4 vs. UVM4
fxn_compLoc(4:7, [colors_comb([4,5], :); colors_single([5,3], :)], {'HM4', 'VM4', 'LVM4', 'UVM4'}, subjList,  LF_CombLoc_allSubj, LF_CombLoc_aveSubj, markers_allSubj, nameFolder_fig_allSubj_, title_, ticks_, ticklabels_)
% HM4 vs. VM4
fxn_compLoc([4,5], colors_comb([4,5], :), {'HM4', 'VM4'}, subjList,  LF_CombLoc_allSubj, LF_CombLoc_aveSubj, markers_allSubj, nameFolder_fig_allSubj_, title_, ticks_, ticklabels_)
% HM4 vs. LVM4
fxn_compLoc([4,6], [colors_comb(4, :); colors_single(5, :)], {'HM4', 'LVM4'}, subjList,  LF_CombLoc_allSubj, LF_CombLoc_aveSubj, markers_allSubj, nameFolder_fig_allSubj_, title_, ticks_, ticklabels_)
% HM4 vs. UVM4
fxn_compLoc([4,7], [colors_comb(4, :); colors_single(3, :)], {'HM4', 'UVM4'}, subjList,  LF_CombLoc_allSubj, LF_CombLoc_aveSubj, markers_allSubj, nameFolder_fig_allSubj_, title_, ticks_, ticklabels_)
% LVM4 vs. UVM4
fxn_compLoc([6,7], colors_single([5,3], :), {'LVM4', 'UVM4'}, subjList,  LF_CombLoc_allSubj, LF_CombLoc_aveSubj, markers_allSubj, nameFolder_fig_allSubj_, title_, ticks_, ticklabels_)

if nLocSingle>5
    % ecc0, ecc8
    fxn_compLoc([1,3], colors_comb([1,3], :), {'Ecc0', 'Ecc8'}, subjList,  LF_CombLoc_allSubj, LF_CombLoc_aveSubj, markers_allSubj, nameFolder_fig_allSubj_, title_, ticks_, ticklabels_)
    % ecc0, ecc4, ecc8
    fxn_compLoc(1:3, colors_comb(1:3, :), {'Ecc0', 'Ecc4', 'Ecc8'}, subjList,  LF_CombLoc_allSubj, LF_CombLoc_aveSubj, markers_allSubj, nameFolder_fig_allSubj_, title_, ticks_, ticklabels_)
    % ecc4, ecc8
    fxn_compLoc([2,3],colors_comb(2:3, :), {'Ecc4', 'Ecc8'}, subjList,  LF_CombLoc_allSubj, LF_CombLoc_aveSubj, markers_allSubj, nameFolder_fig_allSubj_, title_, ticks_, ticklabels_)
    
    % HM8 vs. VM8 vs. LVM8 vs. UVM8
    fxn_compLoc(8:11, [colors_comb([6,7], :); colors_single([9,7], :)], {'HM8', 'VM8', 'LVM8', 'UVM8'}, subjList,  LF_CombLoc_allSubj, LF_CombLoc_aveSubj, markers_allSubj, nameFolder_fig_allSubj_, title_, ticks_, ticklabels_)
    % HM8 vs. VM8
    fxn_compLoc([8,9], colors_comb([6,7], :), {'HM8', 'VM8'}, subjList,  LF_CombLoc_allSubj, LF_CombLoc_aveSubj, markers_allSubj, nameFolder_fig_allSubj_, title_, ticks_, ticklabels_)
    % HM8 vs. LVM8
    fxn_compLoc([8,10], [colors_comb(6, :); colors_single(9, :)], {'HM8', 'LVM8'}, subjList,  LF_CombLoc_allSubj, LF_CombLoc_aveSubj, markers_allSubj, nameFolder_fig_allSubj_, title_, ticks_, ticklabels_)
    % HM8 vs. UVM8
    fxn_compLoc([8,11], [colors_comb(6, :); colors_single(7, :)], {'HM8', 'UVM8'}, subjList,  LF_CombLoc_allSubj, LF_CombLoc_aveSubj, markers_allSubj, nameFolder_fig_allSubj_, title_, ticks_, ticklabels_)
    % LVM8 vs. UVM8
    fxn_compLoc([10, 11], colors_single([9,7], :), {'LVM8', 'UVM8'}, subjList,  LF_CombLoc_allSubj, LF_CombLoc_aveSubj, markers_allSubj, nameFolder_fig_allSubj_, title_, ticks_, ticklabels_)
end

%%
function fxn_compLoc(indLoc, colors, namesLoc, subjList,  LF_CombLoc_allSubj, LF_CombLoc_aveSubj, markers_allSubj, nameFolder_fig_allSubj_, title_, ticks, ticklabels)

data_allSubj = [];
data_aveSubj = data_allSubj;

for ii =1:length(indLoc)
    data_allSubj = [data_allSubj, LF_CombLoc_allSubj{indLoc(ii)}];
    data_aveSubj = [data_aveSubj, LF_CombLoc_aveSubj{indLoc(ii)}];
end

[nsubj, nLoc] = size(data_allSubj);

% if LF_CombLoc_allSubj{1}(1)<0, y_ticks = Neq_log_ticks; y_ticklabels = Neq_ln_ticks; % Neq
% else, y_ticks = Eff_ln_ticks; y_ticklabels = y_ticks;% Eff
% end

figure('Position', [0 0 600 400]), hold on

% group ave
[ave, ~, ~, sem] = getCI(data_allSubj, 2, 1);
for iLoc = 1:nLoc
    bar(iLoc, ave(iLoc), 'BarWidth', .3, 'FaceColor', colors(iLoc, :), 'EdgeColor', 'k', 'HandleVisibility', 'off')
    errorbar(iLoc, ave(iLoc), sem(iLoc), '.', 'Color', colors(iLoc, :), 'CapSize', 0, 'HandleVisibility', 'off')
end

% data derived from group-averaged thresh
for iLoc = 1:nLoc
    plot(iLoc+.3, data_aveSubj(iLoc), 'o', 'color', colors(iLoc, :), 'MarkerFaceColor', colors(iLoc, :),'MarkerSize', 10,'HandleVisibility', 'off')
end

% idvd
MarkerFaceColor = 'w';
for isubj =1:nsubj
%     subjName = subjList{isubj};
%     if any(strcmp(subjName, subjList_AB)) && MarkerFaceColor = ones(1,3)/2; end
    plot(1:nLoc, data_allSubj(isubj, :), ['-', markers_allSubj{isubj}], 'color', ones(1,3)/2, 'MarkerFaceColor', MarkerFaceColor,'MarkerEdgeColor', 'k', 'MarkerSize',10)
end

xlim([0, nLoc+1])
xticks(1:nLoc)
xticklabels(namesLoc)

ylim(ticks([1, end])), yticks(ticks), yticklabels(ticklabels)

IV_loc = repmat(1:nLoc, nsubj, 1);

%%%%%%%%%%%%%%%%%%
if data_allSubj(1,1)>0, data_allSubj = log10(data_allSubj);end % regardless Neq or Eff, compare the log form
%%%%%%%%%%%%%%%%%%

% ANOVA
anova_text = print_nANOVA({'Loc'}, data_allSubj(:), {IV_loc(:)}, nsubj, 1);

% t-test
if nLoc==2
    [~, p, ~, stats] = ttest(data_allSubj(:, 1), data_allSubj(:, 2));
    title(sprintf('%s\n%st=%.2f, p=%.3f (%d/%d)', title_, anova_text, stats.tstat, p, sum(data_allSubj(:, 1)>data_allSubj(:, 2)),nsubj))
else
    title(sprintf('%s\n%s', title_, anova_text))
end

legend(subjList, 'Location','best')
set(findall(gcf, '-property', 'LineWidth'), 'LineWidth',1.5)
set(findall(gcf, '-property', 'fontsize'), 'fontsize',20)

switch nLoc
    case 2
        figNameLoc = sprintf('%s_vs_%s', namesLoc{1}, namesLoc{2});
    case 3
        figNameLoc = sprintf('%s%s%s', namesLoc{1}, namesLoc{2}, namesLoc{3});
    case 4
        figNameLoc = sprintf('%s%s%s%s', namesLoc{1}, namesLoc{2}, namesLoc{3}, namesLoc{4});
end

% if isempty(dir(sprintf('%s/%s', folder_extension, nameINE))), mkdir(sprintf('%s/%s', folder_extension)),  end
saveas(gcf, sprintf('%s/%s.jpg', nameFolder_fig_allSubj_, figNameLoc))

end

