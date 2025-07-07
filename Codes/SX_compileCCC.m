

% compile ccc and save in OOD and idvd filder
% Columns of "ccc": Loc | NoiseSD | signalCST | correct | iStair | ORI

clear all, close all, clc, format compact, commandwindow; warning off % SX; force the cursor to go automatically to command window

% generate paths
addpath(genpath('Data/Data_OOD')); % SX
addpath(genpath('Data/Data_OOD/')); % SX
addpath(genpath('Codes/')); % SX

%% subj infos
clc
nNoise = input('       >>> Enter nNoise: ');
SF = input('       >>> Enter SF: ');

noiseSD_old = [0 .055 .11 .165 .22 .33 .44]; % do NOT delete
subjList_AB= {'AB', 'MJ', 'LH', 'SP',  'AS', 'CM'};
% subjList_JA = {'fc', 'ja', 'jfa', 'zw'};

switch SF
    case 6
        SF_str = '6';
        iLoc_tgt_all = 1:9;
        subjList= {'AD', 'AS', 'DT', 'HH', 'HL', 'JY', 'LL', 'MD', 'RC', 'RE', 'SX', 'ZL'}; % n=12
        subjList = {'AS'};
        subjList = {'JH'}; %Rachel created this line on March 11 2025 for running pilot for JH
    case 4
        SF_str = '4';
        iLoc_tgt_all = 1:9;
        subjList= {'AD',         'DT', 'HH', 'HL',        'LL', 'MD', 'RC',        'SX', 'ZL'}; % n=9
    case 5
        SF_str='5_AB';
        subjList= subjList_AB; iLoc_tgt_all = 1:9;
        %     case 51
        %         SF_str='5_JA';
        %         %         subjList = {'ec', 'fc', 'il', 'ja', 'jfa', 'zw', 'ab', 'aw', 'dc', 'kae', 'mg', 'mr'}; nLoc=9; nLocHM=2;
        %         subjList = subjList_JA; iLoc_tgt_all = 1:9;
end

nsubj = length(subjList);
nLoc = length(iLoc_tgt_all);

%------------------%
SX_analysis_setting
%------------------%

%%
nameFolder_dataOOD = sprintf('Data/Data_OOD/nNoise%d/SF%s/ccc', nNoise, SF_str);
if isempty(dir(nameFolder_dataOOD)), mkdir(nameFolder_dataOOD), end

for isubj = 1:nsubj
    subjName = subjList{isubj};
    
    fprintf('\n\n******** %d/%d %s (SF=%d)  *********\n', isubj, nsubj, subjName, SF)
    fprintf('\nnNoise=%d, nLoc=%d\n', nNoise, nLoc)
    
    nameFolder_Data = sprintf('Data/Data/nNoise%d/SF%s/%s', nNoise, SF_str, subjName);
    
    %-------------------%
    SX_analysis_setting
    %-------------------%
    
    %% extract ccc data
    for iccc = 5%1:nccc
        nameFileCCC = sprintf('%s/%s_ccc_%s.mat', nameFolder_Data, subjName, namesCCC{iccc});
        
        nameFileCCC_OOD = sprintf('%s/%s_ccc_%s.mat', nameFolder_dataOOD, subjName, namesCCC{iccc});
        
        %         if ~(any(strcmp(subjName, subjList_AB)))
        
        fprintf('CCC (%s) file creating...\n', namesCCC{iccc})
        switch iccc
            case 1, nameFiles_add_all = sprintf('%s/%s_*E1_b*.mat', nameFolder_Data, subjName);
            case 2, nameFiles_add_all = sprintf('%s/%s*E3_b*.mat', nameFolder_Data, subjName);
            case 3, nameFiles_add_all = sprintf('%s/%s*E4_b*.mat', nameFolder_Data, subjName);
            case 4, nameFiles_add_all = sprintf('%s/%s*E*_b*.mat', nameFolder_Data, subjName);
            case 5, nameFiles_add_all = sprintf('%s/%s*E*_b*.mat', nameFolder_Data, subjName);
        end
        dirFiles_add_all = dir(nameFiles_add_all); nFiles_ccc = length(dirFiles_add_all);
        fprintf(' * %d files *\n', nFiles_ccc)
        nFilesStair = length(dir(sprintf('%s/*E1_b*', nameFolder_Data)));
        % only look at data after titration
        if iccc==4, dirFiles_add_all = dirFiles_add_all(nFilesStair+1:end); nFiles_ccc = nFiles_ccc-nFilesStair; end
        if (iccc==1) && (nFiles_ccc>0), constant.expMode=1; end
        if (iccc==2) && (nFiles_ccc>0), constant.expMode=3; end
        if (iccc==3) && (nFiles_ccc>0), constant.expMode=4; end
        if (iccc==4) && (nFiles_ccc>0), constant.expMode=4; end
        
        ccc = [];
        % load staircase data for the old dataset
        if strcmp(subjName, 'SP')
            load(sprintf('%s/%s_ccc_%s.mat', nameFolder_Data, subjName, namesCCC{1}), 'ccc')
            fprintf('SP: loaded\n')
        end
        
        % concatenate/append new files
        for ifile = 1:nFiles_ccc
            load(dirFiles_add_all(ifile).name, 'real_sequence')
            
            % change index of noise SD to real values (now, the recorded noiseSD are still doubled!!)
            ntrials = length(real_sequence.extNoiseLvl);
            for itrial = 1:ntrials
                if real_sequence.extNoiseLvl(itrial) >=1
                    real_sequence.extNoiseLvl(itrial) = noiseSD_old(real_sequence.extNoiseLvl(itrial));
                end
            end

            ccc = [ccc;...
                real_sequence.targetLoc(real_sequence.trialDone==1)'...
                real_sequence.extNoiseLvl(real_sequence.trialDone==1)'...
                real_sequence.scontrast(real_sequence.trialDone==1)'...
                real_sequence.iscor(real_sequence.trialDone==1)'...
                real_sequence.stair(real_sequence.trialDone==1)'...
                real_sequence.stimOri(real_sequence.trialDone==1)'];
        end % ifile
        
        switch iccc
            case 1, ccc_stair = ccc; save(nameFileCCC, 'ccc_stair')
            case 2, ccc_const = ccc; save(nameFileCCC, 'ccc_const')
            case 3, ccc_manual = ccc; save(nameFileCCC, 'ccc_manual')
            case 4, ccc_nonS = ccc; save(nameFileCCC, 'ccc_nonS')
            case 5, ccc_all = ccc; save(nameFileCCC, 'ccc_all'), save(nameFileCCC_OOD, 'ccc_all');
        end
        
        fprintf('DONE\n')
        %         end % if strcmp
        
    end % iccc
    
end % isubj

fprintf('\n\n========= DONE =========\n\n')

