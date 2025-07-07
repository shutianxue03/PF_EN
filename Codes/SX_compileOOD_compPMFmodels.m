%%%% PERFORMANCE FIELDS ? EQUIVALENT NOISE %%%%

% 2018 by Antoine Barbot
% adapted by Shutian Xue in Feb, 2023

%%%%%%%%%%%%%%%%%%
% PRESENT STUDY: %
%%%%%%%%%%%%%%%%%%
% Use equivalent noise method and LAM model to characterize the functional
% sources of perceptual inefficiencies as a function of eccentricity and polar angle

clear all, close all, clc, format compact, commandwindow; % SX; force the cursor to go automatically to command window

% generate paths
addpath(genpath('Data_OOD/')); % SX
addpath(genpath('SX_toolbox/')); % SX
addpath(genpath('fxn_analysis/')); % SX

%% Load PMF and store LL of each PMF model
clc, clear all
load('Data/params.mat')
nBoot = 1e3;
flag_locType = 1; % 1=singleLoc, 2=combLoc
% ianalysisMode = 2; %[2, 1, 3, 4] % 1-2: Bin data; 1 and 3: filter data
flag_binData = 1;%analysisModes(ianalysisMode, 1);
flag_filterData = 1;%analysisModes(ianalysisMode, 2);
flag_n9 = 0; % 1=only include the shared 9 people (so str_SF must="SF456")

% For comparing left vs. right HM
iLoc_LR_all = [2,4,6,8]; %leftHM4, rightHM4, leftHM8, rightHM8
nLoc_LR = length(iLoc_LR_all);

str_SF = 'SF456'; flag_n9 = 0; % 1=only include the 9 shared subjects
% str_SF = 'SF46'; flag_n9 = 0; % 1=only include the 9 shared subjects
% str_SF = 'SF46'; flag_n9 = 1; % 1=only include the 9 shared subjects
str_n9 = ''; if flag_n9, str_n9='_n9'; end
str_folder = sprintf('Rscripts/DataTable/%s%s', str_SF, str_n9);
if isempty(dir(str_folder)), mkdir(str_folder), end

%------------------%
SX_analysis_setting
%------------------%
SF_all = [4, 51, 5, 6];

clc

