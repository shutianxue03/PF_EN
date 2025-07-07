function [staircase] = SetStaircaseResponse(staircase,x,r)
%  [staircase] = SetStaircaseResponse(staircase,x,r)

if nargin < 3, error('Not enough input arguments.'); end

staircase.x(staircase.i) = x;
staircase.r(staircase.i) = r;

end