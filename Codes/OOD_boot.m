function OOD_boot(isubj, nNoise, SF, nBoot, flag_estimateThresh, flag_binData, flag_filterData)

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

%%
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

%% file name
nameFolder_dataOOD = sprintf('Data_OOD/nNoise%d/SF%s', nNoise, SF_str);
nameFileCCC_OOD = sprintf('%s/ccc/%s_ccc_all.mat', nameFolder_dataOOD, subjName);

if isempty(dir([nameFolder_dataOOD, '/', subjName])), mkdir([nameFolder_dataOOD, '/', subjName]), end
nameFile_fitPMF = sprintf('%s/%s/%s_fitPMF_B%d_constim%d_Bin%dFilter%d.mat', ...
    nameFolder_dataOOD, subjName, subjName, fit.nBoot, fit.nBins, flag_binData, flag_filterData);

%% load ccc data
load(nameFileCCC_OOD, 'ccc_all');
ccc = ccc_all;

%% empty containers
% assert(nNoise == max(ccc(:, 2)));
nNoise = length(noiseSD_full);
ind_LocNoise = combvec(1:nLoc, 1:nNoise);

cst_log_unik_allLocN = cell(nLoc*nNoise, 1);
nCorr_allLocN = cst_log_unik_allLocN;
nData_allLocN = cst_log_unik_allLocN;
pC_allLocN = cst_log_unik_allLocN;

estP_allLocN = cst_log_unik_allLocN;
% pC_pred_allLocN = cst_log_unik_allLocN;
% converged_allLocN = cst_log_unik_allLocN;
LL_allLocN = cst_log_unik_allLocN;
R2_weighted_allLocN = cst_log_unik_allLocN;
% thresh_log_allLocN = cst_log_unik_allLocN;

fprintf('\n\n***** Start running PARFOR ******\n\n')

iLocNoise_all = 1:nLoc*nNoise; % delete!!!

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
    
    fprintf('\n %d/%d: Loc#%d N#%d... ', iLocNoise, nLoc*nNoise, iLoc, iNoise)
    
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
    ccc_full = ccc(indLocNoise, :);
    
    if isempty(ccc_full)
        fprintf(' NOT exist\n')
    else
        thresh_log_stair=nan;
        if ~isnan(ccc_full(1, 5))
            endpoint_log = []; for istair = 1:4, stair = ccc_full(ccc_full(:, 5)==istair, 3); endpoint_log(istair) = log10(stair(end)); end
            thresh_log_stair = mean(endpoint_log);
        end
        
        %------------------------------------------------%
%         ccc_full((ccc_full(:, 3)>100/100) & (ccc_full(:, 3)<=150/100), 3)=100/100; % limit the cst of trials to be within 100%
        ccc_full(ccc_full(:, 3)>gaborCST_ub, :)=[];
%         assert(max(ccc_full(:, 3))<=100/100, 'ALERT: Max cst is above 100%')
        [cst_log_unik, nCorr, nData, pC, estP_allB, LL_allB, R2_weighted_allB, converged_allB, pC_pred_allB, thresh_log_allB] = ...
            OOD_fitPMF(flag_estimateThresh, ccc_full, fit, thresh_log_stair);
        %------------------------------------------------%
        assert(any(cst_log_unik<=gaborCST_ub))
        
%         figure , hold on
%         pC_pred = PAL_Weibull(median(estP_allB(:, 4, :), 1), fit.curveX_ln);
%         plot(cst_log_unik, pC, 'o')
%         plot(fit.curveX_log, pC_pred, '-'), ylim([.5,1]), yline(.75, 'k--')
%         xlim([-2.5, 0])
%         title(sprintf('%s Noise%.3f', namesCombLoc{iLoc}, noiseSD_full(iNoise)))
%         save(sprintf('old_%s_%d_%s_N%d.jpg', subjName, SF, namesCombLoc{iLoc},iNoise))

        cst_log_unik_allLocN{iLocNoise} = cst_log_unik;
        nCorr_allLocN{iLocNoise} = nCorr;
        nData_allLocN{iLocNoise} = nData;
        pC_allLocN{iLocNoise} = pC;
        
        estP_allLocN{iLocNoise} = estP_allB;
%         pC_pred_allLocN{iLocNoise} = pC_pred_allB;
%         converged_allLocN{iLocNoise} = converged_allB;
        LL_allLocN{iLocNoise} = LL_allB;
        R2_weighted_allLocN{iLocNoise} = R2_weighted_allB;
%         if flag_estimateThresh, thresh_log_allLocN{iLocNoise} = thresh_log_allB; end
    end
end % parfor iLocNoise = 1:nLoc*nNoise

%% Save outputs
save(nameFile_fitPMF,'*_allLocN')
fprintf('\n\nPMF analysis saved\n\n')

time_end = datetime('now')
time_end - time_start
