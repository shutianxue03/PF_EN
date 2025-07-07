%% Analyze
clc
nsubj_full = 31;       % Total number of subjects
namesGoF = {'R2', 'AIC', 'AICc', 'BIC', 'RSS'}; nGoF = length(namesGoF);
indLoc_s_all = {[1,2,3], [1,4,8], [1,5,9], [4,5], [6,7], [8,9], [10,11]}; nIndLoc_s = length(indLoc_s_all); str_LocSelected_all = cell(nIndLoc_s,1);
SF_load_all = [4,51,5,6];

% Initiate placeholders for 4 dimensions: iErrorType, iTvCModel, iiIndLoc_s and iGoF (hence. 'all4')
GoF_raw_all4 = cell(nTvC, nIndLoc_s, nErrorType, nGoF);
nParams_s_all4 = GoF_raw_all4;
indParamVary_s_all4 = GoF_raw_all4;
GoF_delta_s_all4 = GoF_raw_all4;
IndCand_GroupBest_all4 = GoF_raw_all4;
IndCand_IdvdBest_all4 = GoF_raw_all4;
iCand_basedOnAve_s_all4 = GoF_raw_all4;
R2_allPerfLoc_all4 = cell(nTvC, nIndLoc_s, nErrorType);

% Loop over each error type
for iErrorType = 1:nErrorType %1={'ErrLogCst'}, 2={'ErrLnCst'}, 3={'ErrLnEg'}
    flag_errorType = iErrorType;
    
    % Loop over each TvC Model
    for iTvCModel = 1:nTvC
        
        switch iTvCModel
            case 1, nCand_max = 25;  nParams_full = 2;
            case 2, nCand_max = 125;  nParams_full = 3;
        end
        
        % Loop over each group of locations
        for iiIndLoc_s = 1:nIndLoc_s
            indLoc_s = indLoc_s_all{iiIndLoc_s};
            nLoc_s = length(indLoc_s);
            namesCombLoc_s = namesCombLoc(indLoc_s); % Get location names
            str_LocSelected = strjoin(namesCombLoc_s, ''); % Concatenate location names
            str_LocSelected_all{iiIndLoc_s} = str_LocSelected;
            
            % Regenerate index of candidate models
            switch nLoc_s
                case 2
                    iCond_all = [0,1];
                    R2_criterion = .5; % only models with group-averaged R2 higher than this level will be selected
                    str_IndIncl_explanation = sprintf('0=Fixed | 1=free to vary between %s & %s\n', namesCombLoc_s{1}, namesCombLoc_s{2});
                case 3
                    iCond_all = 0:4;
                    switch iTvCModel
                        case 1, if iiIndLoc_s == 3, R2_criterion = .7; else, R2_criterion=.7; end
                        case 2, switch iiIndLoc_s, case 1, R2_criterion = .8; case 2, R2_criterion = .82; case 3, R2_criterion=.75; end
                    end
                    str_IndIncl_explanation = sprintf('0=Fixed for 3 loc | 4=free to vary across %s %s %s\n1=Fixed for %s & %s | 2=Fixed for %s & %s | 3=Fixed for %s & %s', ...
                        namesCombLoc_s{1}, namesCombLoc_s{2}, namesCombLoc_s{3}, ...
                        namesCombLoc_s{2}, namesCombLoc_s{3}, ...
                        namesCombLoc_s{1}, namesCombLoc_s{3}, ...
                        namesCombLoc_s{1}, namesCombLoc_s{2});
            end
            %------------------------------------------------------%
            indParamVary_allCand = fxn_getIndParamIncl(nParams_full, iCond_all);
            %------------------------------------------------------%
            nCand_full = size(indParamVary_allCand, 1); % Total candidate models
            indCand_plot = 1:nCand_full; % Indices of models to plot
            
            % Initialize matrices to store GoF metrics
            R2_VaryLocMC_acrossSF = nan(nsubj_full, nCand_full);
            AIC_VaryLocMC_acrossSF = nan(nsubj_full, nCand_full); % summed across Loc and Perf
            AICc_VaryLocMC_acrossSF = AIC_VaryLocMC_acrossSF;
            BIC_VaryLocMC_acrossSF = AIC_VaryLocMC_acrossSF;
            RSS_VaryLocMC_acrossSF = AIC_VaryLocMC_acrossSF;
            nParams_allCand_acrossSF = AIC_VaryLocMC_acrossSF;
            R2_perPerfLoc_acrossSF = nan(nsubj_full, nCand_full, nLoc_s, nPerf);
            
            % Loop over spatial frequencies (SF)
            for SF_load = SF_load_all
                %------------
                fxn_loadSF
                %------------
                load(nameFile_varyLocMC_allSubj, 'R*_varyLocMC_allSubj', 'n*_varyLocMC_allSubj');
                
                % Extract RSS, R2, and parameter counts
                R2_nMC_perLocPerf = squeeze(R2_varyLocMC_allSubj(:, iiIndLoc_s, indCand_plot, 1:nLoc_s, :)); % nsubj x 7 x nCand_max x nLoc_s_max x nPerf
                R2_nMC = mean(R2_nMC_perLocPerf, [3,4]);
                RSS_nMC = squeeze(RSS_varyLocMC_allSubj(:, iiIndLoc_s, indCand_plot, 1:nLoc_s, :));
                RSS_nMC = sum(RSS_nMC, [3,4]);
                nParams_nMC = squeeze(nParams_varyLocMC_allSubj(:, iiIndLoc_s, indCand_plot));
                nData_nMC = squeeze(nData_varyLocMC_allSubj(:, iiIndLoc_s, indCand_plot));
                
                % Save RSS, R2 and nParams
                RSS_VaryLocMC_acrossSF(isubj_start:isubj_end, indCand_plot) = RSS_nMC;
                R2_VaryLocMC_acrossSF(isubj_start:isubj_end, indCand_plot) = R2_nMC;
                nParams_allCand_acrossSF(isubj_start:isubj_end, indCand_plot) = nParams_nMC;
                
                % save R2 for each loc and perfLevel
                R2_perPerfLoc_acrossSF(isubj_start:isubj_end, indCand_plot, :, :) = R2_nMC_perLocPerf;
                R2_VaryLocMC_acrossSF(R2_VaryLocMC_acrossSF<0)=0;
                R2_perPerfLoc_acrossSF(R2_perPerfLoc_acrossSF<0) = 0;
                
                % Compute and save ICs for each candidate model
                AIC_VaryLocMC_acrossSF(isubj_start:isubj_end, indCand_plot) = fxn_getAIC(RSS_nMC, nData_nMC, nParams_nMC);
                AICc_VaryLocMC_acrossSF(isubj_start:isubj_end, indCand_plot) = fxn_getAICc(RSS_nMC, nData_nMC, nParams_nMC);
                BIC_VaryLocMC_acrossSF(isubj_start:isubj_end, indCand_plot) = fxn_getBIC(RSS_nMC, nData_nMC, nParams_nMC);
                
            end %SF_load
            
            % Combine GoF metrics into a single cell array
            GoF_raw_acrossSF = {R2_VaryLocMC_acrossSF, AIC_VaryLocMC_acrossSF, AICc_VaryLocMC_acrossSF, BIC_VaryLocMC_acrossSF, RSS_VaryLocMC_acrossSF};
            % Store R2_perPerfLoc
            R2_allPerfLoc_all4{iTvCModel, iiIndLoc_s, iErrorType} = R2_perPerfLoc_acrossSF;
            
            clear  *VaryLocMC_acrossSF* *varyLocMC_allSubj*
            
            % Loop over GoF metrics for visualization
            for iGoF = 1:nGoF
                
                % Store GoF_raw
                GoF_allSubj = GoF_raw_acrossSF{iGoF};
                GoF_raw_all4{iTvCModel, iiIndLoc_s, iErrorType, iGoF} = GoF_allSubj;
                
                % Calculate delta ICs
                if iGoF==1, GoF_delta_allSubj = GoF_allSubj; str_rank = 'descend'; % For R2, higher values are better
                else, GoF_delta_allSubj = GoF_allSubj - min(GoF_allSubj, [], 2); str_rank = 'ascend'; % For AIC, AICc, and BIC, lower values are better
                end
                assert(size(GoF_delta_allSubj, 1) == nsubj_full) % Ensure the number of rows matches the number of subjects
                
                % Identify and store the best IDVD model
                IndCand_IdvdBest = nan(nsubj_full, 1); % Initialize array for sorted indices
                for isubj_acrossSF = 1:nsubj_full
                    if strcmp(namesGoF{iGoF}, 'R2'), [GoF_s_allSubj_max, i] = max(GoF_delta_allSubj(isubj_acrossSF, :));
                    else,                                          [GoF_s_allSubj_min, i] = min(GoF_delta_allSubj(isubj_acrossSF, :)); assert(GoF_s_allSubj_min<1e5, 'ERROR: The selected model does not have delta value=0')
                    end
                    IndCand_IdvdBest(isubj_acrossSF) = i;
                end
                IndCand_IdvdBest_all4{iTvCModel, iiIndLoc_s, iErrorType, iGoF} = IndCand_IdvdBest;
                
                % Calculate group ave and obtain ranking based on group best
                [GoF_delta_ave, ~, ~, GoF_delta_sem] = getCI(GoF_delta_allSubj, 2, 1); % Compute average (ave) and SEM for each model
                [~, iRank_basedOnAve] = sort(GoF_delta_ave, str_rank); % Sort by average GoF values
                
                % Sort and store delta GoF
                GoF_delta_s_all4{iTvCModel, iiIndLoc_s, iErrorType, iGoF} = GoF_delta_allSubj(:, iRank_basedOnAve);
                
                % Obtain and store Group best
                IndCand_GroupBest = iRank_basedOnAve(1);
                IndCand_GroupBest_all4{iTvCModel, iiIndLoc_s, iErrorType, iGoF} = IndCand_GroupBest;
                
                % Sort and store iCand
                iCand_s_basedonAve = 1:nCand_full;
                iCand_s_basedonAve = iCand_s_basedonAve(iRank_basedOnAve);
                iCand_basedOnAve_s_all4{iTvCModel, iiIndLoc_s, iErrorType, iGoF} = iCand_s_basedonAve;
                
                % Sort and store index and nParams of each candidate
                indParamVary_s_all4{iTvCModel, iiIndLoc_s, iErrorType, iGoF} = indParamVary_allCand(iRank_basedOnAve, :);
                nParams_s_all4{iTvCModel, iiIndLoc_s, iErrorType, iGoF} = nParams_allCand_acrossSF(:, iRank_basedOnAve);
                
            end % iGoF
            
        end % iiIndLoc_s
    end % iTvCModel
