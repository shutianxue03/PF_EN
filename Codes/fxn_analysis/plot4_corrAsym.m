
iNoise = 1;

if flag_combineEcc8
    thresh_asym_allSubj_ = thresh_asym_allSubj(:,:, [2,6,7]);
    LF_CombLoc_allSubj_ = LF_CombLoc_allSubj([1, 6:9]);
    LF_asym_allSubj_ = LF_asym_allSubj(:, [2,6,7]);
    namesAsym_ = namesAsym([2,6,7]);
else
    thresh_asym_allSubj_ = thresh_asym_allSubj;
    LF_CombLoc_allSubj_ = LF_CombLoc_allSubj;
    LF_asym_allSubj_ = LF_asym_allSubj;
    namesAsym_ = namesAsym;
end
nasym = length(namesAsym_);

%% 
figure('Position', [0 100 1500 1e3])
for iasym = 1:nasym
    if nasym>3, subplot(2,4,iasym+1),
    else, subplot(1,nasym,iasym+1),
    end
    
%     basicFxn_drawCorrAsym(thresh_asym_allSubj_(:, iNoise, iasym), LF_asym_allSubj_(:, iasym), y_ticks_asym, y_ticks_asym, [], [], namesAsym_{iasym});
    basicFxn_drawCorrAsym(thresh_asym_allSubj_(:, iasym), LF_asym_allSubj_(:, iasym), [], [], [], [], namesAsym_{iasym});
    
end

legend(subjList, 'Location', 'best')
sgtitle(sprintf('SF%d %s%d [%s] collapseHM=%d', SF, namesTvCModel{iTvC}, iLF, namesLF{iLF}, flag_collapseHM))
set(findall(gcf, '-property', 'fontsize'), 'fontsize',12)
saveas(gcf, sprintf('%s/corrAsym.jpg', nameFolder_fig_allSubj_))

