function runTrialSequence(design,el)

global constant scr visual participant sequence stimulus response timing params

% show cursor only in demo mode
if constant.EYETRACK
    HideCursor;
else
    ShowCursor;
end

FlushEvents('keyDown');
KbName('UnifyKeyNames'); % unify keynames for different operating systems
% set priority of window activities to maximum
priorityLevel = MaxPriority(scr.main);
Priority(priorityLevel);

real_sequence = [];


for b = params.lastblock+(1:design.nBlocksPerSession)
    trackCor      = [];
    nTrial = length(design.block(b).trial);
    
    t      = 0;
    nTrials = nTrial;

    while t < nTrial
        t = t + 1;
        trialDone = 0;
        trial = t;
        
        td = design.block(b).trial(trial);

        
        if trial == 1
            showTextPage(scr.main, sprintf('Block %i of %i - Calibration',b-params.lastblock,design.nBlocksPerSession),18,1,8);
        end
        
        
        % clean operator screen
        Eyelink('command','clear_screen');
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Eyelink Stuff
        if trial==1 % calibration
            if constant.EYETRACK
                calibresult = EyelinkDoTrackerSetup(el);
                if calibresult==el.TERMINATE_KEY
                    return
                end
            end
        end
        
        Eyelink('message', 'STARTING TRIALS');
        
        if constant.EYETRACK
            if Eyelink('isconnected')==el.notconnected		% cancel if eyeLink is not connected
                return
            end
        end
        
        % This supplies a title at the bottom of the eyetracker display
        Eyelink('command', 'record_status_message ''Block %d of %d, Trial %d of %d''', b-params.lastblock, design.nBlocksPerSession, trial, nTrial);
        % this marks the start of the trial
        Eyelink('message', 'TRIALID %d', trial);
        
        ncheck = 0;
        fix    = 0;
        record = 0;
        
        while fix~=1 || ~record
            if ~record
                Eyelink('startrecording');	% start recording
                % start recording 100 msec before just to be safe
                WaitSecs(.1);
                if constant.EYETRACK
                    key=1;
                    while key~= 0
                        key = EyelinkGetKey(el); % dump any pending local keys
                    end
                end
                
                err=Eyelink('checkrecording'); 	% check recording status
                if err==0
                    record = 1;
                    Eyelink('message', 'RECORD_START');
                else
                    record = 0;	% results in repetition of fixation check
                    Eyelink('message', 'RECORD_FAILURE');
                end
            end
            
            if fix~=1 && record
                Eyelink('command','clear_screen 0');
                rubber([]);		% clean screen
                fix    = checkFixation(td);	% check fixation
                ncheck = ncheck + 1;
            end
            
            if fix~=1 && record
                % calibration, if maxCheck drift corrections did not
                % succeed
                if constant.EYETRACK
                    calibresult   = EyelinkDoTrackerSetup(el);
                    if calibresult==el.TERMINATE_KEY
                        return
                    end
                end
                record = 0;
            end
        end
        
        Eyelink('message', 'TRIAL_START %d', trial);
        Eyelink('message', 'SYNCTIME');		% zero-plot time for EDFVIEW
        
        
        [tData] = runTrial_ENDO(td,trial,b);
        
        Eyelink('message', 'TRIAL_END %d',  trial);
        Eyelink('stoprecording');
        
        
        % go to next trial if fixation was not broken
        if tData.fixBreak==1
            trialDone = 0;
            feedback('Fixate please.',td.fixLoc(1),td.fixLoc(2));
        elseif tData.fixBreak==0
            trialDone = 1;
                        
            real_sequence(b).trialInd(trial)     = trial;
            real_sequence(b).scue(trial)         = tData.scue;
            real_sequence(b).stair(trial)        = tData.stair;
            real_sequence(b).scontrast(trial)    = tData.stimContrast;
            
            real_sequence(b).targetLoc(trial)    = tData.targetLoc;
            real_sequence(b).extNoiseLvl(trial)  = tData.extNoiseLvl;
            
            real_sequence(b).stimOri(trial)      = tData.stimOri;
            real_sequence(b).resp(trial)         = tData.resp;
            real_sequence(b).iscor(trial)        = tData.cor;
            real_sequence(b).rt(trial)           = tData.rt;
            
            trackCor = [trackCor tData.cor];

        end
        real_sequence(b).trialDone(trial)   = trialDone;

        if ~constant.EYETRACK; fprintf(1,'\nTrial %i done',trial); end
        
        if ~trialDone
            ntt = length(design.block(b).trial)+1;  % new trial number
            design.block(b).trial(ntt) = td;        % add trial at the end of the block
            nTrial = nTrial+1;
            
            if ~constant.EYETRACK; fprintf(1,' Fixation break - trial added, now total of %i trials',nTrial); end
        end
        WaitSecs(td.ITIDur);
    end
    perf= mean(trackCor);
showTextPage(scr.main, sprintf('Percent Correct: %i',round(perf*100)),18,1,8);

end

% save last block run
params.lastblock  =  b;

% end eye-movement recording
if constant.EYETRACK
    Screen(el.window,'FillRect',el.backgroundcolour);   % hide display
    WaitSecs(0.1);Eyelink('stoprecording');             % record additional 100 msec of data
end

rubber([]);
Screen('DrawText',scr.main,'Thanks, you have finished this part of the experiment.',100,100,visual.fgColor);
Screen('Flip',scr.main);
Eyelink('command','clear_screen');
Eyelink('command', 'record_status_message ''ENDED''');
WaitSecs(1);
rubber([]);

h = waitbar(1,'Saving data, please wait...');
save(['./',participant.dataDir,'/',participant.dataID,datestr(now,'yyyymmdd_HHMM'),'.mat'],'participant','real_sequence','sequence','stimulus','response','timing','params','visual','scr','design');
save(['./',participant.dataDir,'/','lastRunFile.mat'],'real_sequence','sequence','stimulus','response','timing','params','visual','scr','design');

close(h);
