

function initStim

global constant visual scr params
%% Visual params
visual.ppd = va2pix(1,scr); % pixel per degree
visual.degPerCm = scr.viewingDist./57;
visual.scrCenter = [scr.centerX scr.centerY scr.centerX scr.centerY];

visual.black = BlackIndex(scr.main);
visual.white = WhiteIndex(scr.main);
visual.postcue = [0 0 0];
visual.precue = [.9 .9 .9];
visual.neutral = [.33 .33 .33];

visual.bgColor = (visual.white+visual.black)./2; % background color
visual.fgColor = visual.black; % foreground color

%% Eyetracking
visual.fixCheckRad = 1.5*visual.ppd; % fixation check radius
visual.fixCheckkCol = [167 127 127]-60; % fixation check color
visual.fixColor = [127 167 127]-60; % foreground color

% boundary radius (enveloping landmarks)
visual.boundRad = sqrt(.1^2 + .1^2)*visual.ppd;
visual.fNyquist = 0.5;

%% PH
params.lengthPlaceHolder = round(.3.*visual.ppd);
params.offsetPosPlaceHolder = 0;%round(-.1.*visual.ppd);
params.widthPlaceHolder = 2;

%% Cue
params.fixWdth = round(.05.*visual.ppd);
params.fixSize = round(.15.*visual.ppd);
params.EndoCueSize = round(visual.ppd.*.7);

%% Gabor
params.gaborexc = [0 4 8]*visual.ppd;
params.nLoc_PH = 9;
params.gaborsiz = 3.3.*visual.ppd;
params.patchsiz = 3.*visual.ppd;
params.gaborenvelopedev = 1.*visual.ppd;
params.gaborangle = [135, 45];
params.gaborfrequency = constant.SF/visual.ppd; % AB: 5
params.gaborexc = round(params.gaborexc);
params.gaborsiz = round(params.gaborsiz/2)*2;

%% NOISE (change to noiseSD_all later)
params.extNoiseLvl = [0, .055, .11, .165, .22, .33, .44]*2;

%% Staircase
if any(constant.expMode==[1,5])
    params.startLvl = log10([.02 .5 .02 .5]); % AB: log10([.02 .5 .02 .5]);
    params.nTrialsPerStair = constant.nTrialsPerStair; % AB: 9, cou zheng
else % practice
    params.startLvl = log10(.4); % AB: log10([.02 .5 .02 .5]);
    params.nTrialsPerStair = 8; % AB: 9, cou zheng
end

params.stairRule = [3 3 2 2]; % number of downs
params.stairStep = [.2 .1 .05];

params.nStairs = length(params.startLvl);
% assert(length(params.startLvl) == length(params.stairRule))

% set catch trials to have anchor points at very low/high cst
if constant.expMode==1
    params.catchLvl = log10([.02, 1]); % 0.01 is too low, most of 
else % practice
    params.catchLvl = [];
end

% params.nTrialsCatch = length(params.catchLvl); % AB
params.nStairsCatch = length(params.catchLvl);

params.stairStopRule = 100;
params.maxVal = log10(1);
params.minVal = log10(.001);





