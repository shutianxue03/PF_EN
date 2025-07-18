
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% fxn_fitTvCIDVD.m
% Last updated by Shutian Xue in Mar, 2025

% Purpose:
%   Fits Threshold vs. Contrast (TvC) data across multiple location groups using either the
%   Linear Amplifier Model (LAM) or the Perceptual Template Model (PTM). Supports flexible
%   parameterization and model selection for each group of locations.
%
% Usage:
%   Called as a function or script within the PF_EN analysis pipeline.
%
% Inputs (required in workspace or as arguments):
%   - iTvCModel: Model type (1 = LAM, 2 = PTM)
%   - params0_LAM, lb_LAM, ub_LAM: Initial values and bounds for LAM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Initialization
indLoc_s_all = {[1,2,3], [1,4,8], [1,5,9], [4,5], [6,7], [8,9], [10,11], [1, 4, 6, 7, 8, 10, 11], [4,5,8,9], [6,7,10,11]}; nIndLoc_s = length(indLoc_s_all); % Total number of location groups
assert(strcmp(text_locType, 'combLoc'), 'ALERT: text_locType must be "combLoc".');

% Default parameter values and bounds
switch iTvCModel
    case 1 % LAM [Slope, Neq in energy unit]
        params0_def = params0_LAM; % Initial parameter estimates
        lb_def = lb_LAM; % Lower bounds
        ub_def = ub_LAM; % Upper bounds
    case 2 % PTM [Gamma, Nadd, Beta]
        params0_def = params0_PTM(2:4); % Initial guesses for parameters
        lb_def = lb_PTM(2:4); % Lower bounds
        ub_def = ub_PTM(2:4); % Upper bounds
end
nParams_full = length(params0_def); % Total number of parameters

% Initiate placeholders
R2_BestSimplest_allLoc = nan(nIndLoc_s, nLoc_s_max, nPerf);
switch iTvCModel
    case 1, est_BestSimplest_allLoc = nan(nIndLoc_s, nLoc_s_max, nParams_full, nPerf);
    case 2, est_BestSimplest_allLoc = nan(nIndLoc_s, nLoc_s_max, nParams_full);
end

