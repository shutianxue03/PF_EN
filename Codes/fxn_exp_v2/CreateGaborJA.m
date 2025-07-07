function gabor = createGabor(sizePixels,cyclesPerImage,phase_offset,contrast,mask,cRange)
%Purpose:   Create a Gabor to display
%Input:     sizePixels: 1X2 matrix, expressing size in pixels in x and y
%           cyclesPerImage: Cycles of the sinusoid over the size in pixels
%           phase_offset: The phase offset
%           contrast: The desired stimulus contrast as a proportion
%           mask: Premade gaussian envelope (use My2DGauss.m)
%           cRange: Range of monitor index values
%           background: The background index. 
%Output:    A sinusoidal grating of a given phase and contrast in a
%           Gaussian envelope

%Make a sinusoidal grating
x = 0:sizePixels(2)-1;
f = cyclesPerImage/(sizePixels(2)-1);
fr = f * 2 * pi;
grating = sin(fr*x-phase_offset);
grating = repmat(grating, sizePixels(1), 1);

%Adjust the stimulus contrast
grating = grating .* mask;
gabor = grating * contrast * min(cRange);