for SF = SF_all % do NOT change to SF_load!!

    %--------------------%
    initAnalysis
    %--------------------%
    fprintf('\n    ===============================\n')
    fprintf('      n=%d [SF = %d] nNoise = %d\n      nBins = %d\n      nLoc = %d (single) + %d (HM)', nsubj, SF, nNoise, fit.nBins, nLocSingle, nLocHM)
    fprintf('\n    ===============================\n')

    SF_ = SF; SF_(SF_==51)=5;
    SF_fit = SF_;

    switch flag_locType
        case 1, text_locType = 'singleLoc'; nLoc = nLocSingle; colors_allLoc = colors_single; names_allLoc = namesSingleLoc; flag_plotIDVD=1;
        case 2, text_locType = 'combLoc'; nLoc = nLoc; colors_allLoc = colors_asym; names_allLoc = namesCombLoc; flag_plotIDVD=0;
    end

    % FOLDERS & FILES (group)
    nameFolder_dataOOD_load = sprintf('Data_OOD/nNoise%d/SF%s', nNoise, SF_str); if isempty(dir(nameFolder_dataOOD_load)), mkdir(nameFolder_dataOOD_load), end
    nameFolder_dataOOD_save = sprintf('Data_OOD/nNoise%d/SF%s', nNoise_save, SF_str); if isempty(dir(nameFolder_dataOOD_save)), mkdir(nameFolder_dataOOD_save), end
    nameFile_PMF_GoF_allSubj = sprintf('%s/n%d_PMF_B%d_constim%d_Bin%dFilter%d_%s_%s.mat', ...
        nameFolder_dataOOD_save, nsubj, nBoot, fit.nBins, flag_binData, flag_filterData, text_collapseHM, text_locType);

    % Create Empty Containers
    LL_PMF_allSubj = nan(nsubj, nLoc, nNoise, nModels);
    R2_PMF_allSubj = LL_PMF_allSubj;
    nData_PMF_allSubj = LL_PMF_allSubj;
    thresh_log_LR_allSubj = nan(nsubj, length(iLoc_LR_all), nNoise, nPerf);
   
    for isubj = 1:nsubj

        subjName = subjList{isubj};
        fprintf('\n\n******** %d/%d %s [Bin%d Filter%d] *********\n', isubj, nsubj, subjName, flag_binData, flag_filterData)

        % Load data
        nameFile_fitPMF = sprintf('%s/%s/%s_fitPMF_B%d_constim%d_Bin%dFilter%d.mat', nameFolder_dataOOD_load, subjName, subjName, nBoot, fit.nBins, flag_binData, flag_filterData);
        if isempty(nameFile_fitPMF), error('ALERT: Data does not exist!'),
        else, load(nameFile_fitPMF), fprintf('PMF Fitting LOADED\n')
        end

        %---------------%
        fxn_prepAnalysis
        %---------------%

        % Store R2, LL and ndata
        R2_weighted_allB(isnan(R2_weighted_allB)) = 0;
        R2_PMF_allSubj(isubj, :, :, :) = getCI(R2_weighted_allB, 1, 1); % GoF of each PMF model (they all have 2 parameters)
        LL_PMF_allSubj(isubj, :, :, :) = getCI(LL_allB, 1, 1); % GoF of each PMF model (they all have 2 parameters)
        for iModel = 1:nModels
            nData_PMF_allSubj(isubj, :, :, iModel) = nData_perLoc;
        end
        if flag_collapseHM==0
            thresh_log_LR_allSubj(isubj, :, :, :) = thresh_log(iLoc_LR_all, :, :);
        end
        assert(~isnan(any(thresh_log_LR_allSubj(:))), 'ALERT: NaN in thresh_log_LR_allSubj!!!')
    end % isubj

    % Calculate Delta BIC
    % fxn_getBIC_LL = @(LL, nData, nParams) nParams .* log(nData) + 2 * LL;
    BIC_PMF_allSubj = fxn_getBIC_LL(LL_PMF_allSubj, nData_PMF_allSubj, fit.nParams);

    % SAVE
    save(nameFile_PMF_GoF_allSubj, 'R2_PMF_allSubj', 'BIC_PMF_allSubj', 'thresh_log_LR_allSubj')
    clear *PMF_allSubj

end % SF

fprintf('\n\n======== DONE LOADING ========\n\n')


%% 1. Create a DataTable (just Weibull)
clc
%   DV: R2 and delta BIC
%   IV: PMFmodel (x4, all subj), loc (x9, all subj), noise level (x2, diff subj), SF (x3, diff subject)
flag_nestedMC = 0;% arbitary
flag_varyLocMC = 0;% arbitary
iTvCModel = 1; % arbitary
iErrorType = 1; % arbitary
SF_load_all = SF_all;
iPMF_best = 4; % Kudos to Weibull!

indSubj_acrossSF = [];
indLoc_acrossSF = indSubj_acrossSF;
indSF_acrossSF = indSubj_acrossSF;
indNoise_acrossSF = indSubj_acrossSF;
% indPMFm_acrossSF = indSubj_acrossSF; % m for PMF model
BIC_acrossSF = indSubj_acrossSF;
R2_acrossSF = indSubj_acrossSF;

