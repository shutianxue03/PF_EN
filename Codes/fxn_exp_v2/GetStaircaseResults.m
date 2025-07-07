function [results] = GetStaircaseResults(staircase,estimation,ifirst)

if nargin < 3, error('Not enough input arguments.'); end

results = struct;

results.pctarget = staircase.pctarget;
results.pfdir = staircase.pfdir;

results.n = staircase.i-1;

results.x = staircase.x(1:results.n);
results.r = staircase.r(1:results.n);

results.nstp = length(find(staircase.istp <= results.n));
results.istp = staircase.istp(1:results.nstp);

results.nrev = length(find(staircase.irev <= results.n));
results.irev = staircase.irev(1:results.nrev);

results.nupd = length(find(staircase.iupd <= results.n));
results.iupd = staircase.iupd(1:results.nupd);

switch estimation
    case 'overall'
        if isempty(ifirst) || ifirst > results.nstp
            results.ithr = nan;
            results.xthr = nan;
        else
            results.ithr = results.istp(ifirst:end);
            results.xthr = 10^mean(log10(results.x(results.ithr)));
            results.pthr = mean(results.r(results.istp(ifirst-1)+1:end));
        end
    case 'reversals'
        if isempty(ifirst) || ifirst > results.nrev
            results.ithr = nan;
            results.xthr = nan;
        else
            results.ithr = results.irev(ifirst:end);
            results.xthr = 10^mean(log10(results.x(results.ithr)));
            ifirst = find(results.istp == results.irev(ifirst));
            results.pthr = mean(results.r(results.istp(ifirst-1)+1:end));
        end
    otherwise
        error('Unknown threshold estimation.');
end

end