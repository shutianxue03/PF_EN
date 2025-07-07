function [fener] = GetFilterEnergy(patch,envelopedev,frequency,angle)

if nargin < 4, error('Not enough input arguments.'); end

fener = nan(size(angle));
for i = 1:numel(angle)
    fener(i) = sqrt(sum(GetFilterResponse(patch,envelopedev,frequency,angle(i),[0 0.25]).^2));
end

end