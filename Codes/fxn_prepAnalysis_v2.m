
iWeibull = 4; %'Logistic', 'CumNorm', 'Gumbel',  'Weibull'}
iBeta = 2; % alpha, beta, gamma, lambda

%% Initialize empty containers
imodel_best_all = nan(nLocSingle, nNoise);  % Best model index for each location and noise condition
cst_log_unik_all = cell(nLocSingle, nNoise);  % Unique contrast levels for each location and noise
nCorr_all = cst_log_unik_all;  % Number of correct responses
nData_all = cst_log_unik_all;  % Total number of data points
estP_all = cst_log_unik_all;  % Estimated parameters
yfit_all = cst_log_unik_all;  % Fitted responses (predicted probabilities)
thresh_log_all = cst_log_unik_all;  % Log-transformed thresholds
LL_all = nan(nLocSingle, nNoise, nModels);  % Log-likelihood values for bootstrap iterations
R2_weighted_all = LL_all;  % Weighted R² values for bootstrap iterations

%% Loop over all combinations of locations and noise levels
for iLocNoise_ = 1:nLocSingle*nNoise
    %------------------%
    extractiLocNoise % produces iNoise; uses flag_collapseHM
    %------------------%
    if isempty(cst_log_unik_allLocN{iLocNoise})
        fprintf('*NOT exist*\n')
    else
        % a = thresh_log_allLocN{iLocNoise};
        % if isempty(a) % unmute this to avoid estimating threshold
        thresh_log_all_ = nan(nModels, nPerf);
        pred_all = nan(nModels, length(fit.curveX_log));
        for iModel = 1:nModels
            switch iModel, case 1, fit.PF = @PAL_Logistic; case 2, fit.PF = @PAL_CumulativeNormal; case 3, fit.PF = @PAL_Gumbel; case 4, fit.PF = @PAL_Weibull; end
            % decide x curve (fine)
            if iModel==4, cst_fineG = 10.^fit.curveX_log; else, cst_fineG = fit.curveX_log; end

            estP = squeeze(estP_allLocN{iLocNoise}(iModel, :));

            if isnan(estP(2)), estP(2) = Inf; end
            % assert(~any(isnan(estP)), sprintf('ALERT: There are NaN values in est P in Loc=%d nNoise=%d!!', iLoc_record, iNoise))
            % save predicted pC
            pred = fit.PF(estP, cst_fineG);
            pred_all(iModel, :) = pred; % should match this format: pC_pred_allB = nan(nBoot, nModels, length(curveX_log));

            % save estimated thresh
            for iPerf = 1:nPerf
                thresh = fit.PF(estP, perfThresh_all(iPerf)/100, 'Inverse');
                if thresh == -Inf, thresh=nan; end
                thresh_log = 99; if iModel==4, if thresh<0, error('ALERT: thresh is negative so cannot convert to log10!!'); end, thresh_log=log10(thresh); else, thresh_log = thresh; end
                if ~isreal(thresh_log)
                    thresh_log
                else
                    thresh_log_all_(iModel, iPerf) = thresh_log;
                end
            end % iPerf
        end % iModel
    end

    % Convert nans in log thresh to the upper bound
    thresh_log_all_(isnan(thresh_log_all_)) = log10(gaborCST_ub);

    % reorganize data
    cst_log_unik_all{iLoc_record, iNoise} = cst_log_unik_allLocN{iLocNoise};
    nCorr_all{iLoc_record, iNoise} = nCorr_allLocN{iLocNoise};
    nData_all{iLoc_record, iNoise} = nData_allLocN{iLocNoise};
    estP_all{iLoc_record, iNoise} = estP_allLocN{iLocNoise};
    % yfit_all{iLoc_record, iNoise} = pC_pred_allLocN{iLocNoise}; % do NOT save the pred pC in OOD_boot
    yfit_all{iLoc_record, iNoise} = pred_all;
    thresh_log_all{iLoc_record, iNoise} = thresh_log_all_;
    LL_all(iLoc_record, iNoise, :) = LL_allLocN{iLocNoise};
    R2_weighted_all(iLoc_record, iNoise, :) = R2_weighted_allLocN{iLocNoise};

end %iLocNoise_

% convert negative R2 and nan to 0
R2_weighted_all(R2_weighted_all<0) = 0;
R2_weighted_all(isnan(R2_weighted_all)) = 0;

%% Calculate combined location thresholds
thresh_log_all_mat_singleLoc = nan([nLocSingle, nNoise, size(thresh_log_all{1,1})]);
nData_all_mat_singleLoc = nan(nLocSingle, nNoise);
beta_all_mat_singleLoc = nan(nLocSingle, nNoise);

