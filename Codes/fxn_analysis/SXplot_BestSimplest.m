%----------------%
SX_fitTvC_setting
%----------------%
clc
text_locType = 'combLoc';
wd_bar = .5; buffer = .01;
switch str_SF, case 'SF456', SF_load_all = [4, 5, 6]; case 'SF46', SF_load_all = [4, 6]; end
iNoise_thresh = 1; % 1=the threshold at no noise

% 1{'Fov'}    2{'ecc4'}    3{'ecc8'}
% 4{'HM4'}    5{'VM4'}    6{'LVM4'}    7{'UVM4'}
% 8{'HM8'}    9{'VM8'}   10{'LVM8'}    11{'UVM8'}

% Load the optimal model
% load(sprintf('IndCand_GroupBest_all4_SF%s.mat', str_SF), 'IndCand_GroupBest_all4')

% for iTvCModel = 2%1:nTvC

switch iTvCModel
    case 1 % LAM
        y_ticks = ticks_LAM; y_ticklabels = ticklabels_LAM; namesLF = namesLF_LAM; namesLF_Labels = namesLF_Labels_LAM;
        iParams_all = 1:2; str_sgtitle = namesTvCModel{iTvCModel};

    case 2 % PTM
        str_sgtitle = sprintf('%s %s', namesTvCModel{iTvCModel}, nameModel);
        switch nameModel
            case 'NoNmul', y_ticks = ticks_PTM(2:4); y_ticklabels = ticklabels_PTM(2:4); iParams_all = 1:3; namesLF = namesLF_PTM(2:4); namesLF_Labels = namesLF_PTM(2:4);
            case 'FullModel', y_ticks = ticks_PTM; y_ticklabels = ticklabels_PTM;iParams_all = 1:4; namesLF = namesLF_PTM; namesLF_Labels = namesLF_PTM;
        end
end
nParams = length(iParams_all);

% Loop through each error type
% for iErrorType = 1%1:nErrorType; % namesErrorType = {'ErrLogCst'}    {'ErrLnCst'}    {'ErrLnEg'}

