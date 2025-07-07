function drawEndoCue(col,loc,cueCond,cuedLoc)

global scr visual params
% Screen(scr.main,'FillOval',col,loc+[-pu -pu pu pu]);
Screen('TextSize',scr.main,params.EndoCueSize);
offsetCueX = round(params.EndoCueSize/3.8);
offsetCueY = round(params.EndoCueSize/2.2);
xxx = [4 2.5 4 2.5];

if cueCond==0
    Screen('DrawLine',scr.main,col,loc(1)-xxx(1).*params.fixSize,loc(2),loc(1)-xxx(2).*params.fixSize,loc(2),params.fixWdth);
    Screen('DrawLine',scr.main,col,loc(1)+xxx(1).*params.fixSize,loc(2),loc(1)+xxx(2).*params.fixSize,loc(2),params.fixWdth);
    Screen('DrawLine',scr.main,col,loc(1),loc(2)-xxx(3).*params.fixSize,loc(1),loc(2)-xxx(4).*params.fixSize,params.fixWdth);
    Screen('DrawLine',scr.main,col,loc(1),loc(2)+xxx(3).*params.fixSize,loc(1),loc(2)+xxx(4).*params.fixSize,params.fixWdth);
    
    Screen('DrawText',scr.main,'X',loc(1)-offsetCueX,loc(2)-offsetCueY,col);
    
elseif cueCond==2
    
    switch cuedLoc
        case 1
            Screen('DrawText',scr.main,'0',loc(1)-offsetCueX,loc(2)-offsetCueY,col);
            
        case 2
            Screen('DrawText',scr.main,'1',loc(1)-offsetCueX,loc(2)-offsetCueY,col);
            Screen('DrawLine',scr.main,col,loc(1)-xxx(1).*params.fixSize,loc(2),loc(1)-xxx(2).*params.fixSize,loc(2),params.fixWdth);
        case 3
            Screen('DrawText',scr.main,'1',loc(1)-offsetCueX,loc(2)-offsetCueY,col);
            Screen('DrawLine',scr.main,col,loc(1),loc(2)-xxx(3).*params.fixSize,loc(1),loc(2)-xxx(4).*params.fixSize,params.fixWdth);
        case 4
            Screen('DrawText',scr.main,'1',loc(1)-offsetCueX,loc(2)-offsetCueY,col);
            Screen('DrawLine',scr.main,col,loc(1)+xxx(1).*params.fixSize,loc(2),loc(1)+xxx(2).*params.fixSize,loc(2),params.fixWdth);
        case 5
            Screen('DrawText',scr.main,'1',loc(1)-offsetCueX,loc(2)-offsetCueY,col);
            Screen('DrawLine',scr.main,col,loc(1),loc(2)+xxx(3).*params.fixSize,loc(1),loc(2)+xxx(4).*params.fixSize,params.fixWdth);
            
        case 6
            Screen('DrawText',scr.main,'2',loc(1)-offsetCueX,loc(2)-offsetCueY,col);
            Screen('DrawLine',scr.main,col,loc(1)-xxx(1).*params.fixSize,loc(2),loc(1)-xxx(2).*params.fixSize,loc(2),params.fixWdth);
        case 7
            Screen('DrawText',scr.main,'2',loc(1)-offsetCueX,loc(2)-offsetCueY,col);
            Screen('DrawLine',scr.main,col,loc(1),loc(2)-xxx(3).*params.fixSize,loc(1),loc(2)-xxx(4).*params.fixSize,params.fixWdth);
        case 8
            Screen('DrawText',scr.main,'2',loc(1)-offsetCueX,loc(2)-offsetCueY,col);
            Screen('DrawLine',scr.main,col,loc(1)+xxx(1).*params.fixSize,loc(2),loc(1)+xxx(2).*params.fixSize,loc(2),params.fixWdth);
        case 9
            Screen('DrawText',scr.main,'2',loc(1)-offsetCueX,loc(2)-offsetCueY,col);
            Screen('DrawLine',scr.main,col,loc(1),loc(2)+xxx(3).*params.fixSize,loc(1),loc(2)+xxx(4).*params.fixSize,params.fixWdth);
            
    end
end