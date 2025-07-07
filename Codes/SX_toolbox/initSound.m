%% sound
InitializePsychSound(1); % 1 for precise timing
% Open the audio device
pahandle = PsychPortAudio('Open');
device = PsychPortAudio('GetDevices');
params.fs = device.DefaultSampleRate;
params.pahandle =  pahandle;
params.freqCorrect = 1e3;
params.freqNeutral = 8e2;
params.freqWrong = 6e2;
params.amp = 1;
