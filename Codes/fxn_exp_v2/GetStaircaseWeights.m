function [w] = GetStaircaseWeights(pc,d,flooratchance)
%  [w] = GetStaircaseWeights(pc,d,[flooratchance])

if nargin < 3, flooratchance = false; end
if nargin < 2, error('Not enough input arguments.'); end

b = factorial(d)./(factorial(0:+1:d).*factorial(d:-1:0)).*pc.^(0:+1:d).*(1-pc).^(d:-1:0);

w = pc-linspace(0,1,d+1);
if flooratchance == true
    w(1:floor(d/2)) = w(floor(d/2)+1);
end

w = w./sum(b.*abs(w));

end