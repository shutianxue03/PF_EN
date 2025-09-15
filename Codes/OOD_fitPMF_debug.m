
function [cst_log_unik, nCorr, nData, pC, estP_allM, LL_allM, R2_weighted_allM] = OOD_fitPMF_debug(ccc_full, fit, str_PMF_fittingMethod, SubjSF, indLocNoise)
% OOD_fitPMF fits psychometric functions to observer data (e.g., contrast vs. performance).
%
% Inputs:
%   flag_estimateThresh: whether to estimate threshold values
%   ccc_full: trial-level data, [Loc, noise level, contrast, correctness, stair condition]
%   fit: struct of fitting parameters (models, PF type, search grids, etc.)
%   thresh_log_stair: (unused here but passed for compatibility)
%
% Outputs:
%   cst_log_unik: unique log-contrast levels
%   nCorr: number of correct trials at each level
%   nData: total trials at each level
%   pC: proportion correct
%   estP_allB: bootstrapped parameter estimates
%   LL_allB: log-likelihood values
%   R2_weighted_allB: R² values (weighted)
%   converged_allB: convergence flags
%   pC_pred_allB: predicted PF values on interpolated contrast levels
%   thresh_log_allB: estimated thresholds in log units

%% Setup
SX_analysis_setting;  % load global settings
warning off;
flag_print = 0;

flag_binData = fit.flag_binData;
flag_filterData = fit.flag_filterData;

cst_log_full = log10(ccc_full(:, 3));
corr_full = ccc_full(:, 4);
isStair_full = ccc_full(:, 5) <= 6;  % 1=staircase/catch, 0=constim
curveX_log = fit.curveX_log;

%% Bin or aggregate data
if flag_binData
    % Bin staircase data
    nBins = fit.nBins;
    cst_log_stair = cst_log_full(isStair_full==1);
    corr_stair = corr_full(isStair_full==1);
    [N, ~, indBin] = histcounts(cst_log_stair, nBins);
    cst_log_unik = []; nCorr = []; nData = [];
    
    for iBin = 1:nBins
        if N(iBin) > 0
            inds = (indBin == iBin);
            cst_log_unik(end+1) = mean(cst_log_stair(inds));
            nCorr(end+1) = nansum(corr_stair(inds));
            nData(end+1) = sum(inds);
        end
    end
    
    % Append constim trials (already unique)
    cst_log_unik_constim = unique(cst_log_full(isStair_full == 0));
    for val = cst_log_unik_constim(:)'
        inds = cst_log_full == val;
        cst_log_unik(end+1) = val;
        nCorr(end+1) = nansum(corr_full(inds));
        nData(end+1) = sum(inds);
    end
    
else
    % Use raw unique contrast levels
    cst_log_unik = unique(cst_log_full);
    nCorr = nan(1, length(cst_log_unik));
    nData = nCorr;
    
    for i = 1:length(cst_log_unik)
        inds = (cst_log_full == cst_log_unik(i));
        nCorr(i) = nansum(corr_full(inds));
        nData(i) = sum(inds);
    end
end

%% Add artificial anchor trials at low contrast (if specified)
if flag_filterData
    gaborCST_log_anchor = [-4, -3]; % log 10 contrast levels
    
    iLoc=indLocNoise(1);
    iNoise=indLocNoise(2);
    switch SubjSF
        case 'HL4'
            switch iNoise
                case 7 % 0.22
                    if iLoc==5, gaborCST_log_anchor = [gaborCST_log_anchor, -2, -1.5]; end % LVM4
                case 9 % 0.44
                    if iLoc==7, gaborCST_log_anchor = [gaborCST_log_anchor, -2, -1.5, -1]; end % UVM8
            end
        case 'ASM6'
            if iLoc == 7 % UVM8
                if iNoise ==7 % 0.22
                    gaborCST_log_anchor = [gaborCST_log_anchor, -2, -1.5, -1]; % 0.083
                end
            end
        case 'JY6'
            if iLoc==5
                if iNoise==4, gaborCST_log_anchor = [gaborCST_log_anchor, -2, -1.5]; % 0.083
                elseif iNoise==7, gaborCST_log_anchor = [gaborCST_log_anchor, -2, -1.5]; % 0.22
                end
            end
        case 'LL6'
            switch iNoise
                case 9 % 0.44
                    switch iLoc
                        case 7, gaborCST_log_anchor = [gaborCST_log_anchor, -1]; % UVM8
                    end
                case 7 % 0.22
                    switch iLoc
                        case 7, gaborCST_log_anchor = [gaborCST_log_anchor, -1.5, -1]; % UVM8
                        case 10, gaborCST_log_anchor = [gaborCST_log_anchor, -1]; % HM4
                    end
                case 3 % 0.055
                    switch iLoc
                        case 7, gaborCST_log_anchor = [gaborCST_log_anchor, -1]; % UVM8
                    end
            end
            
    end
    nAnchor = length(gaborCST_log_anchor);  % number of anchors
    nA = 50;      % total artificial trials per anchor
    
    cst_log_unik = [gaborCST_log_anchor, cst_log_unik];
    nCorr = [ones(1,nAnchor)*nA/2, nCorr];
    nData = [ones(1,nAnchor)*nA, nData];
    
    if flag_print
        fprintf('[Added anchors at low contrast] ...\n');
    end
