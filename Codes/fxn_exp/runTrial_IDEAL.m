function [td,params] = runTrial(td,trial,block,params,visual)

td.stimContrast  =  (10.^params.UD{td.targetLoc,td.extNoiseLvl,td.stair}.xCurrent);

% define tilt
if sign(randn)>0
    td.stimOri = 1;
else
    td.stimOri = 2;
end

% % generate noise patches
noiseImg       = []; gabortex       = [];
tempNoise      = []; gabor          = [];
tempStim       = []; stim1 =[]; stim2 =[];

alpha          = CreateCircularAperture(params.gaborsiz,round(.25.*visual.ppd));
% create dynamic white noise sequence
noiseImg    = randn(params.gaborsiz,params.gaborsiz,5,params.nLoc)...
    .*params.extNoiseLvl(td.extNoiseLvl).*visual.bgColor; %Make the noise and adjust its contrast


% create gabor
gaborPhase  = 2*pi*rand;

gabor       = CreateGabor(params.gaborsiz,params.gaborenvelopedev,params.gaborangle(td.stimOri),params.gaborfrequency,...
    gaborPhase,2.*visual.bgColor.*td.stimContrast);
gabor1       = CreateGabor(params.gaborsiz,params.gaborenvelopedev,params.gaborangle(td.stimOri),params.gaborfrequency,...
    gaborPhase,2.*visual.bgColor.*td.stimContrast);
gabor2       = CreateGabor(params.gaborsiz,params.gaborenvelopedev,params.gaborangle(mod(td.stimOri,2)+1),params.gaborfrequency,...
    gaborPhase,2.*visual.bgColor.*td.stimContrast);


% add stim to target noise sequence
for fr = 1 %Iterate through the number of frames
    noiseImg(:,:,fr) = (noiseImg(:,:,fr,td.targetLoc)+gabor);
end

% make texture
stimImg  = min(max(noiseImg.*alpha + visual.bgColor,0),1);
stimImg1 = min(max(gabor1.*alpha + visual.bgColor,0),1);
stimImg2 = min(max(gabor2.*alpha + visual.bgColor,0),1);


response(block).iscor(trial) = idealObserver(stimImg,stimImg1,stimImg2);
%%
td.cor = response(block).iscor(trial)

% update staircase
params.UD{td.targetLoc,td.extNoiseLvl,td.stair} = ...
    PAL_AMUD_updateUD(params.UD{td.targetLoc,td.extNoiseLvl,td.stair},...
    td.cor);
% adjust step size after 10 trials
if length(params.UD{td.targetLoc,td.extNoiseLvl,td.stair}.response)==10
    params.UD{td.targetLoc,td.extNoiseLvl,td.stair}.stepSizeUp   = params.stairStep(2);
    params.UD{td.targetLoc,td.extNoiseLvl,td.stair}.stepSizeDown = params.stairStep(2);
elseif length(params.UD{td.targetLoc,td.extNoiseLvl,td.stair}.response)==20
    params.UD{td.targetLoc,td.extNoiseLvl,td.stair}.stepSizeUp   = params.stairStep(3);
    params.UD{td.targetLoc,td.extNoiseLvl,td.stair}.stepSizeDown = params.stairStep(3);
end

