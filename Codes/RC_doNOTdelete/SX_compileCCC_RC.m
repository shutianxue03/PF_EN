%% THIS SCRIPT IS GETTING THE CCC_AVERAGE

% compile ccc and save in OOD and idvd filder

clear all, close all, clc, format compact, commandwindow; % SX; force the cursor to go automatically to command window
warning off
% generate paths
addpath(genpath('Data/')); % SX
addpath(genpath('Data_OOD/')); % SX
addpath(genpath('SX_toolbox/')); % SX
addpath(genpath('fxn_exp/'));
addpath(genpath('fxn_analysis/')); % SX

% global constant scr visual participant sequence stimulus response confidence timing params
% % do NOT globalized design because it's huge
% load('Data/params.mat')

%% subj infos
SF = input('       >>> Enter SF: ');
nNoise= input('       >>> Enter nNoise: ');
if SF==6
    subjList= {'SX', 'DT', 'RC', 'HL', 'HH', 'JY', 'MD', 'ZL'}; iLoc_tgt_all=1:5;
    subjList= {'SX', 'DT', 'RC', 'AD', 'HH', 'JY', 'MD', 'ZL'}; iLoc_tgt_all=1:5;

    %subjList= {'AS'}; iLoc_tgt_all=1:5;
else
    subjList= {'AB', 'MJ', 'LH', 'SP',  'AS', 'CM'}; iLoc_tgt_all=1:9;
end

nsubj = length(subjList);
nLoc = length(iLoc_tgt_all);

SX_analysis_setting

nameFolder_dataOOD = sprintf('Data_OOD/nNoise%d/SF%d/ccc', nNoise, SF);
    if isempty(dir(nameFolder_dataOOD)), mkdir(nameFolder_dataOOD), end

ianalysisMode_all = input('      >>> Analysis mode to loop, in a vector [1,2,3,4]: ');
analysisModes = [1,1;1,0;0,1; 0,0]; % BinnedFilterd, Binned, Filtered, Raw
folder_extension = sprintf('nNoise%d/SF%d', nNoise, SF);



for ianalysisMode = ianalysisMode_all
        flag_binData = analysisModes(ianalysisMode, 1);
    flag_filterData = analysisModes(ianalysisMode, 2);
    
    folderName_extraAnalysis = '';
    if flag_binData, folderName_extraAnalysis = [folderName_extraAnalysis, 'Binned'];end
    if flag_filterData, folderName_extraAnalysis = [folderName_extraAnalysis, 'Filtered'];end
    if isempty(folderName_extraAnalysis), folderName_extraAnalysis = 'Raw'; end

for isubj =1:nsubj
    subjName=subjList{isubj};
    fprintf('\n\n******** %d/%d %s (SF=%d) [%s] *********\n', isubj, nsubj, subjName, SF, folderName_extraAnalysis)

    nameFolder = sprintf('%s/%s', folder_extension, subjName);
    nameFolder_data = sprintf('Data/%s', nameFolder);
    nameFolder_fig = sprintf('fig/%s/Bin%dFilter%d', nameFolder, flag_binData, flag_filterData); if isempty(dir(nameFolder_fig)), mkdir(nameFolder_fig), end
    nameFolder_figStair = sprintf('fig/%s/staircase', nameFolder); if isempty(dir(nameFolder_figStair)), mkdir(nameFolder_figStair), end

    nameFileCCC = sprintf('%s/%s_ccc_all.mat', nameFolder_data, subjName);
    nameFileCCC_OOD = sprintf('%s/%s_ccc_all.mat', nameFolder_dataOOD, subjName);

    if ~exist ('ccc_all', 'var')
    load(nameFileCCC)
    else 
        aa= load(nameFileCCC);
        ccc_all = [ccc_all; aa.ccc_all];
    end 
end



% for isubj =1:nsubj
%         subjName=subjList{isubj};
% 
%         fprintf('\n\n******** %d/%d %s (SF=%d) [%s] *********\n', isubj, nsubj, subjName, SF, folderName_extraAnalysis)
% 
%         nameFolder = sprintf('%s/%s', folder_extension, subjName);
%         nameFolder_data = sprintf('Data/%s', nameFolder);
%         nameFolder_fig = sprintf('fig/%s/Bin%dFilter%d', nameFolder, flag_binData, flag_filterData); if isempty(dir(nameFolder_fig)), mkdir(nameFolder_fig), end
%         nameFolder_figStair = sprintf('fig/%s/staircase', nameFolder); if isempty(dir(nameFolder_figStair)), mkdir(nameFolder_figStair), end
% 
%%
% if run this script with an empty var space, load Params_stair in each
% subj's folder, then run this script

