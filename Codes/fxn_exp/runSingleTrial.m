function [td] = runSingleTrial(td,trial,block)

% 2013 by Antoine Barbot, adapted from Martin Rolfs

global scr visual parameters const keys stimulus response timing

FlushEvents('KeyDown');

% fixation boundaries
cxm = td.fixLoc(1);
cym = td.fixLoc(2);
rad = visual.boundRad;
chk = visual.fixCkRad;

Eyelink('command','draw_box %d %d %d %d 15', cxm-chk, cym-chk, cxm+chk, cym+chk);
Screen('BlendFunction', scr.main, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);


if td.color == 2
    color = parameters.color_default([2,1,3],:);
else
    color = parameters.color_default;
end

% create stim
gabortex = [];
for ipatch = 1:2
    if td.target == 1 && td.sprobe == ipatch
        stimulus(block).phase(ipatch,trial) = rand;
        gabor = CreateGabor(parameters.gaborsiz,parameters.gaborenvelopedev,...
            parameters.gaborangle(td.fprobe),parameters.gaborfrequency,...
            stimulus(block).phase(ipatch,trial),td.contrast*2*visual.lumibg);
    else
        stimulus(block).phase(ipatch,trial) = 0;
        gabor = zeros(parameters.gaborsiz);
    end
    noise = CreateSmoothedNoise(parameters.gaborsiz,parameters.noisekerneldev,...
        parameters.noisedev*2*visual.lumibg);
    gabor = min(max(visual.lumibg+gabor+noise,0),1);
    alpha = CreateCircularAperture(parameters.gaborsiz);
    gabortex(ipatch) = Screen('MakeTexture',scr.main,cat(3,gabor,alpha),[],[],2);
    stimulus(block).patch{ipatch,trial} = gabor.*alpha+visual.lumibg*(1-alpha);
end

stimulus(block).contrast(trial) = td.contrast;

% cue & fixation
cuerct = CenterRectOnPoint([0,0,12,12],scr.xres/2, scr.yres/2);
cuetex = Screen('MakeTexture',scr.main,cat(3,ones(12),CreateCircularAperture(12)),[],[],2);

fixrct = CenterRectOnPoint([0,0,34,34],scr.xres/2, scr.yres/2);
fixtex = Screen('MakeTexture',scr.main,cat(3,ones(34),CreateCircle(34,3)),[],[],2);

barpos        = nan(2,2,2);
barpos(:,:,1) = [scr.xres/2+[-15,+15]/sqrt(2);scr.yres/2+[-15,+15]/sqrt(2)];
barpos(:,:,2) = [scr.xres/2+[-15,+15]/sqrt(2);scr.yres/2+[+15,-15]/sqrt(2)];

extrabarpos        = nan(2,2,2);
extrabarpos(:,:,2) = [scr.xres/2+[-20,0]/sqrt(2);scr.yres/2+[0,-20]/sqrt(2)];
extrabarpos(:,:,1) = [scr.xres/2+[-20,0]/sqrt(2);scr.yres/2+[0,20]/sqrt(2)];

extrabarpos2        = nan(2,2,2);
extrabarpos2(:,:,2) = [scr.xres/2+[0,20]/sqrt(2);scr.yres/2+[20,0]/sqrt(2)];
extrabarpos2(:,:,1) = [scr.xres/2+[0,20]/sqrt(2);scr.yres/2+[-20,0]/sqrt(2)];

% stim 
gaborrct = [ ...
    CenterRectOnPoint([0,0,parameters.gaborsiz,parameters.gaborsiz],scr.xres/2-parameters.gaborexc,scr.yres/2); ...
    CenterRectOnPoint([0,0,parameters.gaborsiz,parameters.gaborsiz],scr.xres/2+parameters.gaborexc,scr.yres/2)];

placerct = [ ...
    CenterRectOnPoint([0,0,parameters.gaborsiz,parameters.gaborsiz],0, 0-parameters.gaborexc); ...
    CenterRectOnPoint([0,0,parameters.gaborsiz,parameters.gaborsiz],0, 0+parameters.gaborexc)];
placetex = Screen('MakeTexture',scr.main,cat(3,ones(parameters.gaborsiz),CreateCircle(parameters.gaborsiz,3)),[],[],2);

