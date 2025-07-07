
iLoc=1;

if flag_plot, hold on, grid on, end

for istair=1:nStairs
    if istair<=2, color = 'r'; % staircase for left-tilted
    elseif istair<=4, color = 'b'; % staircase for left-tilted
    else , color = 'k'; % staircase for left-tilted
    end
    staircase_log = log10(ccc(ccc(:, 1)==iLoc & ccc(:, 2)==iNoise & ccc(:, 5)==istair, 3));
    if flag_plot, plot(staircase_log, '.-', 'Color', color), end
    if istair<=4, endpoints(istair)=staircase_log(end); end
end % istair

if flag_plot
    yline(mean(endpoints(1:2)), 'r-', 'LineWidth',2);
    yline(mean(endpoints(3:4)), 'b-', 'LineWidth',2);
    yline(mean(endpoints), 'k-', 'LineWidth',3);
    xlabel('trial#')
    ylabel('log contrast')
    yticks(-3:.5:0)
    yticklabels(round(10.^(-3:.5:0)*100))
    ylim([-3, 0]);
    endpoints_ = 100*10.^(endpoints);
    title(sprintf('%.2f%%\nL: %.1f%% // R: %.1f%%', mean(endpoints_), mean(endpoints_([1,2])), mean(endpoints_([3,4]))))
end

thresh_log_stair(iNoise) = mean(endpoints);

