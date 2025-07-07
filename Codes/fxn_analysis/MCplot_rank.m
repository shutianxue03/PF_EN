
flag_plotIDVDdev = 1;
flag_devErrorbar = 1;
flag_fancyXticks = 1;

errorbar_down = 10; % default=1 (not reduce siz eof errorbar)
indCand = 1:nCand_full;
nCand_show = 8; % only show the first xx models in the rank
wd_border = 1.2; % default 5
sz_ticks = 12; % 30
sz_fig_rank = [400 400];
sz_fig_box = [400 nParams*30];

% y_ticks_all = {linspace(-1, 1, 5)/1e4, linspace(-6, 14, 5)/1e5};
y_ticks_all = {linspace(0, 2, 5)/1e4, linspace(0, 4, 5)/1e5};

nameFolder_fig = 'Fig/acrossSFs/SF456/VaryLocMC';
if isempty(dir(nameFolder_fig)), mkdir(nameFolder_fig); end

nRowsSubplots = 2; %Row 1 is GoF, Row 2 is freq of the best model
isubplots = reshape(1:nRowsSubplots*nGoF, nGoF, nRowsSubplots)';
figure('Position', [0 0  2e3 2e3])

for iGoF = 1:nGoF
    
    data_allSubj = IC_allLoc{iGoF};
    [ave, ~, ~, sem] = getCI(data_allSubj, 2, 1);
    
    % get the first several best-fitting candidate model for each subj for each GoF
    nsubj = size(data_allSubj, 1);
    iSort_allSubj = nan(nsubj, nCand_full);
    for isubj=1:nsubj
        if strcmp(namesGoF{iGoF}, 'R2'), str_order = 'descend'; else, str_order = 'ascend'; end
        [data_sorted, iSort] = sort(data_allSubj(isubj, :), str_order);
        iSort_allSubj(isubj, :) = iSort;
    end
    iBest_allSubj = iSort_allSubj(:, 1); % select the best-fitting candiadte model for each subject
    
    % get the freq and ranked imodel (max freq to min)
    [freq, iBest_freq] = groupcounts(iBest_allSubj); % sorted by iBest_best (from min to max), not by freq!!
    [freq, ii] = sort(freq, 'descend');
    iBest_freq = iBest_freq(ii); % because the output of groupcounts sort from min to max
    nChosen = length(freq);
    
    %     sem = withinSubjErr(data_allSubj(:, :, iIC));
    [~, irank_groupAVE] = sort(ave, str_order); % sort based on averaged dev (for CV) for IC
    iBEST_groupAVE = irank_groupAVE(1);
    if strcmp(namesGoF{iGoF}, 'R2'), GoF_ave = ave; text_delta = '';
    else, GoF_ave = ave-min(ave); text_delta = 'Delta';
    end
    
    %%%%%%
    % Visualization
    %%%%%%
    subplot(2, nGoF, isubplots(1, iGoF)), hold on
    bar(indCand(1:nCand_show), GoF_ave(irank_groupAVE(1:nCand_show)), 'BarWidth', .5, 'FaceColor', ones(1,3)*.5, 'Edgecolor', ones(1,3)*.5)
    if flag_devErrorbar
        errorbar(indCand(1:nCand_show), GoF_ave(irank_groupAVE(1:nCand_show)), sem(1:nCand_show), '.k', 'CapSize', 0)
    end
    
    % IDVD data
    if flag_plotIDVDdev
        GoF_idvd = cell(nsubj,1);
        for isubj = 1:nsubj
            GoF_idvd{isubj} = squeeze(data_allSubj(isubj, irank_groupAVE(1:nCand_show))) - min(ave(1:nCand_show));
            plot(indCand(1:nCand_show), GoF_idvd{isubj}, '.-', 'color', ones(1,3)*.8)
        end
        % indicate the subj of the line by showing the marker of the idvd best model
        % do NOT combine with the for loop above!! (to ensure marker is on top of lines)
        for isubj = 1:nsubj
            for im_idvd = 1:nCand_show
                if im_idvd == iBest_allSubj(isubj)
                    iii = find(im_idvd == irank_groupAVE(1:nCand_show));
                    if sum(iii)
                        plot(iii, GoF_idvd{isubj}(iii), 'ko')
                    end
                end
            end
        end
    end
    
    % (fancy) xlabel ticks (NEEDS to be in the loop!)
    xTL_allC = cell(1, nCand_show);
    for ichosen = 1:nCand_show
        xTL = sprintf('[%d]', irank_groupAVE(ichosen));
        for iif = 1:nParams
            xTL = sprintf('%s\\newline%d', xTL, indParamVary_allCand(irank_groupAVE(ichosen), iif));
        end
        xTL_allC{ichosen} = xTL;
    end
    
    xlim([0, nCand_show+1])
    xticks(indCand(1:nCand_show))
    if flag_fancyXticks, xticklabels(xTL_allC), end
        
    ylabel(sprintf('%s %s', text_delta, namesGoF{iGoF}))
    title(namesGoF{iGoF})
            
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    % FREQ (in the same order as the last fig)
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    %         figure('Position', [0,500, 800, 550]), hold on
    %     if MCmode == 3, subplot(2, nGoF, iIC + nGoF), else, subplot(2,1,2), end
    
    subplot(2, nGoF, isubplots(2, iGoF)), hold on
    xTL_allC = cell(nCand_show, 1);
    for ichosen = 1:nChosen
        xPos = find(iBest_freq(ichosen) == irank_groupAVE(1:nCand_show));
        bar(xPos, freq(ichosen), 'FaceColor', 'w', 'BarWidth', .5)
    end
    
    xticks([]) % consistent wth the dev plot
    %     xticks(1:nChosen)
    %     xticklabels((xTL_allC)%, xtickangle(-50)
    xlim([.5, nCand_show+1.5])
    ylim([0, max(freq)+1])
    xlim([0, nCand_show+1])
    %     xlabel('Candidate model #')
    ylabel('Freq. best')
    ylim([0, 15])
    
    set(findall(gcf, '-property', 'FontSize'), 'FontSize',sz_ticks)
    set(findall(gcf, '-property', 'LineWidth'), 'LineWidth',wd_border)
    
    % save figure
%     saveas(gcf, sprintf('%s/%s.jpg', nameFolder_fig, str_LocSelected));
    
end % iGoF
