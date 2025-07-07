function [x,y] = getCoord

global constant scr

if ~constant.EYETRACK
	[x,y] = GetMouse( scr.main );         % get gaze position from mouse							
else
	evt = Eyelink( 'newestfloatsample');	
	x   = evt.gx(constant.DOMEYE);			
	y   = evt.gy(constant.DOMEYE);			
end
