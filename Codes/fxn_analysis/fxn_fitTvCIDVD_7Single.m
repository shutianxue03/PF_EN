
% Initialization
indLoc_s = [1,     4,6,7,        8,10,11];
nLoc_s = length(indLoc_s); % Number of locations in the group

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

% Initiate place hodlers
R2_7Single = nan(nLoc_s_max, nPerf);

%%
% Suppress warnings and set optimization options
warning off
options = optimoptions('fmincon', 'MaxIterations', 5000, 'Display', 'off');
nrep = 20;

% Get dimensions of input data
switch iTvCModel
    case 1, [nLoc, nNoise, nPerf] = size(threshEnergy);
    case 2, [nLoc, nNoise, nPerf] = size(threshEnergy);
end

% Calculate weights for fitting
nData_perLoc_mat = repmat(nData_perLoc, [1, 1, nPerf]);
if flag_weightedFitting, weight = nData_perLoc_mat;
else, weight = ones(size(nData_perLoc_mat));
end

% Define objective function for RSS calculation
        fxn_getRSS_weightAfterSquare = @(params_allLoc) sum((    log10(sqrt(fxn_predTvC_varyLocMC(iTvCModel, indParamVary, dprimes, SF_fit, noiseEnergy, params_allLoc, nLoc))) ...
            - log10(sqrt(threshEnergy(:)))   ).^2.* weight(:));
        fxn_getRSS_weightBeforeSquare = @(params_allLoc) sumsqr((   log10(sqrt(fxn_predTvC_varyLocMC(iTvCModel, indParamVary, dprimes, SF_fit, noiseEnergy, params_allLoc, nLoc))) ...
            - log10(sqrt(threshEnergy(:)))   ) .* weight(:));

% Decide weighting strategy
% fxn_getRSS = fxn_getRSS_weightAfterSquare; mode_weight=1; % this algorithm gives perfect R2!!
fxn_getRSS = fxn_getRSS_weightBeforeSquare; mode_weight=2;

% Perform parameter optimization using MultiStart
problem_ML = createOptimProblem('fmincon', 'objective', fxn_getRSS, 'x0', params0, 'lb', lb, 'ub', ub, 'options', options);
ms_ML = MultiStart('StartPointsToRun', 'bounds', 'UseParallel', 1, 'Display', 'off');
[params_est, RSS_] = run(ms_ML, problem_ML, nrep);

% Make predictions based on the estimated parameters
%---------------------------------------------------------------------------------%
threshEnergy_pred = fxn_predTvC_varyLocMC(iTvCModel, indParamVary, dprimes, SF_fit, noiseEnergy, params_est, nLoc);
%---------------------------------------------------------------------------------%
threshEnergy_pred = reshape(threshEnergy_pred, [nLoc, nNoise, nPerf]);

% Calculate (weighted) R²
R2 = nan(nLoc, nPerf);
RSS = R2;
switch iErrorType
    case 1 % Log cst
        thresh_meas = log10(sqrt(threshEnergy));
        thresh_pred = log10(sqrt(threshEnergy_pred));
    case 2 % Ln Cst
        thresh_meas = sqrt(threshEnergy);
        thresh_pred = sqrt(threshEnergy_pred);
    case 3 % Ln energy
        thresh_meas = threshEnergy;
        thresh_pred = threshEnergy_pred;
end

for iiLoc = 1:nLoc
    for iPerf = 1:nPerf
        weight_ = weight(iiLoc, :, iPerf);
        thresh_meas_ = thresh_meas(iiLoc, :, iPerf);
        thresh_meas_ave = mean(thresh_meas_);
        thresh_pred_ = thresh_pred(iiLoc, :, iPerf);
        
        switch mode_weight
            case 1 % Weight after squaring
                residual_log_squared = (thresh_meas_ - thresh_pred_).^2;
                RSS(iiLoc, iPerf) = sum(residual_log_squared .* weight_);
                var_weighted = weight_ .* ((thresh_meas_ - thresh_meas_ave).^2);
                
            case 2 % Weight before squaring
                residual_log = weight_ .* (thresh_meas_ - thresh_pred_);
                RSS(iiLoc, iPerf) = sumsqr(residual_log);
                diff_weighted = weight_ .* (thresh_meas_ - thresh_meas_ave);
                residual_log_squared = residual_log.^2;
                var_weighted = diff_weighted.^2;
        end
        
        % Calculate R²
        R2(iiLoc, iPerf) = 1 - sum(residual_log_squared) / sum(var_weighted);
    end % iPerf
end % iiLoc

% convert Inf and 1 to 0
R2(abs(R2)==Inf)=0;
R2(R2==1)=0;

% Check RSS consistency
% assert(abs(sum(RSS(:)) - RSS_) < 1e-4, sprintf('ERROR: RSS mismatch (%.4f vs. %.4f)', sum(RSS(:)), RSS_));

