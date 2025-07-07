
% combine the loc: 5 single, HM. VM, Peri
% 4 deg
y_allComb = [y_all; mean(y_all([2,4], :), 1); mean(y_all([5,3], :), 1); mean(y_all(2:end, :), 1)];
ecc = 4;
if nLoc==9
    ecc = 8;
    y_allComb = [y_all([1, 6:9], :); mean(y_all([6,8], :), 1); mean(y_all([7,9], :), 1); mean(y_all(6:end, :), 1)];
end

figure('Position', [ 0 0 ncomp*400 nNoise*300])
for iNoise = 1:nNoise
    y = y_allComb(:, iNoise);
    ymax = max(y);
    
    for icomp = 1:ncomp
        subplot(nNoise, ncomp+1, icomp+(ncomp+1)*(iNoise-1)), hold on
        for iiLoc = 1:2
            plot(iiLoc, y(iCompPair(icomp, iiLoc)), 'o', 'markerfacecolor', 'w', 'markeredgecolor', colors_comb(iCompPair(icomp, iiLoc), :), 'markersize', 10)
        end
        
        %%%%
        if iNoise==1
            xticks(1:2)
            xticklabels(namesLocComb(iCompPair(icomp, :)))
            xtickangle(45)
        else
            xticks([])
        end
        xlim([0, 3])
        ylim([-2, -.5])
        yticks_ = linspace(-2, -.5, 5);
        yticks(yticks_)
        yticklabels(round(10.^yticks_*100))
        
        if icomp==1
            title(sprintf('Threshold [N_{ext} = %d%%]', round(params.extNoiseLvl(iNoise)*100)))
        end
    end % icomp
    
    % plot ECC/HVA/VMA/LR
    subplot(nNoise, ncomp+1, (ncomp+1)*iNoise), hold on
    bar(1:ncomp, squeeze(asym(iNoise, iperf, :)))
    yline(0, 'color', ones(1,3)*.5);
    
    if iNoise==1
        xticks(1:ncomp)
        xticklabels(namesAsym)
        xlim([0, ncomp+1])
        xtickangle(45);
    else
        xticks([])
    end
    %%%%%
    
end % iNoise

sgtitle(sprintf('%s [%s] [%d deg ecc]', subjName, nn, ecc))
set(findall(gcf, '-property', 'fontsize'), 'fontsize',18)
set(findall(gcf, '-property', 'linewidth'), 'linewidth',2)
saveas(gcf, sprintf('%s/%s_%s_compLoc.jpg', nameFolder_fig, participant.subjName, nn))