end

%% Compute observed proportion correct
pC = nCorr ./ nData;

%% Initialize output containers
estP_allM = nan(nModels, fit.nParams);
LL_allM = nan(nModels, 1);
R2_weighted_allM = LL_allM;
pC_pred_allM = nan(nModels, length(curveX_log));

%% Fit psychometric function for each model
for iModel = 1:nModels
    if flag_print
        fprintf('%s...', fit.PMF_models{iModel});
    end
    
    % Choose PF
    switch iModel
        case 1, fit.PF = @PAL_Logistic;
        case 2, fit.PF = @PAL_CumulativeNormal;
        case 3, fit.PF = @PAL_Gumbel;
        case 4, fit.PF = @PAL_Weibull;
    end
    
    % Adjust contrast format (log or linear)
    searchGrid = fit.searchGrid;
    PMF_param0 = fit.PMF_param0;
    PMF_lb = fit.PMF_lb;
    PMF_ub = fit.PMF_ub;
    if iModel == 4  % Weibull: takes in linear contrast
        cst_fit = 10.^cst_log_unik;
        searchGrid.alpha = 10.^searchGrid.alpha;
        cst_fineG = 10.^curveX_log;
        alphaLimits = 10.^fit.alphaLimits;
        PMF_param0(1) = 10^PMF_param0(1);
        PMF_lb(1) = 10^PMF_lb(1);
        PMF_ub(1) = 10^PMF_ub(1);
    else  % Other models: takes in log contrast
        cst_fit = cst_log_unik;
        cst_fineG = curveX_log;
        alphaLimits = fit.alphaLimits;
    end
    
    % param estimation (fmincon)
    switch str_PMF_fittingMethod
        case 'fmincon'
            warning off
            options = optimoptions('fmincon', 'MaxIterations', 5000, 'Display', 'off');
            nrep = 20;
            if iModel==1 % Logitic function
                fxn_getnLL = @(params) -sum(corr_full .* log(fit.PF(params, cst_log_full)) + ...
                    (1 - corr_full) .* log(1 - fit.PF(params, cst_log_full)));
            else % Other models
                fxn_getnLL = @(params) -sum(nCorr .* log(fit.PF(params, cst_fit)) + ...
                    (nData - nCorr) .* log(1 - fit.PF(params, cst_fit)));
            end
            problem_ML = createOptimProblem('fmincon', 'objective', fxn_getnLL, 'x0', PMF_param0, 'lb', PMF_lb, 'ub', PMF_ub, 'options', options);
            ms_ML = MultiStart('StartPointsToRun', 'bounds', 'UseParallel', 1, 'Display', 'off');
            [estP_perM, LL_perM] = run(ms_ML, problem_ML, nrep);
            
        case 'palamedes'
            estP = PAL_PFML_Fit(cst_fit, nCorr, nData, ...
                searchGrid, fit.paramsFree, fit.PF, ...
                'SearchOptions', fit.options, ...
                'AlphaLimits', alphaLimits, ...
                'LapseLimits', fit.lapseLimits, ...
                'GuessLimits', fit.guessLimits);
            
            [~, estP_allB_perM, LL_allB_perM] = ...
                PAL_PFML_BootstrapParametric(cst_fit, nData, ...
                estP, fit.paramsFree, fit.nBoot_PMF, fit.PF, ...
                'AlphaLimits', alphaLimits, ...
                'LapseLimits', fit.lapseLimits, ...
                'GuessLimits', fit.guessLimits);
            [LL_perM, indBest] = min(LL_allB_perM);
            estP_perM = estP_allB_perM(indBest, :);
            
    end
    
    % Save outputs
    estP_allM(iModel, :) = estP_perM;
    LL_allM(iModel) = LL_perM;
    
    % Predictions and R2
    if isnan(estP_perM(2)), estP_perM(2) = Inf; end  % catch unstable slope
    
    % Predicte pC
    pC_pred_allM(iModel, :) = fit.PF(estP_perM, cst_fineG);
    
    % Calculate R2 (weighted)
    pC_fit = fit.PF(estP_perM, cst_fit);
    weighted_mean_pC = sum(nData .* pC) / sum(nData);
    WSS_res = sum(nData .* (pC - pC_fit).^2);
    WSS_tot = sum(nData .* (pC - weighted_mean_pC).^2);
    R2_weighted_allM(iModel) = 1 - (WSS_res / WSS_tot);
end % iModel

%% Remove anchor trials (if added earlier)
if flag_filterData
    cst_log_unik = cst_log_unik(nAnchor+1:end);
    nCorr = nCorr(nAnchor+1:end);
    nData = nData(nAnchor+1:end);
    pC = pC(nAnchor+1:end);
end

