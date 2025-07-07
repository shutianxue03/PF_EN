function el = SX3_initEL(window)

eyeDataDir = 'eyedata';
eyeFile = 'xx';
if length(eyeFile) > 8, error('EL file name CANNOT contain > 8 digits !!!'),end
% *** file name MUST NOT contain '_' ***
% file name can only contain 8 digits !!!

%% Initialize eye tracker
[el,exitFlag] = rd_eyeLink('eyestart', window, {eyeFile});
if exitFlag, return, end

%% save
el.eyeDataDir  = eyeDataDir;
el.eyeFile = eyeFile;

%% create folder
if ~exist(el.eyeDataDir,'dir'), mkdir(el.eyeDataDir); end