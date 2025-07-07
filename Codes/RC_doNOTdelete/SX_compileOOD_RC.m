%%%% PERFORMANCE FIELDS ? EQUIVALENT NOISE %%%%

% 2018 by Antoine Barbot
% started to be adapted by Shutian Xue in Feb, 2023

%%%%%%%%%%%%%%%%%%
% PRESENT STUDY: %
%%%%%%%%%%%%%%%%%%
% Use equivalent noise method and LAM model to characterize the functional
% sources of perceptual inefficiencies as a function of eccentricity and polar angle

% clear all
clear all, close all, clc, format compact, commandwindow; % SX; force the cursor to go automatically to command window

% generate paths
addpath(genpath('Data/')); % SX
addpath(genpath('SX_toolbox/')); % SX
addpath(genpath('fxn_exp/'));
addpath(genpath('fxn_analysis/')); % SX

global constant scr visual participant sequence stimulus response confidence timing params
% do NOT globalized design because it's huge
load('Data/params.mat')
clc, format compact

% generate paths
addpath(genpath('Data/')); % SX
addpath(genpath('SX_toolbox/')); % SX
addpath(genpath('fxn_exp/'));
addpath(genpath('fxn_analysis/')); % SX

%%
SX_analysis_setting
flag_combineEcc4 = input('        >>> Combine ecc=4 (1=YES, 0=NO): ');
if flag_combineEcc4, SF = nan; else, SF = input('        >>> Enter SF (5, 6, 51): '); end
nNoise = input('        >>> Enter nNoise: ');
flag_plotIDVD = input('         >>> Whether plot figures (1=plot): '); %1=plot idvd data (time-consuming!!)
if flag_plotIDVD, flag_plotSinglePanel = input('         >>> Whether plot single panel (1=plot): '); end
fit.nBoot = input('         >>> Enter number of bootstraps: ');
iccc_all = 5; % 5=fit PMF to ALL trials
ianalysisMode_all = input('         >>> Analysis mode to loop, in a vector [1,2,3,4]: ');
model_decide = input('         >>> Which model (enter nan if choose the best model): ');

switch SF
    case 6
        SF='6';
        subjList= {'SX', 'DT', 'RC', 'HL', 'HH', 'JY', 'MD', 'ZL', 'AD'}; nLoc=5;
        subjList= {'SX', 'DT', 'RC',         'HH', 'JY', 'MD', 'ZL', 'AD'}; nLoc=5;
        subjList= {'average8'}; nLoc=5;
        params.extNoiseLvl = [0 .055 .11 .165 .22 .33 .44];
    case 5
        SF='5';
        subjList= {'AB', 'MJ', 'LH', 'SP',  'AS', 'CM'}; nLoc=9;
        params.extNoiseLvl = [0 .055 .11 .165 .22 .33 .44];
    case 51
        SF='5_JA';
        subjList = {'ec', 'fc', 'il', 'ja', 'jfa', 'zw', 'ab', 'aw', 'kae', 'mg', 'mr'}; nLoc=9;
        params.extNoiseLvl = [0, 0.055, 0.11, 0.165, 0.22, 0.275, 0.33];
end
noiseLvl_all = params.extNoiseLvl; % do not delete
if flag_combineEcc4
    subjList = {'AB', 'MJ', 'LH', 'SP',  'AS', 'CM',       'SX', 'DT', 'RC', 'HL', 'HH', 'JY', 'MD', 'ZL', 'AD'}; nLoc=5; % including HL
    subjList = {'AB', 'MJ', 'LH', 'SP',  'AS', 'CM',       'SX', 'DT', 'RC',          'HH', 'JY', 'MD', 'ZL', 'AD'}; nLoc=5;
end
nsubj = length(subjList);

%% print info
fprintf('\n    ===============================\n      n=%d [SF = %s] nNoise = %d, nLoc = %d\n    ===============================\n', ...
    nsubj, SF, nNoise, nLoc)