% Plot results if requested
if flag_plot
    figure('Position', [100, 100, nLoc*300, 300]);
    for iiLoc = 1:nLoc
        subplot(1, nLoc, iiLoc);
        hold on;
        plot(log10(sqrt(noiseEnergy)), log10(sqrt(squeeze(threshEnergy(iiLoc, :, :)))), '--ko');
        plot(log10(sqrt(noiseEnergy)), log10(sqrt(squeeze(threshEnergy_pred(iiLoc, :, :)))), 'b-');
        xlabel('Noise (SD)');
        ylabel('Thresh (SD)');
        %         ylim([0, 0.35]);
        title(sprintf('Loc %d', iiLoc));
    end
    sgtitle(sprintf('[PTM %s] R2=%.2f (Error Type: %s)', num2str(indParamVary), mean(R2, 1), namesErrorType{iErrorType}));
end



%% 
% % Generate candidate models based on parameter inclusion
% switch nLoc_s
%     case 2, iCond_all = [0, 1];
%     case 3, iCond_all = 0:4;
% end
% %--------------------------------------------------------------------------------%
% indParamVary_allCand = fxn_getIndParamIncl(nParams_full, iCond_all); % Generate all combinations
% %--------------------------------------------------------------------------------%
% 
% % Load the best & simplest model
% %     load('IndCand_GroupBest_all4.mat', 'IndCand_GroupBest_all4')
% %     iCand_groupBest = IndCand_GroupBest_all4{iTvCModel, iErrorType, iGoF_inUse};
% iCand_groupBest = IndCand_GroupBest_vec(iiIndLoc_s);
% indParamVary = indParamVary_allCand(iCand_groupBest, :); % Current candidate
% 
% % Retrieve parameter bounds for current candidate
% %--------------------------------------------------------------------------------%
% [params0, ub, lb] = MC_getLimits(indParamVary, params0_def, ub_def, lb_def, nLoc_s);
% %--------------------------------------------------------------------------------%
% 
% % Retry mechanism for fitting
% switch iTvCModel
%     case 1 % LAM
%         params_est_allPerf = cell(1, nPerf);
%         R2 = nan(nLoc_s, nPerf);
%         for iPerf=1:nPerf
%             %--------------------------------------------------------------------------------%
%             [params_est_vec_perPerf, ~, RSS_perPerf, R2_perPerf] = fitTvC_varyLocMC(iTvCModel, indParamVary, noiseEnergy_true, threshEnergy(indLoc_s, :, iPerf), dprimes, SF_fit, params0, lb, ub, iErrorType, flag_weightedFitting, nData_perLoc(indLoc_s, :), 0);
%             %--------------------------------------------------------------------------------%
%             params_est_allPerf{iPerf} = params_est_vec_perPerf;
%             R2(:, iPerf) = R2_perPerf;
%         end
%     case 2 % PTM
%         %--------------------------------------------------------------------------------%
%         [params_est_vec, ~, RSS, R2] = fitTvC_varyLocMC(iTvCModel, indParamVary, noiseEnergy_true, threshEnergy(indLoc_s, :, :), dprimes, SF_fit, params0, lb, ub, iErrorType, flag_weightedFitting, nData_perLoc(indLoc_s, :), 0);
%         %--------------------------------------------------------------------------------%
% end
% 
% % Convert estimated params
% switch iTvCModel
%     case 1 % LAM
%         est_7Single = nan(nLoc_s, nParams_full, nPerf);
%         for iPerf = 1:nPerf
%             %--------------------------------------------------------------------------------%
%             params_est_cell_opt = MC_vec2cell(indParamVary, params_est_allPerf{iPerf}, nLoc_s);
%             est_7Single(:, :, iPerf) = MC_cell2mat(indParamVary, params_est_cell_opt, nLoc_s); % nLoc_s x nParams
%             %--------------------------------------------------------------------------------%
%         end % iPerf
%         % to fill the last row (the 3rd loc with NaNs)
%         if nLoc_s==2
%             R2 = [R2; nan(1, nPerf)];
%             est_7Single = cat(1, est_7Single, nan(1, nParams_full, nPerf));
%         end
% 
%     case 2 % PTM
%         %--------------------------------------------------------------------------------%
%         params_est_cell_opt = MC_vec2cell(indParamVary, params_est_vec, nLoc_s);
%         est_7Single = MC_cell2mat(indParamVary, params_est_cell_opt, nLoc_s); % nLoc_s x nParams
%         %--------------------------------------------------------------------------------%
%         % to fill the last row (the 3rd loc with NaNs)
%         if nLoc_s == 2
%             R2 = [R2; nan(1, nPerf)];
%             est_7Single = [est_7Single; nan(1, nParams_full)];
%         end
% 
% end % switch iTvCModel
% 
% % Store R2 and estimated params
% R2_7Single = R2;
% 
% 
