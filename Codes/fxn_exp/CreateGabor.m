function [patch] = CreateGabor(siz,envelopedev,angle,frequency,phase,contrast)

if nargin < 6 || isempty(contrast)
    contrast = 1;
end
if nargin < 5 || isempty(siz) || isempty(envelopedev) || isempty(frequency) || isempty(angle) || isempty(phase)
    error('Not enough input arguments.');
end

siz   = floor(siz/2)*2;
[x,y] = meshgrid((1:siz)-(siz+1)/2);

patch = 0.5*contrast*cos(2*pi*(frequency*(sin(pi/180*angle)*x+cos(pi/180*angle)*y)+phase));

gaussEnv  = exp(-((x/envelopedev).^2)-((y/envelopedev).^2));
patch = patch.*gaussEnv;

end