function threshEnergy_pred = fxn_PTM_nestedMC(indParamIncl, dprimes, noiseEnergy, params_allLoc, SF_fit)
% DO NOT change to fxn_PTM_nestedMC
nPerf = length(dprimes);
nNoise = length(noiseEnergy);
nLoc = size(params_allLoc, 1);
% nLoc = length(params_allLoc)/nParams; % unmute when using bads
% params_allLoc = reshape(params_allLoc, [nLoc, nParams]); % unmute when using bads

threshEnergy_pred = nan(nLoc, nNoise, nPerf);
for iLoc = 1:nLoc
    for iPerf = 1:nPerf
        %------------------------------------------------------------------------------------%
        threshEnergy_pred(iLoc, :, iPerf) = fxn_PTM(indParamIncl, params_allLoc(iLoc, :), noiseEnergy, dprimes(iPerf), SF_fit);
        %------------------------------------------------------------------------------------%
    end
end

% cstEnergy_pred = cstEnergy_pred(:).'; % unmute when using bads
threshEnergy_pred = threshEnergy_pred(:);

end

