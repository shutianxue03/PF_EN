clc
%----------------%
SX_fitTvC_setting
%----------------%

ecc_all = [4,8]; polar_all = [1,2];
indLoc_s_all = {[4,5,8,9], [6,7,10,11]}; nIndLoc_s = length(indLoc_s_all);
nEcc = length(ecc_all); nPolar = length(polar_all);
% iEcciPolar_all = flip(combvec(polar_all, 1:nEcc))';
% iEcciPolar_all = {[1,1], [1,2]; [2,1], [2,2]};
for iiIndLoc_s = 1:nIndLoc_s
    indLoc_s = indLoc_s_all{iiIndLoc_s};
    indLoc_s_mat = reshape(indLoc_s, nEcc, nPolar)';
    nLoc_s = length(indLoc_s);
    namesCombLoc_s = namesCombLoc(indLoc_s);
    str_LocSelected = []; for iiLoc = 1:nLoc_s, str_LocSelected = sprintf('%s%s', str_LocSelected, namesCombLoc_s{iiLoc});end

    fprintf('\n%s\n', str_LocSelected)

    indSubj_allSF = [];
    indEcc_allSF = indSubj_allSF;
    indPolar_allSF = indSubj_allSF;
    indSF_allSF = indSubj_allSF;
    indNoise_allSF = indSubj_allSF;
    indPerf_allSF = indSubj_allSF;
    threshN0_log_allSF = indSubj_allSF;

    for SF_load = SF_load_all
        %------------
        fxn_loadSF
        %------------
        load(nameFile_fitTvC_allSubj, 'thresh_log_allSubj')

        indSubj = nan(nsubj, nEcc, nPolar, nNoise, nPerf);
        indEcc = indSubj;
        indPolar = indSubj;
        indSF = indSubj;
        indNoise = indSubj;
        indPerf = indSubj;
        threshN0_log = indSubj;

        SF = SF_load; SF(SF==51)=5;
        for isubj_acrossSF=1:nsubj
            for iEcc=1:nEcc
                for iPolar=1:nPolar
                    for iNoise=1:nNoise
                        for iPerf=1:nPerf
                            indSubj(isubj_acrossSF, iEcc, iPolar, iNoise, iPerf) = isubj_ANOVA(isubj_acrossSF);
                            indSF(isubj_acrossSF, iEcc, iPolar, iNoise, iPerf) = SF;
                            indEcc(isubj_acrossSF, iEcc, iPolar, iNoise, iPerf) = ecc_all(iEcc);
                            indPolar(isubj_acrossSF, iEcc, iPolar, iNoise, iPerf) = polar_all(iPolar);
                            indNoise(isubj_acrossSF, iEcc, iPolar, iNoise, iPerf) = noiseSD_full(iNoise);
                            indPerf(isubj_acrossSF, iEcc, iPolar, iNoise, iPerf) = perfThresh_all(iPerf);
                            threshN0_log(isubj_acrossSF, iEcc, iPolar, iNoise, iPerf) = thresh_log_allSubj(isubj_acrossSF, indLoc_s_mat(iEcc, iPolar), iNoise, iPerf);
                        end
                    end
                end
            end
        end

        indSubj_allSF = [indSubj_allSF; indSubj(:)];
        indEcc_allSF = [indEcc_allSF; indEcc(:)];
        indPolar_allSF = [indPolar_allSF; indPolar(:)];
        indSF_allSF = [indSF_allSF; indSF(:)];
        indNoise_allSF = [indNoise_allSF; indNoise(:)];
        indPerf_allSF = [indPerf_allSF; indPerf(:)];
        threshN0_log_allSF = [threshN0_log_allSF; threshN0_log(:)];

    end % SF_load

    % construct a table
    dataTable = table(indSubj_allSF, indPolar_allSF, indEcc_allSF, indSF_allSF, indNoise_allSF, indPerf_allSF, threshN0_log_allSF, ...
        'VariableNames', {'Subj',  'Polar', 'Ecc',  'SF', 'NoiseSD', 'PerfLevel', 'Thresh'});

    %% Conduct Linear Mixed Model
    flag_printLMM = 1; flag_plotLMM= 1;
    nameFolder_fig_LMM = sprintf('%s/LMM/%s', nameFolder_Fig_Thresh, str_LocSelected); mkdir(nameFolder_fig_LMM)

    formula = 'Thresh ~ Polar * Ecc * SF * NoiseSD + (1|Subj)';
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
        IV_single_all = {'SF', 'Ecc', 'Polar'};
        nameFolder_fig_ = sprintf('%s/ANOVA/%s/%s', nameFolder_Fig_Thresh, str_LocSelected, strjoin(IV_single_all, 'x')); mkdir(nameFolder_fig_)
        diary(sprintf('%s/Posthoc.txt', nameFolder_fig_)) % Starts saving output to 'output.txt
        %--------------------------------------------------------------------------------
        fxn_printANOVA_MulComp(dataTable, IV_single_all, paramData, y_label, title_, nameFolder_fig_)
        %--------------------------------------------------------------------------------
        diary off; clc

        % Include noise level but not SF
        IV_single_all = {'Ecc' 'Polar', 'NoiseSD'};
        nameFolder_fig_ = sprintf('%s/ANOVA/%s/%s', nameFolder_Fig_Thresh, str_LocSelected, strjoin(IV_single_all, 'x')); mkdir(nameFolder_fig_)
        diary(sprintf('%s/Posthoc.txt', nameFolder_fig_)) % Starts saving output to 'output.txt
        %--------------------------------------------------------------------------------
        fxn_printANOVA_MulComp(dataTable, IV_single_all, paramData, y_label, title_, nameFolder_fig_)
        %--------------------------------------------------------------------------------
        diary off; clc


        % % Include SF but not noise level
        % IV_single_all = {'SF', 'Ecc', 'PerfLevel', 'Polar'};
        % nameFolder_fig_ = sprintf('%s/%s/%s', nameFolder_Fig_Thresh, str_LocSelected, strjoin(IV_single_all, 'x'));
        % diary(sprintf('%s/Posthoc.txt', nameFolder_fig_)) % Starts saving output to 'output.txt
        % %--------------------------------------------------------------------------------
        % fxn_printANOVA_MulComp(dataTable, IV_single_all, paramData, y_label, title_, nameFolder_fig_)
        % %--------------------------------------------------------------------------------
        % diary off; clc
        %
        % % Include noise level but not SF
        % IV_single_all = {'Ecc', 'PerfLevel', 'Polar', 'NoiseSD'};
        % nameFolder_fig_ = sprintf('%s/%s/%s', nameFolder_Fig_Thresh, str_LocSelected, strjoin(IV_single_all, 'x'));
        % diary(sprintf('%s/Posthoc.txt', nameFolder_fig_)) % Starts saving output to 'output.txt
        % %--------------------------------------------------------------------------------
        % fxn_printANOVA_MulComp(dataTable, IV_single_all, paramData, y_label, title_, nameFolder_fig_)
        % %--------------------------------------------------------------------------------
        %  diary off; clc
    end
end % indLoc_s

close all
fprintf('\n ================== Thresholds (Ecc x Polar) DONE ==================\n\n')