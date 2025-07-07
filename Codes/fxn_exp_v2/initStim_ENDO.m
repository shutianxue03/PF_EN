function initStim_ENDO

global visual scr params

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% Visual params %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
va2pix(1,scr)
visual.ppd       = va2pix(1,scr);   % pixel per degree
visual.degPerCm  = scr.viewingDist./57;
visual.scrCenter = [scr.centerX scr.centerY scr.centerX scr.centerY];

visual.black     = BlackIndex(scr.main);
visual.white     = WhiteIndex(scr.main);
visual.postcue   = [.1 .1 .1];
visual.precue    = [.9 .9 .9];
visual.neutral   = [.35  .35  .35];

visual.bgColor   = (visual.white+visual.black)./2;  % background color
visual.fgColor   = visual.black;      % foreground color
visual.lumibg    = 255.*visual.bgColor;
% visual.lumibg   = .5;

% eyetracking parameters
visual.fixCheckRad  = 1.5*visual.ppd;  % fixation check radius
visual.fixCheckkCol = [167  127  127]-60;  % fixation check color
visual.fixColor     = [127  167  127]-60;  % foreground color
% boundary radius (enveloping landmarks)
visual.boundRad     = sqrt(.1^2 + .1^2)*visual.ppd;
visual.fNyquist     = 0.5;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% Stimulus params %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

params.gaborexc         = [0 4 8]*visual.ppd;
params.nLoc             = 9;
params.gaborsiz         = 3.3.*visual.ppd;
params.patchsiz         = 3.*visual.ppd;
params.gaborenvelopedev = .8.*visual.ppd;
params.gaborangle       = [135 45];
params.gaborfrequency   = 5/visual.ppd;
params.gaborexc         = round(params.gaborexc);
params.gaborsiz         = round(params.gaborsiz/2)*2;

params.lengthPlaceHolder    = round(.3.*visual.ppd);
params.offsetPosPlaceHolder = 0;%round(-.1.*visual.ppd);
params.widthPlaceHolder     = 1.5;
 
params.fixWdth      = round(.05.*visual.ppd);
params.fixSize      = round(.15.*visual.ppd);
params.EndoCueSize  = round(visual.ppd.*.7);


%(4*7*9*40 + 2*7*9*8)/72

% params.extNoiseLvl      = [0 .055 .11 .165 .22 .275 .33];
% params.extNoiseLvl      = [0 .055 .11 .165 .22 .33 .44];
params.extNoiseLvl        = [0 .11 .22 .33 .44];

params.startLvl         = log10([.01 .5 .01 .5]);
params.stairRule        = [3  3    2  2];
params.stairStep        = [.2 .1 .05];
params.nTrialsPerStair  = 4;

params.catchLvl         = log10([.01 1]);
params.nTrialsCatch     = 1; % # of catch trials / condition;
params.stairStopRule    = 100;
params.maxVal           = log10(1);
params.minVal           = log10(.001);

params.lastblock        = 0;