
%%%%%%%%%%%%%%%%%%%%%%
% NOW, only the full model was fitted
% Search for "for iCand = nCand"
%%%%%%%%%%%%%%%%%%%%%%

clc;
% Flags and Initialization
flag_plotWhileFitting = 0; % !!!CAUTION!!!: set this to 1 could lead to production of many figures
flag_plotGoF = 1; % Flag to plot goodness-of-fit (GoF) metrics
indLoc_s_all = {[1,2,3], [1,4,8], [1,5,9], [4,5], [6,7], [8,9], [10,11]}; nIndLoc_s = length(indLoc_s_all); % Total number of location groups

% Validate location type
assert(strcmp(text_locType, 'combLoc'), 'text_locType must be "combLoc".');

% Default parameter values and bounds
switch iTvCModel
    case 1 % LAM [Slope, Neq in energy unit]
        params0_def = params0_LAM; % Initial parameter  estimates
        lb_def = lb_LAM; % Lower bounds
        ub_def = ub_LAM; % Upper bounds
        
    case 2 % PTM [Gamma, Nadd, Beta]
        params0_def = params0_PTM(2:4); % Initial guesses for parameters
        lb_def = lb_PTM(2:4); % Lower bounds
        ub_def = ub_PTM(2:4); % Upper bounds
end
nParams_full = length(params0_def); % Total number of parameters

% Initialize storage for results across all location groups
% GoF
RSS_varyLocMC_allLoc = nan(nIndLoc_s, nCand_max, nLoc_s_max, nPerf);
R2_varyLocMC_allLoc = RSS_varyLocMC_allLoc;
nParams_varyLocMC_allLoc = nan(nIndLoc_s, nCand_max);
nData_varyLocMC_allLoc = nParams_varyLocMC_allLoc;
% Estimated Params and predicted TvCs
switch iTvCModel
    case 1, est_varyLocMC_allLoc = nan(nIndLoc_s, nCand_max, nLoc_s_max, nParams_full, nPerf);
    case 2, est_varyLocMC_allLoc = nan(nIndLoc_s, nCand_max, nLoc_s_max, nParams_full);
end