% predefine time stamps
tFix         = NaN;
tpreCueOn    = NaN;
tpreISI      = NaN;
tStimOn      = NaN;
tStimOff     = NaN;
tpostCueOn   = NaN;
tfixCheckOff = NaN;
tClr         = NaN;


% Stimulus presentation: Fixation
Screen('DrawTexture',scr.main,placetex,[],gaborrct(1,:),[],[],[],color(1,:));
Screen('DrawTexture',scr.main,placetex,[],gaborrct(2,:),[],[],[],color(2,:));
Screen('DrawTexture',scr.main,cuetex,[],cuerct,[],[],[],0);
Screen('DrawLine',scr.main,[0,0,0],barpos(1,1,1),barpos(2,1,1),barpos(1,2,1),barpos(2,2,1),4);
Screen('DrawLine',scr.main,[0,0,0],barpos(1,1,2),barpos(2,1,2),barpos(1,2,2),barpos(2,2,2),4);
Screen('DrawLine',scr.main,[0,0,0],extrabarpos(1,1,1),extrabarpos(2,1,1),extrabarpos(1,2,1),extrabarpos(2,2,1),2);
Screen('DrawLine',scr.main,[0,0,0],extrabarpos(1,1,2),extrabarpos(2,1,2),extrabarpos(1,2,2),extrabarpos(2,2,2),2);
Screen('DrawLine',scr.main,[0,0,0],extrabarpos2(1,1,1),extrabarpos2(2,1,1),extrabarpos2(1,2,1),extrabarpos2(2,2,1),2);
Screen('DrawLine',scr.main,[0,0,0],extrabarpos2(1,1,2),extrabarpos2(2,1,2),extrabarpos2(1,2,2),extrabarpos2(2,2,2),2);
Screen('DrawTexture',scr.main,fixtex,[],fixrct,[],[],[],0);
Screen('DrawingFinished',scr.main);
tFixON = Screen('Flip', scr.main);
Eyelink('message', 'EVENT_FixationDot');


% run trial
eyePhase    = 1;  %fixation 
breakIt     = 0;
fixBreak    = 0;
preCueOn    = 0;
preISIOn    = 0;
stimOn      = 0;
postCueOn   = 0;
postISIOn   = 0;
fixCheckOff = 0;
t = GetSecs;


if td.fcue ==3
    fbar1 = 1;
    fbar2 = 2;
    fcol1 = color(td.scue,:);
    fcol2 = color(td.scue,:);
else
    fbar1 = 3-td.fcue;
    fbar2 = td.fcue;
    fcol1 = [0 0 0];
    fcol2 = color(td.scue,:);
