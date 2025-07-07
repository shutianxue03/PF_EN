sz=100;
noiseSD=44/100;
noisePatch = randn(sz, sz) * noiseSD;

% figure, imagesc(noisePatch), colorbar

ppd = 32;
sz = 3;
psz = sz*ppd;
envelopedev = 1*ppd;
angle = 0;
frequency=6/ppd;
phase = 0;
contrast = 1;

gabor = CreateGabor(psz,envelopedev,angle,frequency,phase,contrast);

noisePatch = randn(psz, psz) * noiseSD;

figure, imagesc(gabor), colorbar

%%
patch = noisePatch;
patch = gabor;
patch = gabor+noisePatch;

psz = size(patch, 1);
patch_fft2D = fftshift(abs(fft2(patch)).^2);
figure, imagesc(patch_fft2D), colorbar

%%
% patch_fft1D = patch_fft2D(:, 4);
patch_fft1D = mean(patch_fft2D, 2);
% x = 1:psz;
x = (-psz/2:psz/2-1)/psz;

% figure, imagesc(x, x, gabor_fft2D)
figure, hold on, stem(x, patch_fft1D), xline(frequency, 'r-');
xticks(x(1:16:end)), xticklabels(x(1:16:end)*ppd)

%%

%%

function [patch] = CreateGabor(siz,envelopedev,angle,frequency,phase,contrast)

if nargin < 6 || isempty(contrast)
    contrast = 1;
end
if nargin < 5 || isempty(siz) || isempty(envelopedev) || isempty(frequency) || isempty(angle) || isempty(phase)
    error('Not enough input arguments.');
end

siz   = floor(siz/2)*2;
[x,y] = meshgrid((1:siz)-(siz+1)/2);

patch = contrast*cos(2*pi*(frequency*(sin(pi/180*angle)*x+cos(pi/180*angle)*y)+phase));

gaussEnv  = exp(-((x/envelopedev).^2)-((y/envelopedev).^2));
patch = patch.*gaussEnv;

end