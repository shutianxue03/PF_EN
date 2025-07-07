
%%
gabor_L = CreateGabor(params.gaborsiz, params.gaborenvelopedev, -45, params.gaborfrequency, gaborPhase, 2.*visual.bgColor);
gabor_R = CreateGabor(params.gaborsiz, params.gaborenvelopedev, 45, params.gaborfrequency, gaborPhase, 2.*visual.bgColor);

gabor_L = min(max((gabor_L + visual.bgColor)/255, 0), 1);
gabor_R = min(max((gabor_R + visual.bgColor)/255, 0), 1);

template_diff = gabor_L - gabor_R;
tgt = squeeze(mean(noiseImg_(:,:, :, run.targetLoc), 3));
internalVar = sum(tgt(:).*template_diff(:));

if run.stimOri==1 % Left
    if internalVar>0; r=1; else, r=2; end
else
    if internalVar<0; r=2; else, r=1; end
end

%%
% thresh=[.1, .3];
% % higher c, higher confidence
% if run.stimContrast > thresh(2)
%     r=run.stimOri; c=2;
% elseif (run.stimContrast>thresh(1))&&(run.stimContrast<=thresh(2))
%     if rand<.7, r=run.stimOri;
%     else, if run.stimOri==1, r=2; else, r=1;end
%     end
%     if rand<.8, c=2; else, c=1; end
% elseif run.stimContrast<=thresh(1)
%     if run.stimOri==1, r=2; else, r=1;end
%     c=1;
% end