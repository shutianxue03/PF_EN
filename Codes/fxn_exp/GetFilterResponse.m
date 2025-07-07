function [fresp] = GetFilterResponse(patch,envelopedev,frequency,angle,phase)

if nargin < 5, error('Not enough input arguments.'); end

siz = size(patch,1);
lumibg = patch(1,1);

fresp = nan(size(phase));
for i = 1:numel(phase)
    templ = CreateGabor(siz,envelopedev,angle,frequency,phase(i),1).*CreateCircularAperture(siz);
    fresp(i) = sum((patch(:)-lumibg).*templ(:))/sum(templ(:).^2)/min(2*lumibg,2*(1-lumibg));
end

end