end % iErrorType
fprintf('\n\n ============== VaryLoc MC Analysis DONE ==============\n\n')


%% Plot
% Flags for visualization and data processing
flag_plotVaryLocMC_Group = 1;
flag_plotVaryLocMC_Idvd = 1;
iGoF_plotIdvd  = [1,3,4]; % just plot R2, AICc and BIC

wd_line = 2;
nCand_show_ = 8;

% Loop through each error type
for iErrorType = 1%1:nErrorType %1={'ErrLogCst'}, 2={'ErrLnCst'}, 3={'ErrLnEg'}
    
    % Loop thru each TvC model
    for iTvCModel = 1%1:nTvC
        switch iTvCModel
            case 1, indParamExist = [1,1]; namesLF = namesLF_LAM;
            case 2, indParamExist = [0,1,1,1]; namesLF = namesLF_PTM; % see fxn_nestedMC
        end
        nParams_full = length(namesLF);
        str_namesLF = strjoin(namesLF, ', ');
        
        % Loop through each loc group
        for iiIndLoc_s =1% 1:nIndLoc_s
            indLoc_s = indLoc_s_all{iiIndLoc_s};
            nLoc_s = length(indLoc_s);
            namesCombLoc_s = namesCombLoc(indLoc_s); % Get location names
            str_LocSelected = strjoin(namesCombLoc_s, ''); % Concatenate location names
            
            switch nLoc_s
                case 2
                    iCond_all = [0,1];
                    R2_criterion = .5; % only models with group-averaged R2 higher than this level will be selected
                    str_IndIncl_explanation = sprintf('0=Fixed | 1=free to vary between %s & %s\n', namesCombLoc_s{1}, namesCombLoc_s{2});
                case 3
                    iCond_all = 0:4;
                    switch iTvCModel
                        case 1, if iiIndLoc_s == 3, R2_criterion = .7; else, R2_criterion=.7; end
                        case 2, switch iiIndLoc_s, case 1, R2_criterion = .8; case 2, R2_criterion = .82; case 3, R2_criterion=.75; end
                    end
                    str_IndIncl_explanation = sprintf('0=Fixed for 3 loc | 4=free to vary across %s %s %s\n1=Fixed for %s & %s | 2=Fixed for %s & %s | 3=Fixed for %s & %s', ...
                        namesCombLoc_s{1}, namesCombLoc_s{2}, namesCombLoc_s{3}, ...
                        namesCombLoc_s{2}, namesCombLoc_s{3}, ...
                        namesCombLoc_s{1}, namesCombLoc_s{3}, ...
                        namesCombLoc_s{1}, namesCombLoc_s{2});
            end
            
            % Generate parameter inclusion configurations
            %------------------------------------------------------%
            indParamVary_allCand = fxn_getIndParamIncl(nParams_full, iCond_all);
            %------------------------------------------------------%
            nCand_full = size(indParamVary_allCand, 1);
            
            % show a subset of best models
            nCand_show = nCand_show_;
            if nCand_full<nCand_show, nCand_show=nCand_full; end
            
            % Loop through content to plot
            for flag_GoF_plotIDVD = [1,0] %1=plot idvd lines; in group averaged GoF figures and plot idvd data & pred; 0=NOT
                
                %%%%%%%%%%%%%
                % Visualize group data
                %%%%%%%%%%%%%
                switch flag_GoF_plotIDVD
                    case 1, str_idvd = 'Idvd'; yticks_IC = linspace(0, 100, 5); yticks_RSS = linspace(0, 2e4, 5);
                    case 0, str_idvd = 'NoIdvd'; yticks_IC = linspace(0, 30, 5); yticks_RSS = linspace(0, 1e4, 5);
                end
                
                figure('Position', [0 0 2e3 2e3])
                
                % Loop through each GoF
                for iGoF = 1:nGoF
                    
                    % Settings for each GoF
                    yticks_R2 = linspace(.5, 1, 5);
                    if iGoF == 1, str_delta = ''; y_ticks = yticks_R2;
                    else, str_delta = 'Delta'; y_ticks = yticks_IC;
                        if strcmp(namesGoF{iGoF}, 'RSS'), y_ticks = yticks_RSS; end
                    end
                    
                    % Extract data for plotting group average
                    GoF_delta_s_allSubj = GoF_delta_s_all4{iTvCModel, iiIndLoc_s, iErrorType, iGoF};
                    iCand_basedOnAve_s = iCand_basedOnAve_s_all4{iTvCModel, iiIndLoc_s, iErrorType, iGoF};
                    indParamVary_s_allCand = indParamVary_s_all4{iTvCModel, iiIndLoc_s, iErrorType, iGoF};
                    nParams_s_allCand = nParams_s_all4{iTvCModel, iiIndLoc_s, iErrorType, iGoF};
                    
                    subplot(2, 3, iGoF), hold on
                    % Calculate group ave
                    [GoF_delta_s_ave, ~, ~, GoF_delta_s_sem] = getCI(GoF_delta_s_allSubj, 2, 1);
                    
                    % Plot group averages
                    bar(1:nCand_show, GoF_delta_s_ave(1:nCand_show), 'BarWidth', 0.5, 'FaceColor', ones(1, 3) * 0.5, 'EdgeColor', ones(1, 3) * 0.5); % Bar plot of sorted GoF values
                    errorbar(1:nCand_show, GoF_delta_s_ave(1:nCand_show), GoF_delta_s_sem(1:nCand_show), '.k', 'CapSize', 0, 'LineWidth', wd_line);
                    
                    % Plot individual data if enabled
                    if flag_GoF_plotIDVD
                        for isubj_acrossSF = 1:nsubj_full
                            plot(1:nCand_show, GoF_delta_s_allSubj(isubj_acrossSF, 1:nCand_show), '-', 'color', [.4, .4, .4]);
                        end
                    end
                    
                    % Generate custom x-axis labels for the candidate models
                    xLABEL_allCand = cell(1, nCand_show);
                    for iiCand = 1:nCand_show
                        xLABEL = sprintf('[%d] %s (%d)', iCand_basedOnAve_s(iiCand), num2str(indParamVary_s_allCand(iiCand, :)), nParams_s_allCand(1, iiCand));
                        xLABEL_allCand{iiCand} = xLABEL;
                    end
                    
                    % Configure x-axis and plot labels
                    if strcmp(namesGoF{iGoF}, 'R2'), yline(R2_criterion, 'k-', 'linewidth', 2); end
                    xlim([0, nCand_show + 1]);
                    xticks(1:nCand_show); xticklabels(xLABEL_allCand); xtickangle(90)
                    ylabel(sprintf('%s %s', str_delta, namesGoF{iGoF}));
                    yticks(y_ticks); ylim([min(y_ticks), max(y_ticks)]);
                    
                    % Title reporting the best-fitting model
                    title(sprintf('%s%s M%d [%s]', str_delta, namesGoF{iGoF}, iCand_basedOnAve_s(1), num2str(indParamVary_s_allCand(1, :))));
                    
                end % iGoF
                
                % Set the font size & line width of all text elements in the figure
                set(findall(gcf, '-property', 'fontsize'), 'fontsize', 12);
                
                % Add a super title
                switch iTvCModel
                    case 1
                        sgtitle(sprintf('[%s] LAM [%s %s] n=%d (showing %d/%d best models)\n%s\n', ...
                            ErrorTypes_all{iErrorType}, namesLF_LAM{1}, namesLF_LAM{2}, nsubj_full,    nCand_show, nCand_full,   str_IndIncl_explanation));
                    case 2
                        sgtitle(sprintf('[%s ]PTM [%s %s %s] n=%d (showing %d/%d best models)\n%s\n', ...
                            ErrorTypes_all{iErrorType}, namesLF_PTM{2}, namesLF_PTM{3}, namesLF_PTM{4}, nsubj_full,    nCand_show, nCand_full,   str_IndIncl_explanation));
                end
                
                % Save the figure
                nameFolder_fig = sprintf('Fig/acrossSFs/SF456/VaryLocMC_%s/MC/%s', namesTvCModel{iTvCModel}, str_LocSelected);
                if isempty(dir(nameFolder_fig)), mkdir(nameFolder_fig); end
                saveas(gcf, sprintf('%s/%s_%s.jpg', nameFolder_fig, str_idvd, ErrorTypes_all{iErrorType}));
                
                close all
                
                %% Visualize idvd data
                %%%%%%%%%%%
                if flag_GoF_plotIDVD && flag_plotVaryLocMC_Idvd
                    iPerf_plot = 2;
                    wd_line = 2;
                    line_style = {'-', '--', ':'};
                    
                    % Loop through each SF
                    for SF_load = SF_load_all
                        % load data, est params and preds
                        %------------
                        fxn_loadSF
                        %------------
                        load(nameFile_varyLocMC_allSubj, '*est_varyLocMC_allSubj');
                        load(nameFile_fitTvC_allSubj, 'thresh_log_allSubj');
                        indSubj_VaryLoc = isubj_start:isubj_end;
                        
                        % Loop through each GoF to decide the best candidate model
                        for iGoF = iGoF_plotIdvd
                            switch SF_load
                                case 4, figure('Position', [0, 0, 500*3 2e3]);
                                case 51, figure('Position', [0, 0, 500*2 2e3]);
                                case 5, figure('Position', [0, 0, 500*3 2e3]);
                                case 6, figure('Position', [0, 0, 500*4 2e3]);
                            end
                            
                            
                            % Extract data for plotting idvd data
                            indCand_GroupBest = IndCand_GroupBest_all4{iTvCModel, iiIndLoc_s, iErrorType, iGoF};
                            indCand_IdvdBest = IndCand_IdvdBest_all4{iTvCModel, iiIndLoc_s, iErrorType, iGoF};
                            GoF_raw_allSubj = GoF_raw_all4{iTvCModel, iiIndLoc_s, iErrorType, iGoF};
                            R2_allPerfLoc = R2_allPerfLoc_all4{iTvCModel, iiIndLoc_s, iErrorType};
                            
                            % Loop through each subj to plot idvd data & pred
                            for isubj_perSF = 1:nsubj
                                isubj_acrossSF = isubj_perGroup(isubj_perSF);
                                switch SF_load
                                    case 4, subplot(3,3, isubj_perSF), sz_marker = 10;
                                    case 51, subplot(2,2, isubj_perSF), sz_marker = 20;
                                    case 5, subplot(2,3, isubj_perSF), sz_marker = 20;
                                    case 6, subplot(3,4, isubj_perSF), sz_marker = 10;
                                end
                                SF=SF_load; SF(SF==51)=5;
                                str_legends = [];
                                
                                dprime = dprimes(iPerf_plot);
                                slope_ideal_ = slope_ideal(SF-3, iPerf_plot);
                                GoF_raw = GoF_raw_allSubj(isubj_acrossSF, :);
                                
                                % Plot pred and data for each loc
                                hold on, grid on
                                for iiLoc = 1:nLoc_s
                                    color_ = colors_asym(indLoc_s(iiLoc), :);
                                    % Extract data
                                    thresh_data_log_perIdvd = squeeze(thresh_log_allSubj(isubj_perSF, indLoc_s(iiLoc), :, iPerf_plot));
                                    % Extract pred
                                    switch iTvCModel
                                        case 1, params_allCand = squeeze(est_varyLocMC_allSubj(isubj_perSF, iiIndLoc_s, 1:nCand_full, iiLoc, :, iPerf_plot));
                                        case 2, params_allCand = squeeze(est_varyLocMC_allSubj(isubj_perSF, iiIndLoc_s, 1:nCand_full, iiLoc, :));
                                    end
                                    
                                    R2_raw = R2_allPerfLoc(isubj_acrossSF, :, iiLoc, iPerf_plot);
                                    
                                    % Extract Group best and predict TvC
                                    %----------------------------------------------------------------------------------------------------%
                                    [pred_log_GroupBest, params_GroupBest, iParamMC_GroupBest, GoF_GroupBest, str_legends] = ...
                                        fxn_spitPred(iTvCModel, indCand_GroupBest, GoF_raw, R2_raw, params_allCand, indParamVary_allCand, indParamExist, noiseEnergy_intp_true, dprime, slope_ideal_, str_legends);
                                    %----------------------------------------------------------------------------------------------------%
                                    
                                    % Extract Idvd best and predict TvC
                                    iCand_IdvdBest_perIdvd = indCand_IdvdBest(isubj_acrossSF);
                                    %----------------------------------------------------------------------------------------------------%
                                    [pred_log_IdvdBest, params_IdvdBest, iParamMC_IdvdBest, GoF_IdvdBest, str_legends] = ...
                                        fxn_spitPred(iTvCModel, iCand_IdvdBest_perIdvd, GoF_raw, R2_raw, params_allCand, indParamVary_allCand, indParamExist, noiseEnergy_intp_true, dprime, slope_ideal_, str_legends);
                                    %----------------------------------------------------------------------------------------------------%
                                    
                                    % Extract Full Model and predict TvC
                                    iCand_FullModel = nCand_full;
                                    %----------------------------------------------------------------------------------------------------%
                                    [pred_log_FullModel, params_FullModel, iParamMC_FullModel, GoF_FullModel, ~] = ...
                                        fxn_spitPred(iTvCModel, iCand_FullModel, GoF_raw, R2_raw, params_allCand, indParamVary_allCand, indParamExist, noiseEnergy_intp_true, dprime, slope_ideal_, str_legends);
                                    %----------------------------------------------------------------------------------------------------%
                                    
                                    if indCand_IdvdBest == iCand_FullModel, assert(GoF_FullModel == GoF_IdvdBest, 'ERROR: Idvd vs. Full: same iCand, but diff GoF'), end
                                    if indCand_GroupBest == iCand_FullModel, assert(GoF_FullModel == GoF_GroupBest, 'ERROR: Group vs. Full: same iCand, but diff GoF'), end
                                    
                                    % PLOT
                                    % Group-best fitting line
                                    plot(noiseSD_intp_log_true, pred_log_GroupBest, line_style{1}, 'color', color_, 'LineWidth', wd_line)
                                    % Idvd-best fitting line
                                    plot(noiseSD_intp_log_true, pred_log_IdvdBest, line_style{2}, 'color', color_, 'LineWidth', wd_line/1.5)
                                    % Full model fitting line
                                    plot(noiseSD_intp_log_true, pred_log_FullModel, line_style{3}, 'color', color_, 'LineWidth', wd_line/1.5, 'HandleVisibility', 'off')
                                    % Data
                                    plot(noiseSD_log_all, thresh_data_log_perIdvd, ['-', markers_allSF{SF-3}], 'color', color_, 'MarkerFaceColor', color_, 'MarkerEdgeColor', 'w', 'MarkerSize', sz_marker, 'LineWidth', wd_line/3, 'HandleVisibility', 'off')
                                    
                                    if iTvCModel == 1
                                        xline(log10(params_GroupBest(2)), line_style{1}, 'LineWidth', wd_line/1.5, 'HandleVisibility', 'off');
                                        xline(log10(params_IdvdBest(2)), line_style{2}, 'color', color_, 'LineWidth', wd_line/1.5, 'HandleVisibility', 'off');
                                    end
                                    
                                end % iiLoc
                                
                                xlabel('External noise SD')
                                x_ticks = noiseSD_log_all;
                                x_ticklabels = round(noiseSD_full, 3);
                                xlim([x_ticks(1)-.1, x_ticks(end)+.1]), xticks(x_ticks), xticklabels(x_ticklabels)%, xtickangle(90)
                                
                                ylabel('Contrast threshold');
                                yticks(cst_log_ticks), yticklabels(round(cst_ln_ticks)),
                                % ylim(cst_log_ticks([1, end])) % mute this line to free the range of y-axis
                                
                                % Legend
                                nColLegends = 2; %Left: Group best, right: idvd best
                                legend(str_legends, 'Orientation', 'horizontal', 'NumColumns', nColLegends, 'Location', 'best', 'FontSize', 8);
                                
                                % Title of each subplot
                                if iGoF==1
                                    title(sprintf('%s\nGroup best (%s): M%d [%s] (%s=%.3f)\nIdvd best (%s) M%d [%s] (%s=%.3f)\nFull model (%s): M%d [%s] (%s=%.3f)', ...
                                        subjList{isubj_perSF}, ...
                                        line_style{1}, indCand_GroupBest,             num2str(iParamMC_GroupBest), namesGoF{iGoF}, GoF_GroupBest, ...
                                        line_style{2}, iCand_IdvdBest_perIdvd, num2str(iParamMC_IdvdBest),    namesGoF{iGoF}, GoF_IdvdBest, ...
                                        line_style{3}, iCand_FullModel,              num2str(iParamMC_FullModel),  namesGoF{iGoF}, GoF_FullModel))
                                else
                                    title(sprintf('%s\nGroup best (%s): M%d [%s] (%s=%.0f)\nIdvd best (%s) M%d [%s] (%s=%.0f)\nFull model (%s): M%d [%s] (%s=%.0f)', ...
                                        subjList{isubj_perSF}, ...
                                        line_style{1}, indCand_GroupBest,             num2str(iParamMC_GroupBest), namesGoF{iGoF}, GoF_GroupBest, ...
                                        line_style{2}, iCand_IdvdBest_perIdvd, num2str(iParamMC_IdvdBest),    namesGoF{iGoF}, GoF_IdvdBest, ...
                                        line_style{3}, iCand_FullModel,              num2str(iParamMC_FullModel),  namesGoF{iGoF}, GoF_FullModel))
                                end
                            end % isubj
                            
                            % Super title
                            sgtitle(sprintf('%s [%s] SF%d (n=%d) [%s] Perf level=%d%% (Error Type: %s)\nBased on %s: Group best (%s) is M%d [%s]', ...
                                namesTvCModel{iTvCModel}, str_namesLF, SF, nsubj, str_LocSelected, perfThresh_all(iPerf_plot), ErrorTypes_all{iErrorType},...
                                namesGoF{iGoF}, line_style{1}, indCand_GroupBest, num2str(iParamMC_GroupBest)))
                            
                            % Save the figure
                            nameFolder_fig = sprintf('Fig/acrossSFs/SF456/VaryLocMC_%s/IdvdFits/%s/%s', namesTvCModel{iTvCModel}, str_LocSelected, ErrorTypes_all{iErrorType});
                            if isempty(dir(nameFolder_fig)), mkdir(nameFolder_fig); end
                            saveas(gcf, sprintf('%s/SF%dn%d_%s.jpg', nameFolder_fig, SF, nsubj, namesGoF{iGoF}));
                            
                            close all
                            
                        end % iGoF
                    end %SF_load
                end
            end %flag_GoFplotIdvd
        end % iiIndLoc_s
    end % iTvCModel
end % iErrorType

fprintf('\n\n ============== VaryLoc MC Plotting DONE ==============\n\n')
clear *est_varyLocMC_allSubj
