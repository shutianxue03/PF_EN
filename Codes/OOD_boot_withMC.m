function OOD_boot_withMC(isubj, nNoise, SF, nBoot, flag_estimateThresh, flag_binData, flag_filterData)
% isubj=3, nNoise=9, SF=6, nBoot=2, flag_estimateThresh=0, flag_binData=1, flag_filterData=1
% if run this script with an empty var space, load Params_stair in each
% subj's folder, then run this script
% Modified based on OOD_boot_debug
% includes running model comparison of 1 full vs. 15 reduced PTM

% INPUTS
%    isubj:
%    nNoise: number of external noise levels, default is 9
%    SF: the SF of Gabor signal; AB's dataset=5, SX's =6 cpd
%    nBoot: number of bootstraps, default is 1000
%    flag_estimateThresh: 0=not estimate threshold (to avoid rerunning bootstrapping had we chosen a diff perf level)
%    flag_binData: 1=bin data into multiple bins (defined in SX_analysis_setting); 0=raw data
%    flag_filterData: 1=take out data that are noisy (rarely used)


clc, format compact

% generate paths
addpath(genpath('Data/Data_OOD/')); % SX
addpath(genpath('Codes/')); % SX

time_start = datetime('now')

% Generate the seed
rng(0, 'twister')

%%
%------------------%
SX_analysis_setting
%------------------%
gaborCST_ub = gaborCST_ub;
fit.flag_binData = flag_binData;
fit.flag_filterData = flag_filterData;
str_PMF_fittingMethod = 'fmincon';
str_weightType = 'LLPMF';
PMFmodel_decide = 4;

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
        subjList = {'fc', 'ja', 'jfa', 'zw'};  % only those who have a data at all 9 locations
        nLocSingle=9; nLocHM=2;
        noiseSD_full = [0 .055 .11 .165 .22 .33 .44]/2; % in ccc_all, col#2 is index (1-7), not real values!
end

nsubj = length(subjList);
subjName = subjList{isubj};
nLoc = nLocSingle + nLocHM;

%% print info
fprintf('\n =========================\n')
fprintf('S%d/%d %s [SF = %d]\n      nBoot = %d; nBoot for PMF = %d\n      nNoise = %d x nLoc = %d (single) + %d (collapsed)', ...
    isubj, nsubj, subjName, SF, nBoot, fit.nBoot_PMF, nNoise, nLocSingle, nLocHM)
fprintf('\n      Perf levels for thresh est: [%s]\n      Estimate threshold: %d\n      Bin data = %d (nBins=%d), Filter data = %d\n      PMF fitting method: %s', ...
    num2str(perfThresh_all), flag_estimateThresh, flag_binData, fit.nBins, flag_filterData, str_PMF_fittingMethod)
fprintf('\n =========================\n')

%% file name
nameFolder_dataOOD = sprintf('Data/Data_OOD/nNoise%d/SF%s', nNoise, SF_str);
nameFileCCC_OOD = sprintf('%s/ccc/%s_ccc_all.mat', nameFolder_dataOOD, subjName);

if isempty(dir([nameFolder_dataOOD, '/', subjName])), mkdir([nameFolder_dataOOD, '/', subjName]), end
nameFile_fitPMF = sprintf('%s/%s/%s_fitPMF_B%d_constim%d_Bin%dFilter%d.mat', ...
    nameFolder_dataOOD, subjName, subjName, nBoot, fit.nBins, flag_binData, flag_filterData);

%% load ccc data
load(nameFileCCC_OOD, 'ccc_all');
ccc = ccc_all;

%% Preallocate placeholders
nIndLoc_s = 10; nLoc_s_max = 7; nParams_full = 3; nCand_max = 16;% see fxn_fitTvCIDVD
LL_PMF_allLoc_allB = nan(nLocComb, nNoise, nBoot); % nLocComb=11
thresh_log_allLoc_allB = nan(nLocComb, nNoise, nPerf, nBoot); % nLocComb=11
nData_allLoc_allB = nan(nLocComb, nNoise, nBoot);
R2_BestSimplest_allLoc_allB = nan(nIndLoc_s, nLoc_s_max, nPerf, nBoot);
est_BestSimplest_allLoc_allB = nan(nIndLoc_s, nLoc_s_max, nParams_full, nBoot);
dBIC_nestedMC_allLoc_allB = nan(nIndLoc_s, nCand_max, nBoot); % 16: number of nested PTM models
R2_nestedMC_allLoc_allB = dBIC_nestedMC_allLoc_allB;

