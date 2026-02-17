%==========================================================================
% compile_ccc_and_count_trials.m
%
% Purpose
%   Compile trial-level data ("ccc") from per-block *.mat files and save:
%     (1) per-subject ccc_all into subject folder, and
%     (2) per-subject ccc_all into OOD aggregate folder.
%   Also records total trial counts per subject and SF, and reports the mean
%   trials per (noise x location) cell.
%
% Output table ("ccc_all") columns:
%   1 Loc        : target location index (1..9)
%   2 NoiseSD    : external noise SD (in RMS contrast units)
%   3 signalCST  : signal contrast
%   4 correct    : correctness (0/1)
%   5 iStair     : staircase index/label
%   6 ORI        : stimulus orientation
%   7 RT         : reaction time (seconds; if stored that way)
%
% Notes / assumptions
%   - For older datasets, extNoiseLvl may be stored as an *index* (>=1) that
%     needs mapping via noiseSD_old. This script converts it in-place.
%   - If iccc==4 (nonS), it only keeps blocks after titration (skips E1_* files).
%   - Subject 'SP' loads an existing ccc file first (legacy behavior preserved).
%
%==========================================================================

clear all; close all; clc; format compact; commandwindow;
warning off; % keep original behavior

%% Paths (avoid duplicate addpath)
addpath(genpath('Data/Data_OOD'));
addpath(genpath('Codes/'));

%% Settings
clc
nNoise = 9; % number of external noise levels used in the experiment

% Legacy mapping: when extNoiseLvl is stored as an index (>=1) instead of SD.
% IMPORTANT: keep as-is for old dataset compatibility.
noiseSD_old = [0 .055 .11 .165 .22 .33 .44]; %#ok<NASGU>

% Subject lists (kept as in original script)
subjList_AB = {'AB', 'MJ', 'LH', 'SP', 'AS', 'CM'};
% subjList_JA = {'fc', 'ja', 'jfa', 'zw'};

SF_all = [4, 6];
nSF = numel(SF_all);

% Preallocate (max 12 subjects x 2 SFs)
nTrials_allSubj = nan(12, nSF);

