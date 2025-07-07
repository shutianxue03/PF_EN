function [params_est, threshEnergy_pred, RSS, Rsquared] = fitTvC_LAM(noiseEnergy, threshEnergy, flag_weightedFitting, nData_perLoc, flag_plot)
% Purpose: Fit the LAM to data that are the contrast energy at threshold as a function of noise energy.
%%%%%%%%%%%%%%%%%%%%%%%%
% FIT FOR EACH PERF LEVEL SEPARATELY!!
%%%%%%%%%%%%%%%%%%%%%%%%
% see the version fitting all perf levels together in fitTvC_LAM

%Inputs:
%           noiseEnergy: the noise energy (i.e., noise rms contrast ^ 2)
%           threshEnergy: the contrast energy at threshold
%           nData_perLoc: the number of trials per data point

%Outputs:
%           params_est: estimated params, [slope, intercept], intercept is an estimate of Neq, the critical spectral density of the noise
%           threshEnergy_pred: predicted threshold energy
%           Rsquared: goodness-of-fit

%[coeff,r,J]=nlinfit(noiseEnergy,threshEnergy,@lam_tvc,params); %Non-linear regression

%Stopped using nlinfit because the parameters kept trying to go negative
%without boundaries

warning off

options = optimoptions('fmincon','MaxIterations', 5000,'Display','off');
nrep = 20;

% calculate weight
% if flag_weightedFitting, weight = nData_perLoc/sum(nData_perLoc);
if flag_weightedFitting, weight = nData_perLoc;
else, weight = ones(size(nData_perLoc)); %weight = weight/sum(weight);
end
% assert(abs(sum(weight)-1)<1e-8)

% define function
fxn_getDev = @(params) sumsqr((fxn_LAM(params, noiseEnergy)-threshEnergy).*weight); % weighted by ntrials
% define initial point, upper and lower bounds
params0 = [1, (25/100)^2]; % slope and Neq (in energy unit, hence, SD^2)
lb = [.001, (1/100)^2];
ub = [5.5, (44/100)^2]; % 5.5 is from (1^2-0^2)/(.44^2-0) = 5.16
ub = [5.5, (100/100)^2]; % 5.5 is from (1^2-0^2)/(.44^2-0) = 5.16

% fit
problem_ML = createOptimProblem('fmincon','objective', fxn_getDev,'x0',params0,'lb',lb,'ub',ub,'options',options);
ms_ML = MultiStart('StartPointsToRun', 'bounds','UseParallel', 1, 'Display', 'off');
[params_est, RSS] = run(ms_ML, problem_ML, nrep);
% params_est = bads(fxn_getDev, params0, lb, ub); % did NOT work very well for PTM, at L7-9; work perfectly for LAM though

% make prediction
threshEnergy_pred = fxn_LAM(params_est, noiseEnergy);

% calculate R2
thresh_log = log10(sqrt(threshEnergy));
thresh_pred_log = log10(sqrt(threshEnergy_pred));
residual_log = weight.*(thresh_log-thresh_pred_log);
var_log = weight.*(thresh_log-mean(thresh_log));
Rsquared = 1-sumsqr(residual_log)/sumsqr(var_log); %Calculate r^2 of the fit based on the residuals
if abs(Rsquared)==Inf, Rsquared=0; end

%%
if flag_plot
    figure('Position', [100 100 800 400])
    subplot(1,2,1), hold on
    plot(noiseEnergy, threshEnergy, '--ko')
    plot(noiseEnergy, threshEnergy_pred, 'b-')
    xline(params_est(2), 'r-');
    xlabel('Noise Energy')
    ylabel('Thresh Energy')
    
    subplot(1,2,2), hold on
    plot(sqrt(noiseEnergy), sqrt(threshEnergy), '--ko')
    plot(sqrt(noiseEnergy), sqrt(threshEnergy_pred), 'b-')
    xline(sqrt(params_est(2)), 'r-');
    xlabel('Noise (SD)')
    ylabel('Thresh (SD)')
    
    sgtitle(sprintf('[LAM] R2=%.2f', Rsquared))
end
end