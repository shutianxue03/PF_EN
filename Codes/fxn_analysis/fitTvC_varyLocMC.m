function [params_est, threshEnergy_pred, RSS, R2] = fitTvC_varyLocMC(iTvCModel, indParamVary, noiseEnergy, threshEnergy, dprimes, SF_fit, params0, lb, ub, iErrorType, flag_weightedFitting, nData_perLoc, flag_plot)
% Purpose: Fits the PTM model to threshold contrast energy data as a function of noise energy.

% Inputs:
%   - iTvCModel: Model type to be used for fitting
%   - indParamVary: Indices of parameters to vary
%   - noiseEnergy: Noise energy (e.g., noise RMS contrast squared)
%   - threshEnergy: Threshold contrast energy (squared noise SD)
%   - dprimes: d' values corresponding to performance levels
%   - params0: Initial parameter values for optimization
%   - lb: Lower bounds for parameter fitting
%   - ub: Upper bounds for parameter fitting
%   - flag_weightedFitting: Boolean, whether to apply weighted fitting
%   - nData_perLoc: Number of data points per location
%   - flag_plot: Boolean, whether to generate plots of the results
% Outputs:
%   - params_est: Estimated parameters
%   - threshEnergy_pred: Predicted threshold contrast energy
%   - RSS: Residual Sum of Squares
%   - R2: Coefficient of determination (R²)

% Suppress warnings and set optimization options
warning off
options = optimoptions('fmincon', 'MaxIterations', 5000, 'Display', 'off');
nrep = 20;

% Get dimensions of input data
switch iTvCModel
    case 1, [nLoc, nNoise, nPerf] = size(threshEnergy);
    case 2, [nLoc, nNoise, nPerf] = size(threshEnergy);
end

% Decide weight for each noise level
nData_perLoc_mat = repmat(nData_perLoc, [1,1,nPerf]);
if flag_weightedFitting
    % More trials, more weight
    weight = nData_perLoc_mat;
    %  Better PMF fitting (higher R2), more weight
else, weight = ones(size(nData_perLoc_mat));
end


% Define objective function for RSS calculation
namesErrorType = {'ErrLogCst', 'ErrLnCst', 'ErrLnEg'};
switch iErrorType
    case 1 % log cst
        fxn_getRSS_weightAfterSquare = @(params_allLoc) sum((    log10(sqrt(fxn_predTvC_varyLocMC(iTvCModel, indParamVary, dprimes, SF_fit, noiseEnergy, params_allLoc, nLoc))) ...
            - log10(sqrt(threshEnergy(:)))   ).^2.* weight(:));
        fxn_getRSS_weightBeforeSquare = @(params_allLoc) sumsqr((   log10(sqrt(fxn_predTvC_varyLocMC(iTvCModel, indParamVary, dprimes, SF_fit, noiseEnergy, params_allLoc, nLoc))) ...
            - log10(sqrt(threshEnergy(:)))   ) .* weight(:));
        
    case 2 % linear cst
        fxn_getRSS_weightAfterSquare = @(params_allLoc) sum((    sqrt(fxn_predTvC_varyLocMC(iTvCModel, indParamVary, dprimes, SF_fit, noiseEnergy, params_allLoc, nLoc)) ...
            - sqrt(threshEnergy(:))   ).^2.* weight(:));
        fxn_getRSS_weightBeforeSquare = @(params_allLoc) sumsqr((   sqrt(fxn_predTvC_varyLocMC(iTvCModel, indParamVary, dprimes, SF_fit, noiseEnergy, params_allLoc, nLoc)) ...
            - sqrt(threshEnergy(:))   ) .* weight(:));
        
    case 3 % linear energy
        fxn_getRSS_weightAfterSquare = @(params_allLoc) sum((    fxn_predTvC_varyLocMC(iTvCModel, indParamVary, dprimes, SF_fit, noiseEnergy, params_allLoc, nLoc) ...
            - threshEnergy(:)   ).^2.* weight(:));
        fxn_getRSS_weightBeforeSquare = @(params_allLoc) sumsqr((   fxn_predTvC_varyLocMC(iTvCModel, indParamVary, dprimes, SF_fit, noiseEnergy, params_allLoc, nLoc) ...
            - threshEnergy(:)   ) .* weight(:));
end

% Decide weighting strategy
% fxn_getRSS = fxn_getRSS_weightAfterSquare; mode_weight=1; % this algorithm gives perfect R2!!
fxn_getRSS = fxn_getRSS_weightBeforeSquare; mode_weight=2;

% Perform parameter optimization using MultiStart
problem_ML = createOptimProblem('fmincon', 'objective', fxn_getRSS, 'x0', params0, 'lb', lb, 'ub', ub, 'options', options);
ms_ML = MultiStart('StartPointsToRun', 'bounds', 'UseParallel', 1, 'Display', 'off');
[params_est, RSS_] = run(ms_ML, problem_ML, nrep);

% Validate RSS calculation
% RSS1 = fxn_getRSS(params_est);
% a=log10(sqrt(fxn_predTvC_varyLocMC(iTvCModel, indParamVary, dprimes, noiseEnergy, params_est, nLoc)));
% b=log10(sqrt(threshEnergy(:)));
% RSS2 = fxn_getRSS_confirm(a, b, weight(:), mode_weight);
% assert(abs(RSS1 - RSS2) < 1e-4, sprintf('ERROR: RSS mismatch (%.4f vs. %.4f)', RSS1, RSS2));

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

%% Plot results if requested
if flag_plot
    % convert a vector to a matrix for plotting purpose
    % only works for samenumber of params per loc!!
    params_est_mat = reshape(params_est, nLoc, length(params_est)/nLoc);
    
    if nLoc>3, figure('Position', [100, 100, 1.5e3, .8e3]);iplots = [13, 14, 18, 8, 15, 23, 3];
    else, figure('Position', [100, 100, nLoc*500, 300]);
    end
        
    for iiLoc = 1:nLoc
        if nLoc>3, subplot(5,5,iplots(iiLoc));
        else, subplot(1, nLoc, iiLoc);
        end
        hold on;
        plot([-1.8, log10(sqrt(noiseEnergy(2:end)))], log10(sqrt(squeeze(threshEnergy(iiLoc, :, :)))), '--ko');
        plot([-1.8, log10(sqrt(noiseEnergy(2:end)))], log10(sqrt(squeeze(threshEnergy_pred(iiLoc, :, :)))), 'b-');
        xlabel('Noise (SD)');
        ylabel('Thresh (SD)');
%         ylim([-2, -0.4]);
        grid on;
        xlim([-2, 0])
        title(sprintf('Loc %d [R2=%s]\nEstP: %s', iiLoc, ...
            strjoin(arrayfun(@num2str, round(R2(iiLoc, :),2), 'UniformOutput', false), '|'), ...
            strjoin(arrayfun(@num2str, round(params_est_mat(iiLoc, :),1), 'UniformOutput', false), '|')));
    end
    sgtitle(sprintf('[PTM %s] (Error Type: %s)', num2str(indParamVary), namesErrorType{iErrorType}));
end
end

%% Confirm RSS calculation for debugging
function RSS = fxn_getRSS_confirm(a, b, weight, mode_weight)
diff = a - b;
switch mode_weight
    case 1 % Weight after squaring
        diff_squared_weighted = (diff.^2) .* weight;
        RSS = sum(diff_squared_weighted);
    case 2 % Weight before squaring
        RSS = sumsqr(diff .* weight);
end

end
