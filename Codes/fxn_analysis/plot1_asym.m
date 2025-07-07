

figure('Position', [0 0 800 400]), hold on
% idvd data
MarkerFaceColor = 'w';
for isubj=1:nsubj%, plot(1:4, HVA_allSubj(isubj, :), '-')
    subjName = subjList{isubj};
%     if any(strcmp(subjName, subjList_AB)) && flag_combineMode, MarkerFaceColor = ones(1,3)/2; end
    MarkerFaceColor = ones(1,3)/2;
    plot(1:nasym, LF_asym_allSubj(isubj, :), ['-', markers_allSubj{isubj}], 'Color', ones(1,3)/2, 'MarkerSize', 10, 'MarkerFaceColor', MarkerFaceColor)
end

% group average
errorbar(1:nasym, LF_asym_ave, LF_asym_sem, 'ok', 'CapSize', 0, 'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', 'k', 'HandleVisibility', 'off')

% LF derived from group averaged threshold
plot((1:nasym)+.2, LF_asym_aveSubj, 'ok', 'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', 'w', 'HandleVisibility', 'off')

yline(0, 'k');
xticks(1:nasym), xticklabels(namesAsym), xtickangle(45)
ylabel('Asymmetry (%)')
ylim(y_ticks_asym([1, end]))
yticks(y_ticks_asym)
xlim([0, nasym+1])
title(sprintf('SF%d (n=%d) %s%d %s [collapseHM=%d]', SF, nsubj, namesTvCModel{iTvC}, iLF, namesLF{iLF}, flag_collapseHM))
% legend(subjList, 'Location', 'best', 'NumColumns', 5)

set(findall(gcf, '-property', 'fontsize'), 'fontsize',18)
set(findall(gcf, '-property', 'fontsize'), 'linewidth',2)

saveas(gcf, sprintf('%s/asym.jpg', nameFolder_fig_allSubj_))
