
% % Setting
% clear *allLocN params
% switch str_SF
%     case '456'
%         SF_load_all = [4, 51, 5, 6]; SF_all = 4:6; namesSF = {'SF4', 'SF5', 'SF6'}; markers_allSF = {'s', 'pentagram', 'hexagram'}; 
%     case '46'
%         SF_load_all = [4, 6]; SF_all = SF_load_all; namesSF = {'SF4', 'SF6'}; markers_allSF = {'s', 'hexagram'}; 
% end
% nSF = length(namesSF);
nameFolder_Fig_Main = sprintf('Fig/acrossSFs/SF%s', str_SF);

%% ANOVA on Thresholds: 
clc
flag_plotANOVA = 0;
nameFolder_Fig_Thresh = sprintf('%s/Thresholds', nameFolder_Fig_Main);
% Eccentricity effect, HVA and VMA
% Loc x SF x NoiseLevels x PerfLevels on Thresholds (eccentricity effect, HVA/VMA at EACH ecc separately)
%----------------------%
SXplot_Thresholds_Ecc
%----------------------%

clc
% ANOVA on Thresholds: HVA and VMA
% Ecc x Polar x SF x NoiseLevels x PerfLevels on Thresholds
%----------------------%
SXplot_Thresholds_EccPolar
%----------------------%

%% Nested Model Comparison
% Examine whether the full PTM model fits better than reduced models
if flag_nestedMC
    nameFolder_fig_MCnested = sprintf('%s/MC/MC_Nested', nameFolder_Fig_Main);
    %------------------%
    SXplot_NestedMC
    %------------------%
end

%% Vary-Location Model Comparison
if flag_varyLocMC
    nameFolder_fig_MCvaryLoc = sprintf('%s/MC/MC_VaryLoc', nameFolder_Fig_Main);
    flag_plotVaryLocMC = 0;
    flag_plotVaryLocMC_Idvd = 0;
    
    %------------------%
    SXplot_VaryLocMC
    %------------------%
end
% Output: IndCand_GroupBest_all4_SF456 ot SF46 (nTvC x nLoc7 x nLoc_s x nGoF)

%% LAM vs. PTM fitting (as a fxn of TvC model, locGroup and SF)
% Must have run the analysis part of 'SXplot_VaryLocMC'
if flag_varyLocMC
    nameFolder_fig_MC_LAMPTM = sprintf('%s/MC/MC_LAMPTM', nameFolder_Fig_Main);
    %------------------%
    SXplot_LAMvsPTM
    %------------------%
end

%% PLOT TvCs and PTM PARAMETERS
if flag_BestSimplestFitting
    % indLoc_s_all should not be changed!! Because the value of iiIndLoc_s is fixed
    indLoc_s_all = {[1,2,3], [1,4,8], [1,5,9], [4,5], [6,7], [8,9], [10,11]}; nIndLoc_s = length(indLoc_s_all); % Total number of location groups
    nameFolder_fig_PF = sprintf('%s/PF', nameFolder_Fig_Main);
    
    flag_plot_TvC = 1;
    flag_plot_ANOVA = 0; flag_multComp = 'Manual'; % 'MatlabFxn' and 'Manual', takes effect in fxn_plotMultipleComp
    flag_plot_contribution = 0;
    flag_plot_Corr = 0;
    flag_plot_CorrAsym = 0;
    
    %------------------%
    % SXplot_BestSimplest
    %------------------%

    %------------------%
    SXplot_BestSimplest_forPRE3
    %------------------%
    
    %-----------------------%
    % SXplot_compParamsRep
    %-----------------------%
end

fprintf('\n=============== DONE ===============\n')

%% Correlation between LAM and PTM params
%------------------%
SXplot_corrLAMPTM
%------------------%


