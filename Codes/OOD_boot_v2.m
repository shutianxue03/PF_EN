function OOD_boot_v2(isubj, nNoise, SF, nBoot, flag_estimateThresh, flag_binData, flag_filterData)
% clear all, isubj=1, nNoise=9, SF=6, nBoot=2, flag_estimateThresh=0, flag_binData=1, flag_filterData=1

% if run this script with an empty var space, load Params_stair in each
% subj's folder, then run this script

% INPUTS
%    isubj:
%    nNoise: number of external noise levels, default is 9
%    SF: the SF of Gabor signal; AB's dataset=5, SX's =6 cpd
%    nBoot: number of bootstraps, default is 1000
%    flag_estimateThresh: 0=not estimate threshold (to avoid rerunning bootstrapping had we chosen a diff perf level)
%    flag_binData: 1=bin data into multiple bins (defined in SX_analysis_setting); 0=raw data
%    flag_filterData: 1=take out data that are noisy (rarely used)

%%
clc, format compact

% generate paths
addpath(genpath('Data_OOD/')); % SX
addpath(genpath('SX_toolbox/')); % SX
addpath(genpath('fxn_analysis/')); % SX

time_start = datetime('now')

% Generate the seed
rng(0, 'twister')

%%
%------------------%
SX_analysis_setting
%------------------%
gaborCST_ub = gaborCST_ub;
fit.nBoot = nBoot;
fit.flag_binData = flag_binData;
fit.flag_filterData = flag_filterData;

switch SF
    case 6
        SF_str = '6';
        subjList = {'AD', 'DT', 'HH', 'HL', 'LL', 'MD', 'RC',  'SX', 'ZL', 'ASM', 'JY', 'RE'}; % SF=6, n=12s % ASM is Ajay (Male)
        nLocSingle=9; nLocHM=2;
        noiseSD_full = [0 .055 .11 .165 .22 .33 .44 .66 .88];

    case 4
        SF_str = '4';
        subjList = {'AD', 'DT', 'HH', 'HL', 'LL', 'MD', 'RC',  'SX', 'ZL'                       }; % SF=4, n=9
        nLocSingle = 9; nLocHM = 2;
        noiseSD_full = [0 .055 .11 .165 .22 .33 .44 .66 .88];

    case 5
        SF_str = '5_AB';
        subjList = {'AB', 'ASF', 'CM', 'LH', 'MJ', 'SP'}; % ASF is Angela Shen (Female)
        nLocSingle = 9; nLocHM = 2;
        noiseSD_full = [0 .055 .11 .165 .22 .33 .44]/2; % in ccc_all, col#2 is index (1-7), not real values!

    case 51
        SF_str = '5_JA';
        %         subjList = {'fc', 'ja', 'jfa', 'zw', 'ab',  'kae', 'ec', 'il', 'aw', 'mg', 'mr', 'dc'};
        subjList = {'fc', 'ja', 'jfa', 'zw'};  % only those who have a data at all 9 locations
        nLocSingle=9; nLocHM=2;
        noiseSD_full = [0 .055 .11 .165 .22 .33 .44]/2; % in ccc_all, col#2 is index (1-7), not real values!
end

nsubj = length(subjList);
subjName = subjList{isubj};
nLoc = nLocSingle + nLocHM;

%% print info
fprintf('\n =========================\n')
fprintf('S%d/%d %s [SF = %d] nBoot = %d\n      nNoise = %d x nLoc = %d (single) + %d (collapsed)', ...
    isubj, nsubj, subjName, SF, fit.nBoot, nNoise, nLocSingle, nLocHM)
fprintf('\n      Perf levels for thresh est: [%s]\n      Estimate threshold: %d\n      Bin data = %d (nBins=%d), Filter data = %d', ...
    num2str(perfThresh_all), flag_estimateThresh, flag_binData, fit.nBins, flag_filterData)
fprintf('\n =========================\n')

%% Define file name
nameFolder_dataOOD = sprintf('Data_OOD/nNoise%d/SF%s', nNoise, SF_str);
nameFileCCC_OOD = sprintf('%s/ccc/%s_ccc_all.mat', nameFolder_dataOOD, subjName);

if isempty(dir([nameFolder_dataOOD, '/', subjName])), mkdir([nameFolder_dataOOD, '/', subjName]), end
nameFile_fitPMF = sprintf('%s/%s/%s_fitPMF_B%d_constim%d_Bin%dFilter%d.mat', ...
    nameFolder_dataOOD, subjName, subjName, fit.nBoot, fit.nBins, flag_binData, flag_filterData);

%% load ccc data
load(nameFileCCC_OOD, 'ccc_all');
ccc = ccc_all;

