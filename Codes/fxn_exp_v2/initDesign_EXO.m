function design = initDesign(vpcode)

global scr visual sequence participant params constant

% randomize random
rand('state',sum(100*clock));

design.fixDur       = 0.250;      % fixation duration [s]
design.preCueNoise  = 0.500;      % fixation duration [s]
design.preCueDur    = 0.080;      % preCue   duration [s]
design.preISIDur    = 0.040;      % preISI   duration [s]
design.stimDur      = 0.050;      % target   duration [s]
design.postISIDur   = 0.600;      % postISI  duration [s]
design.afterKeyDur  = 0.100;      
design.ITIDur       = 0.400;      % ITI interval [s]

design.fixX     = 0.0;         % eccentricity of fixation x (relative to screen center)
design.fixY     = 0.0;         % eccentricity of fixation y (relative to screen center)

design.nLoc            = 9;
design.nStairs         = length(params.startLvl);
design.nNoiseLvL       = length(params.extNoiseLvl);
design.nTrialsPerStair = 4;%60;

sequenceMatrix = [];
for cueCond = 1
    for loc = 1:design.nLoc
        for noise = 1:design.nNoiseLvL
            for st = 1:design.nStairs
                for nTrials = 1:design.nTrialsPerStair;
                    sequenceMatrix = [sequenceMatrix;constant.CUE 1 2 st];
                end
            end
        end
    end
end


sequenceMatrix = Shuffle(sequenceMatrix);
sequenceMatrix = Shuffle(sequenceMatrix);


design.nBlocks = 112; % 28 half-sessions of 4 blocks of 135 trials = 112 blocks
design.nBlocksPerSession = 4;
sequenceMatrix = [sequenceMatrix repmat([1:design.nBlocks]',length(sequenceMatrix)./design.nBlocks,1)];

for block = 1:design.nBlocks
    
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
        trial(t).preCueDur   = round(design.preCueDur/scr.fd)*scr.fd;
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
                'stepSizeUp',params.stairStep,'stepSizeDown',params.stairStep,...
                'stopCriterion','trials','stopRule',60,'startValue',params.startLvl(st),...
                'xMax',params.maxVal,'xMin',params.minVal,'truncate','yes');
        end
    end
end
