function OOD_boot_collapseHM(isubj, nNoise, SF, flag_binData, flag_filterData)

%%
% if run this script with an empty var space, load Params_stair in each
% subj's folder, then run this script
% INPUTS
%    isubj:
%    nNoise: number of external noise levels, default is 7
%    SF: the SF of Gabor signal; AB's dataset=5, SX's =6 cpd
%    flag_binData: 1=bin data into multiple bins (defined in SX_analysis_setting); 0=raw data
%    flag_filterData: 1=take out data that are noisy (rarely used)

%%
clc, format compact

% generate paths
addpath(genpath('Data_OOD/')); % SX
addpath(genpath('SX_toolbox/')); % SX
addpath(genpath('fxn_analysis/')); % SX

time_start = datetime('now');

%%
SX_analysis_setting
fit.nBoot = 1e2;
fit.flag_binData = 1;
fit.flag_filterData = 1;
ecc_all = [4,8];

%%
switch SF
    case 6
        SF='6';
        subjList= {'SX', 'DT', 'RC',  'HH', 'JY', 'MD', 'ZL','AD'}; nLoc=5;nLocHM=1;
        params.extNoiseLvl = [0 .055 .11 .165 .22 .33 .44];
    case 5
        SF='5';
        subjList= {'AB', 'MJ', 'LH', 'SP',  'AS', 'CM'}; nLoc=9;nLocHM=2;
        params.extNoiseLvl = [0 .055 .11 .165 .22 .33 .44];
    case 51
        SF='5_JA';
        subjList = {'ec', 'fc', 'il', 'ja', 'jfa', 'zw', 'ab', 'kae'}; nLoc=9; nLocHM=2;% subjs who have data on HM 
        params.extNoiseLvl = [0, 0.055, 0.11, 0.165, 0.22, 0.275, 0.33];
end

nsubj = length(subjList);
subjName = subjList{isubj};
subjName = 'average8';

%% print info
fprintf('         *** Collapse HM ***         ')
fprintf('\n    =========================\n      S%d/%d %s [SF = %s] nBoot = %d\n      nNoise = %d, nLoc = %d\n      Bin data = %d, Filter data = %d\n    =========================\n', ...
    isubj, nsubj, subjName, SF, fit.nBoot, nNoise, nLoc, flag_binData, flag_filterData)

%% file name
nameFolder_dataOOD = sprintf('Data_OOD/nNoise%d/SF%s', nNoise, SF);
nameFileCCC_OOD = sprintf('%s/ccc/%s_ccc_all.mat', nameFolder_dataOOD, subjName);
if isempty(dir([nameFolder_dataOOD, '/', subjName])), mkdir([nameFolder_dataOOD, '/', subjName]), end

nameFolder_fig_collapseHM = sprintf('fig/nNoise%d/SF%s/%s/Bin%dFilter%d/collapseHM', nNoise, SF, subjName, flag_binData, flag_filterData);
if isempty(dir(nameFolder_fig_collapseHM)), mkdir(nameFolder_fig_collapseHM), end

nameFile_fitPMF_collapseHM = sprintf('%s/%s/%s_fitPMF_collapseHM_B%d_Bin%dFilter%d.mat', ...
    nameFolder_dataOOD, subjName, subjName, fit.nBoot, flag_binData, flag_filterData);

%% load ccc data
load(nameFileCCC_OOD, 'ccc_all');
ccc = ccc_all;

%% empty containers
ind_LocNoise = combvec(1:nLocHM, 1:nNoise);

cst_log_unik_allLocN = cell(nLocHM*nNoise, 1);
nCorr_allLocN = cst_log_unik_allLocN;
nData_allLocN = cst_log_unik_allLocN;
pC_allLocN = cst_log_unik_allLocN;

yfit_allLocN = cst_log_unik_allLocN;
PSE_allLocN = cst_log_unik_allLocN;
converged_allLocN = cst_log_unik_allLocN;
LL_allLocN = cst_log_unik_allLocN;
slope_allLocN = cst_log_unik_allLocN;
guess_allLocN = cst_log_unik_allLocN;
lapse_allLocN = cst_log_unik_allLocN;
estP_allLocN = cst_log_unik_allLocN;

fprintf('\n\n***** Start running PARFOR ******\n\n')

