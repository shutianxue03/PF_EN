function [staircase] = RefreshStaircase(staircase)
%  [staircase] = RefreshStaircase(staircase)

if nargin < 1, error('Not enough input arguments.'); end

if ~isnan(staircase.r(staircase.i))
    if ~mod(staircase.i-staircase.j, staircase.dcur)
        staircase.nstp = staircase.nstp+1;
        staircase.istp(staircase.nstp) = staircase.i;
        nc = sum(staircase.r(staircase.i-staircase.dcur+1:staircase.i));
        staircase.wcur = staircase.w(nc+1);
        if abs(sign(staircase.wcur)-sign(staircase.wold)) > 1
            staircase.nrev = staircase.nrev+1;
            staircase.irev(staircase.nrev) = staircase.i;
        end
        staircase.wold = staircase.wcur;
        staircase.x(staircase.i+1) = staircase.x(staircase.i)*10^(staircase.pfdir*staircase.wcur*staircase.scur);
    else
        staircase.x(staircase.i+1) = staircase.x(staircase.i);
    end
    staircase.i = staircase.i+1;
    if staircase.i == length(staircase.x)
        staircase.x = [staircase.x,nan(1,staircase.i)];
        staircase.r = [staircase.r,nan(1,staircase.i)];
    end
end

end