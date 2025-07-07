
% get unique contrast levels
cst_unik = unique(ccc(iLoc_all==iLoc_tgt & iNoise_all==iNoise, 3));
icst_all = ccc(:,3);
curveX  = fit.curveX;
if flag_logCST
    cst_unik = log10(cst_unik); 
    icst_all = log10(icst_all); % do NOT move upward, as it has to be rounded first
    curveX = log10(fit.curveX);
end

nCorr = nan(length(cst_unik), 1); nData=nCorr; pC=nCorr;

for icst_unik = 1:length(cst_unik)
    indTrial = (iLoc_all==iLoc_tgt) & (iNoise_all==iNoise) & (icst_all>cst_unik(icst_unik)-0.001 & icst_all<=cst_unik(icst_unik)+0.001);
    nCorr(icst_unik) = nansum(icor_all(indTrial));
    nData(icst_unik) = nansum(indTrial==1);
    pC(icst_unik) = nCorr(icst_unik)./nData(icst_unik);
end % icst_unik
if flag_logCST, cst_all{iLoc_tgt, iNoise} = 10.^cst_unik; else, cst_all{iLoc_tgt, iNoise} = cst_unik; end
nCorr_all{iLoc_tgt, iNoise} = nCorr;
nData_all{iLoc_tgt, iNoise} = nData;
pC_all{iLoc_tgt, iNoise} = pC;

% fit PF
if length(cst_unik)>1
    
    [paramVals, LL, exitflag] = PAL_PFML_Fit(cst_unik, nCorr, nData,...
        fit.searchGrid, fit.paramsFree, fit.PF,'SearchOptions',fit.options,'lapseLimits',fit.lapseLimits,'guessLimits',fit.guessLimits);
%     slope=paramVals(2);
    slope=paramVals(2) * ((1-.5)./sqrt(2.*pi)); % according to Strasburger 2001 eq.18
    slope_all(iLoc_tgt, iNoise) = slope;
    yfit_all{iLoc_tgt,iNoise} = fit.PF(paramVals, curveX);
    y = nCorr./nData;
    ypred = fit.PF(paramVals, cst_unik);
    R2 = 1-sum((ypred-y).^2)/sum((y-mean(y)).^2);
    LL_all(iLoc_tgt, iNoise) = LL;
    R2_all(iLoc_tgt, iNoise) = R2;
    for iPerf = 1:nPerf
        perfPSE = perfPSE_all(iPerf)/100;
        PSE_all(iLoc_tgt, iNoise, iPerf) = fit.PF(paramVals, perfPSE, 'Inverse');
    end
end
