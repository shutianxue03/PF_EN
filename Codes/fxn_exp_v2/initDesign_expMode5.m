function design = initDesign_expMode5

global scr visual participant params constant

% MODE 1 (titration)
design.iLoc_tgt_all_mode1 = input('            >>> Loc for mode 1 (titration): ');
params.noiseSD_all_mode1 = input('            >>> Noise SD for mode 1 (titration): ');
params.nNoiseSD_mode1 = length(params.noiseSD_all_mode1);
% MODE 4 (constim)
cst_ln_manual = input('            >>> Manually add constim stim (linear): ');
[nLoc_mode4, nNoiseSD_mode4] = size(cst_ln_manual);
nConstim = 0; for iLoc=1:nLoc_mode4, for iN=1:nNoiseSD_mode4; if ~isnan(cst_ln_manual{iLoc, iN}), nConstim=nConstim+length(cst_ln_manual{iLoc, iN}); cst_ln_manual{iLoc, iN} = cst_ln_manual{iLoc, iN}/100; end, end, end
params.extNoiseLvl_full_mode4 = params.noiseSD_all_mode1; assert(length(params.extNoiseLvl) == nNoiseSD_mode4)
design.ntrialsPerConstim = input('            >>> Number of trials per point: ');

design.nRepeat = 2;
design.nStairs = params.nStairs ;
design.nStairsCatch = params.nStairsCatch;
design.nTrialsPerStair = params.nTrialsPerStair;

% common steps for creating design
rand('state',sum(100*clock));

% time
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

% location
design.fixX = 0.0; % eccentricity of fixation x (relative to screen center)
design.fixY = 0.0; % eccentricity of fixation y (relative to screen center)

params.nLoc_PH = 9; % 9 placeholders (regardless how many locations being tested)
design.nLoc_tgt = constant.nLoc_tgt; % manually controlled
design.nStairs = length(params.startLvl); % edit in initStim
design.nTrialsPerStairCatch = 6;
if constant.expMode==2
    design.nTrialsPerStairCatch = 2; %SX, default=2; set anchoring points in each staircase in 'initStim'
end

%%
% SX_analysis_setting % why is this here??

%% MODE 1 (titration at certain loc and noise SD)
sequenceMatrix_mode1 = []; % (4th column is iStair!!)
dataMode = 1;
for irep = 1:design.nRepeat
    sequenceMatrix_perRep = [];
    
    % main trials
    for iLoc = design.iLoc_tgt_all_mode1
        for iNoise = 1:params.nNoiseSD_mode1
            for iStair = 1:design.nStairs
                if iStair<=design.nStairs/2, ORI=1; else, ORI=2; end
                for i_nTrials = 1:params.nTrialsPerStair
                    sequenceMatrix_perRep = [sequenceMatrix_perRep; dataMode, iLoc, ...
                        params.noiseSD_all_mode1(iNoise), iStair, ORI];
                end
            end
        end
    end
    
    % catch trials
    for iLoc = design.iLoc_tgt_all_mode1
        for iNoise = 1:params.nNoiseSD_mode1
            for iStair = design.nStairs + (1:design.nStairsCatch)
                for i_nTrials = 1:design.nTrialsPerStairCatch
                    if i_nTrials<=design.nTrialsPerStairCatch/2, ORI=1; else, ORI=2; end
                    sequenceMatrix_perRep = [sequenceMatrix_perRep; dataMode, iLoc, ...
                        params.noiseSD_all_mode1(iNoise), iStair, ORI];
                end
            end
        end
    end
    
    %     randomize trial matrix, twice
    sequenceMatrix_perRep = sequenceMatrix_perRep(randperm(size(sequenceMatrix_perRep, 1)),:);
    sequenceMatrix_perRep = sequenceMatrix_perRep(randperm(size(sequenceMatrix_perRep, 1)),:);
    sequenceMatrix_mode1 = [sequenceMatrix_mode1; sequenceMatrix_perRep];
end % for irep

