function [cst_log_unik, nCorr, nData, pC, estP_allB, LL_allB, R2_weighted_allB, ...
    converged_allB, pC_pred_allB, thresh_log_allB] = OOD_fitPMF_v3(flag_estimateThresh, ccc_full, fit)
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

nBoot_PMF = fit.nBoot_PMF;
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
    gaborCST_log_anchor = [-4, -3];
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
estP_allB = nan(nBoot_PMF, nModels, fit.nParams);
LL_allB = nan(nBoot_PMF, nModels);
converged_allB = LL_allB;
R2_weighted_allB = LL_allB;
pC_pred_allB = nan(nBoot_PMF, nModels, length(curveX_log));
thresh_log_allB = nan(nBoot_PMF, nModels, nPerf);

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
    if iModel == 4  % Weibull: linear scale
        cst_fit = 10.^cst_log_unik;
        searchGrid.alpha = 10.^searchGrid.alpha;
        cst_fineG = 10.^curveX_log;
        alphaLimits = 10.^fit.alphaLimits;
        PMF_param0(1) = 10^PMF_param0(1);
        PMF_lb(1) = 10^PMF_lb(1);
        PMF_ub(1) = 10^PMF_ub(1);
    else
        cst_fit = cst_log_unik;
        cst_fineG = curveX_log;
        alphaLimits = fit.alphaLimits;
    end

    % Initial param estimation (fmincon)
%     if iModel==1
%         fxn_getnLL = @(params) -sum(corr_full .* log(fit.PF(params, cst_log_full)) + ...
%             (1 - corr_full) .* log(1 - fit.PF(params, cst_log_full)));
%     else
%         fxn_getnLL = @(params) -sum(nCorr .* log(fit.PF(params, cst_fit)) + ...
%             (nData - nCorr) .* log(1 - fit.PF(params, cst_fit)));
%     end
%     estP = fmincon(fxn_getnLL, PMF_param0, [], [], [], [], PMF_lb, PMF_ub, [], fit.PMF_options);

    % Initial param estimation (Palamedes)
    estP = PAL_PFML_Fit(cst_fit, nCorr, nData, ...
        searchGrid, fit.paramsFree, fit.PF, ...
        'SearchOptions', fit.options, ...
        'AlphaLimits', alphaLimits, ...
        'LapseLimits', fit.lapseLimits, ...
        'GuessLimits', fit.guessLimits);

    % Parametric bootstrap
    estP_allB_perM = nan(nBoot_PMF, fit.nParams);
    LL_allB_perM = nan(nBoot_PMF, 1);
    converged_allB_perM = LL_allB_perM;

    [~, estP_allB_perM, LL_allB_perM, converged_allB_perM] = ...
        PAL_PFML_BootstrapParametric(cst_fit, nData, ...
        estP, fit.paramsFree, nBoot_PMF, fit.PF, ...
        'AlphaLimits', alphaLimits, ...
        'LapseLimits', fit.lapseLimits, ...
        'GuessLimits', fit.guessLimits);

    if flag_print
        fprintf(' (%.0f%% converged)\n', mean(converged_allB_perM == 1) * 100);
    end

    % Save outputs
    estP_allB(:, iModel, :) = estP_allB_perM;
    LL_allB(:, iModel) = LL_allB_perM;
    converged_allB(:, iModel) = converged_allB_perM;

    % Predictions and R²
    for iB = 1:nBoot_PMF
        estParams = estP_allB_perM(iB, :);
        if isnan(estParams(2)), estParams(2) = Inf; end  % catch unstable slope

        % Predicted curve
        pC_pred_allB(iB, iModel, :) = fit.PF(estParams, cst_fineG);

        % R² (weighted)
        pC_fit = fit.PF(estParams, cst_fit);
        weighted_mean_pC = sum(nData .* pC) / sum(nData);
        WSS_res = sum(nData .* (pC - pC_fit).^2);
        WSS_tot = sum(nData .* (pC - weighted_mean_pC).^2);
        R2_weighted_allB(iB, iModel) = 1 - (WSS_res / WSS_tot);

        % Estimate threshold at specified performance levels
        if flag_estimateThresh
            for iPerf = 1:nPerf
                perfThresh = fit.perfThresh_all(iPerf) / 100;
                thresh = fit.PF(estParams, perfThresh, 'Inverse');

                % Convert to log scale if needed
                if iModel == 4
                    if thresh < 0
                        error('Threshold negativelog10 undefined');
                    end
                    thresh_log = log10(thresh);
                else
                    thresh_log = thresh;
                end

                if thresh == -Inf
                    thresh_log = nan;
                end

                thresh_log_allB(iB, iModel, iPerf) = thresh_log;
            end
        end
    end
end

%Quick plot
% quickPlot_PMF

%% Remove anchor trials (if added earlier)
if flag_filterData
    cst_log_unik = cst_log_unik(nAnchor+1:end);
    nCorr = nCorr(nAnchor+1:end);
    nData = nData(nAnchor+1:end);
    pC = pC(nAnchor+1:end);
end