function drawFixationX(col,loc)

global scr visual params
% Screen(scr.main,'FillOval',col,loc+[-pu -pu pu pu]);
Screen('DrawLine',scr.main,col,loc(1)-params.fixSize,loc(2)-params.fixSize,loc(1)+params.fixSize,loc(2)+params.fixSize,params.fixWdth);
Screen('DrawLine',scr.main,col,loc(1)-params.fixSize,loc(2)+params.fixSize,loc(1)+params.fixSize,loc(2)-params.fixSize,params.fixWdth);