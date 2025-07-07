function design = initDesign(vpcode)

global scr visual sequence participant params

% randomize random
rand('state',sum(100*clock));

design.fixDur       = 0.300;      % fixation duration [s]
design.preCueDur    = 0.060;      % preCue   duration [s]
design.preISIDur    = 0.00;      % preISI   duration [s]
design.stimDur      = 0.100;      % target   duration [s]
design.postISIDur   = 0.100;      % postISI  duration [s]
% design.postCueDur   = 0.500;      % postCue  duration [s]
design.afterKeyDur  = 0.100;      
design.ITIDur       = 0.100;      % ITI interval [s]

design.fixX     = 0.0;         % eccentricity of fixation x (relative to screen center)
design.fixY     = 0.0;         % eccentricity of fixation y (relative to screen center)

sequenceMatrix = [];
for nTrialCond = 1:10
    for testSide = 1:2
        sequenceMatrix = [sequenceMatrix; testSide 3 6];
    end
end

sequenceMatrix = Shuffle(sequenceMatrix);
sequenceMatrix = Shuffle(sequenceMatrix);

design.nBlocks = 1;
sequenceMatrix = [sequenceMatrix repmat([1:design.nBlocks]',length(sequenceMatrix)./design.nBlocks,1)];

for block = 1:design.nBlocks
    
    trialBlock    = sequenceMatrix(:,4)==block;
    sequenceBlock = sequenceMatrix(trialBlock,:);
    
    for t = 1:length(sequenceBlock)
        
        fixX  = design.fixX;
        fixY  = design.fixY;
        
        trial(t).block         = block; % block
        
        trial(t).testSide      = sequenceBlock(t,1);
        trial(t).scue          = sequenceBlock(t,2);
        trial(t).testContrast  = params.testcontrast(sequenceBlock(t,3));
        
        trial(t).stdContrast   = params.stdcontrast;
        
        trial(t).fixLoc       = visual.scrCenter+...
            (visual.ppd*[design.fixX design.fixY design.fixX design.fixY]);

        trial(t).fixCol       = visual.fixColor;
        trial(t).marCol       = visual.black;
        
        trial(t).fixDur      = round(design.fixDur/scr.fd)*scr.fd;
        trial(t).preCueDur   = round(design.preCueDur/scr.fd)*scr.fd;
        trial(t).preISIDur   = round(design.preISIDur/scr.fd)*scr.fd;
        trial(t).stimDur     = round(design.stimDur/scr.fd)*scr.fd;
        trial(t).postISIDur  = round(design.postISIDur/scr.fd)*scr.fd;
%         trial(t).postCueDur  = round(design.postCueDur/scr.fd)*scr.fd;
        trial(t).ITIDur      = round(design.ITIDur/scr.fd)*scr.fd;
        trial(t).afterKeyDur = design.afterKeyDur;
        
        design.block(block).trial(t) = trial(t);

    end
% %     % randomize trial sequence
%     r = randperm(t);
end

design.blockOrder = randperm(block);

design.block      = design.block(design.blockOrder);
design.nTrialsPB  = t;   % number of trials per Block
