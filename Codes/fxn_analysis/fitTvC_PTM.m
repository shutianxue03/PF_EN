% function [params_est, threshEnergy_pred, RSS, Rsquared] = fitTvC_PTM(indParamIncl, noiseEnergy, threshEnergy, dprimes, params0_def, lb_def, ub_def, flag_weightedFitting, nData_perLoc, flag_plot)
% % Purpose: Fit the PTM to data that are the contrast energy at threshold as a function of noise energy.
% %Inputs:
% %           noiseEnergy the noise energy (i.e., noise rms contrast ^ 2)
% %           threshEnergy: the contrast energy at threshold (squared noise SD)
% %           dprimes: dprimes corresponding to the performance levels
% %           params0: initial values
% %           lb: lower bound
% %           ub: upper bound
% 
% warning off
% options = optimoptions('fmincon','MaxIterations', 5000,'Display','off');
% nrep = 20;
% 
% nPerf = length(dprimes);
% nNoise = length(noiseEnergy);
% % [nLoc, nNoise, nPerf] = size(threshEnergy);
% if size(threshEnergy, 1) ~= nPerf, threshEnergy=threshEnergy'; end
% 
% % calculate weight
% nData_perLoc_ = repmat(nData_perLoc, size(threshEnergy, 1), 1);
% % if flag_weightedFitting, weight = nData_perLoc_(:)/sum(nData_perLoc_(:));
% if flag_weightedFitting, weight = nData_perLoc_(:);
% else, weight = ones(size(nData_perLoc_)); %weight = weight(:)/sum(weight(:));
% end
% % assert(abs(sum(weight(:))-1)<1e-8)
% 
% % define function
% fxn_getDev = @(params) sumsqr((fxn_PTM_allPerf(indParamIncl, dprimes, noiseEnergy, params) - threshEnergy(:)) .* weight);
% 
% % define initial point, upper and lower bounds
% % params0 = [.25, 5, .005, 2.5]; % Nmul, gamma, sigma_add, beta, (beta2)
% % lb = [0,0,0,0];
% % ub = [1/max(dprimes), 10, .2, 5]; % ub of Nmul is determined to enforce the denominator to be positive (Nmul<1/dprime_max)
% 
% % fit
% problem_ML = createOptimProblem('fmincon','objective', fxn_getDev,'x0',params0,'lb',lb,'ub',ub,'options',options);
% ms_ML = MultiStart('StartPointsToRun', 'bounds','UseParallel', 1, 'Display', 'off');
% [params_est, RSS] = run(ms_ML, problem_ML, nrep);
% % [params_est, RSS] = bads(fxn_getDev, params0, lb, ub); % did NOT work very well for PTM, at L7-9; work perfectly for LAM though
% 
% % make prediction
% threshEnergy_pred = fxn_PTM_allPerf(indParamIncl, dprimes, noiseEnergy, params_est);
% threshEnergy_pred = reshape(threshEnergy_pred, [nPerf, nNoise]);
% 
% % calculate (weighted) R2
% Rsquared = nan(1, nPerf);
% thresh_log = log10(sqrt(threshEnergy));
% thresh_pred_log = log10(sqrt(threshEnergy_pred));
% 
% for iperf = 1:nPerf
%     residual_log = weight.*(thresh_log(iperf ,:)-thresh_pred_log(iperf ,:));
%     var_log = weight.*(thresh_log(iperf ,:)-mean(thresh_log(iperf ,:)));
%     Rsquared(iperf) = 1-sumsqr(residual_log)/sumsqr(var_log); %Calculate r^2 of the fit based on the residuals
%     if abs(Rsquared(iperf))==Inf, Rsquared(iperf)=0; end
% end
% 
% %%
% if flag_plot
%     figure('Position', [100 100 800 400])
%     subplot(1,2,1), hold on
%     plot(noiseEnergy, threshEnergy, '--ko')
%     plot(noiseEnergy, threshEnergy_pred, 'b-')
%     xlabel('Noise Energy')
%     ylabel('Thresh Energy')
%     
%     subplot(1,2,2), hold on
%     plot(sqrt(noiseEnergy), sqrt(threshEnergy), '--ko')
%     plot(sqrt(noiseEnergy), sqrt(threshEnergy_pred), 'b-')
%     xlabel('Noise (SD)')
%     ylabel('Thresh (SD)')
%     
%     sgtitle(sprintf('[PTM] R2=%.2f, %.2f, %.2f', Rsquared))
% end
% end
% 
