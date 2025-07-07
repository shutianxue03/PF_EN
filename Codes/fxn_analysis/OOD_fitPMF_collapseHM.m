% 
% function [cst_log_unik, nCorr, nData, pC, yfit_allB, PSE_allB, converged_allB, LL_allB, slope_allB, guess_allB, lapse_allB, estP_allB, PSE_LHM_allB, PSE_RHM_allB] = OOD_fitPMF_collapseHM(ccc_full1, ccc_full2, fit, thresh_log_stair)
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % ONLY FIT CUM-GAUSS function (to save time)!
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% % Input: ccc_full [4 columns]: 1=Loc, 2=noise level, 3=cst, 4=correctness
% close all, clc
% SX_analysis_setting
% warning off
% flag_print = 0;
% nBoot = fit.nBoot;
% flag_binData = fit.flag_binData;
% flag_filterData = fit.flag_filterData;
% 
% figure('Position', [ 0 0 1200 500])
% subplot(1,2,1), hold on
% for iLocHM = 1:3 % 1=left, 2=right,3=collapse
%     switch iLocHM
%         case 1, ccc_full = ccc_full1; colorHM = 'r';
%         case 2, ccc_full = ccc_full2; colorHM = 'b';
%         case 3, ccc_full = [ccc_full1;ccc_full2]; colorHM = 'k';
%     end
%     
%     cst_log_full = log10(ccc_full(:, 3));
%     corr_full = ccc_full(:, 4);
%     curveX_log  = log10(fit.curveX);
%     
%     %% get unique contrast levels and corresponding pC
%     if flag_binData
%         nBins = fit.nBins; % defined in SX_analysis_setting
%         [N, ~, indBin] = histcounts(cst_log_full, nBins);
%         cst_log_unik = []; nCorr = []; nData = [];
%         for iBin = 1:nBins
%             if N(iBin)>0
%                 cst_log_unik = [cst_log_unik, mean(cst_log_full(indBin==iBin))];
%                 nCorr = [nCorr, nansum(corr_full(indBin==iBin))];
%                 nData = [nData, nansum(indBin==iBin)]; assert(nansum(indBin==iBin) == N(iBin))
%             end
%         end
%         assert(length(cst_log_unik) == sum(N>0))
%     else
%         cst_log_unik = unique(cst_log_full);
%         nCorr = nan(length(cst_log_unik), 1); nData=nCorr;
%         for icst_unik = 1:length(cst_log_unik)
%             indCST = cst_log_full==cst_log_unik(icst_unik);
%             nCorr(icst_unik) = nansum(corr_full(indCST));
%             nData(icst_unik) = nansum(indCST==1);
%         end % icst_unik
%         cst_log_unik = cst_log_unik';
%         nCorr = nCorr';
%         nData = nData';
%     end
%     
%     pC = nCorr./nData;
%     
%     %% empty containers
%     yfit_allB = nan(nBoot, nModels, length(curveX_log));
%     PSE_allB = nan(nBoot, nModels,nPerf);
%     converged_allB = nan(nBoot, nModels);
%     LL_allB = converged_allB;
%     slope_allB = converged_allB;
%     guess_allB = converged_allB;
%     lapse_allB = converged_allB;
%     estP_allB = nan(nBoot, nModels,fit.nParams);
%     
%     %%
%     if flag_filterData
%         % remove data with pC <.4 and when cst<2% pC>.65
%         ind_noise = (pC<=.4) | (pC>.7 & cst_log_unik < thresh_log_stair);
%         ind=boolean(1-ind_noise);
%         cst_log_unik = cst_log_unik(ind);
%         nCorr = nCorr(ind);
%         nData = nData(ind);
%         pC = pC(ind);
%         
%         cst_log_unik = [-3, -2.5, cst_log_unik];
%         nCorr = [15 15 nCorr];
%         nData = [30 30 nData];
%         
%         if flag_print, fprintf('[Removed ~%.0f%% trials] ...', 100*mean(1-ind)), end
%     end
%     
%     %% fit PF
%     %     if iLocHM==3
%     for iModel = 2%1:nModels
%         if flag_print, fprintf('%s...', PMF_models{iModel}), end
%         switch iModel
%             case 1, fit.PF = @PAL_Logistic;
%             case 2, fit.PF = @PAL_CumulativeNormal;
%             case 3, fit.PF = @PAL_Gumbel;
%             case 4, fit.PF = @PAL_Weibull;
%         end
%         
%         % adjust the format of cst (linear/log)
%         searchGrid = fit.searchGrid;
%         if iModel==4, cst_fit = 10.^cst_log_unik; cst_fineG = 10.^curveX_log;  searchGrid.alpha = 10.^fit.searchGrid.alpha; % weibull fit to linear values
%         else, cst_fit = cst_log_unik; cst_fineG = curveX_log; searchGrid.alpha = fit.searchGrid.alpha;
%         end
%         
%         % estimate parameters
%         [paramVals] = PAL_PFML_Fit(cst_fit, nCorr, nData, ...
%             searchGrid, fit.paramsFree, fit.PF,'SearchOptions',fit.options,'LapseLimits',fit.lapseLimits,'GuessLimits',fit.guessLimits);
%         
%         % calculate goodness of fit
% %         [Dev, pDev, DevSim, converged] = PAL_PFML_GoodnessOfFit(cst_fit, nCorr, nData, ...
% %             paramVals, fit.paramsFree, fit.nBoot, fit.PF,'LapseLimits',fit.lapseLimits,'GuessLimits',fit.guessLimits);
% %         'Dev': Deviance (transformed likelihood ratio comparing fit of PMF to fit of saturated model)
% %         'pDev': proportion of the B Deviance values from simulations that were greater than Deviance value of data. 
% %                     The greater the value of pDev, the better the fit.
% %         'DevSim': vector containing all B simulated Deviance values.
% 
%         % conduct bootstrapping
%         [~, paramVals, LL, converged] = PAL_PFML_BootstrapParametric(cst_fit, nData, ...
%             paramVals, fit.paramsFree, fit.nBoot, fit.PF,'LapseLimits',fit.lapseLimits,'GuessLimits',fit.guessLimits);
%         
%         
%         if flag_print, fprintf(' (%.0f%%) ', mean(converged == 1)*100), end
%         
%         % estimate PSE
%         for iB = 1:fit.nBoot
%             if isnan(paramVals(iB, 2)), paramVals(iB, 2) = Inf; end
%             
%             % save predicted pC
%             yfit_allB(iB, iModel, :) = fit.PF(paramVals(iB, :), cst_fineG);
%             
%             % save estimated PSE
%             for iPerf = 1:nPerf
%                 perfPSE = perfPSE_all(iPerf)/100;
%                 
%                 PSE = fit.PF(paramVals(iB, :), perfPSE, 'Inverse');
%                 if PSE == -Inf, PSE=nan; end
%                 if iModel==4, if PSE<=0, error('ALERT: PSE is negative cannot take log10!!'); end, PSE=log10(PSE); end
%                 PSE_allB(iB, iModel, iPerf) = PSE;
%             end
%         end % iPerf
%         
%         switch iLocHM
%             case 1, PSE_LHM_allB = PSE_allB;
%             case 2, PSE_RHM_allB = PSE_allB;
%         end
%         converged_allB(:, iModel) = converged;
%         LL_allB(:, iModel) = LL;
%         slope_allB(:, iModel) = paramVals(:, 2) * ((1-.5)./sqrt(2.*pi)); % according to Strasburger 2001 eq.18
%         guess_allB(:, iModel) = paramVals(:, 3);
%         lapse_allB(:, iModel) = paramVals(:, 4);
%         estP_allB(:, iModel, :) = paramVals;
%         
%     end % im=1:nModels
%     %     end % if iLocHM==3
%     quickPlot_PMF_collapseHM
% end % iLoc
% 