for SF_load = SF_load_all
    %-----------
    fxn_loadSF
    %-----------
    % nameFile_PMF_allSubj = sprintf('%s/n%d_PMF_B%d_constim%d_Bin%dFilter%d_%s_%s.mat', ...
    %     nameFolder_dataOOD_save, nsubj, nBoot, fit.nBins, flag_binData, flag_filterData, text_collapseHM, text_locType);
    % load(nameFile_PMF_allSubj, '*PMF_allSubj')
    nameFile_PMF_GoF_allSubj = sprintf('%s/n%d_PMF_B%d_constim%d_Bin%dFilter%d_%s_%s.mat', ...
        nameFolder_dataOOD_save, nsubj, nBoot, fit.nBins, flag_binData, flag_filterData, text_collapseHM, text_locType);
    load(nameFile_PMF_GoF_allSubj, '*PMF_allSubj')

    SF = SF_load; SF(SF==51)=5;
    SF_fit = SF;

    indSubj = nan(nsubj, nLocSingle, nNoise);
    indLoc = indSubj;
    indSF = indSubj;
    indNoise = indSubj;
    % indPMFm = indSubj; % m for PMF model
    BIC = indSubj;
    R2 = indSubj;

    for isubj=1:nsubj
        for iLoc=1:nLocSingle
            for iNoise=1:nNoise
                % for iPMF=1:nModels
                indSubj(isubj, iLoc, iNoise) = isubj_ANOVA(isubj);
                indLoc(isubj, iLoc, iNoise) = iLoc;
                indSF(isubj, iLoc, iNoise) = SF;
                indNoise(isubj, iLoc, iNoise) = noiseSD_full(iNoise);
                % indPMFm(isubj, iLoc, iNoise, iPMF) = iPMF;
                BIC(isubj, iLoc, iNoise) = BIC_PMF_allSubj(isubj, iLoc, iNoise, iPMF_best);
                R2(isubj, iLoc, iNoise) = R2_PMF_allSubj(isubj, iLoc, iNoise, iPMF_best);
                % end
            end
        end
    end

    indSubj_acrossSF = [indSubj_acrossSF; indSubj(:)];
    indLoc_acrossSF = [indLoc_acrossSF; indLoc(:)];
    indSF_acrossSF = [indSF_acrossSF; indSF(:)];
    indNoise_acrossSF = [indNoise_acrossSF; indNoise(:)];
    % indPMFm_acrossSF = [indPMFm_acrossSF; indPMFm(:)];
    BIC_acrossSF = [BIC_acrossSF; BIC(:)];
    R2_acrossSF = [R2_acrossSF; R2(:)];

end % SF

% Construct a table
dataTable = table(...
    categorical(indSubj_acrossSF), ...
    categorical(indLoc_acrossSF), ...
    categorical(indSF_acrossSF), ...
    categorical(indNoise_acrossSF), ...
    double(BIC_acrossSF), ...
    double(R2_acrossSF), ...
    'VariableNames', {'Subj', 'Loc', 'SF', 'NoiseSD', 'BIC', 'R2'});
% writetable(dataTable, 'Rscripts/dataTable/dataTable_PMF_GoF_Weibull.csv')
writetable(dataTable, sprintf('%s/PMF_GoF_Weibull.csv', str_folder))

fprintf('\n\n======== DONE SAVING ========\n\n')

%% 2. Create a DataTable (all 4 PMF models)
clc
%   DV: R2 and delta BIC
%   IV: PMFmodel (x4, all subj), loc (x9, all subj), noise level (x2, diff subj), SF (x3, diff subject)
flag_nestedMC = 0;% arbitary
flag_varyLocMC = 0;% arbitary
iTvCModel = 1; % arbitary
iErrorType = 1; % arbitary
SF_load_all = SF_all;

indSubj_acrossSF = [];
indLoc_acrossSF = indSubj_acrossSF;
indSF_acrossSF = indSubj_acrossSF;
indNoise_acrossSF = indSubj_acrossSF;
indPMFm_acrossSF = indSubj_acrossSF; % m for PMF model
BIC_acrossSF = indSubj_acrossSF;
R2_acrossSF = indSubj_acrossSF;