for iLocSingle = 1:nLocSingle
    for iNoise=1:nNoise
        % Aggregate thresholds and data counts for each location and noise level
        assert(isreal(thresh_log_all{iLocSingle, iNoise}), 'ERROR: thesh log is NO REAL!!!')
        thresh_log_all_mat_singleLoc(iLocSingle, iNoise, :, :, :) = thresh_log_all{iLocSingle, iNoise};
        nData_all_mat_singleLoc(iLocSingle, iNoise) = sum(nData_all{iLocSingle, iNoise});
        beta_all_mat_singleLoc(iLocSingle, iNoise) = median(estP_all{iLocSingle, iNoise}(iWeibull, iBeta));
    end
end

if flag_locType == 2 % combLoc
    % Combine location for nData and beta (because they dononly have two dimensions: Loc and noiseSD)
    nData_all_mat_combLoc = cell2mat(fxn_extractAsym(nData_all_mat_singleLoc')).';
    beta_all_mat_combLoc = cell2mat(fxn_extractAsym(beta_all_mat_singleLoc')).';

    % Preallocate
    thresh_log_all_mat_combLoc = nan([nLocComb, nNoise, size(thresh_log_all{1,1})]);
    LL_all_mat_combLoc = nan(nLocComb, nNoise, nModels);
    R2_weighted_all_mat_combLoc = nan(nLocComb, nNoise, nModels);

    % Combine location
    for iNoise=1:nNoise
        for iModelPMF=1:nModels
            LL_all_mat_combLoc(:, iNoise, iModelPMF) = cell2mat(fxn_extractAsym(squeeze(LL_all(:, iNoise, iModelPMF)))).'; % muted due to wrong matrix shape
            R2_weighted_all_mat_combLoc(:, iNoise, iModelPMF) = cell2mat(fxn_extractAsym(squeeze(R2_weighted_all(:, iNoise, iModelPMF)))).';
            for iPerf=1:nPerf
                thresh_log_all_mat_combLoc(:, iNoise, iModelPMF, iPerf) = cell2mat(fxn_extractAsym(squeeze(thresh_log_all_mat_singleLoc(:, iNoise, iModelPMF, iPerf)).')).';
            end
        end
    end

    % Store combined data back in cell format
    thresh_log_all = cell(nLocComb, nNoise);
    nData_sum_all = thresh_log_all; % change from 'nData_all' to 'ndata_sum_all', as the former should be a cell containing nData of ALL noise levels
    for iLocComb = 1:nLocComb
        for iNoise=1:nNoise
            thresh_log_all{iLocComb, iNoise} = squeeze(thresh_log_all_mat_combLoc(iLocComb, iNoise, :, :, :));
            nData_sum_all{iLocComb, iNoise} = squeeze(nData_all_mat_combLoc(iLocComb, iNoise));
        end
    end

    LL_all = LL_all_mat_combLoc;
    R2_weighted_all = R2_weighted_all_mat_combLoc;
end

%%
%-----------------%
SX_fitTvC_setting
%-----------------%

thresh_log = nan(nLoc, nNoise, nPerf); % "nLoc" here can be either nLocSingle (flag_locType=1) or nLocComb (flag_locType=2)
nData_perLoc = nan(nLoc, nNoise);

for iLoc = 1:nLoc
    for iNoise = 1:nNoise
        thresh_log(iLoc, iNoise, :) = getCI(thresh_log_all{iLoc, iNoise}(iWeibull, :), 1); % here, all models should have the same thresh_log (hence iWeibull can take any value; but for simplcity, we take the redundant way)
        switch flag_locType
            case 1, nData_perLoc(iLoc, iNoise) = sum(nData_all{iLoc, iNoise}); % do NOT change nData_all to nData_sum_all
            case 2, nData_perLoc(iLoc, iNoise) = sum(nData_sum_all{iLoc, iNoise}); % do NOT change nData_all to nData_sum_all
        end
    end
end

% Constrain threshold to be below the ub (used for TvC fitting in "fxn_fitTvCIDVD")
% thresh_log(thresh_log>gaborCST_ub) = gaborCST_ub;

% convert threshold contrast to energy (used for TvC fitting in "fxn_fitTvCIDVD")
threshEnergy = (10.^thresh_log).^2;

%% organize thresh_log and nData by location groups
% thresh_log_perLocG = nan(nIndLoc_s, nNoise, nPerf);
% nData_perLocG = nan(nIndLoc_s, nNoise);
% for iiIndLoc_s = 1:nIndLoc_s
%     indLoc_s = indLoc_s_all{iiIndLoc_s};
%     nLoc_s = length(indLoc_s); % Number of locations in the group
%     thresh_log_perLocG(iiIndLoc_s, 1:nLoc_s, xx, xx) = thresh_log(indLoc_s, :, :);
%     nData_perLocG(iiIndLoc_s, 1:nLoc_s, xx, xx) = nData_perLoc(indLoc_s, :);
% end