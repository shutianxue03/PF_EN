


%% display thank-you message
Screen('FillRect', scr.main, visual.bgColor, scr.rect); Screen('Flip', scr.main); WaitSecs(.1);
DrawFormattedText(scr.main,'Thanks, you have finished this part of the experiment.','center', 'center', visual.black);
Screen('Flip',scr.main);

WaitSecs(2);
sca;

%% turn off sound track
for ff = [800, 600, 400], makeBeep(ff, .2), end
PsychPortAudio('Close', params.pahandle);

%%
fprintf(1,'\n\nDuration: %.1f min\n\n.', (toc)/60);

%% turn off EL recording and save eye file
if constant.EYETRACK
    el.eyeFile = 'xx'; el.eyeDataDir = 'eyedata'; % stupid hardcode
    if ~exist(el.eyeDataDir,'dir'), mkdir(el.eyeDataDir); end
    rd_eyeLink('eyestop', scr.main, {el.eyeFile, el.eyeDataDir});
end

%% rename eyedata file
if constant.EYETRACK
    if ~exist('iblock_local', 'var'), iblock_local = real_sequence.iblock_local; end
    string_datetime = datestr(now,'yyyymmdd_HHMM');
    if iblock_local<10, string_b = sprintf('b0%d', iblock_local-1);
    else, string_b = sprintf('b%d', iblock_local-1);
    end
    
    eyeFile_edf_old = sprintf('%s/%s.edf', el.eyeDataDir, el.eyeFile);
    
    if ~isempty(dir(eyeFile_edf_old))
        
        if constant.expMode==4
        eyeFile_edf_new = sprintf('%s/%s_eye_E%d_s%d_%s_%s.edf', ...
            constant.nameFolder, constant.nameFolder(end-1:end), constant.expMode, constant.iSess, string_b, string_datetime);
        else
            eyeFile_edf_new = sprintf('%s/%s_eye_E%d_%s_%s.edf', ...
            constant.nameFolder, constant.nameFolder(end-1:end), constant.expMode, string_b, string_datetime);
        end
        
        movefile(eyeFile_edf_old, eyeFile_edf_new)
    end
end
