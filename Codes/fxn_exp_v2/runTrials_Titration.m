function [staircase threshold]=runTrialSequence_Titration(design,el)
%
% 2013 by Antoine Barbot

global scr visual const stimulus response participant staircase sequence timing parameters

% hide cursor if not in dummy mode
if const.TEST
    ShowCursor;
else
    HideCursor;
end


Screen(scr.main, 'Flip');
GetSecs;
WaitSecs(.2);
FlushEvents('keyDown');
Screen('BlendFunction', scr.main, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

% unify keynames for different operating systems
KbName('UnifyKeyNames');

real_sequence = [];
staircase = CreateStaircase(0.6875,0.50,0.10,8);

for b = 1:design.nBlocks
    block  = design.blockOrder(b);
    nTrial = length(design.block(b).trial);
%     nTrial = ;    
    % test trials
    t = 0;
    sumCor=0; 
    nTrials = nTrial;
    

%     stimulus(b).contrast = zeros(1,nTrial);
%     stimulus(b).phase    = zeros(2,nTrial);
%     stimulus(b).patch    = cell(2,nTrial);
%     
%     response(b).resp   = zeros(1,nTrial);
%     response(b).rt     = zeros(1,nTrial);
%     response(b).iscor  = zeros(1,nTrial);
    
    while t < nTrial
        t = t + 1;
        trialDone = 0;
        trial = t;
        if trial == 1
            sub_b = 1;
            showTextPage(scr.main, sprintf('Block %i of %i',sub_b,2),18,1,8);
        elseif trial == round(nTrial./2)
            sub_b= sub_b+1;
            showTextPage(scr.main, sprintf('Block %i of %i',sub_b,2),18,1,8);
        end
        
        if trial == nTrial/2
                staircase = UpdateStaircase(staircase,[],0.05,[]);
        end
        
        td = design.block(b).trial(trial);
        
        
        % clean operator screen
        Eyelink('command','clear_screen');
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Eyelink Stuff
        if trial==1 % calibration
            if ~const.TEST
                calibresult = EyelinkDoTrackerSetup(el);
                if calibresult==el.TERMINATE_KEY
                    return
                end
            end
        end
        Eyelink('message', 'STARTING TRIALS');
        
        if ~const.TEST
            if Eyelink('isconnected')==el.notconnected		% cancel if eyeLink is not connected
                return
            end
        end
        
        % This supplies a title at the bottom of the eyetracker display
        Eyelink('command', 'record_status_message ''Block %d of %d, Trial %d of %d''', b, design.nBlocks, trial, nTrial);
        % this marks the start of the trial
        Eyelink('message', 'TRIALID %d', trial);
        
        ncheck = 0;
        fix    = 0;
        record = 0;
        
        while fix~=1 || ~record
            if ~record
                Eyelink('startrecording');	% start recording
                % You should always start recording 50-100 msec before required
                % otherwise you may lose a few msec of data
                WaitSecs(.1);
                if ~const.TEST
                    key=1;
                    while key~= 0
                        key = EyelinkGetKey(el);		% dump any pending local keys
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
                fix    = checkFix(td);	% fixation is checked
                ncheck = ncheck + 1;
            end
            
            if fix~=1 && record
                % calibration, if maxCheck drift corrections did not succeed
                if ~const.TEST
                    calibresult = EyelinkDoTrackerSetup(el);
                    if calibresult==el.TERMINATE_KEY
                        return
                    end
                end
                record = 0;
            end
        end
        
        Eyelink('message', 'TRIAL_START %d', trial);
        Eyelink('message', 'SYNCTIME');		% zero-plot time for EDFVIEW
        
        
        [tData] = runSingleTrial_Titration(td,trial,b);
        
        Eyelink('message', 'TRIAL_ENDE %d',  trial);
        Eyelink('stoprecording');
        
        
        % go to next trial if fixation was not broken
        if tData.fixBreak==1
            trialDone = 0;
            feedback('Fixate please.',td.fixLoc(1),td.fixLoc(2));
        elseif tData.fixBreak==0
            trialDone = 1;
            

            real_sequence(b).color(trial)   = tData.color;
            real_sequence(b).fcue(trial)    = tData.fcue;
            real_sequence(b).scue(trial)    = tData.scue;
            real_sequence(b).fprobe(trial)  = tData.fprobe;
            real_sequence(b).sprobe(trial)  = tData.sprobe;
            real_sequence(b).target(trial)  = tData.target;
                        
                        
            sumCor= [sumCor+tData.cor];

        end
        
        if const.TEST; fprintf(1,'\nTrial %i done',trial); end
        
        if ~trialDone
            ntt = length(design.block(b).trial)+1;  % new trial number
            design.block(b).trial(ntt) = td;        % add trial at the end of the block
            nTrial = nTrial+1;
            
            if const.TEST; fprintf(1,' Fixation break - trial added, now total of %i trials',nTrial); end
        end
        WaitSecs(design.ITIDur);
    end
    perf= sumCor./nTrials;
    showTextPage(scr.main, sprintf('Percent Correct: %i',round(perf*100)),18,1,8);
end


% end eye-movement recording
if ~const.TEST
    Screen(el.window,'FillRect',el.backgroundcolour);   % hide display
    WaitSecs(0.1);Eyelink('stoprecording');             % record additional 100 msec of data
end

staircase.results = GetStaircaseResults(staircase,'overall',10);
threshold = staircase.results.xthr;
plot(staircase.results.x); hold on
plot([0 length(staircase.results.x)],[threshold threshold],'r--')
legend('staircase',sprintf('threshold: %d',threshold))
save(['./Data/SAFBA_',participant.identifier,'_staircase_',datestr(now,'yyyymmdd-HHMM'),'.mat'],'staircase');

rubber([]);
Screen('DrawText',scr.main,'Thanks, you have finished this part of the experiment.',100,100,visual.fgColor);
Screen('Flip',scr.main);
Eyelink('command','clear_screen');
Eyelink('command', 'record_status_message ''ENDE''');
waitsecs(1);clc

rubber([]);
h = waitbar(1,'Saving data, please wait...');
save(['./Data/SAFBA_',participant.identifier,'_Exp_',datestr(now,'yyyymmdd-HHMM'),'.mat'],'participant','real_sequence','sequence','stimulus','response','timing','parameters','tData','staircase','scr','visual');
close(h);
