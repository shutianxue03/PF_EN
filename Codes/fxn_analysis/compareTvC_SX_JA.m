
% compare the TvC (estimated threshold as a fxn of noise) between JA and
% SX's estimation

% note that in JA's estimation, thresh at some loc are not estimated (or at least not recorded)

close all
subjList = {'fc', 'ja', 'jfa', 'zw', 'ab', 'kae', 'ec', 'il', 'aw', 'mg', 'mr'}; nsubj = length(subjList);
x_noise = [0, .055, .11, .165, .22, .275, .33]; nNoise = length(x_log);
flag_collapseHM=0;
nLoc = 9;
iPerf = 3;

x_log = log10(x_noise);
x_log_ticks = [-1.6, x_log(2:end)];

for isubj = 11%1:nsubj
    subjName = subjList{isubj};
    
    nameFolder_JA = sprintf('Data_OOD/nNoise7/SF5_JA/ccc/%s_ccc_all.mat', subjName);
    load(nameFolder_JA, 'TvC_JA')
    
    nameFolder_SX = sprintf('Data_OOD/nNoise7/SF5_JA/n%d_*HM%d.mat', nsubj, flag_collapseHM);
    dir_ = dir(nameFolder_SX);
    load([dir_.folder,'/', dir_.name], 'thresh_best_allSubj')
    
    thresh_log_min = -1.4;
    thresh_log_max = -.2;
    y_ticks_log = linspace(thresh_log_min, thresh_log_max, 10);
    
    for iLoc = 1:nLoc
        % load
        y_log_SX = squeeze(thresh_best_allSubj(isubj, iLoc, :, iPerf)); y_log_SX = reshape(y_log_SX, [1,nNoise]);
        y_log_JA = log10(TvC_JA(iLoc, :));
        
        figure('Position', [0 200 500 800])
        
        subplot(2,1,1), hold on, grid on, axis square
        plot(x_log_ticks, y_log_JA, 'ro-');
        plot(x_log_ticks, y_log_SX, 'bo-');
        
        xticks(x_log_ticks), xticklabels(round(x_noise*100,1)), xlim([x_log_ticks(1)-.1, x_log_ticks(end)+.1])
        yticks(y_ticks_log)
        yticklabels(round(10.^y_ticks_log*100, 1))
        ylim([thresh_log_min, thresh_log_max])
        legend({'JA''s estimation', 'SX''s estimation'}, 'Location', 'northwest')
        
        subplot(2,1,2), hold on, grid on, axis square
        plot(y_log_JA, y_log_SX, 'ko');
        plot([thresh_log_min, thresh_log_max], [thresh_log_min, thresh_log_max], '-', 'Color', ones(1,3)/2)
                xticks(y_ticks_log)
        xticklabels(round(10.^y_ticks_log*100, 1))
        xlim([thresh_log_min, thresh_log_max])
        
                yticks(y_ticks_log)
        yticklabels(round(10.^y_ticks_log*100, 1))
        ylim([thresh_log_min, thresh_log_max])
        
        xlabel('JA''s estimation')
        ylabel('SX''s estimation')
        
        set(findall(gcf, '-property', 'fontsize'), 'fontsize',12)
        
        sgtitle(sprintf('%s L%d', subjName, iLoc))
    end % iLoc
    
end % isubj

