%%%% PERFORMANCE FIELDS x EQUIVALENT NOISE %%%%


% Last updated by Shutian Xue in May, 2025





clear all, close all, clc, format compact, commandwindow; % SX; force the cursor to go automatically to command window
% set(0, 'DefaultFigureWindowStyle', 'docked')

% generate paths
addpath(genpath('Data/Data_OOD/')); % SX
addpath(genpath('Codes/')); % SX

nameFolder_server = '/Volumes/purplab/EXPERIMENTS/1_Current_Experiments/Shutian_server/PF_EN';

%% Initiate analysis
load(sprintf('%s/Data/Data/params.mat', nameFolder_server))
fit_nBins = 10;%input('         >>> nBins (Number of bins when fitting PMF) = ');
indLoc_s_all = {[1,2,3], [1,4,8], [1,5,9], [4,5], [6,7], [8,9], [10,11], [1, 4,6,7,   8,10,11], [4,5,8,9], [6,7,10,11]}; nIndLoc_s = length(indLoc_s_all); % Total number of location groups

%------------------%
SX_analysis_setting
%------------------%
%----------------%
% SX_fitTvC_setting
%----------------%

for nBoot = [1000, 1];
    str_SF =  'SF46';  SF_load_all = [4, 6]; flag_n9 = 0; nsubj_acrossSF = 21;  namesSF = {'SF4', 'SF6'}; markers_acrossSF = {'s', 'hexagram'};
    % str_SF =  'SF456';  SF_load_all = [4, 5, 51, 6]; flag_n9 = 0; nsubj_acrossSF = 31; namesSF = {'SF4', 'SF5', 'SF6'}; markers_acrossSF = {'s', 'pentagram', 'hexagram'};
    % str_SF =  'SF46';  SF_load_all = [4, 6]; flag_n9 = 1; nsubj_acrossSF = 18;  namesSF = {'SF4', 'SF6'}; markers_acrossSF = {'s', 'hexagram'};
    % str_SF =  'SF6';  SF_load_all = [6]; flag_n9 = 0; nsubj_acrossSF = 12;  namesSF = {'SF6'}; markers_acrossSF = {'hexagram'};% 1=only include the 9 subjects shared between SF4 and SF6

    %--- Manual Settings ---------
    flag_plotGroupTvC = 0; % Plot group TvC curves
    flag_plotIdvdTvC = 0; % Plot individual TvC curves
    flag_plotCorrAsym = 0; % Plot correlation between asymmetries
    iControl_all = [1,0]; % 0= raw data; 1=demean across SFs to reveal subj effect
    nameFolder_Fig_acrossSFs = 'Figures/acrossSFs';
    %---------------------------

    str_n9 = ''; if flag_n9, str_n9 = '_n9'; end
    nSF = length(SF_load_all);
    iPerf_plot = 2; % Performance levels to plot
    nIndLoc_s = 10; nLoc_s_max = 7; % see fxn_fitTvCIDVD
    nParams = nLF_PTM-1;
    nModels_NestedPTM = 16;

    iErrorType = 1; %1=fit TvC using log cst; 2=linear contrast; 3=linear energy
    flag_weightedFitting = 1;
    flag_Bcorrect = 1;
    flag_PTMwithSF = 0;
    iTvCModel = 2; %1=LAM; 2=PTM
    flag_plotIDVD = 0;
    flag_locType = 2;
    nameModel = 'NoNmul';
    IndCand_GroupBest_vec = [125, 125, 125, 8, 8, 8, 8];
    text_locType = 'combLoc';
    nLoc = nLocComb;
    colors_allLoc = colors_asym;
    names_allLoc = namesCombLoc; %flag_plotIDVD=0;
    flag_binData = 1;
    flag_filterData = 1;
    SF_fit = 1;

    % Loop through SF groups
    for SF = SF_load_all
        %--------------------%
        initAnalysis % e.g., subjList
        %--------------------%

        fprintf('\n    ===============================\n')
        fprintf('      n=%d [SF = %d] nNoise = %d\n      nBoot = %d\n      nBins = %d\n      nLoc = %d (single) + %d (HM)', nsubj, SF, nNoise, nBoot, fit.nBins, nLocSingle, nLocHM)
        fprintf('\n    ===============================\n')

        % FOLDERS & FILES (group)
        nameFolder_dataOOD_load = sprintf('%s/Data/Data_OOD/nNoise%d/SF%s', nameFolder_server, nNoise_save, SF_str);
        if isempty(dir(nameFolder_dataOOD_load)), mkdir(nameFolder_dataOOD_load), end
        nameFile_fitTvC_allSubj = sprintf('%s/n%d_fitTvC_B%d_constim%d_Bin%dFilter%d_%s_%s.mat', ...
            nameFolder_dataOOD_load, nsubj, nBoot, fit.nBins, flag_binData, flag_filterData, text_collapseHM, text_locType);

        nameFolder_fig_PF = sprintf('%s/%s/PF', nameFolder_Fig_acrossSFs, str_SF);

        % Create Empty Containers
        thresh_log_allB_allSubj = nan(nsubj, nLocComb, nNoise, nPerf, nBoot);
        nData_allB_allSubj = nan(nsubj, nLocComb, nNoise, nBoot);
        est_BestSimplest_allB_allSubj = nan(nsubj, nIndLoc_s, nLoc_s_max, nParams, nBoot);
        R2_BestSimplest_allB_allSubj = nan(nsubj, nIndLoc_s, nLoc_s_max, nPerf, nBoot);
        dBIC_nestedMC_allB_allSubj = nan(nsubj, nIndLoc_s, nModels_NestedPTM, nBoot); % 16 = number of nested PTM models

        for isubj = 1:nsubj

            subjName = subjList{isubj};
            fprintf('\n\n******** SF%d %d/%d %s [Bin%d Filter%d] *********\n', SF, isubj, nsubj, subjName, flag_binData, flag_filterData)

            % FOLDERS & FILES (idvd)
            nameFile_fitTvC_perSubj = sprintf('%s/%s/%s_fitTvC_B%d_constim%d_Bin%dFilter%d_%s.mat', ...
                nameFolder_dataOOD_load, subjName, subjName, nBoot, fit.nBins,flag_binData, flag_filterData, text_locType);

            % load idvd TvC fitting data
            load(nameFile_fitTvC_perSubj, '*_allLoc_allB') % contains the four *allB files saved below
            fprintf('TvC Fitting LOADED\n')

            % Compile all subj
            thresh_log_allB_allSubj(isubj, :, :, :, :) = thresh_log_allLoc_allB; % nLocComb x nNoise x nPerf x nBoot
            nData_allB_allSubj(isubj, :, :, :) = nData_allLoc_allB; % nLocComb x nNoise x nBoot
            R2_BestSimplest_allB_allSubj(isubj, :, :, :, :) = R2_BestSimplest_allLoc_allB(1:10, :, :, :); % nLocGroups x nLoc_max x nPerf x nBoot
            est_BestSimplest_allB_allSubj(isubj, :, :, :, :) = est_BestSimplest_allLoc_allB(1:10, :, :, :); % nLocGroups x nLoc_max x nParams x nBoot
            dBIC_nestedMC_allB_allSubj(isubj, :, :, :) = dBIC_nestedMC_allLoc_allB(1:10, :, :);

            %====== Plot idvd TvCs (by loc groups) ======
            if flag_plotIdvdTvC
                %----------------%
                SX_fitTvC_setting
                %----------------%

                str_sgtitle = sprintf('%s %s', namesTvCModel{iTvCModel}, nameModel);
                y_ticks = ticks_PTM(2:4); y_ticklabels = ticklabels_PTM(2:4); iParams_all = 1:3; namesLF = namesLF_PTM(2:4); namesLF_Labels = namesLF_PTM(2:4);
                nParams = length(iParams_all);

                flag_nestedMC = 0;
                flag_varyLocMC = 0;
                for iiIndLoc_s = 1:nIndLoc_s
                    indLoc_s = indLoc_s_all{iiIndLoc_s};
                    nLoc_s = length(indLoc_s); % Number of selected locations
                    namesCombLoc_s = namesCombLoc(indLoc_s); % Get location names
                    str_LocSelected = strjoin(namesCombLoc_s, ''); % Concatenate location names into a single string
                    % fprintf('\n-------%s------\n', str_LocSelected) % Print the selected location name

                    figure('Position', [0 0 2e3 800]),
                    subplot(2,4,[1,2,5,6]), hold on, ax = gca; ax.YGrid = 'on';
                    legends_all = cell(1,nLoc_s);
                    for iiLoc = 1:nLoc_s
                        color_ = colors_asym(indLoc_s(iiLoc), :); % Color for location
                        % Take median of boostrapped data (thresh, estP and R2) per subj, and store for each SF
                        [thresh_med, thresh_lb, thresh_ub] = getCI(thresh_log_allLoc_allB(indLoc_s(iiLoc), :, iPerf_plot, :), 1, 4); % thresh_log_allB_allSubj: nsubj x nLocComb_max(11) x nNoise x nPerf x nBoot
                        [estP_med, estP_lb, estP_ub] = getCI(est_BestSimplest_allLoc_allB(iiIndLoc_s, iiLoc, :, :), 1, 4); % est_xx_allB_allSubj: nsubj x nLocGroups x nLoc_max x nParams x nBoot
                        [R2_med, R2_lb, R2_ub] = getCI(R2_BestSimplest_allLoc_allB(iiIndLoc_s, iiLoc, iPerf_plot, :), 1, 4);
                        [nData_med] = getCI(nData_allLoc_allB(indLoc_s(iiLoc), :, :), 1, 3);
                        % Make predictions
                        %------------------------------------------------------------------------------------------%
                        threshEnergy_pred = fxn_PTM([0,1,1,1], estP_med, noiseEnergy_intp_true, dprimes(iPerf_plot), SF_fit);
                        %------------------------------------------------------------------------------------------%
                        % errorbars
                        errorbar(noiseSD_log_all, thresh_med, thresh_med-thresh_lb, thresh_ub-thresh_med, '.', 'color', color_, 'HandleVisibility', 'off', 'CapSize', 0)
                        % median thresh
                        % plot(noiseSD_log_all, thresh_med, 'o', 'color', color_, 'HandleVisibility', 'off', 'MarkerFaceColor', 'w', 'MarkerSize', 10)
                        for iNoise=1:nNoise
                            plot(noiseSD_log_all(iNoise), thresh_med(iNoise), 'o', 'color', color_, 'HandleVisibility', 'off', 'MarkerSize', 10*nData_med(iNoise)/200)
                        end
                        % pred
                        plot(noiseSD_intp_log_true, log10(sqrt(threshEnergy_pred)), '-', 'color', color_)
                        % legend
                        legends_all{iiLoc} = sprintf('%s: R2=%.2f [%.2f, %.2f]\n    Gain: %.2f [%.2f, %.2f]\n    Nadd: %.3f [%.3f, %.3f]\n    Gamma: %.2f [%.2f, %.2f]\n', ...
                            namesCombLoc{indLoc_s(iiLoc)}, R2_med, R2_lb, R2_ub, ...
                            estP_med(3), estP_lb(3), estP_ub(3), ...
                            10^estP_med(2), 10^estP_lb(2), 10^estP_ub(2), ...
                            estP_med(1), estP_lb(1), estP_ub(1));

                    end % iiLoc

                    xlabel('External noise SD');
                    x_ticks = noiseSD_log_all; x_ticklabels = round(noiseSD_full, 3);
                    % x_ticks = [noiseSD_log_all(1), noiseSD_log_full_acrossSF(2:end)]; x_ticklabels = round(noiseSD_full_acrossSF, 3); % defined in fxn_loadSF
                    xlim([x_ticks(1) - 0.1, x_ticks(end) + 0.1]); xticks(x_ticks); xticklabels(x_ticklabels); xtickangle(90)

                    ylabel('Contrast threshold (%)');
                    yticks(cst_log_ticks); yticklabels(round(cst_ln_ticks)); ylim(cst_log_ticks([1, end]));

                    title(sprintf('[%s SF%d] nBoot=%d', subjName, SF, nBoot))
                    % legend(legends_all, 'Location', 'eastoutside')

                    % gain
                    iPlots_sub = [3,4,7,8];
                    for iValue = 1:4
                        subplot(2,4,iPlots_sub(iValue))
                        hold on
                        for iiLoc = 1:nLoc_s

                            color_ = colors_asym(indLoc_s(iiLoc), :); % Color for location
                            if iValue==1 % R2
                                [val_med, val_lb, val_ub] = getCI(R2_BestSimplest_allLoc_allB(iiIndLoc_s, iiLoc, iPerf_plot, :), 1, 4);
                                title('R2')
                                ylim([0, 1]), yticks(0:.25:1)
                            else % three
                                iParam = iValue-1;
                                [val_med, val_lb, val_ub] = getCI(est_BestSimplest_allLoc_allB(iiIndLoc_s, iiLoc, iParam, :), 1, 4); % est_xx_allB_allSubj: nsubj x nLocGroups x nLoc_max x nParams x nBoot
                                title(namesLF_Labels_PTM{iValue})
                                ylim([lb_PTM(iValue), ub_PTM(iValue)])
                                yticks(linspace(lb_PTM(iValue), ub_PTM(iValue), 5))
                            end
                            bar(iiLoc, val_med, 'facecolor', 'w', 'edgecolor', color_)
                            errorbar(iiLoc, val_med, val_med-val_lb, val_ub-val_med, '.', 'color', color_, 'HandleVisibility', 'off', 'CapSize', 0)
                        end % iiLoc
                        xticks(1:nLoc_s)
                        xticklabels(namesCombLoc_s)
                    end % iParam

                    set(findall(gcf, '-property', 'linewidth'), 'linewidth', 1.5)
                    set(findall(gcf, '-property', 'fontsize'), 'fontsize', 15)
                    nameFolder_fig_idvd = sprintf('%s/IdvdTvC_nBoot%d', nameFolder_Fig_acrossSFs, nBoot);
                    if isempty(dir(nameFolder_fig_idvd)), mkdir(nameFolder_fig_idvd), end
                    saveas(gcf, sprintf('%s/%s%d_%s.jpg', nameFolder_fig_idvd, subjName, SF, str_LocSelected))
                end % iiIndLoc_s
                close all
            end
        end % isubj

        % Save group data
        save(nameFile_fitTvC_allSubj, '*_allB_allSubj')
        fprintf('\n\n========= GROUP data saved =========\n\n')

    end %

    %% PLOT TvC
    if flag_plotGroupTvC
        % indLoc_s_all = {[1,2,3], [1,4,8], [1,5,9], [4,5], [6,7], [8,9], [10,11], [1, 4, 6, 7, 8, 10, 11]}; nIndLoc_s = length(indLoc_s_all); % Total number of location groups
        %----------------%
        SX_fitTvC_setting
        %----------------%
        clc

        str_sgtitle = sprintf('%s %s', namesTvCModel{iTvCModel}, nameModel);
        y_ticks = ticks_PTM(2:4); y_ticklabels = ticklabels_PTM(2:4); iParams_all = 1:3; namesLF = namesLF_PTM(2:4); namesLF_Labels = namesLF_PTM(2:4);
        nParams = length(iParams_all);

        flag_nestedMC = 0;
        flag_varyLocMC = 0;

        % Loop through each location group
        for iiIndLoc_s = 1:nIndLoc_s
            indLoc_s = indLoc_s_all{iiIndLoc_s};
            nLoc_s = length(indLoc_s); % Number of selected locations
            if nLoc_s==3, scaling = 1; elseif nLoc_s==2, scaling = 1.5; else, scaling = 1; end
            scaling = 1;
            namesCombLoc_s = namesCombLoc(indLoc_s); % Get location names
            str_LocSelected = strjoin(namesCombLoc_s, ''); % Concatenate location names into a single string
            fprintf('\n-------%s------\n', str_LocSelected) % Print the selected location name

            %---------------------%
            SXplot_TvC_4PRE3_boot
            %---------------------%

        end
    end

    %% Compile thresholds and params into a table
    SX_createLMETable_v2
end % nBoot

