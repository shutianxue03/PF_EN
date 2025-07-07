function design = initDesign

global scr visual sequence participant params constant
% do NOT globalized design because it's huge

% randomize random
rand('state',sum(100*clock));

%% time
design.fixDur = 0.400;  % fixation duration [s] % originally .2
design.fixNoise = 0.050;  % noise duration [s] % originally .05

switch constant.CUE
    case 0 %NO CUE
        design.preCueDur1 = 0.050;  % fixation duration [s]
        design.preCueDur2 = 0.100;  % preCue duration [s]
        design.preISIDur  = 0.100;  % preISI duration [s]
    case 1 %EXO
        design.preCueDur1 = 0.120;  % fixation duration [s]
        design.preCueDur2 = 0.070;  % preCue duration [s]
        design.preISIDur  = 0.060;  % preISI duration [s]
    case 2 %ENDO
        design.preCueDur1 = 0.150;  % fixation duration [s]
        design.preCueDur2 = 0.050;  % preCue duration [s]
        design.preISIDur  = 0.050;  % preISI duration [s]
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

design.stimDur  = 0.050;  % target duration [s]
design.postISIDur = 0.300;  % postISI  duration [s] % originally .3
design.bufferDur  = 0.3; % SX, dur between stim offset and go cue
design.afterKeyDur  = 0.020;
design.ITIDur = .05;  % ITI interval [s], will be jittered (line 162)

%% location
design.fixX = 0.0; % eccentricity of fixation x (relative to screen center)
design.fixY = 0.0; % eccentricity of fixation y (relative to screen center)

params.nLoc_PH = 9; % 9 placeholders (regardless how many locations being tested)
% params.nLoc_tgt =  constant.nLoc_tgt; % manually controlled; should I save 'params' since it change every time
design.nLoc_tgt = constant.nLoc_tgt; % manually controlled

design.nNoiseSD = constant.nNoiseSD; % change to nNoiseSD later

design.nStairs = length(params.startLvl); % edit in initStim
design.nTrialsPerStairCatch = 6;
if constant.expMode==2
    design.nTrialsPerStairCatch = 2; %SX, default=2; set anchoring points in each staircase in 'initStim'
end

%% number of trials in total
constant.nTrialsPerBlock_exp1 = 144; % default:144
constant.nTrialsPerBlock_exp3 = 120; % default: 120
design.nStairs = params.nStairs ;
design.nStairsCatch = params.nStairsCatch;
design.nTrialsPerStair = params.nTrialsPerStair;
if constant.expMode==1, design.nRepeat = constant.nRepet; % need ~5-6, but design up to 10 just to be safe; SX
else, design.nRepeat = 1;
end
design.nTrialsTotal = design.nRepeat * design.nLoc_tgt * design.nNoiseSD * ...
    (design.nStairs * params.nTrialsPerStair + design.nStairsCatch * design.nTrialsPerStairCatch); % SX

fprintf('\n================================================\n*[%s] %d trials*\n%d target locations: [%s]\n%d noise levels\n%d stairs (%d trials per stair)\n%d catch stairs (%d trials per stair)\n%d Reps\n\n', ...
    constant.names_expModes{constant.expMode}, design.nTrialsTotal, design.nLoc_tgt, num2str(constant.iLoc_tgt_all), ...
    design.nNoiseSD, design.nStairs, design.nTrialsPerStair, design.nStairsCatch, design.nTrialsPerStairCatch, design.nRepeat)

%% block & session design
if constant.expMode==1
    design.nTrialsPerBlock = constant.nTrialsPerBlock_exp1; % [manual] number of trials per block, SX
    design.nBlocksPerSession = design.nTrialsTotal/design.nTrialsPerBlock ; % number of blocks per 1h session
else % practice
    design.nTrialsPerBlock = design.nTrialsTotal; % [manual] number of trials per block, SX
    design.nBlocksPerSession = 1; % number of blocks per 1h session
end
design.nBlockTotal = round(design.nTrialsTotal/design.nTrialsPerBlock); % [manual] number of blocks to finish all trials per rep (<=100 trials per block), SX

% if design.nTrialsPerBlock > 150, error('WARNING: number of trials per block is too high (=%d)!!', design.nTrialsPerBlock), end

if design.nBlockTotal/design.nBlocksPerSession<=1
    design.nSess=1;
    fprintf('Number of total trials: %d = %d x %d blocks x %d sessions\n================================================\n\n',  ...)
        design.nTrialsTotal, design.nTrialsPerBlock, design.nBlockTotal, design.nSess)
else
    design.nSess = design.nBlockTotal/design.nBlocksPerSession;
    fprintf('Number of total trials: %d = %d x %d blocks x %d sessions\n================================================\n\n',  ...)
        design.nTrialsTotal, design.nTrialsPerBlock, design.nBlocksPerSession, design.nSess)
end