%%%%%%%%%%%%%%%%
%%% create staircases %%%%
%%%%%%%%%%%%%%%%
for iLoc_tgt = design.iLoc_tgt_all_mode1
    for iNoise = 1:params.nNoiseSD_mode1
        for iStair = 1:design.nStairs
            params.UD_mode1{iLoc_tgt, iNoise, iStair} = PAL_AMUD_setupUD('up',1,'down',params.stairRule(iStair),...
                'stepSizeUp',params.stairStep(1),'stepSizeDown',params.stairStep(1),...
                'stopCriterion','trials','stopRule',params.stairStopRule,'startValue',params.startLvl(iStair),...
                'xMax',params.maxVal,'xMin',params.minVal,'truncate','yes');
        end % for iStair
    end % for iNoise
end % for iLoc

for iLoc_tgt = design.iLoc_tgt_all_mode1
    for iNoise = 1:params.nNoiseSD_mode1
        for iStair = design.nStairs + (1:design.nStairsCatch)
            params.UD_mode1{iLoc_tgt, iNoise, iStair} = PAL_AMUD_setupUD('up',100,'down',100,...
                'stepSizeUp',0,'stepSizeDown',0,...
                'stopCriterion','trials','stopRule',params.stairStopRule,'startValue',params.catchLvl(iStair-design.nStairs),...
                'xMax',params.maxVal,'xMin',params.minVal,'truncate','yes');
        end % for iStair
    end % for iNoise
end % for iLoc

%% MODE 4 (constim certain loc and noise SD)
% initiate staircases and trials matrix for new loc
% sequenceMatrix_mode4 (4th column is linear contrast!!)
dataMode = 2;

sequenceMatrix_mode4 = [];

for iLoc_tgt = nLoc_mode4
    iiLoc = find(iLoc_tgt == nLoc_mode4);
    for iNoise = 1:nNoiseSD_mode4
        if ~isnan(cst_ln_manual{iiLoc, iNoise})
            for iConstim = 1:length(cst_ln_manual{iiLoc, iNoise})
                sequenceMatrix_mode4 = [sequenceMatrix_mode4; repmat([dataMode, iLoc_tgt, ...
                    params.extNoiseLvl(iNoise), cst_ln_manual{iiLoc, iNoise}(iConstim)], design.ntrialsPerConstim, 1)];
            end
        end
    end
end

indOri = repmat([1,2], 1, size(sequenceMatrix_mode4, 1)/2); indOri = indOri(randperm(length(indOri)));
sequenceMatrix_mode4 = [sequenceMatrix_mode4, indOri'];

%% combine
sequenceMatrix = [sequenceMatrix_mode1; sequenceMatrix_mode4];

% design = design_old;
design.nTrialsTotal = size(sequenceMatrix, 1);
design.nTrialsPerBlock = input(sprintf('         >>> Total %d trials, enter number of trials per block: ', design.nTrialsTotal));
design.nBlockTotal = design.nTrialsTotal/design.nTrialsPerBlock; assert(round(design.nBlockTotal) == design.nBlockTotal)

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
    
    for itrial = 1:design.nTrialsPerBlock
        
        % [expMode5 only]
        % the 4th column is istair or cst_linear;
        % the 1st column is dataMode (originally scue)
        trial(itrial).stimContrast = nan;
        trial(itrial).stair = sequenceBlock(itrial,4);
        if constant.expMode==5
            trial(itrial).dataMode  = sequenceBlock(itrial,1);
            if trial(itrial).dataMode ==2 % constim for old loc and noiseSD, so no staircases
                trial(itrial).stimContrast = sequenceBlock(itrial,4);
            end
        else
            trial(itrial).scue  = sequenceBlock(itrial,1);
        end
        
        trial(itrial).targetLoc = sequenceBlock(itrial,2);
        trial(itrial).extNoiseLvl = sequenceBlock(itrial,3); % change to noiseSD later
        trial(itrial).stimOri = sequenceBlock(itrial,5);
        trial(itrial).iNoise = nan; % create empty holders for 'run' to inherit directly from the sequenceMatrix
        
        % params
        fixX  = design.fixX;
        fixY  = design.fixY;
        trial(itrial).fixLoc = visual.scrCenter+ (visual.ppd*[design.fixX, design.fixY, design.fixX, design.fixY]);
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
        trial(itrial).fixBreak = [];
        trial(itrial).rt = [];
        trial(itrial).oriResp = [];
        trial(itrial).confidence = [];
        trial(itrial).cor = [];
        
        design.allBlocks(iblock).allTrials(itrial) = trial(itrial);
    end % for itrial
    
    design.nTrialsPB  = itrial; % number of trials per Block
end

%% block & session design
fprintf('Number of total trials: %d = %d x %d blocks\n================================================\n\n',  ...)
    design.nTrialsTotal, design.nTrialsPerBlock, design.nBlockTotal)


