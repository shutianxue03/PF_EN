function [params_est, threshEnergy_pred, RSS, Rsquared] = fitTvC_PTM_nestedMC(indParamIncl, noiseEnergy, threshEnergy, dprimes, SF_fit, params0_def, lb_def, ub_def, flag_weightedFitting, nData_perLoc, flag_plot)
% Purpose: Fit the PTM to data that are the contrast energy at threshold as a function of noise energy.
%Inputs:
%           noiseEnergy the noise energy (i.e., noise rms contrast ^ 2)
%           threshEnergy: the contrast energy at threshold (squared noise SD)
%           dprimes: dprimes corresponding to the performance levels
%           params0: initial values
%           lb: lower bound
%           ub: upper bound

warning off
options = optimoptions('fmincon','MaxIterations', 5000,'Display','off');
nrep = 20;

% nPerf = length(dprimes);
% nNoise = length(noiseEnergy);
[nLoc, nNoise, nPerf] = size(threshEnergy);
% if size(threshEnergy, 1) ~= nPerf, threshEnergy=threshEnergy'; end

% Decide weight for each noise level
nData_perLoc_mat = repmat(nData_perLoc, [1,1,nPerf]);
if flag_weightedFitting
    % More trials, more weight
    weight = nData_perLoc_mat;
    %  Better PMF fitting (higher R2), more weight
    % xx
else, weight = ones(size(nData_perLoc_mat));
end


% if flag_weightedFitting, weight = nData_perLoc_mat/sum(nData_perLoc_mat(:));
% else, weight = ones(size(nData_perLoc_mat)); weight = weight/sum(weight(:));
% end

%
params0 = repmat(params0_def, nLoc, 1); %params0 = params0(:).'; % convert to colummn vector for bads
lb = repmat(lb_def, nLoc, 1); %lb = lb(:).';
ub = repmat(ub_def, nLoc, 1); %ub = ub(:).';

% define function
% RSS of energy difference
% fxn_getRSS = @(params_allLoc) sumsqr((fxn_PTM_nestedMC(indParamIncl, dprimes, noiseEnergy, params_allLoc) - threshEnergy(:)) .* weight(:));
% RSS of log contrast difference
fxn_getRSS = @(params_allLoc) sumsqr((log10(sqrt(fxn_PTM_nestedMC(indParamIncl, dprimes, noiseEnergy, params_allLoc, SF_fit))) - log10(sqrt(threshEnergy(:)))) .* weight(:));

% fit
problem_ML = createOptimProblem('fmincon','objective', fxn_getRSS,'x0', params0,'lb',lb,'ub',ub,'options',options);
ms_ML = MultiStart('StartPointsToRun', 'bounds','UseParallel', 1, 'Display', 'off');
[params_est, RSS] = run(ms_ML, problem_ML, nrep);
% params_est = bads(fxn_getRSS, params0, lb, ub); % did NOT work very well for PTM, at L7-9; work perfectly for LAM though

% Make prediction
%------------------------------------------------------------------------------------%
threshEnergy_pred = fxn_PTM_nestedMC(indParamIncl, dprimes, noiseEnergy, params_est, SF_fit);
%------------------------------------------------------------------------------------%
threshEnergy_pred = reshape(threshEnergy_pred, [nLoc, nNoise, nPerf]);

% calculate (weighted) R2
Rsquared = nan(nLoc, nPerf);
thresh_log = log10(sqrt(threshEnergy));
thresh_pred_log = log10(sqrt(threshEnergy_pred));

for iLoc=1:nLoc
    for iPerf = 1:nPerf
        residual_log = weight(iLoc, :, iPerf).*(thresh_log(iLoc, :, iPerf)-thresh_pred_log(iLoc, :, iPerf));
        var_log = weight(iLoc, :, iPerf).*(thresh_log(iLoc, :, iPerf)-mean(thresh_log(iLoc, :, iPerf)));
        Rsquared(iLoc, iPerf) = 1-sumsqr(residual_log)/sumsqr(var_log); %Calculate r^2 of the fit based on the residuals
        if any(Rsquared(iLoc, iPerf)==[1,Inf]), Rsquared(iLoc, iPerf)=0; end
    end
end

%%
if flag_plot
    figure('Position', [100 100 800 300])
    for iLoc = 1:nLoc
        subplot(1, nLoc, iLoc), hold on
        plot(sqrt(noiseEnergy), sqrt(squeeze(threshEnergy(iLoc, :, :))), '--ko')
        plot(sqrt(noiseEnergy), sqrt(squeeze(threshEnergy_pred(iLoc, :, :))), 'b-')
        xlabel('Noise (SD)')
        ylabel('Thresh (SD)')
        ylim([0, .35])
        title(sprintf('Loc%d', iLoc))
    end
    sgtitle(sprintf('[PTM %s] R2=%.2f, %.2f, %.2f', num2str(indParamIncl), mean(Rsquared, 1)))
end
end

