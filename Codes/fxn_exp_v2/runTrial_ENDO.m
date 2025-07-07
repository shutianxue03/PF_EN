function [td] = runTrial(td,trial,block)


global constant keys scr visual params stimulus response timing

FlushEvents('KeyDown');

% fixation boundaries
cxm = td.fixLoc(1);
cym = td.fixLoc(2);
rad = visual.boundRad;
chk = visual.fixCheckRad;

Eyelink('command','draw_box %d %d %d %d 15', cxm-chk, cym-chk, cxm+chk, cym+chk);
Screen('BlendFunction', scr.main, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

td.stimContrast  =  (10.^params.UD{td.cueCond,td.targetLoc,td.extNoiseLvl,td.stair}.xCurrent);

% define tilt
if sign(randn)>0
    td.stimOri = 1;
else
    td.stimOri = 2;
end

% % generate noise patches


noiseImg       = []; gabortex       = [];
tempNoise      = []; gabor          = [];
tempStim       = [];


totalNoiseTime = 1000.*([td.fixNoise td.preCueDur1 td.preCueDur2 td.preISIDur td.stimDur td.postISIDur]);
nFramesNoise   = round((totalNoiseTime/1000)/scr.fd);
% alpha          = CreateCircularAperture(params.gaborsiz,round(.25.*visual.ppd));
alpha          = CreateCircularAperture2(params.patchsiz,.75.*visual.ppd,2,params.gaborsiz);
stimInd        = 5; % frame index corresponding to stim onset

% create dynamic white noise sequence
noiseImg    = randn(params.gaborsiz,params.gaborsiz,sum(nFramesNoise),params.nLoc)...
    .*params.extNoiseLvl(td.extNoiseLvl).*visual.bgColor; %Make the noise and adjust its contrast

% create gabor
gaborPhase  = 2*pi*rand;
gabor       = CreateGabor(params.gaborsiz,params.gaborenvelopedev,params.gaborangle(td.stimOri),params.gaborfrequency,...
    gaborPhase,2.*visual.bgColor.*td.stimContrast);

% add stim to target noise sequence
frameInd = sum(nFramesNoise(1:(stimInd-1)));
nframes  = round((totalNoiseTime(stimInd)/1000)/scr.fd);   %get the total number of frames
for fr = frameInd+(1:nframes) %Iterate through the number of frames
    noiseImg(:,:,fr,td.targetLoc) = (noiseImg(:,:,fr,td.targetLoc)+gabor);
end

% make texture
stimImg = min(max(noiseImg + visual.bgColor,0),1);
for iloc = 1:params.nLoc
    for tnoise = 1:sum(nFramesNoise)
          gabortex(iloc,tnoise) = Screen('MakeTexture',scr.main,cat(3,stimImg(:,:,tnoise,iloc),alpha),[],[],2);
    end
end

precueSize = round(.5.*visual.ppd);
if mod(precueSize,2); precueSize = precueSize+1; end
precuerctL = CenterRectOnPoint([0,0,precueSize,precueSize],scr.xres/2-params.gaborexc(2), scr.yres/2-round(2.*params.gaborsiz/3));
precuerctR = CenterRectOnPoint([0,0,precueSize,precueSize],scr.xres/2+params.gaborexc(2), scr.yres/2-round(2.*params.gaborsiz/3));
precuetex  = Screen('MakeTexture',scr.main,cat(3,ones(precueSize),CreateCircularAperture(precueSize)),[],[],2);

% stim
gaborrct = [ ...
    CenterRectOnPoint([0,0,params.gaborsiz,params.gaborsiz],scr.xres/2,scr.yres/2); ... %0
    
    CenterRectOnPoint([0,0,params.gaborsiz,params.gaborsiz],scr.xres/2-params.gaborexc(2),scr.yres/2); ... %WEST  4
    CenterRectOnPoint([0,0,params.gaborsiz,params.gaborsiz],scr.xres/2,scr.yres/2-params.gaborexc(2)); ... %NORTH 4
    CenterRectOnPoint([0,0,params.gaborsiz,params.gaborsiz],scr.xres/2+params.gaborexc(2),scr.yres/2); ... %EAST  4
    CenterRectOnPoint([0,0,params.gaborsiz,params.gaborsiz],scr.xres/2,scr.yres/2+params.gaborexc(2)); ... %SOUTH 4
    
    CenterRectOnPoint([0,0,params.gaborsiz,params.gaborsiz],scr.xres/2-params.gaborexc(3),scr.yres/2); ... %WEST  8
    CenterRectOnPoint([0,0,params.gaborsiz,params.gaborsiz],scr.xres/2,scr.yres/2-params.gaborexc(3)); ... %NORTH 8
    CenterRectOnPoint([0,0,params.gaborsiz,params.gaborsiz],scr.xres/2+params.gaborexc(3),scr.yres/2); ... %EAST  8
    CenterRectOnPoint([0,0,params.gaborsiz,params.gaborsiz],scr.xres/2,scr.yres/2+params.gaborexc(3)); ... %SOUTH 8
    ];

patchrct = [ ...
    CenterRectOnPoint([0,0,params.patchsiz,params.patchsiz],scr.xres/2,scr.yres/2); ... %0
    
    CenterRectOnPoint([0,0,params.patchsiz,params.patchsiz],scr.xres/2-params.gaborexc(2),scr.yres/2); ... %WEST  4
    CenterRectOnPoint([0,0,params.patchsiz,params.patchsiz],scr.xres/2,scr.yres/2-params.gaborexc(2)); ... %NORTH 4
    CenterRectOnPoint([0,0,params.patchsiz,params.patchsiz],scr.xres/2+params.gaborexc(2),scr.yres/2); ... %EAST  4
    CenterRectOnPoint([0,0,params.patchsiz,params.patchsiz],scr.xres/2,scr.yres/2+params.gaborexc(2)); ... %SOUTH 4
    
    CenterRectOnPoint([0,0,params.patchsiz,params.patchsiz],scr.xres/2-params.gaborexc(3),scr.yres/2); ... %WEST  8
    CenterRectOnPoint([0,0,params.patchsiz,params.patchsiz],scr.xres/2,scr.yres/2-params.gaborexc(3)); ... %NORTH 8
    CenterRectOnPoint([0,0,params.patchsiz,params.patchsiz],scr.xres/2+params.gaborexc(3),scr.yres/2); ... %EAST  8
    CenterRectOnPoint([0,0,params.patchsiz,params.patchsiz],scr.xres/2,scr.yres/2+params.gaborexc(3)); ... %SOUTH 8
    ];


% define place holders

% default
for ipos = 1:9
    for inse = 1:sum(nFramesNoise)
        colPlaceHolder{ipos,inse} =  visual.neutral;
        wdtPlaceHolder{ipos,inse} =  params.widthPlaceHolder;
    end
end

% response cue
for ipos = td.targetLoc
    for inse = (sum(nFramesNoise(1:4))+1):sum(nFramesNoise)
        colPlaceHolder{ipos,inse} = visual.postcue;
        wdtPlaceHolder{ipos,inse} = round(params.widthPlaceHolder.*1.25);
    end
end

% precue
if td.scue==1
    for ipos = td.targetLoc
        for inse = sum(nFramesNoise(1:2))+(1:nFramesNoise(3))
            colPlaceHolder{ipos,inse} = visual.precue;
            wdtPlaceHolder{ipos,inse} = params.widthPlaceHolder.*2;
        end
    end
end
% placetex = Screen('MakeTexture',scr.main,cat(3,ones(params.gaborsiz),CreateCircle(params.gaborsiz,1)),[],[],1);

% predefine time stamps
tFix         = NaN;
tfixCheckOff = NaN;
tClr         = NaN;
tNoiseON     = NaN;

% run trial
eyePhase        = 1;  %fixation
breakIt         = 0;
fixBreak        = 0;
fixCheckOff     = 0;
countFrame      = 1;
noiseSequenceOn = [zeros(1,sum(nFramesNoise)) 1];
t               = GetSecs;

for iloc = 1:params.nLoc
    drawPlaceHolders(scr.main,visual.neutral,patchrct(iloc,:),params.lengthPlaceHolder,params.patchsiz,params.offsetPosPlaceHolder,params.widthPlaceHolder)
end
drawEndoCue(visual.neutral,[cxm cym],td.scue,td.targetLoc);
Screen('DrawingFinished',scr.main);
tFixON = Screen('Flip', scr.main);
Eyelink('message', 'EVENT_Fixation');
Beeper(700,.1,.1);

while ~breakIt   
    if ~noiseSequenceOn(countFrame) && t > (tFixON + run.fixDur - scr.fd)
        % Noise
        for iloc = 1:params.nLoc
            Screen('DrawTexture',scr.main,gabortex(iloc,countFrame),[],gaborrct(iloc,:));
            drawPlaceHolders(scr.main,colPlaceHolder{iloc,countFrame},patchrct(iloc,:),params.lengthPlaceHolder,params.patchsiz,params.offsetPosPlaceHolder,wdtPlaceHolder{iloc,countFrame})

%             Screen('DrawTexture',scr.main,placetex,[],gaborrct(iloc,:),[],[],[],colPlaceHolder{iloc,countFrame});
        end
        Screen('DrawingFinished',scr.main);
        tNoiseON(countFrame) = Screen('Flip',scr.main);
        Eyelink('message', 'EVENT_noiseFrameOn');
        noiseSequenceOn(countFrame) = 1;
        countFrame = countFrame+1;
   
    elseif ~fixCheckOff && t >= (tFixON + td.fixDur - scr.fd)
        for iloc = 1:params.nLoc
            drawPlaceHolders(scr.main,colPlaceHolder{iloc,countFrame-1},patchrct(iloc,:),params.lengthPlaceHolder,params.patchsiz,params.offsetPosPlaceHolder,params.widthPlaceHolder)
        end
%         Screen('DrawTexture',scr.main,cuetex,[],cuerct,[],[],[],0);
        %         Screen('DrawLine',scr.main,[0,0,0],barpos(1,1,1),barpos(2,1,1),barpos(1,2,1),barpos(2,2,1),4);
        %         Screen('DrawLine',scr.main,[0,0,0],barpos(1,1,2),barpos(2,1,2),barpos(1,2,2),barpos(2,2,2),4);
%         Screen('DrawTexture',scr.main,fixtex,[],fixrct,[],[],[],0);
        Screen('DrawingFinished',scr.main);
        tfixCheckOFF  = Screen(scr.main,'Flip');
        Eyelink('message', 'EVENT_postCueOff');
        Beeper(800,.1,.1)

        fixCheckOff = 1;
    end
    
    % check eye position
    [x,y] = getCoord;
    
    if sqrt((x-cxm)^2+(y-cym)^2)>chk    % check fixation in a circular area
        fixBreak = 1;
    end
    
    if fixBreak & ~fixCheckOff
        breakIt = 1;
    elseif  fixCheckOff
        breakIt = 2;
    end
    
    t = GetSecs;
end

switch breakIt
    case 1
        data = 'fixBreak';
        Eyelink('command','draw_text 100 100 42 Fixation break');
        td.fixBreak=1;
    case 2
        % check for keypress
        td.fixBreak=0;
        keyPress = 0;
        while ~keyPress
            [keyPress, tRes] = checkButtonPress(keys.respButtons);
        end
        
        % record a minimum of td.minKey sec after displacement
        % WaitSecs(tDis + td.minKey - GetSecs);
        WaitSecs(td.afterKeyDur);
        Screen(scr.main,'FillRect',visual.bgColor,[]);
        for iloc = 1:params.nLoc
            drawPlaceHolders(scr.main,visual.neutral,patchrct(iloc,:),params.lengthPlaceHolder,params.patchsiz,params.offsetPosPlaceHolder,params.widthPlaceHolder)
        end
%         Screen('DrawTexture',scr.main,cuetex,[],cuerct,[],[],[],0);
        %         Screen('DrawLine',scr.main,[0,0,0],barpos(1,1,1),barpos(2,1,1),barpos(1,2,1),barpos(2,2,1),4);
        %         Screen('DrawLine',scr.main,[0,0,0],barpos(1,1,2),barpos(2,1,2),barpos(1,2,2),barpos(2,2,2),4);
%         Screen('DrawTexture',scr.main,fixtex,[],fixrct,[],[],[],0);
        Screen(scr.main,'DrawingFinished');
        tClr = Screen(scr.main,'Flip');
        Eyelink('message', 'EVENT_ClearScreen');
        
        %         tCueON - tFixON
        %         tISION - tCueON
        %         tStimON - tISION
        %         tStimOFF - tStimON
        % timing & RT
        timing(block).fixDur(trial)     = tNoiseON(1)-tFixON;
        timing(block).fixNoise(trial)   = tNoiseON(1+sum(nFramesNoise(1)))-tNoiseON(1);
        timing(block).preCueDur1(trial) = tNoiseON(1+sum(nFramesNoise(1:2)))-tNoiseON(1+sum(nFramesNoise(1)));
        timing(block).preCueDur2(trial) = tNoiseON(1+sum(nFramesNoise(1:3)))-tNoiseON(1+sum(nFramesNoise(1:2)));
        timing(block).ISIDur(trial)     = tNoiseON(1+sum(nFramesNoise(1:4)))-tNoiseON(1+sum(nFramesNoise(1:3)));
        timing(block).stimDur(trial)    = tNoiseON(1+sum(nFramesNoise(1:5)))-tNoiseON(1+sum(nFramesNoise(1:4)));
        timing(block).postISIDur(trial) = tfixCheckOFF-tNoiseON(1+sum(nFramesNoise(1:5)));
        
        
%         [tfixCheckOFF - tFixON...
%             tNoiseON(1)-tFixON...
%             tNoiseON(1+sum(nFramesNoise(1)))-tNoiseON(1)...
%             tNoiseON(1+sum(nFramesNoise(1:2)))-tNoiseON(1+sum(nFramesNoise(1)))...
%             tNoiseON(1+sum(nFramesNoise(1:3)))-tNoiseON(1+sum(nFramesNoise(1:2)))...
%             tNoiseON(1+sum(nFramesNoise(1:4)))-tNoiseON(1+sum(nFramesNoise(1:3)))...
%             tNoiseON(1+sum(nFramesNoise(1:5)))-tNoiseON(1+sum(nFramesNoise(1:4)))...
%             tfixCheckOFF-tNoiseON(1+sum(nFramesNoise(1:5)))]
            
            
        response(block).rt(trial)       = tRes - tfixCheckOFF;
        td.rt  = response(block).rt(trial);
        
        
        % response & feedback
        td.resp = keys.respButtons(keyPress);
        
        switch td.resp
            case keys.StimLeft
                response(block).oriResp(trial)    = 1;
            case keys.StimRight
                response(block).oriResp(trial)    = 2;
        end
        
        
        if response(block).oriResp(trial) == td.stimOri;
            response(block).iscor(trial) = 1;
            Beeper(800,.1,.1);Beeper(1000,.1,.1);
        else
            response(block).iscor(trial) = 0;
            Beeper(500,.1,.1);Beeper(400,.1,.1);Beeper(300,.1,.1);
        end
        td.cor = response(block).iscor(trial);
        
        % update staircase
        params.UD{td.cueCond,td.targetLoc,td.extNoiseLvl,td.stair} = ...
            PAL_AMUD_updateUD(params.UD{td.cueCond,td.targetLoc,td.extNoiseLvl,td.stair},...
            td.cor);
        % adjust step size after 10 trials
        if length(params.UD{td.cueCond,td.targetLoc,td.extNoiseLvl,td.stair}.response)==10
            params.UD{td.cueCond,td.targetLoc,td.extNoiseLvl,td.stair}.stepSizeUp   = params.stairStep(2);
            params.UD{td.cueCond,td.targetLoc,td.extNoiseLvl,td.stair}.stepSizeDown = params.stairStep(2);
        elseif length(params.UD{td.cueCond,td.targetLoc,td.extNoiseLvl,td.stair}.response)==20
            params.UD{td.cueCond,td.targetLoc,td.extNoiseLvl,td.stair}.stepSizeUp   = params.stairStep(3);
            params.UD{td.cueCond,td.targetLoc,td.extNoiseLvl,td.stair}.stepSizeDown = params.stairStep(3);
        end
end
Screen('Close',gabortex);