for SF_load = SF_load_all
    %-----------
    fxn_loadSF
    %-----------
    % nameFile_PMF_allSubj = sprintf('%s/n%d_PMF_B%d_constim%d_Bin%dFilter%d_%s_%s.mat', ...
    %     nameFolder_dataOOD_save, nsubj, nBoot, fit.nBins, flag_binData, flag_filterData, text_collapseHM, text_locType);
    % load(nameFile_PMF_allSubj, '*PMF_allSubj')
    nameFile_PMF_GoF_allSubj = sprintf('%s/n%d_PMF_B%d_constim%d_Bin%dFilter%d_%s_%s.mat', ...
        nameFolder_dataOOD_save, nsubj, nBoot, fit.nBins, flag_binData, flag_filterData, text_collapseHM, text_locType);
    load(nameFile_PMF_GoF_allSubj, '*PMF_allSubj')

    SF = SF_load; SF(SF==51)=5;
    SF_fit = SF;

    indSubj = nan(nsubj, nLocSingle, nNoise, nModels);
    indLoc = indSubj;
    indSF = indSubj;
    indNoise = indSubj;
    indPMFm = indSubj; % m for PMF model
    BIC = indSubj;
    R2 = indSubj;

    for isubj=1:nsubj
        for iLoc=1:nLocSingle
            for iNoise=1:nNoise
                for iPMF=1:nModels
                    indSubj(isubj, iLoc, iNoise, iPMF) = isubj_ANOVA(isubj);
                    indLoc(isubj, iLoc, iNoise, iPMF) = iLoc;
                    indSF(isubj, iLoc, iNoise, iPMF) = SF;
                    indNoise(isubj, iLoc, iNoise, iPMF) = noiseSD_full(iNoise);
                    indPMFm(isubj, iLoc, iNoise, iPMF) = iPMF;
                    BIC(isubj, iLoc, iNoise, iPMF) = BIC_PMF_allSubj(isubj, iLoc, iNoise, iPMF);
                    R2(isubj, iLoc, iNoise, iPMF) = R2_PMF_allSubj(isubj, iLoc, iNoise, iPMF);
                end
            end
        end
    end

    indSubj_acrossSF = [indSubj_acrossSF; indSubj(:)];
    indLoc_acrossSF = [indLoc_acrossSF; indLoc(:)];
    indSF_acrossSF = [indSF_acrossSF; indSF(:)];
    indNoise_acrossSF = [indNoise_acrossSF; indNoise(:)];
    indPMFm_acrossSF = [indPMFm_acrossSF; indPMFm(:)];
    BIC_acrossSF = [BIC_acrossSF; BIC(:)];
    R2_acrossSF = [R2_acrossSF; R2(:)];

end % SF

% Construct a table
dataTable = table(...
    categorical(indSubj_acrossSF), ...
    categorical(indLoc_acrossSF), ...
    categorical(indSF_acrossSF), ...
    double(indNoise_acrossSF), ...
    categorical(indPMFm_acrossSF), ...
    double(BIC_acrossSF), ...
    double(R2_acrossSF), ...
    'VariableNames', {'Subj', 'Loc', 'SF', 'NoiseSD', 'PMF', 'BIC', 'R2'});
% writetable(dataTable, 'Rscripts/dataTable/dataTable_PMF_GoF.csv')
writetable(dataTable, sprintf('%s/PMF_GoF_All4.csv', str_folder))
fprintf('\n\n======== DONE SAVING ========\n\n')

%% 3. Create a data table for comparing threshold at L vs. R HM (L vs. R, 4º vs. 8º, noise, perfLevel)
clc
%   DV: R2 and delta BIC
%   IV: PMFmodel (x4, all subj), loc (x9, all subj), noise level (x2, diff subj), SF (x3, diff subject)
flag_nestedMC = 0;% arbitary
flag_varyLocMC = 0;% arbitary
iTvCModel = 1; % arbitary
iErrorType = 1; % arbitary
SF_load_all = SF_all;

indSubj_acrossSF = [];
indLoc_LR_acrossSF = indSubj_acrossSF;
indSF_acrossSF = indSubj_acrossSF;
indPerf_acrossSF = indSubj_acrossSF;
indNoise_acrossSF = indSubj_acrossSF;
indThresh_log_LR_acrossSF = indSubj_acrossSF; % m for PMF model

