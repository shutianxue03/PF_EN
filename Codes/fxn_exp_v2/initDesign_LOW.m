function design = initDesign(vpcode)

global scr visual sequence participant params constant

% randomize random
rand('state',sum(100*clock));

design.fixDur       = 0.200;      % fixation duration [s]
design.fixNoise     = 0.050;      % noise duration [s]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch constant.CUE
    case 0 %NO CUE
        design.preCueDur1   = 0.050;      % fixation duration [s]
        design.preCueDur2   = 0.100;      % preCue   duration [s]
        design.preISIDur    = 0.100;      % preISI   duration [s]
    case 1 %EXO
        design.preCueDur1   = 0.120;      % fixation duration [s]
        design.preCueDur2   = 0.070;      % preCue   duration [s]
        design.preISIDur    = 0.060;      % preISI   duration [s]
    case 2 %ENDO
        design.preCueDur1   = 0.150;      % fixation duration [s]
        design.preCueDur2   = 0.050;      % preCue   duration [s]
        design.preISIDur    = 0.050;      % preISI   duration [s]
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

design.stimDur      = 0.050;      % target   duration [s]
design.postISIDur   = 0.300;      % postISI  duration [s]
design.afterKeyDur  = 0.050;
design.ITIDur       = 0.050;      % ITI interval [s]

% if constant.EYETRACK==0
%     design.stimDur       =  0.200;      % target   duration [s]
% end


design.fixX     = 0.0;         % eccentricity of fixation x (relative to screen center)
design.fixY     = 0.0;         % eccentricity of fixation y (relative to screen center)

design.nLoc            = 9;
design.nStairs         = length(params.startLvl);
design.nNoiseLvL       = length(params.extNoiseLvl);


design.nBlocks      = 5; % 5 sessions of 6 blocks 
design.nRepet       = 10; % need ~5-6, but design up to 10 just to be safe
design.nBlockTotal  = design.nBlocks.*design.nRepet;
design.nBlocksPerSession = 5;

sequenceMatrixALL = [];
for nRepet = 1:design.nRepet
    % stair
    sequenceMatrix = [];
    for loc = [1 6 7 8 9]%1:design.nLoc
        for noise = [1 design.nNoiseLvL]
            for st = 1:design.nStairs
                for nTrials = 1:params.nTrialsPerStair;
                    sequenceMatrix = [sequenceMatrix;constant.CUE loc noise st];
                end
            end
        end
    end
    
    % catch trials
    for loc = [1 6 7 8 9]%1:design.nLoc
        for noise = [1 design.nNoiseLvL]%1:design.nNoiseLvL
            for st = design.nStairs + (1:2)
                for nTrials = 1:params.nTrialsCatch;
                    sequenceMatrix = [sequenceMatrix;constant.CUE loc noise st];
                end
            end
        end
    end
    
    
    sequenceMatrix = sequenceMatrix(randperm(length(sequenceMatrix)),:);
    sequenceMatrix = sequenceMatrix(randperm(length(sequenceMatrix)),:);
    
    % check design
    for loc=1:design.nLoc; for noise=1:design.nNoiseLvL;cM(loc,noise)=sum(sequenceMatrix(:,2)==loc & sequenceMatrix(:,3)==noise);end;end
%     if sum(sum(cM==(params.nTrialsPerStair.*design.nStairs + 2.*params.nTrialsCatch)))-length(cM(:))~=0;sca;error('CHECK SEQUENCE MATRIX: UNEQUAL # OF TRIALS PER CONDITION');end
    
%     sequenceMatrix    = [sequenceMatrix repmat((((nRepet-1).*design.nBlocks)+(1:design.nBlocks))',length(sequenceMatrix)./design.nBlocks,1)];
    sequenceMatrix    = [sequenceMatrix repmat((((nRepet-1).*design.nBlocks)+(1:design.nBlocks))',length(sequenceMatrix)./design.nBlocks,1)];
    
    sequenceMatrixALL = [sequenceMatrixALL; sequenceMatrix];
end

sequenceMatrix = sequenceMatrixALL;

design.sequenceMatrix = sequenceMatrix;


for block = 1:design.nBlockTotal
    
    trialBlock    = sequenceMatrix(:,end)==block;
    sequenceBlock = sequenceMatrix(trialBlock,:);
    
    for t = 1:length(sequenceBlock)
        
        fixX  = design.fixX;
        fixY  = design.fixY;
        
        trial(t).scue          = sequenceBlock(t,1);
        trial(t).targetLoc     = sequenceBlock(t,2);
        trial(t).extNoiseLvl   = sequenceBlock(t,3);
        trial(t).stair         = sequenceBlock(t,4);
        
        trial(t).fixLoc       = visual.scrCenter+...
            (visual.ppd*[design.fixX design.fixY design.fixX design.fixY]);
        
        trial(t).fixCol       = visual.fixColor;
        trial(t).marCol       = visual.black;
        
        trial(t).fixDur      = round(design.fixDur/scr.fd)*scr.fd;
        trial(t).fixNoise    = round(design.fixNoise/scr.fd)*scr.fd;
        
        trial(t).preCueDur1   = round(design.preCueDur1/scr.fd)*scr.fd;
        trial(t).preCueDur2   = round(design.preCueDur2/scr.fd)*scr.fd;
        
        trial(t).preISIDur   = round(design.preISIDur/scr.fd)*scr.fd;
        trial(t).stimDur     = round(design.stimDur/scr.fd)*scr.fd;
        trial(t).postISIDur  = round(design.postISIDur/scr.fd)*scr.fd;
        trial(t).ITIDur      = round((design.ITIDur.*rand)/scr.fd)*scr.fd;
        trial(t).afterKeyDur = design.afterKeyDur;
        
        design.block(block).trial(t) = trial(t);
    end
    
    design.nTrialsPB  = t;   % number of trials per Block
end


for loc = 1:design.nLoc
    for noise = 1:design.nNoiseLvL
        for st = 1:design.nStairs
            params.UD{loc,noise,st} = PAL_AMUD_setupUD('up',1,'down',params.stairRule(st),...
                'stepSizeUp',params.stairStep(1),'stepSizeDown',params.stairStep(1),...
                'stopCriterion','trials','stopRule',params.stairStopRule,'startValue',params.startLvl(st),...
                'xMax',params.maxVal,'xMin',params.minVal,'truncate','yes');
        end
    end
end


% catch trials ones
for loc = 1:design.nLoc
    for noise = 1:design.nNoiseLvL
        for st = (1:2)+design.nStairs
            params.UD{loc,noise,st} = PAL_AMUD_setupUD('up',100,'down',100,...
                'stepSizeUp',0,'stepSizeDown',0,...
                'stopCriterion','trials','stopRule',params.stairStopRule,'startValue',params.catchLvl(st-design.nStairs),...
                'xMax',params.maxVal,'xMin',params.minVal,'truncate','yes');
        end
    end
end
