
% iblock(_local) is not used here

% inherit staircase and decide iNoise
iNoise = nan;

run.iNoise = iNoise;
flag_updateStair = 0;
if any(constant.expMode==[1,2])
    iNoise = find(params.extNoiseLvl == run.extNoiseLvl);
    flag_updateStair = 1; 
end
if constant.expMode==5
    switch run.dataMode
        case 1 % new noise SD
            params.UD = params.UD_mode1;
            iNoise = find(params.noiseSD_all_mode1== run.extNoiseLvl);
            flag_updateStair = 1;
    end
end

% get Gabor contrast
if constant.expMode==1
    run.stimContrast = (10.^params.UD{run.targetLoc, iNoise, run.stair}.xCurrent);

elseif constant.expMode==2
    run.stimContrast = (10.^params.UD{run.targetLoc, iNoise}.xCurrent);
    
elseif constant.expMode==4
    run.stimContrast = run.stimContrast;
    
elseif constant.expMode==5
    if run.dataMode==2 % constim for old loc and noiseSD
        run.stimContrast = run.stimContrast;
    else
        run.stimContrast = (10.^params.UD{run.targetLoc, iNoise, run.stair}.xCurrent);
    end
end

% randomize tilt only for the practice mode (because there is only one staircase)
if constant.expMode==2, run.stimOri = (rand>.5)+1; end

% get stim presentation time and frame
totalNoiseTime = 1000.*([run.fixNoise, run.preCueDur1, run.preCueDur2, run.preISIDur, run.stimDur, run.postISIDur]);
nFramesStim = round((totalNoiseTime/1000)/scr.fd);
iframe_GaborOnset = 5; % the index of frame-chunk of Gabor onset

%% print (SX)
namesLoc9 = {'Fovea', '4 deg-Left', '4 deg-UVM', '4 deg-Right', '4 deg-LVM', '8 deg-Left', '8 deg-UVM', '8 deg-Right', '8 deg-LVM'};
namesResp = {'Left (CCW)', 'Right (CW)'};
namesConfidence = {'High', 'Mid', 'Low'};
params.namesLoc9 = namesLoc9;
params.namesResp = namesResp;
params.namesConfidence = namesConfidence;

% fprintf('Trial#%d: Loc#%d: %s [%s], Gabor cst = %d%%, noise cst = %d%% [%d], stair #%d\n', ...
%     itrial, run.targetLoc, namesLoc9{run.targetLoc}, namesResp{run.stimOri }, ...
%     round(run.stimContrast*100), round(params.extNoiseLvl(run.extNoiseLvl)*100), run.extNoiseLvl, run.stair)
% fprintf('***** L%d N%d S%d *****\n', run.targetLoc, run.extNoiseLvl, run.stair)

%% create the display
% empty containers
gaborTexture = nan(params.nLoc_PH, sum(nFramesStim));
% tempNoise = []; gabor = [];
% tempStim = [];

% create mask
mask = CreateCircularAperture2(params.patchsiz,.75.*visual.ppd,2,params.gaborsiz);

% create dynamic white noise sequence
% noiseImg = randn(params.gaborsiz, params.gaborsiz, sum(nFramesStim), params.nLoc_all).*params.extNoiseLvl(run.extNoiseLvl).*visual.bgColor;
if constant.demo
    noiseImg = randn(params.gaborsiz, params.gaborsiz, sum(nFramesStim), params.nLoc_PH).*.44*visual.bgColor;
else
    noiseImg = randn(params.gaborsiz, params.gaborsiz, sum(nFramesStim), params.nLoc_PH).*run.extNoiseLvl.*visual.bgColor;
end
% create gabor
gaborPhase = 2*pi*rand; % randomize phase
gabor = CreateGabor(params.gaborsiz, params.gaborenvelopedev, params.gaborangle(run.stimOri), params.gaborfrequency,...
    gaborPhase, 2.*visual.bgColor.*run.stimContrast);

