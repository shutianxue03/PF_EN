function [est, threshEnergy_pred, Rsquared] = fitTvC_LAM(noiseEnergy, threshEnergy, nPerf)
% Purpose: Fit the LAM to data that are the contrast energy at threshold as a function of noise energy.
%%%%%%%%%%%%%%%%%%%%%%%%
% FIT ALL PERF LEVEL TOGETHER!!
%%%%%%%%%%%%%%%%%%%%%%%%

%Inputs:
%           noiseEnergy the noise energy (i.e., noise rms contrast ^ 2)
%           threshEnergy: the contrast energy at threshold (squared noise SD)
%           params0: initial values
%           lb: lower bound
%           ub: upper bound

warning off
options = optimoptions('fmincon','MaxIterations',5000,'Display','off');

nNoise = length(noiseEnergy);

if size(threshEnergy, 1) ~= nPerf, threshEnergy=threshEnergy'; end
params0 = [1, (30/100)^2]; % slope, Neq (in energy unit, hence, SD^2)
lb = [.001, (3/100)^2];
ub = [5.5, .44^2]; % 5.5 is from (1^2-0^2)/(.44^2-0) = 5.16

nrep = 15;

fxn_getDevLAM = @(params) sumsqr(fxn_LAM_allPerf(nPerf, noiseEnergy, params) - threshEnergy(:));

% just one-shot
est_oneshot = fmincon(fxn_getDevLAM, params0, [], [], [], [], lb, ub, [], options); %Non-linear regression % edit lam_tvc

% with multiple starting point
problem_ML = createOptimProblem('fmincon','objective', fxn_getDevLAM,'x0',params0,'lb',lb,'ub',ub,'options',options);
ms_ML = MultiStart('StartPointsToRun', 'bounds','UseParallel', 1, 'Display', 'off');
est = run(ms_ML, problem_ML, nrep);

threshEnergy_pred = fxn_LAM_allPerf(nPerf, noiseEnergy, est);
threshEnergy_pred = reshape(threshEnergy_pred, [nPerf, nNoise]);

Rsquared = nan(1, nPerf);
thresh_log = log10(sqrt(threshEnergy));
thresh_pred_log = real(log10(sqrt(threshEnergy_pred)));
for iperf = 1:nPerf
    residual_log = thresh_log(iperf ,:)-thresh_pred_log(iperf ,:);
    Rsquared(iperf) = 1-sumsqr(residual_log)/sumsqr(thresh_log(iperf ,:)-mean(thresh_log(iperf ,:))); %Calculate r^2 of the fit based on the residuals
end

% figure, hold on
% plot(noiseEnergy, threshEnergy, '--ko')
% plot(noiseEnergy, threshEnergy_pred, 'b-')
%
% figure, hold on
% plot(sqrt(noiseEnergy), sqrt(threshEnergy), 'ko')
% plot(sqrt(noiseEnergy), sqrt(threshEnergy_pred), 'b-')


    function cE_pred = fxn_LAM_allPerf(nPerf, nE, params)
        nNoise = length(nE);
        
        cE_pred = nan(nPerf, nNoise);
        for iPerf = 1:nPerf
            cE_pred(iPerf, :) = fxn_LAM(params, nE);
        end
        cE_pred = cE_pred(:);
    end
end