
for iNoise=1:nNoise
    
    figure('Position', [0 0 2e3 2e3]),
    
    for iLoc = iLoc_tgt_all
        iiLoc = find(iLoc == iLoc_tgt_all);
        
        if nLocSingle==9, subplot(5,5, iplots9(iLoc))
        elseif nLocSingle==5, subplot(3,3, iplots5(iLoc))
        end
        
        hold on, grid on
        
        for istair=1:nstairs
            if istair<=2, color = 'r'; % staircase for left-tilted
            elseif istair<=4, color = 'b'; % staircase for left-tilted
            else , color = 'k'; % staircase for left-tilted
            end
            staircase_log = log10(ccc_all(ccc_all(:, 1)==iLoc & ccc_all(:, 2)==noiseLvl_all_doubled(iNoise) & ccc_all(:, 5)==istair, 3));
            
            plot(staircase_log, '.-', 'Color', color)
            if istair<=4, endpoints(istair)=staircase_log(end); end
            
        end % istair
        yline(mean(endpoints(1:2)), 'r-', 'LineWidth',2);
        yline(mean(endpoints(3:4)), 'b-', 'LineWidth',2);
        yline(mean(endpoints), 'k-', 'LineWidth',3);
        xlabel('trial#')
        ylabel('contrast (%)')
        yticks(-3:.25:0)
        yticklabels(round(10.^(-3:.25:0)*100, 1))
        ylim([-3, 0]);
        endpoints = 100*10.^(endpoints);
        title(sprintf('[L%d]  %.1f%%\nL: %.1f%% // R: %.1f%%', iLoc, mean(endpoints), mean(endpoints([1,2])), mean(endpoints([3,4]))))
        
        % save endpoints
        thresh_stair_single(iLoc, iNoise) = mean(endpoints);
    end % iLoc
    
    sgtitle(sprintf('%s [SF=%d, Noise=%.3f]', subjName, SF, noiseLvl_all(iNoise)))
    
    
    if nLocSingle == 5, set(findall(gcf, '-property', 'fontsize'), 'fontsize',12),
    else, set(findall(gcf, '-property', 'fontsize'), 'fontsize',10)
    end
    
    saveas(gcf, sprintf('%s/N%.0f.jpg', nameFolder_fig_stair, noiseLvl_all(iNoise)*100))
    
end % iNoise
