
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% PERFORMANCE FIELDS ? EQUIVALENT NOISE %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 2018 by Antoine Barbot
% started to be adapted by Shutian Xue in Feb,  2023

%%%%%%%%%%%%%%%%%%
% PRESENT STUDY: %'
%%%%%%%%%%%%%%%%%%
% Use equivalent noise method and LAM model to chacracterize the functional
% sources of perceptual inefficiencies as a function of eccentricity and polar angle

clear all, close all, clc, format compact % SX
commandwindow; % SX; force the cursor to go automatically to command window

% generate paths
addpath(genpath('Data/Data/')); % SX
addpath(genpath('Data/eyedata/')); % SX
addpath(genpath('Codes/')); % SX

global constant scr visual participant sequence stimulus response confidence timing params
% do NOT globalized design because it's huge

%% Enter info
SX_initSettings

%% get response keys & disable keyboard
getKeyAssignment;
fprintf('* Key initiated *\n\n')

%% prepare screens (has to be out at the start!! otherwise no scr input to initStim)
fprintf('* Screen initiating ... *')
initScreen;
fprintf('* Screen initiated *')

%% prepare sound
initSound
fprintf('* Sound initiated *\n\n')

%% initialize eyelink-connection
el=[];
if constant.EYETRACK
    el = SX3_initEL(scr.main);
    fprintf('* Eyelink initiated *\n\n')
else
    fprintf('* Eyelink NOT supposed to be initiated *\n\n')
end% SX

%% titration/constim
scaling=2; % for constim mode only (higher values, finer sampling within the dynamic range)

%% load previous data (to get design and constant.iblock)
if constant.expMode == 2 % practice
    params.lastBlock = 0;
    constant.iSess = 1;
    constant.iblock = 1;
else % NOT practice
    % create folder name, and create an empty folder is non-existent
    dirFolder = dir(constant.nameFolder);
    if isempty(dirFolder), mkdir(constant.nameFolder), fprintf('\n\nFolder created:\n'), addpath(genpath('Data/')); else, fprintf('\n\nFolder exists:\n'), end
    disp(constant.nameFolder)

    % check if last block exists
    if constant.expMode==1
        nameFile_last = sprintf('%s/%s_E1_b*', constant.nameFolder, participant.subjName);

    elseif constant.expMode==3
        % load the last file collected when expMode=1, to get design
        nameFileE1_last = sprintf('%s/%s_E1_b*', constant.nameFolder, participant.subjName);
        dirFileE1_last = dir(nameFileE1_last);
        if ~isempty(dirFileE1_last), load(dirFileE1_last(end).name), fprintf('Titration data loaded\n')
        else, error('ALERT: %s does NOT have titration data!!', participant.subjName);
        end
        nameFile_last = sprintf('%s/%s_E3_b*', constant.nameFolder, participant.subjName);

    elseif constant.expMode==4
        % load the last file collected when expMode=1, to get design
        nameFileE1_last = sprintf('%s/%s_E1_b*', constant.nameFolder, participant.subjName);
        dirFileE1_last = dir(nameFileE1_last);
        if participant.subjName ~='SP',
            if ~isempty(dirFileE1_last), load(dirFileE1_last(end).name), fprintf('Titration data loaded\n')
            else, error('ALERT: %s does NOT have titration data!!', participant.subjName);
            end
        end
        nameFile_last = sprintf('%s/%s_E4_b*', constant.nameFolder, participant.subjName);
        iSess = input('\n\n       >>> Enter the session index: ');
        constant.iSess=iSess;
        nameFile_last = sprintf('%s/%s_E4_s%d_b*', constant.nameFolder, participant.subjName, iSess);

    elseif constant.expMode==5 % (1) add 2 more noise levels at old loc; (2) add more data at old noise levels (3) add 4 new loc
        nameFile_last = sprintf('%s/%s_E5_b*', constant.nameFolder, participant.subjName);

    end
    dirFile_last = dir(nameFile_last);
    fprintf('In the current exp mode [%d], %d files have been collected\n', constant.expMode, length(dirFile_last))

    if isempty(dirFile_last)
        %         constant.iSess = 1;
        constant.iblock = 1;
        params.lastBlock = 0;
    else
        load(dirFile_last(end).name)
        fprintf('Loaded: %s\n', dirFile_last(end).name)
        %         constant.iSess = params.lastSess + 1;
        constant.iblock = params.lastBlock + 1;
    end % if isempty(dirFile_last)
end

%% INITIATE DESIGN
% design and stim
if constant.expMode>=3
    constant.iblock_accumulate = constant.iblock;
end

if constant.iblock==1 % no previous data of the current mode has been collected

    if constant.expMode == 3 % constim levels are derived from titration data
        design_old = design;
        %------------------------------------------------%
        design = initDesign_expMode3(design_old, scaling);
        %------------------------------------------------%

    elseif constant.expMode == 4 % constim levels are manually set

        if participant.subjName =='SP'
            %------------------------------------------------%
            initStim
            design_old = initDesign;
            %------------------------------------------------%
        else, design_old = design;
        end
        %------------------------------------------------%
        design = initDesign_expMode4(design_old, scaling);
        %------------------------------------------------%

    elseif constant.expMode==5 % (1) mode 1 + mode 4
        %------------------------------------------------%
        initStim
        design = initDesign_expMode5;
        %------------------------------------------------%

    elseif constant.expMode < 3
        %------------------------------------------------%
        initStim
        design = initDesign;
        %------------------------------------------------%
    end

else
    fprintf('Using the design/stim created in the last saved file...\n')
    % do NOT need to initiate anything; just follow the design matrix
    % created by the loaded file (the last file of the current exp mode)
end

fprintf('* Stim & Design initiated *\n')

%% run all trials
for ff = 6e2:2e2:1e3, makeBeep(ff, .2), end
tic % do NOT delete!!
real_sequence = runTrialSequence(design, el);

%%%%%%%%%%%%
endExp_SX

%% extract ccc and visualize data
close all, clc

fprintf('Add high noise (e.g., 8th)?')

if constant.expMode~=2
    %     postExpPlot_SX
end
