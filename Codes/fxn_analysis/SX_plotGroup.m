
iPerf_plot = 2;
%----------------%
SX_fitTvC_setting
%----------------%

clc, close all
if nNoise==2, indLoc = [4,5,3];
elseif nNoise>=7
    if nLocSingle==5, indLoc = [1,2,4,5,3]; % nNoise=7, n=6
    elseif nLocSingle==9, indLoc = [1,2,4,6,8,5,3,9,7]; % nNoise=7
    end
end

y_ticks_asym = linspace(-100, 100, 5);
thresh_asym_allSubj = nan(nsubj, nNoise, 10);

switch flag_locType
    case 1
        for iNoise = 1:nNoise
            %=====================================================================================
            [thresh_CombLoc_allSubj, namesCombLoc, asym_perNoise, namesAsym] = fxn_extractAsym(squeeze(thresh_log_allSubj(:, :, iNoise, iPerf_plot)));
            %=====================================================================================
            thresh_asym_allSubj(:, iNoise, 1:length(namesAsym)) = asym_perNoise;
        end
        
    case 2
        
        thresh_CombLoc_allSubj = thresh_log_allSubj;
end

%% fig 1: thresh as a fxn of loc and noise (each panel is a LOC)
if flag_locType==1, plotGroup1, end

%% fig 2: thresh as a fxn of loc and noise (each panel is a NOISE)
plotGroup2

%% fig 3: quantify asymmetries in thresh
if flag_locType==1, plotGroup3, end

%% fig 4: LAM/PTM parameters as a fxn of LOC (many figures!)
if flag_locType==1, plotGroup4, end

%% fig 5: TvC and LF of combined loc
plotGroup5

%% fig 6: threshold ratio (LuDosher1999)
% plotGroup6

%% Linear mixed model - test whether Neq and Eff can predict thresh
% clc
% diary(sprintf('%s/LMM', nameFolder_fig_allSubj))
%
% fprintf('\n\n*** Threshold predicted by Neq (+) and Eff (-) ***\n')
% for iasym = 1:nasym
%     tbl = table(thresh_CombLoc_allSubj{iasym}, Neq_CombLoc_allSubj{iasym}, Eff_CombLoc_allSubj{iasym},...
%         'VariableNames',{'Thresh','Neq', 'Eff'});
%     lme = fitlme(tbl, 'Thresh~Neq + Eff');
%     fprintf('\n%s:\n     %s: slope = %.2f, p = %.3f\n     %s: slope = %.2f, p = %.3f\n', ...
%         namesAsym{iasym}, ...
%         namesLF_short{1}, lme.Coefficients.Estimate(2),lme.Coefficients.pValue(2), ...
%         namesLF_short{2}, lme.Coefficients.Estimate(3), lme.Coefficients.pValue(3))
% end
%
% % with random effect
% fprintf('\n\n*** Threshold predicted by Neq (+) and Eff (-) (with random effect) ***\n')
% for iasym = 1:nasym
%     tbl = table(thresh_CombLoc_allSubj{iasym}, Neq_CombLoc_allSubj{iasym}, Eff_CombLoc_allSubj{iasym}, (1:nsubj)',...
%         'VariableNames',{'Thresh','Neq', 'Eff', 'indSubj'});
%     lme = fitlme(tbl, 'Thresh~Neq + Eff + (1|indSubj)');
%     fprintf('\n%s:\n     %s: slope = %.2f, p = %.3f\n     %s: slope = %.2f, p = %.3f\n', ...
%         namesAsym{iasym}, ...
%         namesLF_short{1}, lme.Coefficients.Estimate(2),lme.Coefficients.pValue(2), ...
%         namesLF_short{2}, lme.Coefficients.Estimate(3), lme.Coefficients.pValue(3))
% end
%
% %% Linear mixed model - test whether ASYMMETRY in Neq and Eff can predict that of thresh
% diary(sprintf('%s/LMM', nameFolder_fig_allSubj))
% fprintf('\n\n*** ASYM of threshold predicted by that of Neq (+) and Eff (-) [with rabdom effect] ***\n')
% for iasym = 1:nasym
%     tbl = table(squeeze(thresh_asym_allSubj(:, iasym)), Neq_asym_allSubj(:, iasym), Eff_asym_allSubj(:, iasym), (1:nsubj)',...
%         'VariableNames',{'Thresh_Asym','Neq_Asym', 'Eff_Asym', 'indSubj'});
%     lme = fitlme(tbl, 'Thresh_Asym ~ Neq_Asym + Eff_Asym+ (1|indSubj)');
%     fprintf('\n%s:\n     %s: slope = %.2f, p = %.3f\n     %s: slope = %.2f, p = %.3f\n', ...
%         namesAsym{iasym}, ...
%         namesLF_short{1}, lme.Coefficients.Estimate(2),lme.Coefficients.pValue(2), ...
%         namesLF_short{2}, lme.Coefficients.Estimate(3), lme.Coefficients.pValue(3))
% end
%
% diary off


