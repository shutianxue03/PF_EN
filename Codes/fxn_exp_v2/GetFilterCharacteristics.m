function [fresp,fsdev] = GetFilterCharacteristics(theta,gaborsiz,gaborenvelopedev,gaborangle,gaborfrequency,gaborphase,gaborcontrast,noisekerneldev,noisedev)
%  [fresp,fsdev] = GetFilterCharacteristics(theta,gaborsiz,gaborenvelopedev,gaborangle,gaborfrequency,gaborphase,gaborcontrast,noisekerneldev,noisedev)

if nargin < 9, error('Not enough input arguments.'); end

gaborsiz = floor(gaborsiz/2)*2;

kernelsiz = 2*ceil(noisekerneldev*3)+1;
kernellim = 0.5*kernelsiz/noisekerneldev;
kernel = normalpdf(linspace(-kernellim,+kernellim,kernelsiz),0,1,false);
kernel = kernel'*kernel;

alpha = CreateCircularAperture(gaborsiz);
gabor = CreateGabor(gaborsiz,gaborenvelopedev,gaborangle,gaborfrequency,gaborphase,gaborcontrast).*alpha;

fresp = zeros(size(theta));
for i = 1:length(theta)
    templ = CreateGabor(gaborsiz,gaborenvelopedev,theta(i),gaborfrequency,gaborphase,1).*alpha;
    fresp(i) = sum(gabor(:).*templ(:))/sum(templ(:).^2);
end

templ = CreateGabor(gaborsiz,gaborenvelopedev,gaborangle,gaborfrequency,gaborphase,1).*alpha;
temps = conv2(templ,kernel,'same');

fsdev = noisedev/sqrt(sum(kernel(:).^2))*sqrt(sum(temps(:).^2))/sum(templ(:).^2);

end