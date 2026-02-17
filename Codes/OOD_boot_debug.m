function OOD_boot_debug(isubj, nNoise, SF, nBoot, flag_estimateThresh, flag_binData, flag_filterData)
% isubj=3, nNoise=9, SF=6, nBoot=2, flag_estimateThresh=0, flag_binData=1, flag_filterData=1
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
fprintf('S%d/%d %s [SF = %d]\n      nBoot for PMF = %d\n      nNoise = %d x nLoc = %d (single) + %d (collapsed)', ...
    isubj, nsubj, subjName, SF, fit.nBoot_PMF, nNoise, nLocSingle, nLocHM)
fprintf('\n      Perf levels for thresh est: [%s]\n      Estimate threshold: %d\n      Bin data = %d (nBins=%d), Filter data = %d\n      PMF fitting method: %s', ...
    num2str(perfThresh_all), flag_estimateThresh, flag_binData, fit.nBins, flag_filterData, str_PMF_fittingMethod)
fprintf('\n =========================\n')

%% file name
nameFolder_dataOOD = sprintf('Data_OOD/nNoise%d/SF%s', nNoise, SF_str);
nameFileCCC_OOD = sprintf('%s/ccc/%s_ccc_all.mat', nameFolder_dataOOD, subjName);

if isempty(dir([nameFolder_dataOOD, '/', subjName])), mkdir([nameFolder_dataOOD, '/', subjName]), end
nameFile_fitPMF = sprintf('%s/%s/%s_fitPMF_B%d_constim%d_Bin%dFilter%d.mat', ...
    nameFolder_dataOOD, subjName, subjName, nBoot, fit.nBins, flag_binData, flag_filterData);

%% load ccc data
load(nameFileCCC_OOD, 'ccc_all');
ccc = ccc_all;

%% Preallocate placeholders
nIndLoc_s = 8; nLoc_s_max = 7; nParams_full = 3;% see fxn_fitTvCIDVD
LL_PMF_allLoc_allB = nan(nLocComb, nNoise, nBoot); % nLocComb=11
thresh_log_allLoc_allB = nan(nLocComb, nNoise, nPerf, nBoot); % nLocComb=11
nData_allLoc_allB= nan(nLocComb, nNoise, nBoot);
R2_BestSimplest_allLoc_allB = nan(nIndLoc_s, nLoc_s_max, nPerf, nBoot);
est_BestSimplest_allLoc_allB = nan(nIndLoc_s, nLoc_s_max, nParams_full, nBoot);

%% Loop through boots
for iBoot = 1:nBoot
    fprintf('\n\nBoot #%d/%d', iBoot, nBoot)

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
                case 1, iLoc_all = [2,4];% ecc4
                case 2, iLoc_all = [6,8];% ecc8
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

        % Reshuffle data for each LocxNoise comb
        nTrials = size(ccc_full, 1);
        indBoot = randsample(nTrials, nTrials, 'true'); assert(length(unique((indBoot))) < nTrials, 'ALERT: Replacement did NOT happen!')
        ccc_full = ccc_full(indBoot, :);

        if isempty(ccc_full)
            fprintf(' NOT exist\n')
        else
            %------------------------------------------------%
            ccc_full(ccc_full(:, 3) > gaborCST_ub, :)=[];

            %             [cst_log_unik, nCorr, nData, pC, estP_allB, LL_allB, R2_weighted_allB] = OOD_fitPMF(flag_estimateThresh, ccc_full, fit);
            % [cst_log_unik, nCorr, nData, pC, estP_allM, LL_allM, R2_weighted_allM] = OOD_fitPMF_v2(ccc_full, fit);
            [cst_log_unik, nCorr, nData, pC, estP_allM, LL_allM, R2_weighted_allM] = OOD_fitPMF_debug(ccc_full, fit, str_PMF_fittingMethod);
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
    %        quickPlot_debug
    %--------------%

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
end % iBoot

