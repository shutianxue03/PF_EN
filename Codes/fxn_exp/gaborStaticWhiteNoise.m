function [image,stimOnFrame,stimOffFrame] = gaborStaticWhiNoise(sizePixels,cyclesPerImage,phase_offset,stim_contr,noise_contr,...
    nMask,mask,cRange,totalTime,stimOn,stimTime,ifi,background)

%Purpose =  create a stimulus of multiple frames that is a gabor embedded in
%           dynamic noise
%Input =    sizePixels: a matrix with two values for the size in pixels
%                   along the x and y respectively
%           cyclesPerImage: the number of cycles to make the sinusoidal
%                   grating
%           phase_offest: the phase of the sinusoid
%           stim_contr: the michelson contrast of the stimulus
%           noise_contr: the RMS contrast of the noise
%           nMask:  the mask to apply to the noise to make the patch circular
%                   rather than rectangular
%           mask:   the mask to apply to the sinusioidal grating, should be a
%                   gaussian envelope 
%           cRange: a matrix containing the background index and the number
%                   of contrast steps
%           totalTime: the total duration of the noise stimulus in msec
%           stimOn: the time at which the gabor should appear within the
%                   noise (msec)
%           stimTime: the duration of the gabor (msec)
%           ifi: the frame duration for each refresh of the screen
%           background: the background index of the screen
%Output=    image = a XYT matrix consisting of XY intensities for each
%                   frame
%           stimOnFrame = the frame when the stimulus comes on (use to get
%               a measure of stimulus onset) 
%           stimOffFrame = the off frame (use to get stimulus offset time)
frames = round((totalTime/1000)/ifi);   %get the total number of frames 
stimOnFrame = round((stimOn/1000)/ifi) + 1; stimOffFrame = round((stimTime/1000)/ifi) + stimOnFrame; %Get the on and off frame numbers for the stimulus
image = randn(sizePixels(1),sizePixels(2),frames) * noise_contr * min(cRange); %Make the noise and adjust its contrast
gabor = CreateGaborJA(sizePixels,cyclesPerImage,phase_offset,stim_contr,mask,cRange); %Make the gabor
for f = 1:frames                                %Iterate through the number of frames
    if f >= stimOnFrame && f < stimOffFrame     %Add the gabor is this is a stimulus frame
        image(:,:,f) = image(:,:,f) + gabor;
    end
    image(:,:,f) = image(:,:,f) .* nMask;       %Apply the noise mask to the frame
end
keyboard
image = floor(image) + background;              %Add the background intensity index to the floored image