for SF_load = SF_load_all
    %-----------
    fxn_loadSF
    %-----------
    % nameFile_PMF_allSubj = sprintf('%s/n%d_PMF_B%d_constim%d_Bin%dFilter%d_%s_%s.mat', ...
    %     nameFolder_dataOOD_save, nsubj, nBoot, fit.nBins, flag_binData, flag_filterData, text_collapseHM, text_locType);
    % load(nameFile_PMF_GoF_allSubj, 'thresh_log_LR_allSubj')
    nameFile_PMF_GoF_allSubj = sprintf('%s/n%d_PMF_B%d_constim%d_Bin%dFilter%d_%s_%s.mat', ...
        nameFolder_dataOOD_save, nsubj, nBoot, fit.nBins, flag_binData, flag_filterData, text_collapseHM, text_locType);
    load(nameFile_PMF_GoF_allSubj, 'thresh_log_LR_allSubj')

    SF = SF_load; SF(SF==51)=5;
    SF_fit = SF;

    indSubj = nan(nsubj, nLoc_LR, nNoise, nPerf);
    indLoc_LR = indSubj;
    indSF = indSubj;
    indPerf = indSubj;
    indNoise = indSubj;
    indThresh_log_LR = indSubj; % m for PMF model

    for isubj = 1:nsubj
        for iiLocLR = 1:nLoc_LR
            for iPerf = 1:nPerf
                for iNoise = 1:nNoise
                    indSubj(isubj, iiLocLR, iNoise, iPerf) = isubj_ANOVA(isubj);
                    indLoc_LR(isubj, iiLocLR, iNoise, iPerf) = iiLocLR;
                    indSF(isubj, iiLocLR, iNoise, iPerf) = SF;
                    indPerf(isubj, iiLocLR, iNoise, iPerf) = perfThresh_all(iPerf)/100;
                    indNoise(isubj, iiLocLR, iNoise, iPerf) = noiseSD_full(iNoise);
                    indThresh_log_LR(isubj, iiLocLR, iNoise, iPerf) = thresh_log_LR_allSubj(isubj, iiLocLR, iNoise, iPerf);
                end
            end
        end
    end

    indSubj_acrossSF = [indSubj_acrossSF; indSubj(:)];
    indLoc_LR_acrossSF = [indLoc_LR_acrossSF; indLoc_LR(:)];
    indSF_acrossSF = [indSF_acrossSF; indSF(:)];
    indPerf_acrossSF = [indPerf_acrossSF; indPerf(:)];
    indNoise_acrossSF = [indNoise_acrossSF; indNoise(:)];
    indThresh_log_LR_acrossSF = [indThresh_log_LR_acrossSF; indThresh_log_LR(:)];

end % SF

% Convert indLoc_LR to ecc and L/R
% 1 for LHM4, 2 for RHM4, 3 for LHM8, 4 for RHM8
ecc_all=[4,8];
indEcc_acrossSF = ecc_all((indLoc_LR_acrossSF>2)+1)'; %1=4º, 2=8º eccentricity 
indLR_acrossSF = (mod(indLoc_LR_acrossSF, 2) ~= 0)+1; % 1=left, 2=right (multiples of 2, which are 2 and 4 for RHM4 and RHM4), 

% Construct a table
dataTable = table(...
    categorical(indSubj_acrossSF), ...
    categorical(indEcc_acrossSF), ...
    categorical(indLR_acrossSF), ...
    categorical(indSF_acrossSF), ...
    categorical(indPerf_acrossSF), ...
    categorical(indNoise_acrossSF), ...
    double(indThresh_log_LR_acrossSF), ...
    'VariableNames', {'Subj', 'Ecc48', 'L1R2', 'SF', 'PerfLevel', 'NoiseSD', 'Thresh_log'});
% writetable(dataTable, 'Rscripts/dataTable/dataTable_LR.csv')
writetable(dataTable, sprintf('%s/PMF_compThreshLR.csv', str_folder))
fprintf('\n\n======== DONE SAVING ========\n\n')