ind_LocNoise5 = combvec(1:5, 1:nNoise);
ind_LocNoise9 = combvec(1:9, 1:nNoise);

for ianalysisMode = ianalysisMode_all % analysisModes: 1-2: Bin data; 1 and 3: filter data
    
    flag_binData = analysisModes(ianalysisMode, 1);
    flag_filterData = analysisModes(ianalysisMode, 2);
    
    %% empty containers
    imodel_best_allSubj = nan(nsubj, nLoc, nNoise);
    PSE_best_allSubj = nan(nsubj, nLoc, nNoise, nPerf);
    slope_best_allSubj = imodel_best_allSubj;
    lapse_best_allSubj = imodel_best_allSubj;
    guess_best_allSubj = imodel_best_allSubj;
    thresh_diff_lb_allSubj = nan(nsubj, nLoc, nModels);
    
    for isubj = 1:nsubj
        subjName=subjList{isubj};
        
        if flag_combineEcc4
            if sum(strcmp(subjName, {'SX', 'DT', 'RC', 'HL', 'HH', 'JY', 'MD', 'ZL', 'AD'})), SF='6';
            else, SF='5'; end
        end
        
        nameFolder_dataOOD = sprintf('Data_OOD/nNoise%d/SF%s', nNoise, SF);
        if flag_combineEcc4
            nameFile_fitPMF_allSubj = sprintf('%s/ecc4/n%d_fitPMF_B%d_Bin%dFilter%d.mat', ...
                nameFolder_dataOOD(1:end-4), nsubj, fit.nBoot, flag_binData, flag_filterData);
        else
            nameFile_fitPMF_allSubj = sprintf('%s/n%d_fitPMF_B%d_Bin%dFilter%d.mat', ...
                nameFolder_dataOOD, nsubj, fit.nBoot, flag_binData, flag_filterData);
        end
        nameFolder_Data = sprintf('Data/nNoise%d/SF%s/%s', nNoise, SF, subjName);
        nameFolder_fig = sprintf('fig/nNoise%d/SF%s/%s/Bin%dFilter%d', nNoise, SF, subjName, flag_binData, flag_filterData); if isempty(dir(nameFolder_fig)), mkdir(nameFolder_fig), end
        nameFile_fitPMF = sprintf('%s/%s/%s_fitPMF_B%d_Bin%dFilter%d.mat', ...
            nameFolder_dataOOD, subjName, subjName, fit.nBoot, flag_binData, flag_filterData);
        
        fprintf('\n\n******** %d/%d %s [Bin%d Filter%d] *********\n', isubj, nsubj, subjName, flag_binData, flag_filterData)
        
        if isempty(nameFile_fitPMF), error('ALERT: Data does not exist!'), else, load(nameFile_fitPMF), fprintf('Loaded\n\n'), end
        
        %% Get best PSE across all models, and replace nan by titration endpoints
        PSE_best_all = nan(nLoc, nNoise, nPerf);
        imodel_best_all = nan(nLoc, nNoise);
        slope_best_all = imodel_best_all;
        lapse_best_all = imodel_best_all;
        guess_best_all = imodel_best_all;
        
        yfit_allB = cell(nLoc, nNoise, nModels);
        PSE_allB = nan(fit.nBoot, nLoc, nNoise, nModels, nPerf);
        LL_allB = nan(fit.nBoot, nLoc, nNoise, nModels);
        
        cst_log_unik_all = cell(nLoc, nNoise);
        nCorr_all = cst_log_unik_all;
        nData_all = cst_log_unik_all;
        yfit_all = cst_log_unik_all;
        
        for iLocNoise_ = 1:nLoc*nNoise
            if flag_combineEcc4 && SF=='5'
                icol = mod(iLocNoise_, nLoc);
                if icol==0, icol=nLoc;irow = iLocNoise_/nLoc;
                else, irow = floor(iLocNoise_/nLoc)+1;
                end
                
                ind_reshaped9 = reshape(1:7*9, [9,7])';
                ind_reshaped5 = reshape(1:7*5, [5,7])';
                
                iLocNoise = ind_reshaped9(irow, icol);
                ind_LocNoise = ind_LocNoise9;
            else
                iLocNoise = iLocNoise_;
                if SF=='6', ind_LocNoise = ind_LocNoise5;else, ind_LocNoise = ind_LocNoise9; end
            end
            
            iLoc = ind_LocNoise(1, iLocNoise);
            iNoise = ind_LocNoise(2, iLocNoise);
            
            fprintf('%d (%d)/%d: L%dN%d ', iLocNoise_, iLocNoise, nLoc*nNoise, iLoc, iNoise)
            
            if isempty(PSE_allLocN{iLocNoise})
                fprintf('*NOT exist*\n')
            else
                fprintf('*Loaded*\n')
                
                %==============================
                fxn_chooseBestModel
                %==============================
                
                % reorganize data
                cst_log_unik_all{iLoc, iNoise} = cst_log_unik_allLocN{iLocNoise};
                nCorr_all{iLoc, iNoise} = nCorr_allLocN{iLocNoise};
                nData_all{iLoc, iNoise} = nData_allLocN{iLocNoise};
                
                for iModel = 1:nModels, yfit_allB{iLoc, iNoise, iModel} = squeeze(yfit_allLocN{iLocNoise}(:, iModel, :)); end
                PSE_allB(:, iLoc, iNoise, :, :) = PSE_allLocN{iLocNoise};
                LL_allB(:, iLoc, iNoise, :)  = LL_allLocN{iLocNoise};
            end
        end %iLocNoise
        
        %% plot idvd data (using the reorganized data)
        if flag_plotIDVD, plotIDVD, end
        
        %% compare N1 and N7 (using bootstrapped data)
        % if N1 does not differ from N7, should discard data, otherwise efficiency will be huge
        iperf=3;
        thresh_diff_lb_all = nan(nLoc, nModels);
        
        figure('Position', [0 100 2e3 300])
        for iModel=1:nModels
            subplot(1,4,iModel), hold on
            for iLoc = 1:nLoc
                thresh_N0 = squeeze(PSE_allB(:, iLoc, 1, iModel, iperf));
                thresh_N7 = squeeze(PSE_allB(:, iLoc, nNoise, iModel, iperf));
                thresh_diff = thresh_N7 - thresh_N0;
                [~, thresh_diff_lb] = getCI(thresh_diff, 1, 1, 1, 1, .95);
                thresh_diff_lb_all(iLoc, iModel) = thresh_diff_lb>0;
                bar(iLoc, thresh_diff_lb, 'EdgeColor', colors9(iLoc, :), 'FaceColor', 'w')
            end
            ylim([-.5, 1])
            xticks(1:nLoc), xticklabels(namesLoc9), xtickangle(45)
            title(PMF_models{iModel})
        end
        sgtitle(sprintf('%s nB=%d', subjList{isubj}, fit.nBoot))
        set(findall(gcf, '-property', 'LineWidth'), 'LineWidth',1.5)
        set(findall(gcf, '-property', 'fontsize'), 'fontsize',15)
        
        %% compile idvd data
        imodel_best_allSubj(isubj, :, :) = imodel_best_all;
        PSE_best_allSubj(isubj, :, :, :) = PSE_best_all; % nLoc x nNoise x nModels x nPerf
        slope_best_allSubj(isubj, :, :) = slope_best_all;
        lapse_best_allSubj(isubj, :, :) = lapse_best_all;
        guess_best_allSubj(isubj, :, :) = guess_best_all;
        thresh_diff_lb_allSubj(isubj, :, :) = thresh_diff_lb_all;
        
    end % isubj
    
    % save group data
    % if nsubj>1
    %     save(nameFile_fitPMF_allSubj, '*_allSubj')
    % end
    save(nameFile_fitPMF_allSubj, '*_allSubj')
end % ianalysisMode



%%
close all
fprintf('\n\n========= DONE =========\n\n')

