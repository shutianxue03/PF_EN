
clc, close all
%----------------%
SX_analysis_setting
SX_fitTvC_setting
%----------------%
text_locType = 'combLoc';
nCand_max = 16;

%     indCand_plot = [15, 16, 10, 13];
indCand_plot = 13:16;
indCand_plot = [15, 16];
indParamIncl_allCand = fxn_getIndParamIncl(nLF_PTM, [0,1]); % Generate inclusion combinations
nCand_plot = length(indCand_plot);
namesGoF = {'R2', 'AIC', 'AICc', 'BIC'}; nGoF = length(namesGoF);
namesGoF = {'R2', 'BIC'}; nGoF = length(namesGoF);
namesAllCand = cell(1, nCand_max);
namesAllCand{13} = 'no Nmul no Gamma'; %[0011]
namesAllCand{14} = 'no Gamma'; %[1011]
namesAllCand{15} = 'No Nmul';%[0,1,1,1];
namesAllCand{16} = 'Full'; %[1,1,1,1];

% Empty containers
indSubj_acrossSF = [];
indSF_acrossSF = [];
AIC_nestedMC_acrossSF = []; % nsubj_full x nLocGroup x nCand
AICc_nestedMC_acrossSF = AIC_nestedMC_acrossSF ;
BIC_nestedMC_acrossSF = AIC_nestedMC_acrossSF ;
R2_nestedMC_acrossSF = AIC_nestedMC_acrossSF ;

for SF_load = SF_load_all
    %------------
    fxn_loadSF
    %------------
    load(nameFile_nestedMC_allSubj, '*nestedMC_allSubj')

    SF = SF_load; SF(SF==51) = 5;
    indSubj_acrossSF = [indSubj_acrossSF, isubj_ANOVA];
    indSF_acrossSF = [indSF_acrossSF, ones(1, nsubj) * SF];

    % convert negative/inf/nan values in R2 to 0
    R2_nestedMC_allSubj(R2_nestedMC_allSubj<0)=0;
    R2_nestedMC_allSubj(R2_nestedMC_allSubj==inf)=0;
    R2_nestedMC_allSubj(isnan(R2_nestedMC_allSubj))=0;

    R2_nMC = squeeze(R2_nestedMC_allSubj(:, :, indCand_plot));
    RSS_nMC = squeeze(RSS_nestedMC_allSubj(:, :, indCand_plot));
    nParams_nMC = nan(size(RSS_nMC)); for iIndLoc=1:nIndLoc_s, nParams_nMC(:, iIndLoc, :) = nParams_nestedMC_allSubj(:, indCand_plot); end
    nData_nMC = nan(size(RSS_nMC)); for iiCand=1:nCand_plot, nData_nMC(:, :, iiCand) = nData_nestedMC_allSubj; end

    AIC_nestedMC_acrossSF = cat(1, AIC_nestedMC_acrossSF, fxn_getAIC(RSS_nMC, nData_nMC, nParams_nMC));
    AICc_nestedMC_acrossSF = cat(1, AICc_nestedMC_acrossSF, fxn_getAICc(RSS_nMC, nData_nMC, nParams_nMC));
    BIC_nestedMC_acrossSF = cat(1, BIC_nestedMC_acrossSF, fxn_getBIC(RSS_nMC, nData_nMC, nParams_nMC));
    R2_nestedMC_acrossSF = cat(1, R2_nestedMC_acrossSF, R2_nMC);
end %SF

nsubj_full = length(indSubj_acrossSF);
GoF_allSubj_acrossSF = {R2_nestedMC_acrossSF, AIC_nestedMC_acrossSF, AICc_nestedMC_acrossSF, BIC_nestedMC_acrossSF};

% Empty containers for ANOVA
indLoc_ANOVA = nan(size(R2_nestedMC_acrossSF));
indCand_ANOVA = indLoc_ANOVA;
indSF_ANOVA = indLoc_ANOVA;
indSubj_ANOVA = indLoc_ANOVA;

% Append index of ANOVA factors
for iiIndLoc_s = 1:nIndLoc_s

    for iiCand=1:nCand_plot
        indSubj_ANOVA(:, iiIndLoc_s, iiCand) = indSubj_acrossSF;
        indSF_ANOVA(:, iiIndLoc_s, iiCand) = indSF_acrossSF;
        indLoc_ANOVA(:, iiIndLoc_s, iiCand) = ones(nsubj_full, 1)*iiIndLoc_s;
        indCand_ANOVA(:, iiIndLoc_s, iiCand) = ones(nsubj_full, 1)*iiCand;
    end
end % iiIndLoc_s

%% ANOVA for each GoF
IV_single_all = {'Cand', 'SF', 'LocGroup'};
for iGoF=1:nGoF
    dataTable = table(indCand_ANOVA(:), indSubj_ANOVA(:), indSF_ANOVA(:), indLoc_ANOVA(:), GoF_allSubj_acrossSF{iGoF}(:), ...
        'VariableNames', {'Cand', 'Subj', 'SF', 'LocGroup', 'GoF'});

    y_label = namesGoF{iGoF};

    %% Conduct Linear Mixed Model
    flag_printLMM = 1; flag_plotLMM= 1;
    nameFolder_fig_LMM = sprintf('%s/LMM/%s', nameFolder_fig_MCnested, y_label); mkdir(nameFolder_fig_LMM)
    formula = 'GoF ~ Cand * SF * LocGroup + (1|Subj)';
    %----------------------------%
    lme = fitlme(dataTable, formula);
    str_LMM = fxn_printLMM3(lme, dataTable, dataTable.GoF, flag_printLMM, flag_plotLMM, nameFolder_fig_LMM);
    %----------------------------%

    %% Conduct ANOVA
    nameFolder_fig_ANOVA = sprintf('%s/ANOVA/%s', nameFolder_fig_MCnested, y_label);
    %--------------------------------------------------------------------------------
    fxn_printANOVA_MulComp(dataTable, IV_single_all, dataTable.GoF, y_label, '', nameFolder_fig_ANOVA)
    %--------------------------------------------------------------------------------
end % iGoF