% add stim to target noise sequence
noiseImg_ = noiseImg; % SX
nframes_beforeGabor = sum(nFramesStim(1:(iframe_GaborOnset-1))); % frameInd
% nframes = round((totalNoiseTime(stimInd)/1000)/scr.fd); %get the total number of frames % AB
nframes_Gabor = nFramesStim(iframe_GaborOnset); % number of frames for Gabor presentation, SX

for iframe = nframes_beforeGabor + (1:nframes_Gabor) %Iterate through the number of frames
    % noiseImg(:,:,iframe,run.targetLoc) = (noiseImg(:,:,fr,run.targetLoc)+gabor); % AB
    noiseImg_(:,:, iframe, run.targetLoc) = (noiseImg(:,:,iframe, run.targetLoc) + gabor); % SX
end
% stimImg = min(max(noiseImg + visual.bgColor, 0),255); % AB, moved up here by SX
stimImg = min(max((noiseImg_ + visual.bgColor)/255, 0), 1); % SX, divide the pixels by 255 to avoid saturation is using a [0,1] scale
% quickPlot_stim % SX

stimImg_ = min(max(gabor/255+.5, 0), 1);%stimImg(:, :, nframes_beforeGabor+1, run.targetLoc);
% stimImg_ = min(max(squeeze(noiseImg(:, :, 1, run.targetLoc))/255+.5, 0), 1);%stimImg(:, :, nframes_beforeGabor+1, run.targetLoc);

fprintf('Michelson cst of Gabor =%.2f%%\n', 100*(max(stimImg_(:))-min(stimImg_(:)))/(max(stimImg_(:))+min(stimImg_(:))))
fprintf('RMS cst of Gabor =%.2f%%\n', 100*sqrt(sumsqr((stimImg_(:)-min(stimImg_(:)))/-min(stimImg_(:)))/length(stimImg_(:))))

% make texture
for iLoc = 1:params.nLoc_PH
    %     for iLocTgt = constant.iLoc_tgt_all%1:constant.iLoc_tgt_all
    for iframe = 1:sum(nFramesStim)
        gaborTexture(iLoc, iframe) = Screen('MakeTexture',scr.main,cat(3,squeeze(stimImg(:,:,iframe,iLoc)),mask),[],[],2);
    end
end

precueSize = round(.5.*visual.ppd);
if mod(precueSize,2); precueSize = precueSize+1; end
precuerctL = CenterRectOnPoint([0,0,precueSize,precueSize], scr.xres/2-params.gaborexc(2), scr.yres/2-round(2.*params.gaborsiz/3));
precuerctR = CenterRectOnPoint([0,0,precueSize,precueSize], scr.xres/2+params.gaborexc(2), scr.yres/2-round(2.*params.gaborsiz/3));
precuetex = Screen('MakeTexture',scr.main,cat(3,ones(precueSize),CreateCircularAperture(precueSize)),[],[],2);

% Location of Gabor
gaborRect = [ ...
    CenterRectOnPoint([0,0,params.gaborsiz,params.gaborsiz],scr.xres/2,scr.yres/2); ... %0
    
    CenterRectOnPoint([0,0,params.gaborsiz,params.gaborsiz],scr.xres/2-params.gaborexc(2),scr.yres/2); ... %WEST 4
    CenterRectOnPoint([0,0,params.gaborsiz,params.gaborsiz],scr.xres/2,scr.yres/2-params.gaborexc(2)); ... %NORTH 4
    CenterRectOnPoint([0,0,params.gaborsiz,params.gaborsiz],scr.xres/2+params.gaborexc(2),scr.yres/2); ... %EAST 4
    CenterRectOnPoint([0,0,params.gaborsiz,params.gaborsiz],scr.xres/2,scr.yres/2+params.gaborexc(2)); ... %SOUTH 4
    
    CenterRectOnPoint([0,0,params.gaborsiz,params.gaborsiz],scr.xres/2-params.gaborexc(3),scr.yres/2); ... %WEST 8
    CenterRectOnPoint([0,0,params.gaborsiz,params.gaborsiz],scr.xres/2,scr.yres/2-params.gaborexc(3)); ... %NORTH 8
    CenterRectOnPoint([0,0,params.gaborsiz,params.gaborsiz],scr.xres/2+params.gaborexc(3),scr.yres/2); ... %EAST 8
    CenterRectOnPoint([0,0,params.gaborsiz,params.gaborsiz],scr.xres/2,scr.yres/2+params.gaborexc(3)); ... %SOUTH 8
    ];

