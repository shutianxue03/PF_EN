
clc; close all;

namesGoF = {'R2', 'RSS', 'AIC', 'AICc', 'BIC'}; nGoF = length(namesGoF);
IV_single_all = {'iTvC', 'SF','LocGroup'};
iGoF_plotIdvd = [1,4,5]; %  {'R2'}    {'RSS'}    {'AIC'}    {'AICc'}    {'BIC'}

assert(exist('indSubj_acrossSF', 'var')==1) % created in SXplot_VaryLocMC
assert(exist('indSF_acrossSF', 'var')==1)

% Iterate through GoF (and plot & conduct ANOVA per GoF)
for iGoF = 5%iGoF_plotIdvd

    y_label = namesGoF{iGoF};

    % Initialize variables for current GoF
    indTvC_ANOVA = [];         % TvC model indices
    indSubj_ANOVA = [];      % Subject indices
    indSF_ANOVA = [];        % Spatial frequency (SF) indices
    indLoc_ANOVA = [];       % Location group indices
    indErrType_ANOVA = []; % ErrorType
    GoF_GroupBest_ANOVA = []; % GoF values of group-best models

    % Loop through each error type
    for iErrorType = 1%1:nErrorType

        % Loop through TvC models and location groups
        for iTvCModel = 1:nTvC

            % Loop through each loc group
            for iiIndLoc_s = 1:nIndLoc_s

                % Append index of ANOVA factors
                indTvC_ANOVA = [indTvC_ANOVA; ones(nsubj_full, 1) * iTvCModel];
                indSubj_ANOVA = [indSubj_ANOVA; indSubj_acrossSF'];
                indSF_ANOVA = [indSF_ANOVA; indSF_acrossSF'];
                indLoc_ANOVA = [indLoc_ANOVA; ones(nsubj_full, 1) * iiIndLoc_s];

                % Extract GoF of the group-best candidate model
                IndCand_GroupBest = IndCand_GroupBest_all4{iTvCModel, iiIndLoc_s, iErrorType, iGoF};

                % Force the full model to be the best model
                if iTvCModel==1 % LAM
                    if iiIndLoc_s<=3, IndCand_GroupBest = 5^2; else, IndCand_GroupBest=2^2; end
                else % PTM
                    if iiIndLoc_s<=3, IndCand_GroupBest = 5^3; else, IndCand_GroupBest=2^3; end
                end
                GoF_GroupBest_ANOVA = [GoF_GroupBest_ANOVA; GoF_raw_all4{iTvCModel, iiIndLoc_s, iErrorType, iGoF}(:, IndCand_GroupBest)];
            end % iiIndLoc_s
        end % iTvCModel

    end % iErrorType

    % Create a table for ANOVA analysis
    dataTable = table(indTvC_ANOVA, indSubj_ANOVA, indSF_ANOVA, indLoc_ANOVA, GoF_GroupBest_ANOVA, ...
        'VariableNames', {'iTvC', 'Subj', 'SF', 'LocGroup', 'GoF_GroupBest'});

    %% Conduct Linear Mixed Model
    flag_printLMM = 1; flag_plotLMM= 1;
    nameFolder_fig_LMM = sprintf('%s/LMM/%s', nameFolder_fig_MC_LAMPTM, namesGoF{iGoF}); mkdir(nameFolder_fig_LMM)
    formula = 'GoF_GroupBest ~ iTvC * SF * LocGroup + (1|Subj)';
    %----------------------------%
    lme = fitlme(dataTable, formula);
    str_LMM = fxn_printLMM3(lme, dataTable, dataTable.GoF_GroupBest, flag_printLMM, flag_plotLMM, nameFolder_fig_LMM);

    %% Conduct and plot ANOVA & multiple comparison
    nameFolder_fig_ANOVA = sprintf('%s/ANOVA/%s', nameFolder_fig_MC_LAMPTM, namesGoF{iGoF});
    %--------------------------------------------------------------------------------
    fxn_printANOVA_MulComp(dataTable, IV_single_all, GoF_GroupBest_ANOVA, y_label, '', nameFolder_fig_ANOVA)
    %--------------------------------------------------------------------------------
end % iGoF

fprintf('\n\n ============== LAM vs. PTM MC Plotting DONE ==============\n\n')
