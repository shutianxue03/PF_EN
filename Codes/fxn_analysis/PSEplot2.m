
% plot PSE 
polarAxesHandle = subplot(5,5, [19, 20, 24, 25]);
ax = gca;
ax.XTick = [];
ax.YTick = [];
polaraxes('Units',polarAxesHandle.Units,'Position',polarAxesHandle.Position)
hold on

colors_allPERF = {'r', 'b', 'k'};
lineStyle = {'-', '--'};
for iperf = 1:length(perfPSE_all)
    for iecc = 1:2
        switch iecc
            case 1, iLoc_perECC = 2:5;
            case 2, iLoc_perECC = 6:9;
        end
        pse_polar = pse_thresh_med([iLoc_perECC, iLoc_perECC(1)], iNoise, iperf);
        pse_fovea = pse_thresh_med(1, iNoise, iperf);
        polarplot([polar_ang, polar_ang(1)], log(pse_polar)-log(pse_fovea), ...
            [colors_allPERF{iperf}, lineStyle{iecc}])%, 'Color', barFaceColors(idata,:))
    end % iecc
    ax = gca;
    ax.ThetaTick = [];
    polarplot([polar_ang, polar_ang(1)], ones(1,5), 'k-', 'linewidth', 2)
end % iperf

