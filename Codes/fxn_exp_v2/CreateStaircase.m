function [staircase] = CreateStaircase(pctarget,xstart,sstart,dstart,flooratchance,pfdir)

if nargin < 6, pfdir = +1; end
if nargin < 5, flooratchance = true; end
if nargin < 4, error('Not enough input arguments.'); end

staircase = struct;

staircase.pctarget = pctarget;
staircase.xstart = xstart;
staircase.sstart = sstart;
staircase.dstart = dstart;
staircase.flooratchance = flooratchance;
staircase.pfdir = sign(pfdir);

staircase.i = 1;
staircase.x = nan(1,1000); staircase.x(1) = xstart;
staircase.r = nan(1,1000);

staircase.scur = staircase.sstart;
staircase.dcur = staircase.dstart;

staircase.j = 0;
staircase.w = GetStaircaseWeights(staircase.pctarget,staircase.dcur,staircase.flooratchance);

staircase.wcur = 0;
staircase.wold = 0;

staircase.nstp = 0;
staircase.istp = nan(1,1000);

staircase.nrev = 0;
staircase.irev = nan(1,1000);

staircase.nupd = 0;
staircase.iupd = nan(1,1000);

end