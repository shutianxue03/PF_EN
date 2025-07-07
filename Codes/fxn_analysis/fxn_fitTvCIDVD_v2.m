

% For fitting PTM, all perf levels were fitted together
% For fitting LAM, each perf level was fitted separately (see together in fxn_fitTvCIDVD)

%-----------------%
SX_fitTvC_setting
%-----------------%

thresh_log = nan(nLoc, nNoise, nPerf);
nData_perLoc = nan(nLoc, nNoise);
for iLoc = 1:nLocSingle
    for iNoise = 1:nNoise
        thresh_log(iLoc, iNoise, :) = getCI(thresh_log_all{iLoc, iNoise}(:, model_decide, :), 1);
        %         thresh_log_allSubj(isubj, iLoc, iNoise, :) = getCI(thresh_log_all{iLoc, iNoise}(:, model_decide, :));  %better to comile putsido
        nData_perLoc(iLoc, iNoise) = sum(nData_all{iLoc, iNoise});
    end
end

% convert to energy
threshEnergy = (10.^thresh_log).^2;

%% 1. fit LAM to TvC (PMF/stair derived) and estimate Neq and Eff
fprintf('\n  Fitting LAM: ')

% empty containers
threshEnergy_LAM_pred_allPerf = nan(nLocSingle, nPerf, nIntp);
R2_LAM_allPerf = nan(nLocSingle, nPerf);
Eff_LAM_allLocPerf = nan(nLocSingle, nPerf);
Neq_log_LAM_allLocPerf = nan(nLocSingle, nPerf);

for iLoc = 1:nLocSingle
    fprintf('     L%d...', iLoc)
    if ~(any(isnan(threshEnergy(iLoc, 1, :))))
        
        for iPerf = 1:nPerf
            % for UVM8, only use the first 8 noise levels
            indNoise = 1:nNoise;
            threshEnergy_ = squeeze(threshEnergy(iLoc, indNoise, iPerf));
            
            %------------------------------------------------------------%
            [est, ~, R2] = fitTvC_LAM(noiseEnergy_true(indNoise), threshEnergy_, flag_weightedFitting, nData_perLoc(iLoc, indNoise));
            %------------------------------------------------------------%
%             assert(est(2) >= lb_LAM(2))
%             assert(est(2) <= ub_LAM(2))
            
            TvC_energy = fxn_LAM(est, noiseEnergy_intp_true); TvC_cst_log = log10(sqrt(TvC_energy));
            threshEnergy_LAM_pred_allPerf(iLoc, iPerf, :) = TvC_energy;
            R2_LAM_allPerf(iLoc, iPerf) = R2;
            slope = est(1);
            Neq_cst_ln = sqrt(est(2));
            Eff = D_ideal/slope;
            Eff_LAM_allLocPerf(iLoc, iPerf) = Eff*100;
            Neq_log_LAM_allLocPerf(iLoc, iPerf) = log10(Neq_cst_ln);
            
        end % iperf
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
        [est, ~, R2] = fitTvC_PTM(noiseEnergy_true, squeeze(threshEnergy(iLoc, :, :)).', dprimes, flag_weightedFitting, nData_perLoc(iLoc, :));
        %------------------------------------------------------------%
        R2_PTM_allPerf(iLoc, :) = R2;
        est_PTM_allPerf(iLoc, :) = est; % Nmul, gamma, sigma_add, beta;
        
        % estimate energy
        TvC_energy_PTM = nan(nPerf, nIntp);
        for iPerf = 1:nPerf
%             threshEnergy_PTM_pred_allPerf(iLoc, iPerf, :) = real(fxn_PTM(est, noiseEnergy_intp_true, dprimes(iPerf)));
            threshEnergy_PTM_pred_allPerf(iLoc, iPerf, :) = fxn_PTM(est, noiseEnergy_intp_true, dprimes(iPerf));
        end
    end
    
end % iLoc
fprintf('DONE\n')
