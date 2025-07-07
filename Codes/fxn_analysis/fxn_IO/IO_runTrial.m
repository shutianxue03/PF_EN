function [correctness, cst, UD, internalVar] = IO_runTrial(UD, run, params, visual)

%run: [iLoc, iNoise, iStair, ORI]

%% extract
iLoc = run(1);
iNoise = run(2);
iStair = run(3);
ORI = run(4);
cst = 10.^UD{iLoc,iNoise,iStair}.xCurrent;

%% create dynamic white noise sequence
% assume 5 frames
noiseImg = randn(params.gaborsiz, params.gaborsiz, 5, params.nLoc)...
    .*params.extNoiseLvl(iNoise).*visual.bgColor; %Make the noise and adjust its contrast

%% create gabor
gaborPhase = 2*pi*rand;

gabor = CreateGabor(params.gaborsiz,params.gaborenvelopedev,params.gaborangle(ORI),params.gaborfrequency,...
    gaborPhase,2.*visual.bgColor.*cst);
gabor1 = CreateGabor(params.gaborsiz,params.gaborenvelopedev,params.gaborangle(ORI),params.gaborfrequency,...
    gaborPhase,2.*visual.bgColor.*cst);
gabor2 = CreateGabor(params.gaborsiz,params.gaborenvelopedev,params.gaborangle(mod(ORI,2)+1),params.gaborfrequency,...
    gaborPhase,2.*visual.bgColor.*cst);

% add stim to target noise sequence
% nFrames = input('How many frames: ')
for iframe = 1%:nFrames %Iterate through the number of frames 
% Jared's code: just one frame
    noiseImg(:,:,iframe) = (noiseImg(:, :, iframe)+gabor);
end

% make texture
aperture = CreateCircularAperture(params.gaborsiz,round(.25.*visual.ppd));
stimImg = min(max(noiseImg.*aperture + visual.bgColor,0),1);
stimImg1 = min(max(gabor1.*aperture + visual.bgColor,0),1);
stimImg2 = min(max(gabor2.*aperture + visual.bgColor,0),1);

%---------------------------------------------------------------------------
[correctness, internalVar] = IO_getResp(stimImg, stimImg1, stimImg2);
%---------------------------------------------------------------------------

% update istaircase
UD{iLoc,iNoise,iStair} = PAL_AMUD_updateUD(UD{iLoc,iNoise,iStair}, correctness);
% adjust step size after 10 trials
if length(UD{iLoc,iNoise,iStair}.response)==10
    UD{iLoc,iNoise,iStair}.stepSizeUp = params.stairStep(2);
    UD{iLoc,iNoise,iStair}.stepSizeDown = params.stairStep(2);
elseif length(UD{iLoc,iNoise,iStair}.response)==20
    UD{iLoc,iNoise,iStair}.stepSizeUp = params.stairStep(3);
    UD{iLoc,iNoise,iStair}.stepSizeDown = params.stairStep(3);
end

