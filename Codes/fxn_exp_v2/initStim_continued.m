function initStim_continued

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
visual.blue      = [0 .25 .75];
visual.postcue    = [.75  .75  .75];
visual.precue   = [0 .75 .5];
visual.neutral   = [.25  .25  .25];

visual.bgColor   = (visual.white+visual.black)./2;  % background color
visual.fgColor   = visual.black;      % foreground color
visual.lumibg    = visual.bgColor./255;
% visual.lumibg   = .5;

% eyetracking parameters
visual.fixCheckRad  = 1*visual.ppd;  % fixation check radius
visual.fixCheckkCol = [167  127  127]-60;  % fixation check color
visual.fixColor     = [127  167  127]-60;  % foreground color
% boundary radius (enveloping landmarks)
visual.boundRad     = sqrt(.1^2 + .1^2)*visual.ppd;
visual.fNyquist     = 0.5;

% % % 
% % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % %%%%% Stimulus params %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % 
% % % params.gaborexc         = [0 4 8]*visual.ppd;
% % % params.nLoc             = 9;
% % % params.gaborsiz         = 3*visual.ppd;
% % % params.gaborenvelopedev = 1*visual.ppd;
% % % params.gaborangle       = [135,45];
% % % params.gaborfrequency   = 6/visual.ppd;
% % % params.noisekerneldev   = (1/6)/params.gaborfrequency;
% % % params.noisedev         = 0.1;
% % % params.gaborexc         = round(params.gaborexc);
% % % params.gaborsiz         = round(params.gaborsiz/2)*2;
% % % 
% % % params.extNoiseLvl      = [0 .055 .11 .165 .22 .275 .33];
% % % % params.extNoiseLvl      = [0 .06 .12 .18 .24 .3 .36]
% % % params.startLvl         = log10([1 30  1 30]);
% % % params.stairRule        = [  3  3    2  2];
% % % params.stairStep        = .1;
% % % params.maxVal           = log10(100);
% % % params.minVal           = log10(.1);
% % % 
% % % params.lastblock        = 0;


% params.color_default = [visual.green;visual.blue;visual.neutral].*visual.white;