%% Loop through boots
for iBoot = 1:nBoot
    fprintf('\n\nBoot #%d/%d  ', iBoot, nBoot)
    
    % Empty containers
    nNoise = length(noiseSD_full);
    ind_LocNoise = combvec(1:nLoc, 1:nNoise);
    
    cst_log_unik_allLocN = cell(nLoc*nNoise, 1);
    nCorr_allLocN = cst_log_unik_allLocN;
    nData_allLocN = cst_log_unik_allLocN;
    pC_allLocN = cst_log_unik_allLocN;
    estP_allLocN = cst_log_unik_allLocN;
    LL_allLocN = cst_log_unik_allLocN;
    R2_weighted_allLocN = cst_log_unik_allLocN;
    
    % fprintf('\n\n***** Start running PARFOR ******\n\n')
    
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
                case 1, iLoc_all = [2,4];% HM4,L10
                case 2, iLoc_all = [6,8];% HM8, L11
            end
        end
        
        % fprintf('\n %d/%d: Loc#%d N#%d... ', iLocNoise, nLoc*nNoise, iLoc, iNoise)
        
        %%% extract ccc %%%
        if any(SF==[5,51]) % AB and JA's data: col#2 of ccc_all are index (1-7), not values!
            switch length(iLoc_all)
                case 1 % single location
                    indLocNoise = ccc(:, 1)==iLoc & ccc(:, 2)==iNoise;
                case 2 % collapsed from two locations
                    indLocNoise = (ccc(:, 1)==iLoc_all(1) | ccc(:, 1)==iLoc_all(2)) & ccc(:, 2)==iNoise;
            end
        else % SF=4 and 6
            assert(max(ccc(:, 2)) == max(noiseSD_full), 'ALERT: The max noiseSD in ccc does NOT match noiseSD_full!')
            switch length(iLoc_all)
                case 1 % single location
                    indLocNoise = (ccc(:, 1)==iLoc) & (ccc(:, 2)==noiseSD_full(iNoise));
                case 2 % collapsed from two locations
                    indLocNoise = (((ccc(:, 1)==iLoc_all(1)) | (ccc(:, 1)==iLoc_all(2)))) & ccc(:, 2)==noiseSD_full(iNoise);
            end
        end
        
        % Extract the ccc
        ccc_full = ccc(indLocNoise, :);
        
        % Reshuffle data for each LocxNoise comb, only when nBoot>1
        if nBoot > 1
            nTrials = size(ccc_full, 1);
            indBoot = randsample(nTrials, nTrials, 'true'); assert(length(unique((indBoot))) < nTrials, 'ALERT: Replacement did NOT happen!')
            ccc_full = ccc_full(indBoot, :);
        end
        
        if isempty(ccc_full)
            fprintf(' NOT exist\n')
        else
            %------------------------------------------------%
            ccc_full(ccc_full(:, 3) > gaborCST_ub, :)=[];
            
            %             [cst_log_unik, nCorr, nData, pC, estP_allB, LL_allB, R2_weighted_allB] = OOD_fitPMF(flag_estimateThresh, ccc_full, fit);
            % [cst_log_unik, nCorr, nData, pC, estP_allM, LL_allM, R2_weighted_allM] = OOD_fitPMF_v2(ccc_full, fit);
            [cst_log_unik, nCorr, nData, pC, estP_allM, LL_allM, R2_weighted_allM] = OOD_fitPMF_debug(ccc_full, fit, str_PMF_fittingMethod, sprintf('%s%d', subjName, SF), [iLoc,iNoise]);
            %             [cst_log_unik, nCorr, nData, pC, estP_allB, LL_allB, R2_weighted_allB] = OOD_fitPMF_v3(flag_estimateThresh, ccc_full, fit);
            %             LL_allM = median(LL_allB, 1); estP_allM = squeeze(median(estP_allB, 1)); R2_weighted_allM = median(R2_weighted_allB, 1);
            %------------------------------------------------%
            assert(any(cst_log_unik<=gaborCST_ub))
            
            %             figure , hold on
            %             pC_pred = PAL_Weibull(estP_allM(4, :), fit.curveX_ln);
            %             pC_pred = PAL_Weibull(median(estP_allB(:, 4, :), 1), fit.curveX_ln);
            %
            %             plot(cst_log_unik, pC, 'o')
            %             plot(fit.curveX_log, pC_pred, '-'), ylim([.5,1]), yline(.75, 'k--')
            %             xlim([-2.5, 0])
            %             title(sprintf('%s Noise%.3f', namesCombLoc{iLoc}, noiseSD_full(iNoise)))
            %             save(sprintf('new_%s_%d_%s_N%d.jpg', subjName, SF, namesCombLoc{iLoc},iNoise))
            
            cst_log_unik_allLocN{iLocNoise} = cst_log_unik;
            nCorr_allLocN{iLocNoise} = nCorr;
            nData_allLocN{iLocNoise} = nData;
            pC_allLocN{iLocNoise} = pC;
            estP_allLocN{iLocNoise} = estP_allM;
            LL_allLocN{iLocNoise} = LL_allM;
            R2_weighted_allLocN{iLocNoise} = R2_weighted_allM;
        end
    end % parfor iLocNoise = 1:nLoc*nNoise
    
    % Save outputs
    % % save(nameFile_fitPMF,'*_allLocN')
    
    %% The minimum amount of setting needed for running TvC fitting for each idvd
    % Copied from initAnalysis (so that the noiseSD_full is not overridden)
    flag_collapseHM = 1;
    flag_combineEcc4 = 0;
    ind_LocNoise9 = combvec(1:9, 1:nNoise); % do not delete
    ind_LocNoise9_inUse = combvec(1:(9+2), 1:nNoise); % do not delete
    
    % Below are all needed by "fxn_prepAnalysis"
    flag_locType = 2; % 2=text_locType is 'combLoc';
    SF_fit = 1;
    text_locType = 'combLoc';
    iTvCModel=2; % 2=PTM
    nParams_full = 3;% NOT including Nmul
    nLoc_s_max = 7; % see fxn_fitTvCIDVD
    IndCand_GroupBest_vec = [125, 125, 125, 8, 8, 8, 8]; % assume using the full model
    iErrorType = 1; % 1=calculating the loss using log contrast
    flag_weightedFitting = 1; % weight the loss (currently, by number of trials per noise level)
    iWeibull = 4; % Decide which model to use:'Logistic', 'CumNorm', 'Gumbel',  'Weibull'
    iBeta = 2; % alpha, beta, gamma, lambda
    
    %---------------%
    fxn_prepAnalysis_debug
    %---------------%
    if any(SF == [4,6])
        if max(noiseSD_full)>.44, noiseSD_full = noiseSD_full/2; end
    end
    %-----------------%
    SX_fitTvC_setting
    %-----------------%
    
    %--------------%
    %     quickPlot_debug % plot PMFs of 9 loc in one panel, per noise level
    %--------------%
    close all
    %--------------%
    flag_plot = 0;
    fxn_fitTvCIDVD
    %--------------%
    
    % save for each bootstrap iteration
    LL_PMF_allLoc_allB(:, :, iBoot) = LL_allB(:, :, PMFmodel_decide);
    thresh_log_allLoc_allB(:, :, :, iBoot) = thresh_log; % from fxn_prepAnalysis_v2
    nData_allLoc_allB(:, :, iBoot) = nData_perLoc;     % from fxn_prepAnalysis_v2
    R2_BestSimplest_allLoc_allB(:, :, :, iBoot) = R2_BestSimplest_allLoc; % from fxn_fitTvCIDVD
    est_BestSimplest_allLoc_allB(:, :, :, iBoot) = est_BestSimplest_allLoc; % from fxn_fitTvCIDVD
    
    if any(SF == [4,6])
        noiseSD_full = noiseSD_full*2; % will be deleted soon!!
    end
    
    % figure, histogram(R2_BestSimplest_allLoc(:))
    
    %% Run Model comparison
    if nBoot < 100 % MC takes too much time
        nParams_full = 4;% including Nmul
        
        %------------------------%
        fxn_nestedMC_PTM
        %------------------------%
        BIC_nestedMC_allLoc = nData_nestedMC_allLoc'.*log(RSS_nestedMC_allLoc ./ nData_nestedMC_allLoc') + log(nData_nestedMC_allLoc') * nParams_nestedMC_allCand;
        dBIC_nestedMC_allLoc = BIC_nestedMC_allLoc - min(BIC_nestedMC_allLoc, [], 2);
        dBIC_nestedMC_allLoc_allB(:, :, iBoot) = dBIC_nestedMC_allLoc;
        R2_nestedMC_allLoc_allB(:, :, iBoot) = R2_nestedMC_allLoc;
        
        figure, bar(R2_nestedMC_allLoc')
    end
end % iBoot

%% Visualize nested MC
% [dBIC_nestedMC_allLoc_med] = getCI(dBIC_nestedMC_allLoc_allB, 1, 3);
% [R2_nestedMC_allLoc_med] = getCI(R2_nestedMC_allLoc_allB, 1, 3);
% figure,
% subplot(1,2,1), bar(dBIC_nestedMC_allLoc_med'), title('Delta BIC')
% subplot(1,2,2), bar(R2_nestedMC_allLoc_med'), title('R2')

%% Save outputs of all bootstraps
nameFile_fitTvC = sprintf('%s/%s/%s_fitTvC_B%d_constim%d_Bin%dFilter%d_%s.mat', ...
    nameFolder_dataOOD, subjName, subjName, nBoot, fit.nBins, flag_binData, flag_filterData, text_locType);

save(nameFile_fitTvC,'*_allLoc_allB')
fprintf('\n\nTvC fitting saved\n\n')

time_end = datetime('now')
time_end - time_start
