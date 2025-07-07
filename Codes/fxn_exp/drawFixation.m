function drawFixation(col,loc)

global scr visual params

pu = round(visual.ppd*0.1);
Screen(scr.main,'FillOval',col,loc+[-pu -pu pu pu]);
% Screen(scr.main,'FrameOval',visual.white,loc+2*[-pu -pu pu pu],pu);