end
td.color
while ~breakIt
    if ~preCueOn && t >= (tFixON + td.fixDur - scr.fd)
        % precue
        Screen('DrawTexture',scr.main,placetex,[],gaborrct(1,:),[],[],[],color(1,:));
        Screen('DrawTexture',scr.main,placetex,[],gaborrct(2,:),[],[],[],color(2,:));
        Screen('DrawTexture',scr.main,cuetex,[],cuerct,[],[],[],[0 0 0]);

        Screen('DrawLine',scr.main,fcol1,barpos(1,1,fbar1),barpos(2,1,fbar1),barpos(1,2,3-fbar1),barpos(2,2,fbar1),4);
        if td.fcue ==3
        Screen('DrawLine',scr.main,fcol1,extrabarpos(1,1,fbar1),extrabarpos(2,1,fbar1),extrabarpos(1,2,fbar1),extrabarpos(2,2,fbar1),2);
        Screen('DrawLine',scr.main,fcol1,extrabarpos2(1,1,fbar1),extrabarpos2(2,1,fbar1),extrabarpos2(1,2,fbar1),extrabarpos2(2,2,fbar1),2);
        end
        Screen('DrawLine',scr.main,fcol2,barpos(1,1,fbar2),barpos(2,1,fbar2),barpos(1,2,fbar2),barpos(2,2,fbar2),4);
        Screen('DrawLine',scr.main,fcol2,extrabarpos(1,1,fbar2),extrabarpos(2,1,fbar2),extrabarpos(1,2,fbar2),extrabarpos(2,2,fbar2),2);
        Screen('DrawLine',scr.main,fcol2,extrabarpos2(1,1,fbar2),extrabarpos2(2,1,fbar2),extrabarpos2(1,2,fbar2),extrabarpos2(2,2,fbar2),2);
        Screen('DrawTexture',scr.main,fixtex,[],fixrct,[],[],[],fcol2);
        Screen('DrawingFinished',scr.main);
        tCueON = Screen('Flip',scr.main,tFixON + td.fixDur - scr.fd/2);
        Eyelink('message', 'EVENT_preCueOn');
        preCueOn = 1;

    elseif ~preISIOn && t > (tFixON + td.fixDur - scr.fd)
        Screen('DrawTexture',scr.main,placetex,[],gaborrct(1,:),[],[],[],color(1,:));
        Screen('DrawTexture',scr.main,placetex,[],gaborrct(2,:),[],[],[],color(2,:));
        Screen('DrawTexture',scr.main,cuetex,[],cuerct,[],[],[],[0 0 0]);
        Screen('DrawLine',scr.main,[0,0,0],barpos(1,1,1),barpos(2,1,1),barpos(1,2,1),barpos(2,2,1),4);
        Screen('DrawLine',scr.main,[0,0,0],barpos(1,1,2),barpos(2,1,2),barpos(1,2,2),barpos(2,2,2),4);
        Screen('DrawLine',scr.main,[0,0,0],extrabarpos(1,1,1),extrabarpos(2,1,1),extrabarpos(1,2,1),extrabarpos(2,2,1),2);
        Screen('DrawLine',scr.main,[0,0,0],extrabarpos(1,1,2),extrabarpos(2,1,2),extrabarpos(1,2,2),extrabarpos(2,2,2),2);
        Screen('DrawLine',scr.main,[0,0,0],extrabarpos2(1,1,1),extrabarpos2(2,1,1),extrabarpos2(1,2,1),extrabarpos2(2,2,1),2);
        Screen('DrawLine',scr.main,[0,0,0],extrabarpos2(1,1,2),extrabarpos2(2,1,2),extrabarpos2(1,2,2),extrabarpos2(2,2,2),2);
        Screen('DrawTexture',scr.main,fixtex,[],fixrct,[],[],[],0);
        Screen('DrawingFinished',scr.main);
        tISION = Screen(scr.main,'Flip',tCueON + td.preCueDur - scr.fd/2);
        Eyelink('message', 'EVENT_preISIOn');
        preISIOn = 1;
        
    elseif ~stimOn && t >= (tFixON + td.fixDur - scr.fd)
        Screen('DrawTexture',scr.main,gabortex(1),[],gaborrct(1,:));
        Screen('DrawTexture',scr.main,gabortex(2),[],gaborrct(2,:));
        Screen('DrawTexture',scr.main,placetex,[],gaborrct(1,:),[],[],[],color(1,:));
        Screen('DrawTexture',scr.main,placetex,[],gaborrct(2,:),[],[],[],color(2,:));
        Screen('DrawTexture',scr.main,cuetex,[],cuerct,[],[],[],0);
        Screen('DrawLine',scr.main,[0,0,0],barpos(1,1,1),barpos(2,1,1),barpos(1,2,1),barpos(2,2,1),4);
        Screen('DrawLine',scr.main,[0,0,0],barpos(1,1,2),barpos(2,1,2),barpos(1,2,2),barpos(2,2,2),4);
        Screen('DrawLine',scr.main,[0,0,0],extrabarpos(1,1,1),extrabarpos(2,1,1),extrabarpos(1,2,1),extrabarpos(2,2,1),2);
        Screen('DrawLine',scr.main,[0,0,0],extrabarpos(1,1,2),extrabarpos(2,1,2),extrabarpos(1,2,2),extrabarpos(2,2,2),2);
        Screen('DrawLine',scr.main,[0,0,0],extrabarpos2(1,1,1),extrabarpos2(2,1,1),extrabarpos2(1,2,1),extrabarpos2(2,2,1),2);
        Screen('DrawLine',scr.main,[0,0,0],extrabarpos2(1,1,2),extrabarpos2(2,1,2),extrabarpos2(1,2,2),extrabarpos2(2,2,2),2);
        Screen('DrawTexture',scr.main,fixtex,[],fixrct,[],[],[],0);
        Screen('DrawingFinished',scr.main);
        tStimON  = Screen(scr.main,'Flip',tISION + td.preISIDur - scr.fd/2);
        Eyelink('message', 'EVENT_stimOn');
        stimOn = 1;
        
    elseif ~postISIOn && t >= (tFixON + td.fixDur - scr.fd)
        % stimulation OFF
        Screen('DrawTexture',scr.main,placetex,[],gaborrct(1,:),[],[],[],color(1,:));
        Screen('DrawTexture',scr.main,placetex,[],gaborrct(2,:),[],[],[],color(2,:));
        Screen('DrawTexture',scr.main,cuetex,[],cuerct,[],[],[],0);
        Screen('DrawLine',scr.main,[0,0,0],barpos(1,1,1),barpos(2,1,1),barpos(1,2,1),barpos(2,2,1),4);
        Screen('DrawLine',scr.main,[0,0,0],barpos(1,1,2),barpos(2,1,2),barpos(1,2,2),barpos(2,2,2),4);
        Screen('DrawLine',scr.main,[0,0,0],extrabarpos(1,1,1),extrabarpos(2,1,1),extrabarpos(1,2,1),extrabarpos(2,2,1),2);
        Screen('DrawLine',scr.main,[0,0,0],extrabarpos(1,1,2),extrabarpos(2,1,2),extrabarpos(1,2,2),extrabarpos(2,2,2),2);
        Screen('DrawLine',scr.main,[0,0,0],extrabarpos2(1,1,1),extrabarpos2(2,1,1),extrabarpos2(1,2,1),extrabarpos2(2,2,1),2);
        Screen('DrawLine',scr.main,[0,0,0],extrabarpos2(1,1,2),extrabarpos2(2,1,2),extrabarpos2(1,2,2),extrabarpos2(2,2,2),2);
        Screen('DrawTexture',scr.main,fixtex,[],fixrct,[],[],[],0);
        Screen('DrawingFinished',scr.main);
        tStimOFF  = Screen(scr.main,'Flip',tStimON + td.targetDur - scr.fd/2);
        Eyelink('message', 'EVENT_postISIOn');
        postISIOn = 1;
       
    elseif ~postCueOn && t >= (tFixON + td.fixDur - scr.fd)
        % probe ON (response period)
        Screen('DrawTexture',scr.main,placetex,[],gaborrct(1,:),[],[],[],color(1,:));
        Screen('DrawTexture',scr.main,placetex,[],gaborrct(2,:),[],[],[],color(2,:));
        Screen('DrawLine',scr.main,[0,0,0],barpos(1,1,3-td.fprobe),barpos(2,1,3-td.fprobe),barpos(1,2,3-td.fprobe),barpos(2,2,3-td.fprobe),4);
