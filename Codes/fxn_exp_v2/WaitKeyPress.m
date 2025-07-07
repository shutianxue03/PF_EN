function [key,t] = WaitKeyPress(whichkeys,timeout,releasewait)
% [key,t] = WaitKeyPress([whichkeys],[timeout],[releasewait])

if nargin < 3 || isempty(releasewait)
    releasewait = true;
end
if nargin < 2 || isempty(timeout)
    timeout = 1;
end
if nargin < 1 || isempty(whichkeys)
    whichkeys = 1:256;
end

key = 0;
t = inf;
t0 = GetSecs;
while GetSecs-t0 < timeout
    [iskeydown,keytime,keys] = KbCheck;
    FlushEvents;
    if any(keys(whichkeys))
        t = keytime;
        key = find(keys(whichkeys),1);
        while releasewait
            [iskeydown,keytime,keys] = KbCheck;
            if ~any(keys(whichkeys)) && GetSecs-t > 0.010
                break
            end
        end
        break
    end
end

end