% Loop through each location group
for iiIndLoc_s = 1:nIndLoc_s

    %--------------------%
    % fxn_createLMMtable
    %--------------------%

    %% 0. TvC and Fitting
    if flag_plot_TvC
        SXplot_TvC
    end

    %% 1. Main effect of SF and Loc on each parameter
    if flag_plot_ANOVA

        clc

        IV_single_all = {'LocComb', 'SF'};
        wd_bar = .2;

        for iParam = iParams_all
            iCol = iParam+4;
            paramName = dataTable.Properties.VariableNames{iCol};
            DV = dataTable{:, iCol};

            % Conduct Linear Mixed Model
            flag_printLMM = 1; flag_plotLMM= 1;
            % nameFolder_fig_ANOVA = sprintf('%s/ANOVA_%s/%s', nameFolder_Fig_Thresh, strjoin(IV_single_all, 'x'), flag_multComp);
            nameFolder_fig_LMM = sprintf('%s/LMM', nameFolder_fig); mkdir(nameFolder_fig_LMM)
            formula = sprintf('%s ~ LocComb * SF + (1|Subj)', paramName);
            %----------------------------%
            lme = fitlme(dataTable, formula);
            str_LMM = fxn_printLMM(lme, dataTable, DV, flag_printLMM, flag_plotLMM, nameFolder_fig_LMM);
            %-------------------

            %% Multiple comparison using coefTest
            SF_unik_all = unique(dataTable.SF );
            loc_unik_all = unique(dataTable.LocComb);  % Extract unique LocComb values

            for SF_unik=SF_unik_all'
                ind_subset = dataTable.SF == SF_unik;
                dataTable_subset = dataTable(ind_subset, :);
                formula = sprintf('%s ~ LocComb + (1|Subj)', paramName);
                lmm_subset = fitlme(dataTable_subset, formula);
                fixed_effects = fixedEffects(lmm_subset);
                fixed_names = lmm_subset.CoefficientNames;  % Extract coefficient names

                % Create contrast matrix for pairwise tests
                % num_levels = length(fixed_effects) - 1;  % Exclude intercept
                contrast_matrix = eye(num_levels);  % Identity matrix for comparisons

                % Loop through all pairwise comparisons of LocComb levels
                for i = 1:length(loc_unik_all)-1
                    for j = i+1:length(loc_unik_all)
                        loc1 = loc_unik_all(i);
                        loc2 = loc_unik_all(j);

                        % Construct contrast vector
                        contrast_vector = zeros(1, length(fixed_names));

                        % Find indices of the coefficients corresponding to LocComb levels
                        idx1 = find(contains(fixed_names, sprintf('LocComb_%d', loc1)));
                        idx2 = find(contains(fixed_names, sprintf('LocComb_%d', loc2)));

                        % If categorical encoding is done with reference coding, adjust indexing
                        if isempty(idx1)  % This means LocComb_1 is used as the reference level
                            idx1 = 1; % Intercept corresponds to LocComb_1
                            contrast_vector(idx1) = 1; % Reference level (baseline)
                            contrast_vector(idx2) = -1; % Comparison level
                        elseif isempty(idx2)
                            idx2 = 1; % Intercept is the reference
                            contrast_vector(idx1) = 1;
                            contrast_vector(idx2) = -1;
                        else
                            contrast_vector(idx1) = 1;
                            contrast_vector(idx2) = -1;
                        end

                        % Conduct pairwise test
                        p_value = coefTest(lmm_subset, contrast_vector);
                        fprintf('Comparison LocComb %d vs %d at SF = %d: p-value = %.4f\n', loc1, loc2, SF_unik, p_value);
                    end
                end
            end

            loc_unik_all = unique(dataTable.LocComb);
            for loc_unik=loc_unik_all'
                ind_subset = dataTable.LocComb == loc_unik;
                dataTable_subset = dataTable(ind_subset, :);
                DV_subset = dataTable_subset{:, iCol};
                nameFolder_fig_LMM = sprintf('%s/LMM/Loc%d', nameFolder_fig, loc_unik); mkdir(nameFolder_fig_LMM)
                formula = sprintf('%s ~ SF + (1|Subj)', paramName);
                %----------------------------%
                lme_sub = fitlme(dataTable_subset, formula);
                str_LMM = fxn_printLMM(lme_sub, dataTable_subset, DV_subset, flag_printLMM, flag_plotLMM, nameFolder_fig_LMM);
            end
            close all

            %% Conduct and plot ANOVA & multiple comparison
            y_label = paramName;
            title_ = str_LocSelected;
            nameFolder_fig_ANOVA = sprintf('%s/ANOVA_%s/%s', nameFolder_fig, strjoin(IV_single_all, 'x'), flag_multComp);
            %--------------------------------------------------------------------------------
            fxn_printANOVA_MulComp(dataTable, IV_single_all, DV, y_label, title_, nameFolder_fig_ANOVA, flag_multComp)
            %--------------------------------------------------------------------------------

        end % iParam
        close all
    end % flag_plot_ANOVA

    %% 2. Contribution to Contrast Threshold (took Gamma gamma out)
    if flag_plot_contribution
    SXplot_contribution
    end

    %% 3. Corr between threshold and PTM params
    if flag_plot_Corr
        SXplot_corr
    end

    %% 4. Corr between asymmetries
    if flag_plot_CorrAsym
        SXplot_corrAsym
    end % if flag_plot_CorrAsym

    %% 5. corr between params and SF
    %         x = dataTable.SF;
    %         for iParam=1:3
    %         y = dataTable.(namesLF{iParam});
    %         figure, plot(x, y, 'o-')
    %         end
end % iiIndLoc_s

close all, clc

% end % iErrorType
% end % iTvC