%% Preallocate placeholders
nIndLoc_s = 8; nLoc_s_max = 7; nParams_full = 3;% see fxn_fitTvCIDVD
thresh_log_allLoc_allB = nan(nLocComb, nNoise, nPerf, nBoot);
nData_allLoc_allB= nan(nLocComb, nNoise, nBoot);
R2_BestSimplest_allLoc_allB = nan(nIndLoc_s, nLoc_s_max, nPerf, fit.nBoot);
est_BestSimplest_allLoc_allB = nan(nIndLoc_s, nLoc_s_max, nParams_full, fit.nBoot);

%% Loop through bootstrap rounds
clc
for iBoot = 1:nBoot
    tic
    fprintf('\n\nBoot #%d/%d', iBoot, nBoot)

    %% empty containers
    nNoise = length(noiseSD_full);
    ind_LocNoise = combvec(1:nLoc, 1:nNoise);

    cst_log_unik_allLocN = cell(nLoc*nNoise, 1);
    nCorr_allLocN = cst_log_unik_allLocN;
    nData_allLocN = cst_log_unik_allLocN;
    pC_allLocN = cst_log_unik_allLocN;
    estP_allLocN = cst_log_unik_allLocN;
    LL_allLocN = cst_log_unik_allLocN;
    R2_weighted_allLocN = cst_log_unik_allLocN;

    iLocNoise_all = 1:nLoc*nNoise;

    parfor iLocNoise = iLocNoise_all % more interested in L6-9
        %     for iLocNoise=1
        %%% decide noise index %%%
        iNoise = ind_LocNoise(2, iLocNoise);

        %%% decide location index
        iLoc = ind_LocNoise(1, iLocNoise);

        if iLoc<=nLocSingle % single location
            iLoc_all = iLoc;
        else
            iLocHM = iLoc - nLocSingle;
            switch iLocHM
                case 1, iLoc_all = [2,4];% ecc4
                case 2, iLoc_all = [6,8];% ecc8
            end
        end

        %         fprintf('\n %d/%d: Loc#%d N#%d... \n', iLocNoise, nLoc*nNoise, iLoc, iNoise)

        %%% extract ccc %%%
        if any(SF==[5,51]) % AB and JA's data: col#2 of ccc_all are index (1-7), not values!
            switch length(iLoc_all)
                case 1 % single location
                    indLocNoise = ccc(:, 1)==iLoc & ccc(:, 2)==iNoise;
                case 2 % collapsed from two locations
                    indLocNoise = (ccc(:, 1)==iLoc_all(1) | ccc(:, 1)==iLoc_all(2)) & ccc(:, 2)==iNoise;
            end
        else
            switch length(iLoc_all)
                case 1 % single location
                    indLocNoise = ccc(:, 1)==iLoc & ccc(:, 2)==noiseSD_full(iNoise);
                case 2 % collapsed from two locations
                    indLocNoise = (ccc(:, 1)==iLoc_all(1) | ccc(:, 1)==iLoc_all(2)) & ccc(:, 2)==noiseSD_full(iNoise);
            end
        end
        ccc_LocNoise = ccc(indLocNoise, :);
        assert(~isempty(ccc_LocNoise), 'ALERT: ccc_LocNoise is empty!\n')

        % reshuffle data for each LocxNoise comb
        nTrials = size(ccc_LocNoise, 1);
        indBoot = randsample(nTrials, nTrials, 'true'); assert(length(unique((indBoot))) < nTrials, 'ALERT: Replacement did NOT happen!')
        ccc_full = ccc_LocNoise(indBoot, :);
%         ccc_full = ccc_LocNoise; % no resampling (for debugging)

        %------------------------------------------------%
        ccc_full(ccc_full(:, 3)>gaborCST_ub, :)=[];
        [cst_log_unik, nCorr, nData, pC, estP_allM, LL_allM, R2_weighted_allM] = ...
            OOD_fitPMF_v2(ccc_full, fit);
        %------------------------------------------------%
%         figure , hold on
%         pC_pred = PAL_Weibull(estP_allM(4, :), fit.curveX_ln);
%         plot(cst_log_unik, pC, 'o')
%         plot(fit.curveX_log, pC_pred, '-'), ylim([.5,1]), yline(.75, 'k--')
%         xlim([-2.5, 0])
%         title(sprintf('%s Noise%.3f', namesCombLoc{iLoc}, noiseSD_full(iNoise)))
%         pause
%         close all

        assert(any(cst_log_unik<=gaborCST_ub))

        cst_log_unik_allLocN{iLocNoise} = cst_log_unik;
        nCorr_allLocN{iLocNoise} = nCorr;
        nData_allLocN{iLocNoise} = nData;
        pC_allLocN{iLocNoise} = pC;
        estP_allLocN{iLocNoise} = estP_allM;
        LL_allLocN{iLocNoise} = LL_allM;
        R2_weighted_allLocN{iLocNoise} = R2_weighted_allM;

        assert(~isempty(LL_allM), 'ALERT: LL_allM is empty!!')
        assert(~isempty(R2_weighted_allM), 'ALERT: R2_weighted_allM is empty!!')

    end % parfor iLocNoise = 1:nLoc*nNoise

    %% Save outputs
