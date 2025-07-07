function response = idealObserver(stimulus,vSignal,hSignal)
%Purpose: Get the response of an ideal observer that is only limited by the
%external noise
%Inputs:    stimulus: a matrix of the signal + noise for the trial
%           vSignal: a matrix of the vertical signal
%           hSignal: a matrix of the horizontal signal
%Outputs:   response: 0 for the first signal (vertical), 1 for the second
%                   signal(horizontal)

r = sum(sum(mean(stimulus,3).*(vSignal - hSignal)));
if r > 0
    response = 1;
else
    response = 0;
end