%% Loop over spatial frequencies
for iSF = 1:nSF
    SF = SF_all(iSF);

    %------------------------------%
    % Define subjects by SF
    %------------------------------%
    switch SF
        case 6
            SF_str = '6';
            iLoc_tgt_all = 1:9;
            subjList = {'AD','AS','DT','HH','HL','JY','LL','MD','RC','RE','SX','ZL'}; % n=12
        case 4
            SF_str = '4';
            iLoc_tgt_all = 1:9;
            subjList = {'AD','DT','HH','HL','LL','MD','RC','SX','ZL'}; % n=9
        case 5
            SF_str = '5_AB';
            subjList = subjList_AB;
            iLoc_tgt_all = 1:9;
        otherwise
            error('Unsupported SF=%g', SF);
    end

    nsubj = numel(subjList);
    nLoc  = numel(iLoc_tgt_all);

    % Setting
    SX_analysis_setting

    %------------------------------%
    % Output folder for OOD ccc
    %------------------------------%
    nameFolder_dataOOD = sprintf('%s/Data/Data_OOD/nNoise%d/SF%s/ccc', nameFolder_server, nNoise, SF_str);
    if isempty(dir(nameFolder_dataOOD))
        mkdir(nameFolder_dataOOD);
    end

    %% Loop over subjects
    for isubj = 1:nsubj
        subjName = subjList{isubj};

        fprintf('\n\n******** %d/%d %s (SF=%d) *********\n', isubj, nsubj, subjName, SF);
        fprintf('nNoise=%d, nLoc=%d\n', nNoise, nLoc);

        % Subject data folder
        nameFolder_Data = sprintf('%s/Data/Data/nNoise%d/SF%s/%s', nameFolder_server, nNoise, SF_str, subjName);

        % Re-run in case SX_analysis_setting depends on subjName / paths
        SX_analysis_setting

        %% Compile ccc data
        % Original code only runs iccc=5 (ccc_all). Keep that behavior.
        for iccc = 5  % 1:nccc  (kept as original: only compile "all")
            % Output file names
            nameFileCCC     = sprintf('%s/%s_ccc_%s.mat', nameFolder_Data, subjName, namesCCC{iccc});
            nameFileCCC_OOD = sprintf('%s/%s_ccc_%s.mat', nameFolder_dataOOD, subjName, namesCCC{iccc});

            fprintf('CCC (%s) file creating...\n', namesCCC{iccc});

            %------------------------------%
            % Decide which block files to load
            %------------------------------%
            switch iccc
                case 1
                    nameFiles_add_all = sprintf('%s/%s_*E1_b*.mat', nameFolder_Data, subjName);
                case 2
                    nameFiles_add_all = sprintf('%s/%s*E3_b*.mat', nameFolder_Data, subjName);
                case 3
                    nameFiles_add_all = sprintf('%s/%s*E4_b*.mat', nameFolder_Data, subjName);
                case 4
                    nameFiles_add_all = sprintf('%s/%s*E*_b*.mat', nameFolder_Data, subjName);
                case 5
                    nameFiles_add_all = sprintf('%s/%s*E*_b*.mat', nameFolder_Data, subjName);
            end

            dirFiles_add_all = dir(nameFiles_add_all);
            nFiles_ccc = numel(dirFiles_add_all);
            fprintf(' * %d files *\n', nFiles_ccc);

            % Count staircase files (E1) for titration removal in iccc==4
            nFilesStair = numel(dir(sprintf('%s/*E1_b*', nameFolder_Data)));

            % Only look at data after titration (legacy behavior)
            if iccc == 4
                dirFiles_add_all = dirFiles_add_all(nFilesStair+1:end);
                nFiles_ccc = nFiles_ccc - nFilesStair;
            end

            % Set constant.expMode (legacy behavior)
            if (iccc==1) && (nFiles_ccc>0), constant.expMode = 1; end
            if (iccc==2) && (nFiles_ccc>0), constant.expMode = 3; end
            if (iccc==3) && (nFiles_ccc>0), constant.expMode = 4; end
            if (iccc==4) && (nFiles_ccc>0), constant.expMode = 4; end

            % Initialize ccc container
            ccc = [];

            % Legacy special-case: load staircase data for old dataset (SP)
            if strcmp(subjName, 'SP')
                load(sprintf('%s/%s_ccc_%s.mat', nameFolder_Data, subjName, namesCCC{1}), 'ccc');
                fprintf('SP: loaded\n');
            end

            %------------------------------%
            % Concatenate/append block files
            %------------------------------%
            for iFile = 1:nFiles_ccc
                fpath = sprintf('%s/%s', dirFiles_add_all(iFile).folder, dirFiles_add_all(iFile).name);
                S = load(fpath, 'real_sequence');

                if ~isfield(S, 'real_sequence') || isempty(S.real_sequence)
                    warning('Missing real_sequence in %s (skipped)', fpath);
                    continue;
                end
                real_sequence = S.real_sequence;

                % Trial inclusion mask
                if isfield(real_sequence, 'trialDone')
                    m = (real_sequence.trialDone == 1);
                else
                    % If trialDone doesn’t exist, assume all trials are valid
                    m = true(size(real_sequence.extNoiseLvl));
                end

                % Convert extNoiseLvl indices to SD values if needed
                % (Original behavior: convert any value >= 1 using noiseSD_old index.)
                nTrials = numel(real_sequence.extNoiseLvl);
                for iTrial = 1:nTrials
                    if real_sequence.extNoiseLvl(iTrial) >= 1
                        real_sequence.extNoiseLvl(iTrial) = noiseSD_old(real_sequence.extNoiseLvl(iTrial));
                    end
                end

                % Defensive checks for expected fields
                reqFields = {'targetLoc','extNoiseLvl','scontrast','iscor','stair','stimOri','rt'};
                for k = 1:numel(reqFields)
                    if ~isfield(real_sequence, reqFields{k})
                        error('Field "%s" missing in %s', reqFields{k}, fpath);
                    end
                end

                % Append rows: [Loc NoiseSD signalCST correct iStair ORI RT]
                ccc = [ccc; ...
                    real_sequence.targetLoc(m)' , ...
                    real_sequence.extNoiseLvl(m)' , ...
                    real_sequence.scontrast(m)' , ...
                    real_sequence.iscor(m)' , ...
                    real_sequence.stair(m)' , ...
                    real_sequence.stimOri(m)' , ...
                    real_sequence.rt(m)' ];
            end % iFile

            %------------------------------%
            % Save outputs (keep original variable names)
            %------------------------------%
            switch iccc
                case 1
                    ccc_stair  = ccc; %#ok<NASGU>
                    save(nameFileCCC, 'ccc_stair');
                case 2
                    ccc_const  = ccc; %#ok<NASGU>
                    save(nameFileCCC, 'ccc_const');
                case 3
                    ccc_manual = ccc; %#ok<NASGU>
                    save(nameFileCCC, 'ccc_manual');
                case 4
                    ccc_nonS   = ccc; %#ok<NASGU>
                    save(nameFileCCC, 'ccc_nonS');
                case 5
                    ccc_all    = ccc; %#ok<NASGU>
                    save(nameFileCCC, 'ccc_all');
                    save(nameFileCCC_OOD, 'ccc_all');
            end

            fprintf('DONE\n');
        end % iccc

        % Record number of compiled trials for this subject & SF
        nTrials_allSubj(isubj, iSF) = size(ccc, 1);
    end % isubj
end % iSF

fprintf('\n\n========= DONE =========\n\n');

%% Summary: average trials per (noise x location) cell
% Flatten and drop missing (for subjects who didn’t do an SF)
nTrials_vec = nTrials_allSubj(:);
nTrials_vec = nTrials_vec(~isnan(nTrials_vec));

% Convert total trials -> trials per (noise x location) cell
trials_per_cell = nTrials_vec / nNoise / nLoc;

% getCI is assumed to exist on path; preserve your original call signature
[nTrials_ave, ~, ~, sem] = getCI(trials_per_cell, 2, 1);

fprintf('Mean trials per (noise x loc) cell: %.2f (SEM=%.2f)\n', nTrials_ave, sem);
