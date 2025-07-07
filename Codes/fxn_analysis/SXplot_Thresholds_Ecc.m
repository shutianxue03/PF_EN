%----------------%
SX_analysis_setting
SX_fitTvC_setting
%----------------%
indLoc_s_all = {[1,2,3], [1,4,8], [1,5,9]}; nIndLoc_s = length(indLoc_s_all); % Total number of location groups

for iiIndLoc_s = 1:nIndLoc_s
    indLoc_s = indLoc_s_all{iiIndLoc_s};
    nLoc_s = length(indLoc_s);
    namesCombLoc_s = namesCombLoc(indLoc_s);
    str_LocSelected = []; for iiLoc = 1:nLoc_s, str_LocSelected = sprintf('%s%s', str_LocSelected, namesCombLoc_s{iiLoc});end

    fprintf('\n *** %s ***\n', str_LocSelected)

    indSubj_acrossSF = [];
    indEcc_acrossSF = indSubj_acrossSF;
    indSF_acrossSF = indSubj_acrossSF;
    indNoise_acrossSF = indSubj_acrossSF;
    indPerf_acrossSF = indSubj_acrossSF;
    threshN0_log_acrossSF = indSubj_acrossSF;

    for SF_load = SF_load_all
        %------------
        fxn_loadSF
        %------------
        load(nameFile_fitTvC_allSubj, 'thresh_log_allSubj')

        SF = SF_load; SF(SF==51)=5;
        indSubj = nan(nsubj, nLoc_s, nNoise, nPerf);
        indEcc = indSubj;
        indSF = indSubj;
        indNoise = indSubj;
        indPerf = indSubj;
        threshN0_log = indSubj;

        for isubj_acrossSF=1:nsubj
            for iLocComb=1:nLoc_s
                for iNoise=1:nNoise
                    for iPerf=1:nPerf
                        indSubj(isubj_acrossSF, iLocComb, iNoise, iPerf) = isubj_ANOVA(isubj_acrossSF);
                        indEcc(isubj_acrossSF, iLocComb, iNoise, iPerf) = iLocComb;
                        indSF(isubj_acrossSF, iLocComb, iNoise, iPerf) = SF;
                        indNoise(isubj_acrossSF, iLocComb, iNoise, iPerf) = noiseSD_full(iNoise);
                        indPerf(isubj_acrossSF, iLocComb, iNoise, iPerf) = perfThresh_all(iPerf);
                        threshN0_log(isubj_acrossSF, iLocComb, iNoise, iPerf) = thresh_log_allSubj(isubj_acrossSF, indLoc_s(iLocComb), iNoise, iPerf);
                    end
                end
            end
        end

        indSubj_acrossSF = [indSubj_acrossSF; indSubj(:)];
        indEcc_acrossSF = [indEcc_acrossSF; indEcc(:)];
        indSF_acrossSF = [indSF_acrossSF; indSF(:)];
        indNoise_acrossSF = [indNoise_acrossSF; indNoise(:)];
        indPerf_acrossSF = [indPerf_acrossSF; indPerf(:)];
        threshN0_log_acrossSF = [threshN0_log_acrossSF; threshN0_log(:)];

    end % SF

    % Construct a table
    dataTable = table(indSubj_acrossSF, indEcc_acrossSF, indSF_acrossSF, indNoise_acrossSF, indPerf_acrossSF, threshN0_log_acrossSF, ...
        'VariableNames', {'Subj', 'Ecc', 'SF', 'NoiseSD', 'PerfLevel', 'Thresh'});

    %% Conduct Linear Mixed Model
    flag_printLMM = 1; flag_plotLMM= 1;
    nameFolder_fig_LMM = sprintf('%s/LMM/%s', nameFolder_Fig_Thresh, str_LocSelected); mkdir(nameFolder_fig_LMM)

    formula = 'Thresh ~ Ecc * SF * NoiseSD + (1|Subj)';
    %----------------------------%
    lme = fitlme(dataTable, formula);
    str_LMM = fxn_printLMM(lme, dataTable, dataTable.Thresh, flag_printLMM, flag_plotLMM, nameFolder_fig_LMM);
    %----------------------------%

    %% Conduct and visualize ANOVA & multiple comparison
    if flag_plotANOVA
        paramData = dataTable.Thresh;
        y_label = 'Thresh';
        title_ = str_LocSelected;

        % Include SF but not noise level
        IV_single_all = {'SF', 'Ecc'};
        nameFolder_fig_ = sprintf('%s/ANOVA/%s/%s', nameFolder_Fig_Thresh, str_LocSelected, strjoin(IV_single_all, 'x')); mkdir(nameFolder_fig_)
        diary(sprintf('%s/Posthoc.txt', nameFolder_fig_)) % Starts saving output to 'output.txt
        %--------------------------------------------------------------------------------
        fxn_printANOVA_MulComp(dataTable, IV_single_all, paramData, y_label, title_, nameFolder_fig_)
        %--------------------------------------------------------------------------------
        diary off; clc
        % Include noise level but not SF
        IV_single_all = {'Ecc', 'NoiseSD'};
        nameFolder_fig_ = sprintf('%s/ANOVA/%s/%s', nameFolder_Fig_Thresh, str_LocSelected, strjoin(IV_single_all, 'x')); mkdir(nameFolder_fig_)
        diary(sprintf('%s/Posthoc.txt', nameFolder_fig_)) % Starts saving output to 'output.txt
        %--------------------------------------------------------------------------------
        fxn_printANOVA_MulComp(dataTable, IV_single_all, paramData, y_label, title_, nameFolder_fig_)
        %--------------------------------------------------------------------------------
        diary off; clc

        % % Include SF but not noise level
        % IV_single_all = {'SF', 'PerfLevel', 'Ecc'};
        % nameFolder_fig_ = sprintf('%s/%s/%s', nameFolder_Fig_Thresh, str_LocSelected, strjoin(IV_single_all, 'x'));
        % diary(sprintf('%s/Posthoc.txt', nameFolder_fig_)) % Starts saving output to 'output.txt
        % %--------------------------------------------------------------------------------
        % fxn_printANOVA_MulComp(dataTable, IV_single_all, paramData, y_label, title_, nameFolder_fig_)
        % %--------------------------------------------------------------------------------
        % diary off; clc
        %
        % % Include noise level but not SF
        % IV_single_all = {'PerfLevel', 'Ecc', 'NoiseSD'};
        % nameFolder_fig_ = sprintf('%s/%s/%s', nameFolder_Fig_Thresh, str_LocSelected, strjoin(IV_single_all, 'x'));
        % diary(sprintf('%s/Posthoc.txt', nameFolder_fig_)) % Starts saving output to 'output.txt
        % %--------------------------------------------------------------------------------
        % fxn_printANOVA_MulComp(dataTable, IV_single_all, paramData, y_label, title_, nameFolder_fig_)
        % %--------------------------------------------------------------------------------
        % diary off; clc
    end
    close all

end % indLoc_s

fprintf('\n ================== Thresholds (Ecc Only) DONE ==================\n\n')