%         if td.fcue ==3
%         Screen('DrawLine',scr.main,[0,0,0],extrabarpos(1,1,3-td.fprobe),extrabarpos(2,1,3-td.fprobe),extrabarpos(1,2,3-td.fprobe),extrabarpos(2,2,3-td.fprobe),2);
%         Screen('DrawLine',scr.main,[0,0,0],extrabarpos2(1,1,3-td.fprobe),extrabarpos2(2,1,3-td.fprobe),extrabarpos2(1,2,3-td.fprobe),extrabarpos2(2,2,3-td.fprobe),2);
%         end
        Screen('DrawTexture',scr.main,cuetex,[],cuerct,[],[],[],[0 0 0]);
        Screen('DrawLine',scr.main,color(td.sprobe,:),barpos(1,1,td.fprobe),barpos(2,1,td.fprobe),barpos(1,2,td.fprobe),barpos(2,2,td.fprobe),4);
        Screen('DrawLine',scr.main,color(td.sprobe,:),extrabarpos(1,1,td.fprobe),extrabarpos(2,1,td.fprobe),extrabarpos(1,2,td.fprobe),extrabarpos(2,2,td.fprobe),2);
        Screen('DrawLine',scr.main,color(td.sprobe,:),extrabarpos2(1,1,td.fprobe),extrabarpos2(2,1,td.fprobe),extrabarpos2(1,2,td.fprobe),extrabarpos2(2,2,td.fprobe),2);
        Screen('DrawTexture',scr.main,fixtex,[],fixrct,[],[],[],color(td.sprobe,:));
        Screen('DrawingFinished',scr.main);
        tprobeON  = Screen(scr.main,'Flip',tStimOFF + td.postISIDur - scr.fd/2);
        Eyelink('message', 'EVENT_postCueOn');
        postCueOn = 1;

    elseif ~fixCheckOff && t >= (tFixON + td.fixDur - scr.fd)
                Screen('DrawTexture',scr.main,placetex,[],gaborrct(1,:),[],[],[],color(1,:));
        Screen('DrawTexture',scr.main,placetex,[],gaborrct(2,:),[],[],[],color(2,:));
        Screen('DrawLine',scr.main,[0,0,0],barpos(1,1,3-td.fprobe),barpos(2,1,3-td.fprobe),barpos(1,2,3-td.fprobe),barpos(2,2,3-td.fprobe),4);