for iLocNoise = 1:nLocHM*nNoise
    
    iLocHM = ind_LocNoise(1, iLocNoise);
    iNoise = ind_LocNoise(2, iLocNoise);
    switch iLocHM
        case 1, iLoc_all = [2,4];% ecc4
        case 2, iLoc_all = [6,8];% ecc8
    end
    fprintf('\n %d/%d: LocHM#%d (L%d & L%d) N#%d... ', iLocNoise, nLoc*nNoise, iLocHM, iLoc_all, iNoise)
    indLocNoise = (ccc(:, 1)==iLoc_all(1) | ccc(:, 1)==iLoc_all(2)) & ccc(:, 2)==iNoise;
    ccc_full = ccc(indLocNoise, :);
    indLocNoise1 = ccc(:, 1)==iLoc_all(1) & ccc(:, 2)==iNoise; ccc_full1 = ccc(indLocNoise1, :);
    indLocNoise2 = ccc(:, 1)==iLoc_all(2) & ccc(:, 2)==iNoise; ccc_full2 = ccc(indLocNoise2, :);
    assert(size(ccc_full1, 1)+size(ccc_full2, 1) == size(ccc_full, 1))
    
    if isempty(ccc_full)
        fprintf(' NOT exist\n')
    else
        thresh_log_stair=nan;
        if ~isnan(ccc_full(1, 5))
            endpoint_log = []; for istair = 1:4, stair = ccc_full(ccc_full(:, 5)==istair, 3); endpoint_log(istair) = log10(stair(end)); end
            thresh_log_stair = mean(endpoint_log);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        [cst_log_unik, nCorr, nData, pC, yfit_allB, PSE_allB, ...
            converged_allB, LL_allB, ...
            slope_allB, guess_allB, lapse_allB, estP_allB, ...
            PSE_LHM_allB, PSE_RHM_allB] = OOD_fitPMF_collapseHM(ccc_full1, ccc_full2, fit, thresh_log_stair);
        
        title(sprintf('[HM on Ecc = %d] %s N=%.0f%%%', ecc_all(iLocHM), subjName, params.extNoiseLvl(iNoise)*100))
        
        iModel=2;iPerf=3;
        subplot(1,2,2), hold on, grid on
        histogram(PSE_LHM_allB(:, iModel, iPerf), 'EdgeColor', 'none', 'FaceColor', 'r', 'facealpha', .3, 'Normalization', 'probability')
        histogram(PSE_RHM_allB(:, iModel, iPerf), 'EdgeColor', 'none', 'FaceColor', 'b', 'facealpha', .3, 'Normalization', 'probability')
        histogram(PSE_allB(:, iModel, iPerf), 'EdgeColor', 'k', 'FaceColor', 'k', 'facealpha', .3, 'Normalization', 'probability')
        [~, p] = ansaribradley(PSE_LHM_allB(:, iModel, iPerf), PSE_RHM_allB(:, iModel, iPerf));
        legend({'Left HM', 'RIght HM', 'Collapse'})
        xlabel(sprintf('Estimated thresh [%s] (%d%%)', PMF_models{iModel}, perfPSE_all(iPerf)))
        yticks(0:.1:.5), ylim([0, .5])
        xticks_ = -3:.5:0; % same as the left panel
        xticks(xticks_)
        xticklabels(round(10.^xticks_*100, 1))
        xlim(xticks_([1, end]))
        title(sprintf('nB=%d, Thresh diffs betwen left and right (p=%.3f)\nLeft=%.2f%%, Right=%.0f%%, Collapse=%.2f%%', ...
            fit.nBoot, p, ...
            10^getCI(PSE_LHM_allB(:, iModel, iPerf), 1, 1)*100, 10^getCI(PSE_RHM_allB(:, iModel, iPerf), 1, 1)*100, 10^getCI(PSE_allB(:, iModel, iPerf), 1, 1)*100))
        
        set(findall(gcf, '-property', 'LineWidth'), 'LineWidth',1.5)
        set(findall(gcf, '-property', 'fontsize'), 'fontsize',15)
        saveas(gcf, sprintf('%s/PMF_N%.0f_ecc%d.jpg', nameFolder_fig_collapseHM, params.extNoiseLvl(iNoise)*100, ecc_all(iLocHM)))

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        cst_log_unik_allLocN{iLocNoise} = cst_log_unik;
        nCorr_allLocN{iLocNoise} = nCorr;
        nData_allLocN{iLocNoise} = nData;
        pC_allLocN{iLocNoise} = pC;
        
        yfit_allLocN{iLocNoise} = yfit_allB;
        PSE_allLocN{iLocNoise} = PSE_allB;
        converged_allLocN{iLocNoise} = converged_allB;
        LL_allLocN{iLocNoise} = LL_allB;
        slope_allLocN{iLocNoise} = slope_allB;
        guess_allLocN{iLocNoise} = guess_allB;
        lapse_allLocN{iLocNoise} = lapse_allB;
        estP_allLocN{iLocNoise} =  estP_allB;
    end
end % iLocNoise

save(nameFile_fitPMF_collapseHM,'*_allLocN')
fprintf('\n\nPMF analysis saved\n\n')

%%
time_end = datetime('now')

time_end - time_start