%% Loop over each group of locations
clc
for iiIndLoc_s = 1:nIndLoc_s
    
    % Extract current location group
    indLoc_s = indLoc_s_all{iiIndLoc_s};
    nLoc_s = length(indLoc_s); % Number of locations in the group
    namesCombLoc_s = namesCombLoc(indLoc_s); % Names of combined locations
    str_LocSelected = strjoin(namesCombLoc_s, '');
    
    % Generate candidate models based on parameter inclusion
    switch nLoc_s
        case 2, iCond_all = [0, 1]; R2_criterion = .5;% Define inclusion for 2 locations
        case 3, iCond_all = 0:4; R2_criterion = .8;% Define inclusion for 3 locations
    end
    %--------------------------------------------------------------------------------%
    indParamVary_allCand = fxn_getIndParamIncl(nParams_full, iCond_all); % Generate all combinations
    %--------------------------------------------------------------------------------%
    nCand = size(indParamVary_allCand, 1); % Number of candidate models
    
    fprintf('\n[%s SF%d S%d/%d] Fitting %d %s (%s) with %d Candidate Models\n', subjName, SF, isubj, nsubj, nLoc_s, text_locType, str_LocSelected, nCand);
    
    % Loop over candidate models
    for iCand = nCand
        %--------------------------------------------------------------------------------%
        indParamVary = indParamVary_allCand(iCand, :); % Current candidate
        %--------------------------------------------------------------------------------%
        % nLoc_s=2
        % 0: Fixed for both locations, nParams = 1
        % 1: Free to vary between two locations, nParams = nLoc_s
        
        % nLoc_s=3
        % 0: Fixed for all three locations, nParams = 1
        % 1: Fixed for 2nd & 3rd, may differ for 1st, nParams = nLoc_s-1
        % 2: Fixed for 1st & 3rd, may differ for 2nd, nParams = nLoc_s-1
        % 3: Fixed for 1st & 2nd, may differ for 3rd, nParams = nLoc_s-1
        % 4: Free to vary across three locations, nParams = nLoc_s
        
        RSS = nan; R2 = nan; params_est_vec = nan;% Initialize metrics
        
        % Retrieve parameter bounds for current candidate
        %--------------------------------------------------------------------------------%
        [params0, ub, lb] = MC_getLimits(indParamVary, params0_def, ub_def, lb_def, nLoc_s);
        %--------------------------------------------------------------------------------%
        
        % Conduct model fitting
        switch iTvCModel
            case 1 % LAM
                params_est_allPerf = cell(1, nPerf);
                RSS = nan(nLoc_s, nPerf);
                R2 = RSS;
                for iPerf=1:nPerf
                    %--------------------------------------------------------------------------------%
                    [params_est_vec_perPerf, ~, RSS_perPerf, R2_perPerf] = fitTvC_varyLocMC(iTvCModel, indParamVary, noiseEnergy_true, threshEnergy(indLoc_s, :, iPerf), dprimes, SF_fit, params0, lb, ub, iErrorType, flag_weightedFitting, nData_perLoc(indLoc_s, :), flag_plotWhileFitting);
                    %--------------------------------------------------------------------------------%
                    params_est_allPerf{iPerf} = params_est_vec_perPerf;
                    RSS(:, iPerf) = RSS_perPerf;
                    R2(:, iPerf) = R2_perPerf;
                end
            case 2 % PTM
                %--------------------------------------------------------------------------------%
                [params_est_vec, ~, RSS, R2] = fitTvC_varyLocMC(iTvCModel, indParamVary, noiseEnergy_true, threshEnergy(indLoc_s, :, :), dprimes, SF_fit, params0, lb, ub, iErrorType, flag_weightedFitting, nData_perLoc(indLoc_s, :), flag_plotWhileFitting);
                %--------------------------------------------------------------------------------%
        end
        
        % Convert nan R2 to 0
        R2(isnan(R2))=0;
        
        % Store predictions
        switch iTvCModel
            case 1 % LAM
                params_est_mat_opt = nan(nLoc_s, nParams_full, nPerf);
                for iPerf = 1:nPerf
                    %--------------------------------------------------------------------------------%
                    params_est_cell_opt = MC_vec2cell(indParamVary, params_est_allPerf{iPerf}, nLoc_s);
                    params_est_mat_opt(:, :, iPerf) = MC_cell2mat(indParamVary, params_est_cell_opt, nLoc_s); % nLoc_s x nParams
                    %--------------------------------------------------------------------------------%
                end % iPerf
                % Save results for all locations and candidates
                % Both RSS and R2 are nLoc_s x nPerf
                if nLoc_s==2 % to fill the last row (the 3rd loc with NaNs)
                    RSS = [RSS; nan(1, nPerf)]; % same name as PTM!!
                    R2 = [R2; nan(1, nPerf)];
                end
                % Estimated params and predicted TvCs
                if nLoc_s==2, params_est_mat_opt = cat(1, params_est_mat_opt, nan(1, nParams_full, nPerf)); end % to fill the last row (the 3rd loc with NaNs)
                est_varyLocMC_allLoc(iiIndLoc_s, iCand, :, :, :) = params_est_mat_opt; % just one more dimension more than PTM
                nParams_varyLocMC_allLoc(iiIndLoc_s, iCand) = length(cell2mat(params_est_allPerf));
                
            case 2 % PTM
                %--------------------------------------------------------------------------------%
                params_est_cell_opt = MC_vec2cell(indParamVary, params_est_vec, nLoc_s);
                params_est_mat_opt = MC_cell2mat(indParamVary, params_est_cell_opt, nLoc_s); % nLoc_s x nParams
                %--------------------------------------------------------------------------------%
                % Save results for all locations and candidates
                % Both RSS and R2 are nLoc_s x nPerf
                if nLoc_s==2 % to fill the last row (the 3rd loc with NaNs)
                    RSS = [RSS; nan(1, nPerf)];
                    R2 = [R2; nan(1, nPerf)];
                end
                
                % Estimated params and predicted TvCs
                if nLoc_s==2, params_est_mat_opt = [params_est_mat_opt; nan(1, nParams_full)]; end % to fill the last row (the 3rd loc with NaNs)
                est_varyLocMC_allLoc(iiIndLoc_s, iCand, :, :) = params_est_mat_opt;
                nParams_varyLocMC_allLoc(iiIndLoc_s, iCand) = length(params_est_vec(:));
        end % switch iTvCModel
        
        % Save RSS, R2 and nData
        RSS_varyLocMC_allLoc(iiIndLoc_s, iCand, :, :) = RSS;
        R2_varyLocMC_allLoc(iiIndLoc_s, iCand, :, :) = R2;
        nData_varyLocMC_allLoc(iiIndLoc_s, iCand) = nLoc_s * nNoise * nPerf;
        
        if nCand<20
            fprintf('M%d (R2=%.2f)\n', iCand, nanmean(R2(:)));
        end
        
    end % iCand
    
    if flag_plotGoF
        namesGoF = {'R2', 'AIC', 'AICc', 'BIC'};
        iGoF_select = [4];
        %---------------------------%
        fxn_VaryLocMC_Plot_perLoc
        %---------------------------%
    end % if flag_plotGoF
    close all
end % iindLoc_s
fprintf('\n ================== VaryLoc MC DONE ==================\n\n') % around 190s (3mins)