%         if td.fcue ==3
%         Screen('DrawLine',scr.main,[0,0,0],extrabarpos(1,1,3-td.fprobe),extrabarpos(2,1,3-td.fprobe),extrabarpos(1,2,3-td.fprobe),extrabarpos(2,2,3-td.fprobe),2);
%         Screen('DrawLine',scr.main,[0,0,0],extrabarpos2(1,1,3-td.fprobe),extrabarpos2(2,1,3-td.fprobe),extrabarpos2(1,2,3-td.fprobe),extrabarpos2(2,2,3-td.fprobe),2);
%         end
        Screen('DrawTexture',scr.main,cuetex,[],cuerct,[],[],[],[0 0 0]);
        Screen('DrawLine',scr.main,color(td.sprobe,:),barpos(1,1,td.fprobe),barpos(2,1,td.fprobe),barpos(1,2,td.fprobe),barpos(2,2,td.fprobe),4);
        Screen('DrawLine',scr.main,color(td.sprobe,:),extrabarpos(1,1,td.fprobe),extrabarpos(2,1,td.fprobe),extrabarpos(1,2,td.fprobe),extrabarpos(2,2,td.fprobe),2);
        Screen('DrawLine',scr.main,color(td.sprobe,:),extrabarpos2(1,1,td.fprobe),extrabarpos2(2,1,td.fprobe),extrabarpos2(1,2,td.fprobe),extrabarpos2(2,2,td.fprobe),2);
        Screen('DrawTexture',scr.main,fixtex,[],fixrct,[],[],[],color(td.sprobe,:));
        Screen('DrawingFinished',scr.main);
        Beeper(600,.1,.1);        
        tfixCheckOFF  = Screen(scr.main,'Flip',tprobeON + td.postCueDur - scr.fd/2);
        Eyelink('message', 'EVENT_postCueOff');
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
        rubber([]);
        Screen(scr.main,'DrawingFinished');
        tClr = Screen(scr.main,'Flip');
        Eyelink('message', 'EVENT_ClearScreen');
        
        if const.TEST; fprintf(1,'\nClearScreen'); end
        

        % timing & RT
        timing(block).fixDur(trial)     = tCueON - tFixON;
        timing(block).cueDur(trial)     = tISION - tCueON;
        timing(block).ISIDur(trial)     = tStimON - tISION;
        timing(block).stimDur(trial)    = tStimOFF - tStimON;
        timing(block).postISIDur(trial) = tprobeON - tStimOFF;

        response(block).rt(trial) = tRes - tprobeON;
        td.rt  = response(block).rt(trial);

        
        % response & feedback
        td.resp = keys.respButtons(keyPress);

        switch td.resp
            case keys.respKeyPresent
                response(block).resp(trial) = 1;
            case keys.respKeyAbsent
                response(block).resp(trial) = 0;
        end
        
        switch response(block).resp(trial) 
            case td.target
                response(block).iscor(trial) = 1;
                Beeper(600,.1,.1);Beeper(800,.1,.1)
            otherwise
                response(block).iscor(trial) = 0;
                Beeper(600,.1,.1);Beeper(400,.1,.1)
        end
        
        td.cor = response(block).iscor(trial);

        Screen('Close',gabortex);
end

