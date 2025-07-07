

asym = nan(nNoise, nPerf, ncomp);
for iNoise = 1:nNoise
    for iperf = 1:nPerf
        y_all = log10(squeeze(PSE_all(:, iNoise, iperf)));
        
        y_allComb = [y_all; mean(y_all([2,4], :), 1); mean(y_all([5,3], :), 1); mean(y_all(2:end, :), 1)];
        if nLoc==9
            y_allComb = [y_all([1, 6:9], :); mean(y_all([6,8], :), 1); mean(y_all([7,9], :), 1); mean(y_all(6:end, :), 1)];
        end
        
        for icomp = 1:ncomp
            asym(iNoise, iperf, icomp) = getAsym(y_allComb(iCompPair(icomp, 1)), y_allComb(iCompPair(icomp, 2)));
        end % icomp
    end % iperf
end % iNoise