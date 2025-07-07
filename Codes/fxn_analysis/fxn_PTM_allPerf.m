function cE_pred = fxn_PTM_allPerf(indParamIncl, dprimes, nE, params)
nPerf = length(dprimes);
nNoise = length(nE);

cE_pred = nan(nPerf, nNoise);
for iPerf = 1:nPerf
    dprime = dprimes(iPerf);
    cE_pred(iPerf, :) = fxn_PTM(indParamIncl, params, nE, dprime);
end
cE_pred = cE_pred(:);
end

