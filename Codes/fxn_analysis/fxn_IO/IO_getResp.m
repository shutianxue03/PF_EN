function [response, internalVar] = IO_getResp(stimulus,signal1,signal2)
% Created by Jared Abrams
% modified by Shutian Xue on 11/21/2023

% Purpose: Get the response of an ideal observer that is only limited by the
% external noise, assuming that the Gabor is the template being used

% Inputs:
%           stimulus: a matrix of the signal + noise for the trial
%           vSignal: a matrix of the left-tilt signal
%           hSignal: a matrix of the right-tilt signal

% Outputs:
%           response: 0=left-tilt, 1=right-tilt

% if nargin==3
    internalVar = stimulus.*(signal1 - signal2);
% elseif nargin==2
%     template = signal1;
%     internalVar = stimulus.*template;
% end

internalVar = sum(internalVar , 'all');

if internalVar > 0
    response = 1;
else
    response = 0;
end