function [doubletone] = CreateDoubleTone(tonefrequency,toneduration,voidduration,samplingrate,attenuation,noise)

if nargin < 6
    noise = [];
end
if nargin < 5
    attenuation = [];
end
if nargin < 4
    error('Not enough input arguments.');
end

tone = CreateTone(tonefrequency,toneduration,samplingrate,attenuation,noise);
doubletone = [tone,zeros(2,ceil(voidduration*samplingrate)),tone];

end