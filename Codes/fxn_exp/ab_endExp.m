function [] = ab_endExp(screenNumber, startclut, edfFile, fileName, path)

ListenChar(0);
ShowCursor;

Screen('LoadNormalizedGammaTable', screenNumber, startclut, []);
Screen('CloseAll')
cd(path)
if isempty(edfFile) == 0
    closeFileStatus = Eyelink('CloseFile');
    if closeFileStatus ~= 0
        fprintf('WARNING: Problem saving EDF file!');
    end
    try
        Eyelink('ReceiveFile', edfFile, strcat(fileName,'.edf'));
    catch %#ok<CTCH>
        fprintf('WARNING: Problem receiving EDF file!\n');
    end
    Eyelink('ShutDown');
end

fclose all;

clear mex;
clear fun;
home;
