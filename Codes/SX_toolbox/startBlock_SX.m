function el = startBlock_SX(iblock_local, design, el)

global params visual scr keys constant
if constant.expMode ~= 2
    DrawFormattedText(scr.main, sprintf('%s\nBlock %d/%d\n',...
        constant.names_expModes{constant.expMode}, iblock_local, design.nBlockTotal), 'center', 'center', visual.black);
    DrawFormattedText(scr.main, sprintf('Press space to calibrate\nPress Q to quit\nPress any other keys to continue\n'), scr.centerX  - 200, scr.centerY + 50, visual.black);
else % practice
    DrawFormattedText(scr.main, sprintf('%s\nBlock %d/%d\n',...
        constant.names_expModes{constant.expMode}, iblock_local, design.nBlockTotal), 'center', 'center', visual.black);
    DrawFormattedText(scr.main, sprintf('Press Q to quit\nPress any other keys to continue\n'), scr.centerX  - 200, scr.centerY + 50, visual.black);
end
Screen('Flip', scr.main);

%% initiate eyetracker
% if constant.EYETRACK
%     el.eyeFile = 'xx';
%     [el,exitFlag] = rd_eyeLink('eyestart', scr.main, {el.eyeFile});
%     el.eyeFile = 'xx';
%     el.eyeDataDir = 'eyedata';
%     if exitFlag, return, end
% end

%% wait for key presses
fprintf('\n\nWaiting for key presses\n\n')

% pause
% if ~constant.flagSimulate
%     CorrecKeyPressed = 0; % unmute
%     while ~ CorrecKeyPressed
%         [keyIsDown, ~, keyCode] = KbCheck; % -1: gather all input devices); % the input should NOT be the screen ind!!
%         if keyIsDown && (sum(keyCode) > 0), keyPressed = find(keyCode); CorrecKeyPressed = 1; end
%     end
%     
%     switch keyPressed
%         case keys.space % Press space to calibrate
%             if constant.EYETRACK
%                 [~, exitFlag] = rd_eyeLink('calibrate', scr.main, el);
%                 if exitFlag, return, end
%                 Screen(scr.main,'FillRect',visual.bgColor,[]); Screen(scr.main, 'Flip');
%             end
%         case keys.stopKey % Press Q to quits
%             endExp_SX
%             error('\n\nALERT: Experiment stopped by the user!\n\n');
%     end
% end
