
% For fitting PTM, all perf levels were fitted together
% For fitting LAM, all perf levels were fitted together

%-----------------%
SX_fitTvC_setting
%-----------------%

thresh_log = nan(nLoc, nNoise, nPerf);
for iLoc = 1:nLocSingle
    for iNoise = 1:nNoise
        thresh_log(iLoc, iNoise, :) = getCI(thresh_log_all{iLoc, iNoise}(:, model_decide, :), 1);
%         thresh_log_allSubj(isubj, iLoc, iNoise, :) = getCI(thresh_log_all{iLoc, iNoise}(:, model_decide, :));  %better to comile putsido
    end
end

% convert to energy
threshEnergy = (10.^thresh_log).^2;

%% 1. fit LAM to TvC (PMF/stair derived) and estimate Neq and Eff
fprintf('\n  Fitting LAM: ')

% empty containers
threshEnergy_LAM_pred_allPerf = nan(nLocSingle, nPerf, nIntp);
R2_LAM_allPerf = nan(nLocSingle, nPerf);
est_LAM_allPerf = nan(nLocSingle, nParams_LAM);

for iLoc = 1:nLocSingle
    fprintf('     L%d...', iLoc)
    if ~(any(isnan(threshEnergy(iLoc, 1, :))))
        
        % fit PTM model
        %------------------------------------------------------------%
        [est, ~, R2] = fitTvC_LAM(noiseEnergy_true, squeeze(threshEnergy(iLoc, :, :)).', nPerf);
        %------------------------------------------------------------%
        R2_LAM_allPerf(iLoc, :) = R2;
        est_LAM_allPerf(iLoc, :) = est; % Nmul, gamma, sigma_add, beta;
        
        % estimate energy
        TvC_energy_LAM = nan(nPerf, nIntp);
        for iPerf = 1:nPerf
            threshEnergy_LAM_pred_allPerf(iLoc, iPerf, :) = fxn_LAM(est, noiseEnergy_intp_true);
        end
    end
    
end % iLoc
fprintf('DONE\n')

%% 2. fit PTM to TvC (PMF derived)
fprintf('\n  Fitting PTM: ')

% empty containers
threshEnergy_PTM_pred_allPerf = nan(nLocSingle, nPerf, nIntp);
R2_PTM_allPerf = nan(nLocSingle, nPerf);
est_PTM_allPerf = nan(nLocSingle, nParams_PTM);

for iLoc = 1:nLocSingle
    fprintf('     L%d...', iLoc)
    if ~(any(isnan(threshEnergy(iLoc, 1, :))))
        
        % fit PTM model
        %------------------------------------------------------------%
        [est, ~, R2] = fitTvC_PTM(noiseEnergy_true, squeeze(threshEnergy(iLoc, :, :)).', dprimes);
        %------------------------------------------------------------%
        R2_PTM_allPerf(iLoc, :) = R2;
        est_PTM_allPerf(iLoc, :) = est; % Nmul, gamma, sigma_add, beta;
        
        % estimate energy
        TvC_energy_PTM = nan(nPerf, nIntp);
        for iPerf = 1:nPerf
            threshEnergy_PTM_pred_allPerf(iLoc, iPerf, :) = real(fxn_PTM(est, noiseEnergy_intp_true, dprimes(iPerf)));
        end
    end
    
end % iLoc
fprintf('DONE\n')
