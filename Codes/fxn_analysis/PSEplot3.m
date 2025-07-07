
% plot ecc effect, HVA, VMA and LR diff
% iperf = 1; %1/2/3=70/75/79%
nLoc = 5; % only look at 4 deg ecc

nNoise = size(PSE_all, 2);

%% create combined loc
PSE_allComb = [PSE_all; mean(PSE_all([2,4], :), 1); mean(PSE_all([5,3], :), 1); mean(PSE_all(2:end, :), 1)];
if nsubj>1
        SEM_allComb = [PSE_SEM; mean(PSE_SEM([2,4], :), 1); mean(PSE_SEM([5,3], :), 1); mean(PSE_SEM(2:end, :), 1)];
    end
% PSE_allComb_allSubj(isubj, :, :) = PSE_allComb;
yticks_ = linspace(-2, -.9, 5);

figure('Position', [ 0 0 1.5e3 800])

% ymax = max(y);
asym = nan(ncomp, nNoise);

for icomp = 1:ncomp
    for iNoise = 1:nNoise
        %     if iINE == 1, y = Neq_allComb.^2; else, y= slope_allComb*100; end
        y = log10(PSE_allComb(:, iNoise));
        subplot(ncomp, nNoise+1, iNoise + (nNoise+1)*(icomp-1)), hold on
        for ii = 1:2
           if nsubj>1 
               errorbar(ii, y(iCompPair(icomp, ii)), SEM_allComb(iCompPair(icomp, ii)), 'k', 'CapSize', 0)
           end
            plot(ii, y(iCompPair(icomp, ii)), 'o', 'markerfacecolor', 'w', 'markeredgecolor', colors_comb(iCompPair(icomp, ii), :), 'markersize', 10)
        end
        if nsubj>1
            for isubj = 1:nsubj
                plot(1:2, PSE_allSubj())
            end
        end
        asym(icomp, iNoise) = getAsym(y(iCompPair(icomp, 1)), y(iCompPair(icomp, 2)));
        if iNoise==1
            xticks(1:2)
            xticklabels(namesLocComb(iCompPair(icomp, :)))
        else, xticklabels([])
        end
        %         xtickangle(45)
        xlim([0.5, 2.5])
        %         if iINE == 1,
        ylim(yticks_([1, end]))
        
        yticks(yticks_)
        yticklabels(round(10.^yticks_*100))
        if icomp == 1
            title(sprintf('N_{ext} = %d%%', round(params.extNoiseLvl(iNoise)*100)))
        end
        
    end % iNoise
    
    % plot the asymmetry index
    subplot(ncomp, nNoise+1, (nNoise+1) * icomp), hold on
    bar(asym(icomp, :))
    yline(0, 'k-');
    xticks(1:nNoise)
    xticklabels(1:nNoise)
    if icomp == 1, title('Asymmetry index'), end
    ylim([-.1, .15])
end % icomp

% sgtitle(subjName)
set(findall(gcf, '-property', 'fontsize'), 'fontsize',18)
set(findall(gcf, '-property', 'linewidth'), 'linewidth',2)
saveas(gcf, sprintf('fig/idvd/PSE/%s.jpg', subjName))

