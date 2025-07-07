function initScreen

global scr

HideCursor;

scr.viewingDist = 57;   % viewing distance (in cm)
scr.colDept     = 16;

% open screens.  
scr.allScreens = Screen('Screens');
scr.expScreen  = max(scr.allScreens);
[scr.main,scr.rect]   = Screen(scr.expScreen,'OpenWindow',[0 0 0],[],scr.colDept,2,0,4); % experimental screen
[scr.main2,scr.rect2] = Screen(0,'OpenWindow',[0 0 0],[],[],2); % black display for the other screen

% % load calibration file
load('0001_yarbus_1280x960_100Hz_57cm_130227.mat');
% load('0001_titchener_130226.mat');
Screen('LoadNormalizedGammaTable',scr.main,repmat(calib.table,1,3));

% Screen('BlendFunction', scr.main, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); % this is needed for the transparency of the gabor envelope ...
% Screen('FillRect',scr.main, background.color);
Screen('FillRect',scr.main2, [0 0 0]);


% get screen information
[scr.xres, scr.yres] = Screen('WindowSize', scr.main);       % heigth and width of screen [pix]

scr.fd = Screen('GetFlipInterval',scr.main);    % frame duration [s]

[width, height] = Screen('DisplaySize', scr.main);

% scr.width       = 400;
% scr.height       = 400;
scr.width   = width;
scr.height  = height;

scr.xpxpcm  = scr.xres/(scr.width./10);
scr.ypxpcm  = scr.yres/(scr.height./10);
scr.xpxpdeg = ceil(tan(2*pi/360)*scr.viewingDist*scr.xpxpcm);
scr.ypxpdeg = ceil(tan(2*pi/360)*scr.viewingDist*scr.ypxpcm);


fprintf(1,'\n\nScreen refresh rate: %.1f Hz.\n\n',1/scr.fd);

% determine window's center
[scr.centerX, scr.centerY] = WindowCenter(scr.main);

WaitSecs(2);

