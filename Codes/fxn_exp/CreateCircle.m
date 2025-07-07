function [patch] = CreateCircle(siz,width,falloff)
%  [patch] = CreateCircle(siz,width,[falloff])

if nargin < 3, falloff = 2; end
if nargin < 2, error('Not enough input arguments.'); end

sigmoidfun = @(x,lims)lims(1)+diff(lims)./(1+exp(-x));

siz = floor(siz/2)*2;
[x,y] = meshgrid((1:siz)-(siz+1)/2);

coef = log(1/0.01-1)*2/falloff;

patch = sigmoidfun(coef*(sqrt(x.^2+y.^2)-siz/2),[1,0]);
patch = min(patch,sigmoidfun(coef*(sqrt(x.^2+y.^2)-(siz/2-width)),[0,1]));

end