function real_sequence = runTrialSequence(design, el)

global constant scr visual participant sequence stimulus response confidence timing params
% do NOT globalized design because it's huge

% show cursor only in demo mode
% if constant.EYETRACK, HideCursor; else, ShowCursor; end % AB

FlushEvents('keyDown');
KbName('UnifyKeyNames'); % unify keynames for different operating systems
% set priority of window activities to maximum
% priorityLevel = MaxPriority(scr.main); % AB
% Priority(priorityLevel); % AB

ib_finished = length(dir(sprintf('%s/%s_E%d*', constant.nameFolder, participant.subjName, constant.expMode)));
ib_start = constant.iblock;

ib_end = design.nBlockTotal;

for iblock_local = ib_start:ib_end
    real_sequence = [];
    
    switch constant.expMode
        case 1, iblock = params.lastBlock+1;
        case 2, iblock = iblock_local;
        case 3, iblock = iblock_local;
        case 4, iblock = iblock_local;
        case 5, iblock = iblock_local;
    end
    
    real_sequence.iblock = iblock;
    real_sequence.iblock_local = iblock_local;
    
    %%%%%%%%% START THE BLOCK %%%%%%%
    el = startBlock_SX(iblock_local, design, el); % SX
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    run_allTrials = design.allBlocks(iblock).allTrials;
    nTrials = length(run_allTrials);
    t = 0;
    % nTrials = nTrial; % AB
    
    while t < nTrials
        t = t + 1;
        trialDone = 0;
        itrial = t;
        
        fixRad = 5; Screen('FillOval', scr.main, [0 0 0], [scr.xres/2-fixRad, scr.yres/2-fixRad, scr.xres/2+fixRad, scr.yres/2+fixRad]); Screen('Flip', scr.main);
        
        % extract params for each trial
        run = design.allBlocks(iblock).allTrials(itrial); % do NOT use run_allTrials!
        run.itrial = itrial;
        run.iblock_local = iblock_local; % iblock among blocks of this session; do NOT put before run = design.allBlocks(iblock).allTrials(itrial);!!
        run.iblock = iblock; % iblock among all blocks of this observer; do NOT put before run = design.allBlocks(iblock).allTrials(itrial);!!
        
        %% run a single trial
        [run, el] = runTrial(el, run, itrial, iblock);
        
        %% go to next trial if fixation was not broken
        if run.fixBreak==1
            trialDone = 0;
        elseif run.fixBreak==0
            trialDone = 1;
            real_sequence.trialInd(itrial) = itrial;
            real_sequence.scue(itrial) = 0;
            if constant.expMode == 5
            real_sequence.dataMode(itrial) = run.dataMode;
            end
            real_sequence.stair(itrial) = run.stair;
            real_sequence.scontrast(itrial)  = run.stimContrast;
            real_sequence.targetLoc(itrial)  = run.targetLoc;
            real_sequence.extNoiseLvl(itrial)  = run.extNoiseLvl;
%             real_sequence.extNoiseLvl(itrial) = params.extNoiseLvl(run.extNoiseLvl);
            real_sequence.stimOri(itrial) = run.stimOri;
            real_sequence.oriResp(itrial) = run.oriResp;
%             real_sequence.confidence(itrial) = run.confidence;
            real_sequence.iscor(itrial) = run.cor;
            real_sequence.rt(itrial) = run.rt;
        end
        real_sequence.trialDone(itrial) = trialDone;
        
        % if ~constant.EYETRACK; fprintf(1,'\nTrial %i done',trial); end % AB
        design.allBlocks(iblock).allTrials(itrial) = run;
        if ~trialDone
            ntt = length(design.allBlocks(iblock).allTrials)+1;  % new trial number; do NOT create a new variable!!
            design.allBlocks(iblock).allTrials(ntt) = run; % add trial at the end of the block
            nTrials = nTrials+1;
            
            fprintf(' Break --> trial added, now total of %d/%d (%d) trials\n\n', itrial, nTrials, design.nTrialsPerBlock);
        else
            if constant.expMode==2
                fprintf(' %d/%d (%d) trials\n\n', itrial, nTrials, design.nTrialsPerBlock);
            end
        end
        
        %% refresh page
        Screen(scr.main,'FillRect',visual.bgColor,[]);
        Screen(scr.main, 'Flip');
        if trialDone, WaitSecs(run.ITIDur); else, WaitSecs(.1);end
        
    end % while t<nTrials
    
    if constant.expMode~=2
        params.lastBlock = params.lastBlock + 1;
    end
    
%     DrawFormattedText(scr.main, 'Saving data...', 'center', 'center');
%     Screen(scr.main, 'Flip');
    %-----------%
    endBlock_SX 
    %-----------%
    
end % for iblock