% function design = initDesign_expMode5
% 
% global scr visual participant params constant
% 
% % randomize random
% design.iLoc_tgt_all_old = 1:5; % SP is 1:9
% design.iLoc_tgt_all_new = 6:9; % SP is nan
% params.noiseSD_new_all = [.66, .88]; %
% params.noiseSD_new2 = [.66, .88]; %
% params.nNoiseSD_new = length(params.noiseSD_new_all);
% params.noiseSD_full =  [0, .055, .11, .165, .22, .33, .44, .66, .88];
% params.noiseSD_full = params.noiseSD_full;
% params.nNoiseSD_full= length(params.noiseSD_full);
% design.nRepeat = 2;
% design.nStairs = params.nStairs ;
% design.nStairsCatch = params.nStairsCatch;
% design.nTrialsPerStair = params.nTrialsPerStair;
% 
% % common steps for creating design
% % randomize random
% rand('state',sum(100*clock));
% 
% % time
% design.fixDur = 0.400;  % fixation duration [s] % originally .2
% design.fixNoise = 0.050;  % noise duration [s] % originally .05
% 
% switch constant.CUE
%     case 0 %NO CUE
%         design.preCueDur1 = 0.050;  % fixation duration [s]
%         design.preCueDur2 = 0.100;  % preCue duration [s]
%         design.preISIDur  = 0.100;  % preISI duration [s]
%     case 1 %EXO
%         design.preCueDur1 = 0.120;  % fixation duration [s]
%         design.preCueDur2 = 0.070;  % preCue duration [s]
%         design.preISIDur  = 0.060;  % preISI duration [s]
%     case 2 %ENDO
%         design.preCueDur1 = 0.150;  % fixation duration [s]
%         design.preCueDur2 = 0.050;  % preCue duration [s]
%         design.preISIDur  = 0.050;  % preISI duration [s]
% end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% design.stimDur  = 0.050;  % target duration [s]
% design.postISIDur = 0.300;  % postISI  duration [s] % originally .3
% design.bufferDur  = 0.3; % SX, dur between stim offset and go cue
% design.afterKeyDur  = 0.020;
% design.ITIDur = .05;  % ITI interval [s], will be jittered (line 162)
% 
% % location
% design.fixX = 0.0; % eccentricity of fixation x (relative to screen center)
% design.fixY = 0.0; % eccentricity of fixation y (relative to screen center)
% 
% params.nLoc_PH = 9; % 9 placeholders (regardless how many locations being tested)
% design.nLoc_tgt = constant.nLoc_tgt; % manually controlled
% design.nStairs = length(params.startLvl); % edit in initStim
% design.nTrialsPerStairCatch = 6;
% if constant.expMode==2
%     design.nTrialsPerStairCatch = 2; %SX, default=2; set anchoring points in each staircase in 'initStim'
% end
% 
% %%
% SX_analysis_setting
% 
% cst_log_lowest = log10(.03);
% cst_log_highest = log10(1.5);
% 
% %% 1. At old locs, add two more noise levels, using staircase
% sequenceMatrix1_newNoiseSD = []; % (4th column is iStair!!)
% dataMode = 1;
% for irep = 1:design.nRepeat
%     sequenceMatrix_perRep = [];
%     
%     % main trials
%     for iLoc = design.iLoc_tgt_all_old
%         for iNoise = 1:params.nNoiseSD_new
%             for iStair = 1:design.nStairs
%                 if iStair<=design.nStairs/2, ORI=1; else, ORI=2; end
%                 for i_nTrials = 1:params.nTrialsPerStair
%                     sequenceMatrix_perRep = [sequenceMatrix_perRep; dataMode, iLoc, ...
%                         params.noiseSD_new2(iNoise), iStair, ORI];
%                 end
%             end
%         end
%     end
%     
%     % catch trials
%     for iLoc = design.iLoc_tgt_all_old
%         for iNoise = 1:params.nNoiseSD_new
%             for iStair = design.nStairs + (1:design.nStairsCatch)
%                 for i_nTrials = 1:design.nTrialsPerStairCatch
%                     if i_nTrials<=design.nTrialsPerStairCatch/2, ORI=1; else, ORI=2; end
%                     sequenceMatrix_perRep = [sequenceMatrix_perRep; dataMode, iLoc, ...
%                         params.noiseSD_new2(iNoise), iStair, ORI];
%                 end
%             end
%         end
%     end
%     
%     %     randomize trial matrix, twice
%     sequenceMatrix_perRep = sequenceMatrix_perRep(randperm(size(sequenceMatrix_perRep, 1)),:);
%     sequenceMatrix_perRep = sequenceMatrix_perRep(randperm(size(sequenceMatrix_perRep, 1)),:);
%     sequenceMatrix1_newNoiseSD = [sequenceMatrix1_newNoiseSD; sequenceMatrix_perRep];
% end % for irep
% 
% %%%%%%%%%%%%%%%%
% %%% create staircases %%%%
% %%%%%%%%%%%%%%%%
% for iLoc_tgt = design.iLoc_tgt_all_old
%     for iNoise = 1:params.nNoiseSD_new
%         for iStair = 1:design.nStairs
%             params.UD1_newNoiseSD{iLoc_tgt, iNoise, iStair} = PAL_AMUD_setupUD('up',1,'down',params.stairRule(iStair),...
%                 'stepSizeUp',params.stairStep(1),'stepSizeDown',params.stairStep(1),...
%                 'stopCriterion','trials','stopRule',params.stairStopRule,'startValue',params.startLvl(iStair),...
%                 'xMax',params.maxVal,'xMin',params.minVal,'truncate','yes');
%         end % for iStair
%     end % for iNoise
% end % for iLoc
% 
% for iLoc_tgt = design.iLoc_tgt_all_old
%     for iNoise = 1:params.nNoiseSD_new
%         for iStair = design.nStairs + (1:design.nStairsCatch)
%             params.UD1_newNoiseSD{iLoc_tgt, iNoise, iStair} = PAL_AMUD_setupUD('up',100,'down',100,...
%                 'stepSizeUp',0,'stepSizeDown',0,...
%                 'stopCriterion','trials','stopRule',params.stairStopRule,'startValue',params.catchLvl(iStair-design.nStairs),...
%                 'xMax',params.maxVal,'xMin',params.minVal,'truncate','yes');
%         end % for iStair
%     end % for iNoise
% end % for iLoc
% 
% %% 2. at old noise levels, add extra data (EXP MODE 4)
% % initiate staircases and trials matrix for new loc
% % sequenceMatrix2_oldNoiseSD (4th column is linear contrast!!)
% dataMode = 2;
% cst_ln_manual = input('\n\n       >>> Manually add constim stim (linear): ');
% nLoc_old = length(design.iLoc_tgt_all_old);
% nConstim = 0; for iLoc=1:nLoc_old, for iN=1:params.nNoiseSD_new; if ~isnan(cst_ln_manual{iLoc, iN}), nConstim=nConstim+length(cst_ln_manual{iLoc, iN}); cst_ln_manual{iLoc, iN} = cst_ln_manual{iLoc, iN}/100; end, end, end
% % SX_analysis_setting
% % design = design_old;
% design.ntrialsPerConstim = constant.ntrialsPerConstim4; fprintf('\nNumber of trials per point is %d!!\n', design.ntrialsPerConstim)% increase from 20 to 30
% % design.nConstim = nConstim;
% 
% sequenceMatrix2_oldNoiseSD = [];
% for iLoc_tgt = design.iLoc_tgt_all_old
%     for iNoise = 1:params.nNoiseSD_new
%         if ~isnan(cst_ln_manual{iLoc_tgt, iNoise})
%             for iConstim = 1:length(cst_ln_manual{iLoc_tgt, iNoise})
%                 sequenceMatrix2_oldNoiseSD = [sequenceMatrix2_oldNoiseSD; repmat([dataMode, iLoc_tgt, ...
%                     params.noiseSD_new2(iNoise), cst_ln_manual{iLoc_tgt, iNoise}(iConstim)], design.ntrialsPerConstim, 1)];
%             end
%         end
%     end
% end
% indOri = repmat([1,2], 1, size(sequenceMatrix2_oldNoiseSD, 1)/2); indOri = indOri(randperm(length(indOri)));
% sequenceMatrix2_oldNoiseSD = [sequenceMatrix2_oldNoiseSD, indOri'];
% 
% %% 3. add 4 new loc (EXP MODE 1)
% % add extra data to data already collected
% % sequenceMatrix3_newLoc (4th column is iStair!!)
% % params.UD3_newLoc{iLoc_tgt, iNoise, iStair}
% dataMode = 3;
% sequenceMatrix3_newLoc = [];
% for irep = 1:design.nRepeat
%     sequenceMatrix_perRep = [];
%     % main trials
%     for iLoc = design.iLoc_tgt_all_new%1:design.nLoc_tgt
%         for iNoise = 1:params.nNoiseSD_new
%             for iStair = 1:design.nStairs
%                 if iStair<=design.nStairs/2, ORI=1; else, ORI=2; end
%                 for i_nTrials = 1:params.nTrialsPerStair
%                     sequenceMatrix_perRep = [sequenceMatrix_perRep; dataMode, iLoc, ...
%                         params.noiseSD_new2(iNoise), iStair, ORI];
%                 end
%             end
%         end
%     end
%     
%     % catch trials
%     for iLoc = design.iLoc_tgt_all_new%1:design.nLoc_tgt
%         for iNoise = 1:params.nNoiseSD_new
%             for iStair = design.nStairs + (1:design.nStairsCatch)
%                 for i_nTrials = 1:design.nTrialsPerStairCatch
%                     if i_nTrials<=design.nTrialsPerStairCatch/2, ORI=1; else, ORI=2; end
%                     sequenceMatrix_perRep = [sequenceMatrix_perRep; dataMode, iLoc, ...
%                         params.noiseSD_new2(iNoise), iStair, ORI];
%                 end
%             end
%         end
%     end
%     
%     %     randomize trial matrix, twice
%     sequenceMatrix_perRep = sequenceMatrix_perRep(randperm(size(sequenceMatrix_perRep, 1)),:);
%     sequenceMatrix_perRep = sequenceMatrix_perRep(randperm(size(sequenceMatrix_perRep, 1)),:);
%     sequenceMatrix3_newLoc = [sequenceMatrix3_newLoc; sequenceMatrix_perRep];
% end % for irep
% 
% %%%%%%%%%%%%%%%%
% %%% create staircases %%%%
% %%%%%%%%%%%%%%%%
% for iLoc_tgt = design.iLoc_tgt_all_new
%     for iNoise = 1:params.nNoiseSD_new
%         for iStair = 1:design.nStairs
%             params.UD3_newLoc{iLoc_tgt, iNoise, iStair} = PAL_AMUD_setupUD('up',1,'down',params.stairRule(iStair),...
%                 'stepSizeUp',params.stairStep(1),'stepSizeDown',params.stairStep(1),...
%                 'stopCriterion','trials','stopRule',params.stairStopRule,'startValue',params.startLvl(iStair),...
%                 'xMax',params.maxVal,'xMin',params.minVal,'truncate','yes');
%         end % for iStair
%     end % for iNoise
% end % for iLoc
% 
% for iLoc_tgt = design.iLoc_tgt_all_new
%     for iNoise = 1:params.nNoiseSD_new
%         for iStair = design.nStairs + (1:design.nStairsCatch)
%             params.UD3_newLoc{iLoc_tgt, iNoise, iStair} = PAL_AMUD_setupUD('up',100,'down',100,...
%                 'stepSizeUp',0,'stepSizeDown',0,...
%                 'stopCriterion','trials','stopRule',params.stairStopRule,'startValue',params.catchLvl(iStair-design.nStairs),...
%                 'xMax',params.maxVal,'xMin',params.minVal,'truncate','yes');
%         end % for iStair
%     end % for iNoise
% end % for iLoc
% 
% %% combine
% sequenceMatrix = [sequenceMatrix1_newNoiseSD;sequenceMatrix2_oldNoiseSD; sequenceMatrix3_newLoc];
% 
% % design = design_old;
% design.nTrialsTotal = size(sequenceMatrix, 1);
% design.nTrialsPerBlock = input(sprintf('         >>> Total %d trials, enter number of trials per block: ', design.nTrialsTotal));
% design.nBlockTotal = design.nTrialsTotal/design.nTrialsPerBlock; assert(round(design.nBlockTotal) == design.nBlockTotal)
% 
% % add iblock index
% if design.nTrialsTotal<design.nTrialsPerBlock
%     indBlock = ones(1,design.nTrialsTotal);
% else
%     indBlock = repmat(1:design.nBlockTotal, 1, design.nTrialsPerBlock);
% end
% sequenceMatrix = [sequenceMatrix, indBlock'];
% 
% % randomize
% sequenceMatrix = sequenceMatrix(randperm(size(sequenceMatrix, 1)),:);
% 
% design.sequenceMatrix = sequenceMatrix;
% 
% %% group trials based on iblock (the 5th col of sequenceMatrix)
% for iblock = 1:design.nBlockTotal
%     itrial_currentBlk = sequenceMatrix(:,end)==iblock;
%     sequenceBlock = sequenceMatrix(itrial_currentBlk,:);
%     %     assert(design.nTrialsPerBlock == size(sequenceBlock, 1))
%     for itrial = 1:design.nTrialsPerBlock
%         
%         % [expMode5 only] 
%         % the 4th column is istair or cst_linear; 
%         % the 1st column is dataMode (originally scue)
%         trial(itrial).stimContrast = nan;
%         trial(itrial).stair = sequenceBlock(itrial,4);
%         if constant.expMode==5
%             trial(itrial).dataMode  = sequenceBlock(itrial,1);
%             if trial(itrial).dataMode ==2 % constim for old loc and noiseSD, so no staircases
%                 trial(itrial).stimContrast = sequenceBlock(itrial,4);
%             end
%         else
%             trial(itrial).scue  = sequenceBlock(itrial,1);
%         end
%         
%         trial(itrial).targetLoc = sequenceBlock(itrial,2);
%         trial(itrial).extNoiseLvl = sequenceBlock(itrial,3); % change to noiseSD later
%         trial(itrial).stimOri = sequenceBlock(itrial,5);
%         trial(itrial).iNoise = nan; % create empty holders for 'run' to inherit directly from the sequenceMatrix
%         
%         % params
%         fixX  = design.fixX;
%         fixY  = design.fixY;
%         trial(itrial).fixLoc = visual.scrCenter+ (visual.ppd*[design.fixX, design.fixY, design.fixX, design.fixY]);
%         trial(itrial).fixDur  = round(design.fixDur/scr.fd)*scr.fd;
%         trial(itrial).fixNoise  = round(design.fixNoise/scr.fd)*scr.fd;
%         trial(itrial).preCueDur1 = round(design.preCueDur1/scr.fd)*scr.fd;
%         trial(itrial).preCueDur2 = round(design.preCueDur2/scr.fd)*scr.fd;
%         trial(itrial).preISIDur = round(design.preISIDur/scr.fd)*scr.fd;
%         trial(itrial).stimDur = round(design.stimDur/scr.fd)*scr.fd;
%         trial(itrial).bufferDur = round(design.bufferDur/scr.fd)*scr.fd;
%         trial(itrial).postISIDur  = round(design.postISIDur/scr.fd)*scr.fd;
%         trial(itrial).ITIDur  = round((design.ITIDur.*rand)/scr.fd)*scr.fd;
%         trial(itrial).afterKeyDur = design.afterKeyDur;
%         
%         % empty containers for recording response
%         trial(itrial).itrial = [];
%         trial(itrial).iblock_local = [];
%         trial(itrial).iblock = [];
%         trial(itrial).fixBreak = [];
%         trial(itrial).rt = [];
%         trial(itrial).oriResp = [];
%         trial(itrial).confidence = [];
%         trial(itrial).cor = [];
%         
%         design.allBlocks(iblock).allTrials(itrial) = trial(itrial);
%     end % for itrial
%     
%     design.nTrialsPB  = itrial; % number of trials per Block
% end
% 
% %% block & session design
% fprintf('Number of total trials: %d = %d x %d blocks\n================================================\n\n',  ...)
%     design.nTrialsTotal, design.nTrialsPerBlock, design.nBlockTotal)
% 
