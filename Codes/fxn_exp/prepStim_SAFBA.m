function prepStim_SAFBA
%
% 2013 by Antoine Barbot

global visual scr parameters

visual.black = BlackIndex(scr.main);
visual.white = WhiteIndex(scr.main);

visual.bgColor  = (visual.white+visual.black)./2;      % background color
visual.fgColor  = visual.black;      % foreground color

visual.lumibg = .5;

% visual.inColor  = visual.white-visual.bgColor;

visual.ppd       = va2pix(1,scr);   % pixel per degree
visual.scrCenter = [scr.centerX scr.centerY scr.centerX scr.centerY];
visual.degPerCm  = scr.viewingDist./57;

visual.fixCkRad = 1.5*visual.ppd;  % fixation check radius
visual.fixCkCol = [167  127  127]-60;  % fixation check color
visual.fixColor = [127  167  127]-60;  % foreground color

visual.pink    = [0.5 0.0,0.5];
visual.blue    = [0.0,0.25,.75];
visual.neutral = [0 0.25 0];
% boundary radius (enveloping landmarks)
visual.boundRad = sqrt(.1^2 + .1^2)*visual.ppd;
visual.fNyquist = 0.5;

% set priority of window activities to maximum
priorityLevel=MaxPriority(scr.main);
Priority(priorityLevel);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% Screen  & Stimulus Parameters %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

parameters.gaborexc         = 5*visual.ppd;
parameters.gaborsiz         = 4*visual.ppd;
parameters.gaborenvelopedev = parameters.gaborsiz/4;
parameters.gaborangle       = [135,45];
parameters.gaborfrequency   = 2/visual.ppd;
parameters.noisekerneldev   = (1/6)/parameters.gaborfrequency;
parameters.noisedev         = 0.1;
parameters.gaborexc = round(parameters.gaborexc);
parameters.gaborsiz = round(parameters.gaborsiz/2)*2;

parameters.color_default = [visual.pink;visual.blue;visual.neutral].*visual.white;