%     save(nameFile_fitPMF,'*_allLocN')

    %% TvC Settings
    %------------------%
    SX_analysis_setting
    %------------------%
    flag_collapseHM =1;
    flag_n9 = 0; % 1=only include the 9 subjects shared between SF4 and SF6
    iErrorType = 1;
%     str_SF =  '456'; %num2str(input('         >>> Enter SF (456 or 46): '));
    flag_weightedFitting = 1;%input('         >>> Conducted weighted fitting for TvC (1=YES): ');
%     flag_Bcorrect = 1;%input('         >>> Bonferroni correction (1=YES): ');
    flag_PTMwithSF = 0;%input('         >>> Whether PTM includes SF (1=YES, 0=NO): ');
    flag_varyLocMC=0; 
    flag_BestSimplestFitting=1; 
    flag_plotIDVD = 0; 
    flag_locType = 2;
    nameModel = 'NoNmul';
    SF_all = [4, 51, 5, 6];
    iTvCModel=2;
    IndCand_GroupBest_vec = [125, 125, 125, 8, 8, 8, 8];
    SF_fit=1;

    if flag_collapseHM
        text_collapseHM = 'collapseHM1';
        nLoc = nLocSingle+nLocHM;
    else
        text_collapseHM = 'collapseHM0';
        nLocHM = 0;
        nLoc = nLocSingle;
    end
    nNoise_save = nNoise;
    flag_combineMode = 0;%input('        >>> Enter Combine Mode (0=not combine, 1=ecc4, 2=ecc8, 3=ecc48): ');
    flag_combineEcc4 = 0; flag_combineEcc8 = 0;flag_combineEcc48 = 0;
    ind_LocNoise5 = combvec(1:5, 1:nNoise); % do not delete
    ind_LocNoise9 = combvec(1:9, 1:nNoise); % do not delete
    ind_LocNoise5_inUse = combvec(1:(5+1), 1:nNoise); % do not delete
    ind_LocNoise9_inUse = combvec(1:(9+2), 1:nNoise); % do not delete

    text_locType = 'combLoc'; nLoc = nLocComb; colors_allLoc = colors_asym; names_allLoc = namesCombLoc; %flag_plotIDVD=0;

    %% Fit TvC
    %------------------%
    fxn_prepAnalysis_v2
    %------------------%

    %------------------%
    fxn_fitTvCIDVD
    %------------------%

    % save for each bootstrap
    thresh_log_allLoc_allB(:, :, :, iBoot) = thresh_log; % from fxn_prepAnalysis_v2
    nData_allLoc_allB(:, :, iBoot) = nData_perLoc;     % from fxn_prepAnalysis_v2
    R2_BestSimplest_allLoc_allB(:, :, :, iBoot) = R2_BestSimplest_allLoc; % from fxn_fitTvCIDVD
    est_BestSimplest_allLoc_allB(:, :, :, iBoot) = est_BestSimplest_allLoc; % from fxn_fitTvCIDVD

%     fprintf('|| Max Gain %.2f', max(est_BestSimplest_allLoc_allB(:, :, 3, :), 4))

    fprintf(' | Max Gain = %.2f', max(est_BestSimplest_allLoc(:, :, 3), [], 'all'))
    fprintf('\nGain:\n')
    est_BestSimplest_allLoc(1:7, 1:3, 3)
end % iBoot


%% Save outputs of all bootstraps
nameFolder_dataOOD_load = sprintf('Data_OOD/nNoise%d/SF%s', nNoise, SF_str); if isempty(dir(nameFolder_dataOOD_load)), mkdir(nameFolder_dataOOD_load), end
nameFolder_dataOOD_save = sprintf('Data_OOD/nNoise%d/SF%s', nNoise_save, SF_str); if isempty(dir(nameFolder_dataOOD_save)), mkdir(nameFolder_dataOOD_save), end

% FOLDERS & FILES (idvd)
nameFile_fitTvC = sprintf('%s/%s/%s_fitTvC_B%d_constim%d_Bin%dFilter%d_%s.mat', ...
    nameFolder_dataOOD_load, subjName, subjName, nBoot, fit.nBins,flag_binData, flag_filterData, text_locType);

save(nameFile_fitTvC,'*_allLoc_allB')
fprintf('\n\nTvC fitting saved\n\n')

time_end = datetime('now')
time_end - time_start


