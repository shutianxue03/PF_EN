
subplot(5,5, indPos(iLoc)), hold on

%% plot raw data
cst = cst_all{iLoc, iNoise};
nData = nData_all{iLoc, iNoise};
nCorr = nCorr_all{iLoc, iNoise};
pC = pC_all{iLoc, iNoise};
for ii=1:length(cst)
    plot(log10(cst(ii)), pC(ii),'ok','MarkerFaceColor','w','MarkerSize',1+round(nData(ii)/5),'Linewidth',1); axis square
end

%% plot PMF
plot(log10(fit.curveX), PMF_pred{iLoc,iNoise},'-k', 'Linewidth',2); % SX

%% plot PSE
PSE_med3 = nan(length(perfPSE_all), 1);
for iperf = 1:length(perfPSE_all)
    PSE_med_ = PSE_med(iLoc, iNoise, iperf);
    PSE_med3(iperf) = PSE_med_; % do NOT delete!
    plot(log10([PSE_med_, PSE_med_]), [0, 1],'-k','Linewidth',1);%SX
end

ylim([0.4 1]);
xlim(log10([.01, 1]))
xticks(log10([.01, .1, .5, 1]))
xticklabels([.01, .1, .5, 1])

%% title
title(sprintf('PSE=%.3f/%.3f/%.3f', PSE_med3))

