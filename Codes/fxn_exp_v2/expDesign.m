function design = expDesign(vpcode)

% 2012 by Antoine Barbot, adapted from Martin Rolfs

global visual scr sequence participant

% randomize random
rand('state',sum(100*clock));

design.fixDur       = 0.500;                       % fixation duration [s]
design.preCueDur    = 0.500;                       % preCue   duration [s]
design.preISIDur    = 0.500;                       % preISI   duration [s]
design.targetDur    = 0.100;                       % target   duration [s]
design.postISIDur   = 0.200;                       % postISI  duration [s]
design.postCueDur   = 0.100;                       % postCue  duration [s]
design.afterKeyDur  = 0.200;
design.ITIDur       = 0.100;                       % ITI      interval [s]

design.levFixX     = 0.0;                          % eccentricity of fixation x (relative to screen center)
design.levFixY     = 0.0;                          % eccentricity of fixation y (relative to screen center)


[sequence] = SAFBA_BuildExperiment;
design.nBlocks = length(sequence);
for block = 1:design.nBlocks
    for t = 1:length(sequence(block).target)
        
        fixx  = design.levFixX;
        fixy  = design.levFixY;
        trial(t).block         = block; % block
        trial(t).color         = sequence(block).color(t); % color code
        trial(t).scue          = sequence(block).scue(t);  % spatial cue
        trial(t).sprobe        = sequence(block).sprobe(t); % spatial probe
        trial(t).fcue          = sequence(block).fcue(t);  % spatial cue
        trial(t).fprobe        = sequence(block).fprobe(t); % spatial probe
        trial(t).target        = sequence(block).target(t); % target y/n
        trial(t).contrast      = participant.contrast;
        
        trial(t).fixLoc        = visual.scrCenter+round(visual.ppd*[fixx fixy fixx fixy]);
        trial(t).fixCol        = visual.fixColor;
        trial(t).marCol        = visual.black;
        
        trial(t).fixDur      = round(design.fixDur/scr.fd)*scr.fd;
        trial(t).preCueDur   = round(design.preCueDur/scr.fd)*scr.fd;
        trial(t).preISIDur   = round(design.preISIDur/scr.fd)*scr.fd;
        trial(t).targetDur   = round(design.targetDur/scr.fd)*scr.fd;
        trial(t).postISIDur  = round(design.postISIDur/scr.fd)*scr.fd;
        trial(t).postCueDur  = round(design.postCueDur/scr.fd)*scr.fd;
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