%%%%%%%%
% plot_setting
%%%%%%%%
SX_analysis_setting
% nNoise = length(noiseLvl_all);
fprintf('\nnNoise=%d, nLoc=%d\n', nNoise, nLoc)
% nameFileStair = sprintf('%s%s_stair.mat', nameFolder_data, subjName);
% fileStair = dir(sprintf('%s%s_E1*', nameFolder_data, subjName));
% nFiles_stair = length(fileStair);


% %% extract ccc data
% warning off
% if sum(strcmp({'AB', 'AS', 'CM', 'LH', 'MJ'}, subjName))==0
%     for iccc = 1:nccc
% 
%         fprintf('CCC (%s) file creating...\n', namesCCC{iccc})
%         nameFileCCC = sprintf('%s%s_ccc_%s.mat', nameFolder_data, subjName, namesCCC{iccc});
% 
%         switch iccc
%             case 1, nameFiles_add_all = sprintf('%s*E1_b*.mat', nameFolder_data);
%             case 2, nameFiles_add_all = sprintf('%s*E3_b*.mat', nameFolder_data);
%             case 3, nameFiles_add_all = sprintf('%s*E4_b*.mat', nameFolder_data);
%             case 4, nameFiles_add_all = sprintf('%s*E*_b*.mat', nameFolder_data);
%             case 5, nameFiles_add_all = sprintf('%s*E*_b*.mat', nameFolder_data);
%         end
%         dirFiles_add_all = dir(nameFiles_add_all); nFiles_ccc = length(dirFiles_add_all);
%         nFilesStair = length(dir(sprintf('%s/*E1_b*', nameFolder_data)));
%         % only look at data after titration
%         if iccc==4, dirFiles_add_all = dirFiles_add_all(nFilesStair+1:end); nFiles_ccc = nFiles_ccc-nFilesStair; end
%         if (iccc==1) && (nFiles_ccc>0), constant.expMode=1; end
%         if (iccc==2) && (nFiles_ccc>0), constant.expMode=3; end
%         if (iccc==3) && (nFiles_ccc>0), constant.expMode=4; end
%         if (iccc==4) && (nFiles_ccc>0), constant.expMode=4; end
% 
%         ccc = [];
%         if strcmp(subjName, 'SP')
%             load(sprintf('%s%s_ccc_stair.mat', nameFolder_data, subjName), 'ccc')
%             fprintf('SP: loaded\n')
%         end
%         for ifile = 1:nFiles_ccc
%             load(dirFiles_add_all(ifile).name, 'real_sequence')
%             ccc = [ccc;...
%                 real_sequence.targetLoc(real_sequence.trialDone==1)'...
%                 real_sequence.extNoiseLvl(real_sequence.trialDone==1)'...
%                 real_sequence.scontrast(real_sequence.trialDone==1)'...
%                 real_sequence.iscor(real_sequence.trialDone==1)'...
%                 real_sequence.stair(real_sequence.trialDone==1)'...
%                 real_sequence.stimOri(real_sequence.trialDone==1)'];
%         end % ifile
% 
%         switch iccc
%             case 1, ccc_stair = ccc; save(nameFileCCC, 'ccc_stair')
%             case 2, ccc_const = ccc; save(nameFileCCC, 'ccc_const')
%             case 3, ccc_manual = ccc; save(nameFileCCC, 'ccc_manual')
%             case 4, ccc_nonS = ccc; save(nameFileCCC, 'ccc_nonS')
%             case 5, ccc_all = ccc; save(nameFileCCC, 'ccc_all')
%         end
%     end % iccc
% else
%     nameFileCCC = sprintf('%s/%s_ccc_all.mat', nameFolder_data, subjName);
%     load(nameFileCCC), if ~exist('ccc_all', 'var'), ccc_all= ccc; end
% end
% fprintf('DONE\n')

% %% fitting PMF - fit & get PSE
% curveX = fit.curveX;
% name_avg = 'average';
% nameFile_fitPMF = sprintf('%s/%s_fitPMF_%s.mat',nameFolder_data, name_avg, folderName_extraAnalysis);
% 
% % if  sum(strcmp({'AB', 'AS', 'CM', 'LH', 'MJ', 'SP'}, subjName))==0
% %     iccc_fit = [1,4,5];
% % else
% %     iccc_fit = [5];
% % end
% iccc_fit = 5;
% 
% if isempty(dir(nameFile_fitPMF))
%     for iccc = iccc_fit
%         switch iccc
%             case 1, ccc = ccc_stair;
%             case 2, ccc = ccc_const;
%             case 3, ccc = ccc_manual;
%             case 4, ccc = ccc_nonS;
%             case 5, ccc = ccc_all;
%         end
%         if isempty(ccc), ccc=ccc_stair; end
%         if iccc == 3
%             fprintf('\n\nCCC (%s): %d data points in total...', namesCCC{iccc}, size(ccc, 1))
%         else
%             fprintf('\n\nCCC (%s): %d data points per loc per noise...', namesCCC{iccc}, round(size(ccc, 1)/nLoc/nNoise))
%         end
% 
%         % empty containers
%         cst_log_unik_all = cell(nLoc, nNoise);
%         nData_all = cst_log_unik_all;
%         nCorr_all = cst_log_unik_all;
%         pC_all = cst_log_unik_all;
% 
%         yfit_allB = cell(nLoc, nNoise, nModels);
%         PSE_allB = nan(fit.nBoot, nLoc, nNoise, nModels, nPerf);
%         slope_allB = nan(fit.nBoot, nLoc, nNoise, nModels);
%         guess_allB = slope_allB;
%         lapse_allB = slope_allB;
%         LL_allB = slope_allB;
%         converged_allB = slope_allB;
%         estP_allB = nan(fit.nBoot, nLoc, nNoise, nModels, 4);
% 
%         for iLoc = iLoc_tgt_all
%             for iNoise = 1:nNoise
%                 fprintf('\nLoc#%d N#%d: ', iLoc, iNoise)
%                 indLocNoise = ccc(:, 1)==iLoc & ccc(:, 2)==iNoise;
%                 ccc_full = ccc(indLocNoise, :);
% 
%                 %%%%%%%%%%%%%%
%                 fxn_fitPMF
%                 %%%%%%%%%%%%%%
% 
%             end % iNoise
%         end % iLoc
% 
%         % compile
%         cst_log_unik_allC{iccc} = cst_log_unik_all;
%         nData_allC{iccc} = nData_all;
%         nCorr_allC{iccc} = nCorr_all;
%         pC_allC{iccc} = pC_all;
% 
%         yfit_allC{iccc} = yfit_allB;
%         PSE_allC{iccc} = PSE_allB;% nLoc x nNoise x nPerf (70,75,79,82)
%         slope_allC{iccc} = slope_allB;
%         guess_allC{iccc} = guess_allB;
%         lapse_allC{iccc} = lapse_allB;
%         LL_allC{iccc} = LL_allB;
%         estP_allC{iccc} = estP_allB;
%         converged_allC{iccc} = converged_allB;
% 
%     end % iccc
%     % check *allC
%     save(nameFile_fitPMF,'*_allC', 'curveX_log')
%     fprintf('\nPSE saved\n')
% else
%     fprintf('\nLoading...')
%     load(nameFile_fitPMF)
%     fprintf(' DONE\n')
% end

% %% Get best PSE across all models, and replace nan by titration endpoints
% iccc_all = 5;
% thresh_best_all = nan(nLoc, nNoise, nPerf);
% imodel_best_all = nan(nLoc, nNoise);
% slope_best_all = imodel_best_all;
% lapse_best_all = imodel_best_all;
% guess_best_all = imodel_best_all;
% 
% if nFiles_stair==0, ccc_stair = ccc; end
% for iLoc = iLoc_tgt_all
%     for iNoise = 1:nNoise
%         iModel_notNaN = [];
%         for iModel = 1:nModels
%             if isnan(getCI(PSE_allC{iccc_all}(:, iLoc, iNoise, iModel, 3), 1, 1)), continue
%             else, iModel_notNaN = [iModel_notNaN, iModel];
%             end
%         end
%         fprintf('L%dN%d: %s\n', iLoc, iNoise, num2str(iModel_notNaN))
%         if isempty(iModel_notNaN), iModel_notNaN = 1; end
%         [~, imodel_best] = max(getCI(LL_allC{iccc_all}(:, iLoc, iNoise, iModel_notNaN), 1, 1));
%         imodel_best = iModel_notNaN(imodel_best);
%         imodel_best_all(iLoc, iNoise) = imodel_best;
% 
%         thresh_best_all(iLoc, iNoise, :) = getCI(PSE_allC{iccc_all}(:, iLoc, iNoise, imodel_best, :));
%         slope_best_all(iLoc, iNoise) = getCI(slope_allC{iccc_all}(:, iLoc, iNoise, imodel_best));
%         lapse_best_all(iLoc, iNoise) = getCI(lapse_allC{iccc_all}(:, iLoc, iNoise, imodel_best));
%         guess_best_all(iLoc, iNoise) = getCI(guess_allC{iccc_all}(:, iLoc, iNoise, imodel_best));
% 
%     end %iNoise
% end % iLoc
end %analysis_mode
nameFileCCCAVG = sprintf('%s/average8_ccc_all.mat', nameFolder_data);
nameFileCCC_OODAVG = sprintf('%s/average8_ccc_all.mat', nameFolder_dataOOD);
save(nameFileCCCAVG, 'ccc_all'), save(nameFileCCC_OODAVG, 'ccc_all');

