function initScreen

global scr constant

% HideCursor; % AB
% AssertOpenGL % AB
% Screen('Preference','SkipSyncTests', 1);

scr.viewingDist = 57;   % viewing distance (in cm)
scr.colDept     = 16;

%% open screens.
scr.allScreens = Screen('Screens');
scr.expScreen  = max(scr.allScreens);

% High bit depth (bit stealing)
% PsychImaging('PrepareConfiguration'); % AB
% PsychImaging('AddTask','General','EnablePseudoGrayOutput'); % AB
% [scr.main,scr.rect] = PsychImaging('OpenWindow', scr.expScreen); % AB
switch constant.screenMode
    case 1, scr.xres = 1280; scr.yres = 960; % SX % SX's iMac the pixel is doubled at display... but normal in L1
    case 2, scr.xres = 800; scr.yres = 600;
    case 3, scr.xres = 400; scr.yres = 300;
end
% Screen('Preference', 'SkipSyncTests', 1);
[scr.main, scr.rect] = Screen('OpenWindow', scr.expScreen, ones(1,3)*255/2, [0 0 scr.xres, scr.yres]); %SX
scr.xres = scr.rect(3); scr.yres = scr.rect(4); % SX

%% load calibration file
% load('Carrasco_L1_SonyGDM5402_sRGB_calibration_02292016.mat'); % L1 % AB
load('GammaTable_L1_09212023.mat'); % L1 % SX
% table = CLUT; % AB
table = GammaTable; % SX
Screen('LoadNormalizedGammaTable', scr.main, table);

% check gamma table
gammatable = Screen('ReadNormalizedGammaTable', scr.main);% load('0001_james_ProP220f_1280x960_100Hz_57cm_Oct2014_110412.mat');
% if nnz(abs(gammatable-table)>0.0001), error('Gamma table not loaded correctly! Perhaps set screen res and retry.'), end % AB; does not work on Linux

Screen('BlendFunction', scr.main, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); % this is needed for the transparency of the gabor envelope ...

% get screen information
% [scr.xres, scr.yres] = Screen('WindowSize', scr.main); % heigth and width of screen [pix] % AB
scr.fd               = Screen('GetFlipInterval',scr.main);    % frame duration [s]
% 
% if constant.EYETRACK
%     if scr.xres~=1280 | scr.yres~=960
%         ShowCursor;error(sprintf('WRONG RESOLUTION OF RESOLUTION IS %d x %d ... USE 1280 x 960 at 100Hz',scr.xres, scr.yres));
%         sca
%     end
% end

scr.width       = 400; scr.height      = 300; % AB
% scr.width = 600; scr.height = 340; % SX

scr.xpxpcm  = scr.xres/(scr.width./10);
scr.ypxpcm  = scr.yres/(scr.height./10);
scr.xpxpdeg = ceil(tan(2*pi/360)*scr.viewingDist*scr.xpxpcm);
scr.ypxpdeg = ceil(tan(2*pi/360)*scr.viewingDist*scr.ypxpcm);

fprintf(1,'\n\nScreen resolution: %d x %d\n',scr.xres,scr.yres);
fprintf(1,'Screen refresh rate: %.1f Hz.\n\n',1/scr.fd);

% determine window's center
% [scr.centerX, scr.centerY] = WindowCenter(scr.main); % AB
scr.centerX = scr.xres/2; scr.centerY = scr.yres/2; % SX

WaitSecs(1);