%% Loop over each group of locations
fprintf('\nLocGroup: ')
for iiIndLoc_s = 1:nIndLoc_s
    fprintf('%d ', iiIndLoc_s)

    % Extract current location group
    indLoc_s = indLoc_s_all{iiIndLoc_s};
    nLoc_s = length(indLoc_s); % Number of locations in the group
    namesCombLoc_s = namesCombLoc(indLoc_s); % Names of combined locations
    str_LocSelected = strjoin(namesCombLoc_s, '');

    % Generate candidate models based on parameter inclusion
    switch nLoc_s
        case 2, iCond_all = [0, 1];
        case 3, iCond_all = 0:4;
        otherwise,iCond_all = 1; % free to vary
    end
    %--------------------------------------------------------------------------------%
    indParamVary_allCand = fxn_getIndParamIncl(nParams_full, iCond_all); % Generate all combinations
    %--------------------------------------------------------------------------------%

    % Load the best & simplest model
    %     load('IndCand_GroupBest_all4.mat', 'IndCand_GroupBest_all4')
    %     iCand_groupBest = IndCand_GroupBest_all4{iTvCModel, iiIndLoc_s, iErrorType, iGoF_inUse};
    
    if nLoc_s <= 3
        iCand_groupBest = IndCand_GroupBest_vec(iiIndLoc_s);
        indParamVary = indParamVary_allCand(iCand_groupBest, :); % Current candidate
    else
        indParamVary = [iCond_all, iCond_all, iCond_all];
    end

    % Retrieve parameter bounds for current candidate
    %--------------------------------------------------------------------------------%
    [params0, ub, lb] = MC_getLimits(indParamVary, params0_def, ub_def, lb_def, nLoc_s);
    %--------------------------------------------------------------------------------%

    % Retry mechanism for fitting
    switch iTvCModel
        case 1 % LAM
            params_est_allPerf = cell(1, nPerf);
            R2 = nan(nLoc_s, nPerf);
            for iPerf=1:nPerf
                %--------------------------------------------------------------------------------%
                [params_est_vec_perPerf, ~, RSS_perPerf, R2_perPerf] = fitTvC_varyLocMC(iTvCModel, indParamVary, noiseEnergy_true, threshEnergy(indLoc_s, :, iPerf), dprimes, SF_fit, params0, lb, ub, iErrorType, flag_weightedFitting, nData_perLoc(indLoc_s, :), 0);
                %--------------------------------------------------------------------------------%
                params_est_allPerf{iPerf} = params_est_vec_perPerf;
                R2(:, iPerf) = R2_perPerf;
            end
        case 2 % PTM
            %--------------------------------------------------------------------------------%
            % Weight is number of trials (more trials per noise level, more important in TvC fitting)
            switch str_weightType
                case 'nData'
                    [params_est_vec, ~, RSS, R2] = fitTvC_varyLocMC(iTvCModel, indParamVary, noiseEnergy_true, threshEnergy(indLoc_s, :, :), dprimes, SF_fit, params0, lb, ub, iErrorType, flag_weightedFitting, nData_perLoc(indLoc_s, :), flag_plot);
                case 'LLPMF'
                    [params_est_vec, ~, RSS, R2] = fitTvC_varyLocMC(iTvCModel, indParamVary, noiseEnergy_true, threshEnergy(indLoc_s, :, :), dprimes, SF_fit, params0, lb, ub, iErrorType, flag_weightedFitting, LL_allB(indLoc_s, :, PMFmodel_decide), flag_plot);
            end
            % Weight is R2 of PMF fitting (better PMF fitting, more important)
            % [params_est_vec, ~, RSS, R2] = fitTvC_varyLocMC(iTvCModel, indParamVary, noiseEnergy_true, threshEnergy(indLoc_s, :, :), dprimes, SF_fit, params0, lb, ub, iErrorType, flag_weightedFitting, 1./R2_weighted_all_mat_combLoc(indLoc_s, :, :, iWeibull, 1, 3)+eps), 0);
            %--------------------------------------------------------------------------------%
    end

    % Convert estimated params
    switch iTvCModel
        case 1 % LAM
            params_est_mat = nan(nLoc_s, nParams_full, nPerf);
            for iPerf = 1:nPerf
                %--------------------------------------------------------------------------------%
                params_est_cell_opt = MC_vec2cell(indParamVary, params_est_allPerf{iPerf}, nLoc_s);
                params_est_mat(:, :, iPerf) = MC_cell2mat(indParamVary, params_est_cell_opt, nLoc_s); % nLoc_s x nParams
                %--------------------------------------------------------------------------------%
            end % iPerf
            % to fill the last row (the 3rd loc with NaNs)
            if nLoc_s==2
                R2 = [R2; nan(1, nPerf)];
                params_est_mat = cat(1, params_est_mat, nan(1, nParams_full, nPerf));
            end

        case 2 % PTM
            %--------------------------------------------------------------------------------%
            params_est_cell_opt = MC_vec2cell(indParamVary, params_est_vec, nLoc_s);
            params_est_mat = MC_cell2mat(indParamVary, params_est_cell_opt, nLoc_s); % nLoc_s x nParams
            %--------------------------------------------------------------------------------%

    end % switch iTvCModel

    % Store R2 and estimated params
    R2_BestSimplest_allLoc(iiIndLoc_s, 1:nLoc_s, :) = R2;
    switch iTvCModel
        case 1, est_BestSimplest_allLoc(iiIndLoc_s, :, :, :) = params_est_mat;
        case 2, est_BestSimplest_allLoc(iiIndLoc_s, 1:nLoc_s, :) = params_est_mat;
    end

end % iiIndLoc_s

