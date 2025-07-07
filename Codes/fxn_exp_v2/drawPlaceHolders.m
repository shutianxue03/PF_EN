function drawPlaceHolders(whichScreen, col, coordInd,siz1,siz2,offpos,wdth)

Screen('DrawLine',whichScreen,col,coordInd(1)+offpos,coordInd(2)+offpos,coordInd(1)+siz1+offpos,coordInd(2)+offpos,wdth);
Screen('DrawLine',whichScreen,col,coordInd(1)+offpos,coordInd(2)+offpos,coordInd(1)+offpos,coordInd(2)+siz1+offpos,wdth);
Screen('DrawLine',whichScreen,col,coordInd(3)-offpos,coordInd(4)-offpos,coordInd(3)-siz1-offpos,coordInd(4)-offpos,wdth);
Screen('DrawLine',whichScreen,col,coordInd(3)-offpos,coordInd(4)-offpos,coordInd(3)-offpos,coordInd(4)-siz1-offpos,wdth);

Screen('DrawLine',whichScreen,col,coordInd(1)+offpos,coordInd(2)+siz2-offpos,coordInd(1)+siz1+offpos,coordInd(2)+siz2-offpos,wdth);
Screen('DrawLine',whichScreen,col,coordInd(1)+siz2-offpos,coordInd(2)+offpos,coordInd(1)+siz2-offpos,coordInd(2)+siz1+offpos,wdth);
Screen('DrawLine',whichScreen,col,coordInd(3)-offpos,coordInd(4)-siz2+offpos,coordInd(3)-siz1-offpos,coordInd(4)-siz2+offpos,wdth);
Screen('DrawLine',whichScreen,col,coordInd(3)-siz2+offpos,coordInd(4)-offpos,coordInd(3)-siz2+offpos,coordInd(4)-siz1-offpos,wdth);
