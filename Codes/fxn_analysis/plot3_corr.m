figure('Position', [0 100 800 400])
for flag_zeroMean = [0,1]
    subplot(1,2,flag_zeroMean+1)
    switch flag_zeroMean, case 1, title_ = 'Zero-mean'; case 0, title_ = 'Raw'; end
    
    if flag_zeroMean
        x_ticks = linspace(-.5, .5, 5);
        switch iTvC
            case 1, if iLF==1, y_ticks = linspace(-2, 2, 5); else, y_ticks = linspace(-5, 5, 5); end
            case 2, 
                switch iLF, 
                    case 1, y_ticks = linspace(-1,1, 5); 
                    case 2, y_ticks = linspace(-10, 10, 5); 
                    case 3, y_ticks = linspace(-.5, .5, 5); 
                    case 4, y_ticks = linspace(-2, 2, 5);
                end
        end
    else
        x_ticks = linspace(-2, 0, 5);
        switch iTvC
            case 1, y_ticks = ticks_LAM{iLF};
            case 2, y_ticks = ticks_PTM{iLF};
        end
    end
    
    % fov, HM4 (mean([L, R])), LVM4, UVM4, HM8 (mean([L, R])), LVM8, UVM8
    ix_all = [1, 4, 6, 7, 8, 10, 11];
    names = namesCombLoc(ix_all);
    colors = colors_asym(ix_all, :);
    
    % create thresh_CombLoc_allSubj
    iNoise_corr = 1; % threshold at absence of noise
    thresh_CombLoc_allSubj = fxn_extractAsym(squeeze(thresh_log_allSubj(:, :, iNoise_corr, iPerf_plot)));
    
    nx = length(ix_all);
    x = [];y=x;
    for iix = 1:nx
        x = [x, thresh_CombLoc_allSubj{ix_all(iix)}];
        y = [y, LF_CombLoc_allSubj{ix_all(iix)}];
    end
    
    %-------%
    basicFxn_drawCorr(x,y, colors, names, x_ticks, y_ticks, [], [], flag_zeroMean, 'pearson', 'both', title_);
    %-------%
    legend(subjList, 'Location', 'best')
    % saveas(gcf, sprintf('%s/corr_%s.jpg', nameFolder_fig_allSubj_, text_combEcc4(1:end-1)))
    
end % flag_zeroMean
sgtitle(sprintf('SF%d %s%d [%s] collapseHM=%d', SF, namesTvCModel{iTvC}, iLF, namesLF{iLF}, flag_collapseHM))
saveas(gcf, sprintf('%s/corr.jpg', nameFolder_fig_allSubj_))