% Location of noise patch
patchRect = [ ...
    CenterRectOnPoint([0,0,params.patchsiz,params.patchsiz],scr.xres/2,scr.yres/2); ... %0
    
    CenterRectOnPoint([0,0,params.patchsiz,params.patchsiz],scr.xres/2-params.gaborexc(2),scr.yres/2); ... %WEST 4
    CenterRectOnPoint([0,0,params.patchsiz,params.patchsiz],scr.xres/2,scr.yres/2-params.gaborexc(2)); ... %NORTH 4
    CenterRectOnPoint([0,0,params.patchsiz,params.patchsiz],scr.xres/2+params.gaborexc(2),scr.yres/2); ... %EAST 4
    CenterRectOnPoint([0,0,params.patchsiz,params.patchsiz],scr.xres/2,scr.yres/2+params.gaborexc(2)); ... %SOUTH 4
    
    CenterRectOnPoint([0,0,params.patchsiz,params.patchsiz],scr.xres/2-params.gaborexc(3),scr.yres/2); ... %WEST 8
    CenterRectOnPoint([0,0,params.patchsiz,params.patchsiz],scr.xres/2,scr.yres/2-params.gaborexc(3)); ... %NORTH 8
    CenterRectOnPoint([0,0,params.patchsiz,params.patchsiz],scr.xres/2+params.gaborexc(3),scr.yres/2); ... %EAST 8
    CenterRectOnPoint([0,0,params.patchsiz,params.patchsiz],scr.xres/2,scr.yres/2+params.gaborexc(3)); ... %SOUTH 8
    ];

%% create place holders
% for iLoc = 1:params.nLoc_all
for iLocPH = 1:params.nLoc_PH % always 9 placeholders
    for iframe = 1:sum(nFramesStim)
        colPlaceHolder{iLocPH, iframe} = visual.neutral;
        wdtPlaceHolder{iLocPH, iframe} = params.widthPlaceHolder;
    end
end

% Resp cue (boldened PHs, onset with Gabor onset, and displayed until noise offset)
% for ipos = run.targetLoc % AB
for iframe_tgt = (sum(nFramesStim(1:(iframe_GaborOnset-1)))+1):sum(nFramesStim)
    colPlaceHolder{run.targetLoc, iframe_tgt} = visual.postcue;
    % wdtPlaceHolder{run.targetLoc, iframe_tgt} = round(params.widthPlaceHolder.*1.1); %AB
    % wdtPlaceHolder{run.targetLoc, iframe_tgt} = params.widthPlaceHolder.*1.1; %SX (remove round())
    wdtPlaceHolder{run.targetLoc, iframe_tgt} = params.widthPlaceHolder.*3; %SX (remove round() and increase the boldening scale)
end
% end

% precue
if constant.expMode<5
    if run.scue==1
        for iLoc = run.targetLoc
            for inse = sum(nFramesStim(1:2))+(1:nFramesStim(3))
                colPlaceHolder{iLoc,inse} = visual.precue;
                wdtPlaceHolder{iLoc,inse} = params.widthPlaceHolder.*2;
            end
        end
    end
end
% placetex = Screen('MakeTexture',scr.main,cat(3,ones(params.gaborsiz),CreateCircle(params.gaborsiz,1)),[],[],1);

%% predefine time stamps
tFix = NaN;
tfixCheckOff = NaN;
tClr = NaN;
tNoiseON = NaN;

eyePhase = 1; %fixation
breakIt = 0;
fixBreak = 0;
fixCheckOff = 0;
countFrame = 1;
noiseSequenceOn = [zeros(1,sum(nFramesStim)) 1];