%% Visualize the TvC data and fitting for each loc group
% for iiIndLoc_s = 1:nIndLoc_s
%     indLoc_s = indLoc_s_all{iiIndLoc_s};
%     nLoc_s = length(indLoc_s); % Number of selected locations
%     namesCombLoc_s = namesCombLoc(indLoc_s); % Get location names
%     str_LocSelected = strjoin(namesCombLoc_s, ''); % Concatenate location names into a single string
%     % fprintf('\n-------%s------\n', str_LocSelected) % Print the selected location name
%
%     figure('Position', [0 0 1e3 800]), hold on,
%     legends_all = cell(1,nLoc_s);
%     for iiLoc = 1:nLoc_s
%         color_ = colors_asym(indLoc_s(iiLoc), :); % Color for location
%         % Take median of boostrapped data (thresh, estP and R2) per subj, and store for each SF
%         [thresh_med, thresh_lb, thresh_ub] = getCI(thresh_log_allLoc_allB(indLoc_s(iiLoc), :, iPerf_plot, :), 1, 4); % thresh_log_allB_allSubj: nsubj x nLocComb_max(11) x nNoise x nPerf x nBoot
%         estP_med = getCI(est_BestSimplest_allLoc_allB(iiIndLoc_s, iiLoc, :, :), 1, 4); % est_xx_allB_allSubj: nsubj x nLocGroups x nLoc_max x nParams x nBoot
%         [R2_med, R2_lb, R2_ub] = getCI(R2_BestSimplest_allLoc_allB(iiIndLoc_s, iiLoc, iPerf_plot, :), 1, 4);
%
%         % Make predictions
%         %------------------------------------------------------------------------------------------%
%         threshEnergy_pred = fxn_PTM([0,1,1,1], estP_med, noiseEnergy_intp_true, dprimes(iPerf_plot), SF_fit);
%         %------------------------------------------------------------------------------------------%
%         % errorbars
%         errorbar(noiseSD_log_all, thresh_med, thresh_med-thresh_lb, thresh_ub-thresh_med, '.', 'color', color_, 'HandleVisibility', 'off', 'CapSize', 0)
%         % median thresh
%         plot(noiseSD_log_all, thresh_med, 'o', 'color', color_, 'HandleVisibility', 'off')
%         % pred
%         plot(noiseSD_intp_log_true, log10(sqrt(threshEnergy_pred)), '-', 'color', color_)
%         % legend
%         legends_all{iiLoc} = sprintf('%s: R2=%.2f [%.2f, %.2f]', namesCombLoc{indLoc_s(iiLoc)}, R2_med, R2_lb, R2_ub);
%
%     end % iiLoc
%     xlabel('External noise SD');
%     if max(noiseSD_full)>.44, noiseSD_full = noiseSD_full/2; end
%     x_ticks = noiseSD_log_all; x_ticklabels = round(noiseSD_full, 3);
%     % x_ticks = [noiseSD_log_all(1), noiseSD_log_full_acrossSF(2:end)]; x_ticklabels = round(noiseSD_full_acrossSF, 3); % defined in fxn_loadSF
%     xlim([x_ticks(1) - 0.1, x_ticks(end) + 0.1]); xticks(x_ticks); xticklabels(x_ticklabels); xtickangle(90)
%
%     ylabel('Contrast threshold (%)');
%     yticks(cst_log_ticks); yticklabels(round(cst_ln_ticks)); ylim(cst_log_ticks([1, end]));
%
%     title(sprintf('[%s SF%d] nBoot=%d', subjName, SF, nBoot))
%     legend(legends_all, 'Location', 'southeast')
%     set(findall(gcf, '-property', 'linewidth'), 'linewidth',1.5)
%     set(findall(gcf, '-property', 'fontsize'), 'fontsize',15)
%     saveas(gcf, sprintf('temp_%s.jpg', str_LocSelected))
% end % iiIndLoc_s

%% Save outputs of all bootstraps
nameFile_fitTvC = sprintf('%s/%s/%s_fitTvC_B%d_constim%d_Bin%dFilter%d_%s.mat', ...
    nameFolder_dataOOD, subjName, subjName, nBoot, fit.nBins, flag_binData, flag_filterData, text_locType);

save(nameFile_fitTvC,'*_allLoc_allB')
fprintf('\n\nTvC fitting saved\n\n')

time_end = datetime('now')
time_end - time_start