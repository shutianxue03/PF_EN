function [staircase] = UpdateStaircase(staircase,xnew,snew,dnew)

if nargin < 4, dnew = []; end
if nargin < 3, snew = []; end
if nargin < 2, xnew = []; end
if nargin < 1, error('Not enough input arguments.'); end

staircase = RefreshStaircase(staircase);

if ~isempty(xnew)
    staircase.x(staircase.i) = xnew;
end
if ~isempty(snew)
    staircase.scur = snew;
end
if ~isempty(dnew)
    staircase.dcur = dnew;
end

staircase.w = GetStaircaseWeights(staircase.pctarget,staircase.dcur,staircase.flooratchance);
staircase.j = staircase.i-1;

staircase.nupd = staircase.nupd+1;
staircase.iupd(staircase.nupd) = staircase.i;

end