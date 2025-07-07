
%% Initialize empty containers
cst_log_unik_all = cell(nLocSingle, nNoise);  % Unique contrast levels for each location and noise
nCorr_all = cst_log_unik_all;  % Number of correct responses
nData_all = cst_log_unik_all;  % Total number of data points
estP_all = cst_log_unik_all;  % Estimated parameters
yfit_all = cst_log_unik_all;  % Fitted responses (predicted probabilities)
thresh_log_allSingle = cst_log_unik_all;  % Log-transformed thresholds
LL_allSingle = nan(nLocSingle, nNoise, nModels);  % Log-likelihood values for bootstrap iterations
R2_weighted_allSingle = LL_allSingle;  % Weighted R² values for bootstrap iterations

%% Loop over all combinations of locations and noise levels
for iLocNoise_ = 1:nLocSingle*nNoise
    %------------------%
    extractiLocNoise % produces iNoise; has flag_collapseHM
    %------------------%
    if isempty(cst_log_unik_allLocN{iLocNoise})
        fprintf('*NOT exist*\n')
    else
        % Reorganize data
        cst_log_unik_all{iLoc_record, iNoise} = cst_log_unik_allLocN{iLocNoise};
        nCorr_all{iLoc_record, iNoise} = nCorr_allLocN{iLocNoise};
        nData_all{iLoc_record, iNoise} = nData_allLocN{iLocNoise};
        estP_all{iLoc_record, iNoise} = estP_allLocN{iLocNoise}; % in each cell: nModels x nParams_PMF
        LL_allSingle(iLoc_record, iNoise, :) = LL_allLocN{iLocNoise};
        R2_weighted_allSingle(iLoc_record, iNoise, :) = R2_weighted_allLocN{iLocNoise};
        
        % Preallocate for thresh and pred pC
        thresh_log_all_ = nan(nModels, nPerf);
        pred_all = nan(nModels, length(fit.curveX_log));
        
        % Loop through each PMF model
        for iModel = 1:nModels
            switch iModel
                case 1, fit.PF = @PAL_Logistic;
                case 2, fit.PF = @PAL_CumulativeNormal;
                case 3, fit.PF = @PAL_Gumbel;
                case 4, fit.PF = @PAL_Weibull;
            end
            
            % Decide the fine x curve
            if iModel==4, cst_fineG = 10.^fit.curveX_log; else, cst_fineG = fit.curveX_log; end
            
            % Extract estimated parameters of a certain PFM model
            estP = squeeze(estP_allLocN{iLocNoise}(iModel, :)); %
            
            % Convert nan slopes to Inf
            if isnan(estP(2)), estP(2) = Inf; end
            % assert(~any(isnan(estP)), sprintf('ALERT: There are NaN values in est P in Loc=%d nNoise=%d!!', iLoc_record, iNoise))
            
            % Calculate and store predicted pC
            pred = fit.PF(estP, cst_fineG);
            pred_all(iModel, :) = pred;
            
            % Calculate and store thresh for each perf level
            for iPerf = 1:nPerf
                thresh = fit.PF(estP, perfThresh_all(iPerf)/100, 'Inverse');
                if thresh == -Inf, thresh = nan; end
                thresh_log = 99;
                % Convert thresh to log if using Weibull function
                if iModel==4, if thresh<0, error('ALERT: thresh is negative so cannot convert to log10!!'); end, thresh_log = log10(thresh); else, thresh_log = thresh; end
                % Check if thresh is real number, then store
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
    
    % Store data
    thresh_log_allSingle{iLoc_record, iNoise} = thresh_log_all_;
    yfit_all{iLoc_record, iNoise} = pred_all;
    
end %iLocNoise_

% Convert negative R2 & nan to 0
R2_weighted_allSingle(R2_weighted_allSingle < 0) = 0;
R2_weighted_allSingle(isnan(R2_weighted_allSingle)) = 0;

%% Calculate combined location thresholds
thresh_log_all_mat_singleLoc = nan([nLocSingle, nNoise, size(thresh_log_allSingle{1,1})]);
nData_all_mat_singleLoc = nan(nLocSingle, nNoise);
beta_all_mat_singleLoc = nan(nLocSingle, nNoise);

% Convert cells to matrices (to match the input format of fxn_extractAsym)
for iLocSingle= 1:nLocSingle
    for iNoise=1:nNoise
        % Aggregate thresholds and data counts for each location and noise level
        assert(isreal(thresh_log_allSingle{iLocSingle, iNoise}), 'ERROR: thesh log is NO REAL!!!')
        thresh_log_all_mat_singleLoc(iLocSingle, iNoise, :, :) = thresh_log_allSingle{iLocSingle, iNoise};
        nData_all_mat_singleLoc(iLocSingle, iNoise) = sum(nData_all{iLocSingle, iNoise});
        beta_all_mat_singleLoc(iLocSingle, iNoise) = estP_all{iLocSingle, iNoise}(iWeibull, iBeta);
    end
end

% Combine location for nData and beta (because they only have two dimensions: Loc and noiseSD)
nData_all_mat_combLoc = cell2mat(fxn_extractAsym(nData_all_mat_singleLoc')).';
beta_all_mat_combLoc = cell2mat(fxn_extractAsym(beta_all_mat_singleLoc')).';

% Preallocate
thresh_log_all_mat_combLoc = nan([nLocComb, nNoise, size(thresh_log_allSingle{1,1})]);
LL_all_mat_combLoc = nan(nLocComb, nNoise, nModels);
R2_weighted_all_mat_combLoc = nan(nLocComb, nNoise, nModels);

% Combine location for LL, R2 and thresh
for iNoise=1:nNoise
    for iModelPMF=1:nModels
        for iPerf=1:nPerf
            thresh_log_all_mat_combLoc(:, iNoise, iModelPMF, iPerf) = cell2mat(fxn_extractAsym(thresh_log_all_mat_singleLoc(:, iNoise, iModelPMF, iPerf)'));
        end
        LL_all_mat_combLoc(:, iNoise, iModelPMF) = cell2mat(fxn_extractAsym(LL_allSingle(:, iNoise, iModelPMF)'));
        R2_weighted_all_mat_combLoc(:, iNoise, iModelPMF) = cell2mat(fxn_extractAsym(R2_weighted_allSingle(:, iNoise, iModelPMF)'));
        
    end
end

% Store combined thresh_log and nData back in cell format
thresh_log_all = cell(nLocComb, nNoise);
nData_sum_all = thresh_log_all; % change from 'nData_all' to 'ndata_sum_all', as the former should be a cell containing nData of ALL noise levels
for iLocComb = 1:nLocComb
    for iNoise=1:nNoise
        thresh_log_all{iLocComb, iNoise} = squeeze(thresh_log_all_mat_combLoc(iLocComb, iNoise, :, :));
        nData_sum_all{iLocComb, iNoise} = squeeze(nData_all_mat_combLoc(iLocComb, iNoise));
    end
end

LL_allB = LL_all_mat_combLoc;
R2_weighted_allB = R2_weighted_all_mat_combLoc;

% Select the PMF model
thresh_log = squeeze(thresh_log_all_mat_combLoc(:, :, iWeibull, :));
nData_perLoc = nData_all_mat_combLoc;

% convert threshold contrast to energy (used for TvC fitting in "fxn_fitTvCIDVD")
threshEnergy = (10.^thresh_log).^2;