%% create trial matrix
sequenceMatrix = [];
for irep = 1:design.nRepeat
    sequenceMatrix_perRep = [];
    % main trials
    for iLoc = constant.iLoc_tgt_all%1:design.nLoc_tgt
        %         for iNoise = constant.ind_Neq%1:design.nNoiseSD
        for iNoise = 1:design.nNoiseSD
            for iStair = 1:design.nStairs
                if iStair<=design.nStairs/2, ORI=1; else, ORI=2; end
                for i_nTrials = 1:params.nTrialsPerStair
                    sequenceMatrix_perRep = [sequenceMatrix_perRep; constant.CUE, iLoc, params.extNoiseLvl(constant.ind_Neq(iNoise)), iStair, ORI];
                end
            end
        end
    end
    
    % catch trials
    for iLoc = constant.iLoc_tgt_all%1:design.nLoc_tgt
        for iNoise = constant.ind_Neq%1:design.nNoiseSD
            for iStair = design.nStairs + (1:design.nStairsCatch)
                for i_nTrials = 1:design.nTrialsPerStairCatch
                    if i_nTrials<=design.nTrialsPerStairCatch/2, ORI=1; else, ORI=2; end
                    sequenceMatrix_perRep = [sequenceMatrix_perRep; constant.CUE, iLoc, params.extNoiseLvl(constant.ind_Neq(iNoise)), iStair, ORI];
                end
            end
        end
    end
    
    %     randomize trial matrix, twice
    sequenceMatrix_perRep = sequenceMatrix_perRep(randperm(size(sequenceMatrix_perRep, 1)),:);
    sequenceMatrix_perRep = sequenceMatrix_perRep(randperm(size(sequenceMatrix_perRep, 1)),:);
    sequenceMatrix = [sequenceMatrix; sequenceMatrix_perRep];
end % for irep

% add iblock index
if design.nTrialsTotal<design.nTrialsPerBlock
    indBlock = ones(1,design.nTrialsTotal);
else
    indBlock = repmat(1:design.nBlockTotal, 1, design.nTrialsPerBlock);
end
sequenceMatrix = [sequenceMatrix, indBlock'];

% randomize
sequenceMatrix = sequenceMatrix(randperm(size(sequenceMatrix, 1)),:);

design.sequenceMatrix = sequenceMatrix;

%% group trials based on iblock (the 5th col of sequenceMatrix)
for iblock = 1:design.nBlockTotal
    itrial_currentBlk = sequenceMatrix(:,end)==iblock;
    sequenceBlock = sequenceMatrix(itrial_currentBlk,:);
    %     assert(design.nTrialsPerBlock == size(sequenceBlock, 1))
    for itrial = 1:design.nTrialsPerBlock
        % design
        trial(itrial).scue  = sequenceBlock(itrial,1);
        trial(itrial).targetLoc = sequenceBlock(itrial,2);
        trial(itrial).extNoiseLvl = sequenceBlock(itrial,3); % change to noiseSD later
        trial(itrial).stair = sequenceBlock(itrial,4);
        trial(itrial).stimOri = sequenceBlock(itrial,5);
        
        % params
        fixX  = design.fixX;
        fixY  = design.fixY;
        trial(itrial).fixLoc = visual.scrCenter+ (visual.ppd*[design.fixX, design.fixY, design.fixX, design.fixY]);
        trial(itrial).fixCol = visual.fixColor;
        trial(itrial).marCol = visual.black;
        trial(itrial).fixDur  = round(design.fixDur/scr.fd)*scr.fd;
        trial(itrial).fixNoise  = round(design.fixNoise/scr.fd)*scr.fd;
        trial(itrial).preCueDur1 = round(design.preCueDur1/scr.fd)*scr.fd;
        trial(itrial).preCueDur2 = round(design.preCueDur2/scr.fd)*scr.fd;
        trial(itrial).preISIDur = round(design.preISIDur/scr.fd)*scr.fd;
        trial(itrial).stimDur = round(design.stimDur/scr.fd)*scr.fd;
        trial(itrial).bufferDur = round(design.bufferDur/scr.fd)*scr.fd;
        trial(itrial).postISIDur  = round(design.postISIDur/scr.fd)*scr.fd;
        trial(itrial).ITIDur  = round((design.ITIDur.*rand)/scr.fd)*scr.fd;
        trial(itrial).afterKeyDur = design.afterKeyDur;
        
        % empty containers for recording response
        trial(itrial).itrial = [];
        trial(itrial).iblock_local = [];
        trial(itrial).iblock = [];
        trial(itrial).stimContrast = [];
        trial(itrial).fixBreak = [];
        trial(itrial).rt = [];
        trial(itrial).oriResp = [];
        trial(itrial).confidence = [];
        trial(itrial).cor = [];
        
        design.allBlocks(iblock).allTrials(itrial) = trial(itrial);
    end % for itrial
    
    design.nTrialsPB  = itrial; % number of trials per Block
end % for iblock

%% create staircases for MAIN trials
for iLoc_tgt = constant.iLoc_tgt_all%1:design.nLoc_tgt
    for iNoise = 1:design.nNoiseSD
        for iStair = 1:design.nStairs
            params.UD{iLoc_tgt, iNoise, iStair} = PAL_AMUD_setupUD('up',1,'down',params.stairRule(iStair),...
                'stepSizeUp',params.stairStep(1),'stepSizeDown',params.stairStep(1),...
                'stopCriterion','trials','stopRule',params.stairStopRule,'startValue',params.startLvl(iStair),...
                'xMax',params.maxVal,'xMin',params.minVal,'truncate','yes');
        end % for iStair
    end % for iNoise
end % for iLoc

%% create staircases for CATCH trials and append them at the send of group of staircases
if constant.expMode==1
    for iLoc_tgt = constant.iLoc_tgt_all%1:design.nLoc_tgt
        for iNoise = 1:design.nNoiseSD
            for iStair = design.nStairs + (1:design.nStairsCatch)
                params.UD{iLoc_tgt, iNoise, iStair} = PAL_AMUD_setupUD('up',100,'down',100,...
                    'stepSizeUp',0,'stepSizeDown',0,...
                    'stopCriterion','trials','stopRule',params.stairStopRule,'startValue',params.catchLvl(iStair-design.nStairs),...
                    'xMax',params.maxVal,'xMin',params.minVal,'truncate','yes');
            end % for iStair
        end % for iNoise
    end % for iLoc
end
