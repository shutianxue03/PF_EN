function [button,t] = WaitMouseClick(whichbuttons,timeout,releasewait)
%  [button,t] = WaitMouseClick([whichbuttons],[timeout],[releasewait])

if nargin < 3 || isempty(releasewait)
    releasewait = true;
end
if nargin < 2 || isempty(timeout)
    timeout = 1;
end
if nargin < 1 || isempty(whichbuttons)
    whichbuttons = 1:3;
end

button = 0;
t = inf;
t0 = GetSecs;
while true
    [xmouse,ymouse,buttons] = GetMouse;
    if any(buttons(whichbuttons))
        t = GetSecs;
        button = find(buttons(whichbuttons),1);
        while releasewait
            [xmouse,ymouse,buttons] = GetMouse;
            if ~any(buttons(whichbuttons)) && GetSecs-t > 0.010
                break
            end
        end
        break
    end
end

end