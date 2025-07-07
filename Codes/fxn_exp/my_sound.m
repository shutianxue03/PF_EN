function my_sound (t)
% ----------------------------------------------------------------------
% my_sound(t)
% ----------------------------------------------------------------------
% Goal of the function :
% Play a wave file a specified number of time.
% ----------------------------------------------------------------------
% Input(s) :
% waveFile : wave file directory
% t : switch between diferent sounds.
% ----------------------------------------------------------------------
% Output(s):
% (none)
% ----------------------------------------------------------------------
% Function created by Martin SZINTE (martin.szinte@gmail.com)
% Last update : 19 / 11 / 2009
% Project : RealMotBlank
% Version : 1.0
% ----------------------------------------------------------------------

% AssertOpenGL;
% if ispc
%     [y, freq] = wavread(waveFile);
%     wavedata = y';
%     nrchannels = size(wavedata,1);
%     InitializePsychSound;
% 
%     pahandle = PsychPortAudio('Open', [], [], 0, freq, nrchannels);
% 
%     PsychPortAudio('FillBuffer', pahandle, wavedata);
%     PsychPortAudio('Start', pahandle, 1, 0, 1);
%     PsychPortAudio('Stop', pahandle);
%     PsychPortAudio('Close', pahandle);

if t == 1
    Snd('Play',[repmat(0.3,1,150) linspace(0.4,0.0,50)].*[zeros(1,100) sin(1:100)],4000);
    Snd('Play',[repmat(0.3,1,150) linspace(0.5,0.0,50)].*[zeros(1,100) sin(1:100)],5000);
elseif t == 2
    Snd('Play',[repmat(0.3,1,150) linspace(0.4,0.0,50)].*[zeros(1,100) sin(1:100)],3000);
elseif t ==3 
    Snd('Play',[repmat(0.3,1,150) linspace(0.5,0.0,50)].*[zeros(1,100) sin(1:100)],4000);
elseif t == 4
    Snd('Play',[repmat(0.5,1,150) linspace(0.3,0.0,50)].*[zeros(1,100) sin(1:100)],7000);
    Snd('Play',[repmat(0.5,1,150) linspace(0.3,0.0,50)].*[zeros(1,100) sin(1:100)],5000);
elseif t == 5
    Snd('Play',[repmat(0.5,1,150) linspace(0.3,0.0,50)].*[zeros(1,100) sin(1:100)],5000);
elseif t == 6
    Snd('Play',[repmat(0.5,1,150) linspace(0.3,0.0,50)].*[zeros(1,100) sin(1:100)],5000);
    Snd('Play',[repmat(0.5,1,150) linspace(0.3,0.0,50)].*[zeros(1,100) sin(1:100)],5000);
    Snd('Play',[repmat(0.5,1,150) linspace(0.3,0.0,50)].*[zeros(1,100) sin(1:100)],5000);
elseif t == 7
    Snd('Play',[repmat(0.5,1,150) linspace(0.3,0.0,50)].*[zeros(1,100) sin(1:100)],200);
elseif t == 8
    Snd('Play',[repmat(0.3,1,150) linspace(0.4,0.0,50)].*[zeros(1,100) sin(1:100)],3000);
    Snd('Play',[repmat(0.3,1,150) linspace(0.4,0.0,50)].*[zeros(1,100) sin(1:100)],1500);
elseif t == 9
    Snd('Play',[repmat(0.3,1,150) linspace(0.4,0.0,50)].*[zeros(1,100) sin(1:100)],3000);
    Snd('Play',[repmat(0.3,1,150) linspace(0.4,0.0,50)].*[zeros(1,100) sin(1:100)],2000);
    Snd('Play',[repmat(0.3,1,150) linspace(0.4,0.0,50)].*[zeros(1,100) sin(1:100)],2000);
elseif t ==10;
    Snd('Play',[repmat(0.3,1,200) linspace(0.3,0.0,50)].*[zeros(1,150) sin(1:100)],12000,16);
    Snd('Play',[repmat(0.3,1,200) linspace(0.3,0.0,50)].*[zeros(1,150) sin(1:100)],1000,16);
end
FlushEvents;
end