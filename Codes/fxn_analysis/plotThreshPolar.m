

figure('Position', [0 0 800 600])
% 1 (fovea)
polarplot([polar_ang, polar_ang(1)], ones(1,5), 'r-', 'linewidth', 3)

hold on
legends = {};
for iNoise = 1:nNoise
    [thresh_ave, ~, ~, thresh_SEM] = getCI(squeeze(y_all(:, iNoise)), 2, 2);
    
    % get ratio relative to fovea
    thresh_ave_ = thresh_ave(2:end)/thresh_ave(1);
    
    if nLoc == 9
        y = [thresh_ave_(5:8)', thresh_ave_(5), thresh_ave_(1:4)', thresh_ave_(1)];
        x = [polar_ang, polar_ang(1), polar_ang, polar_ang(1)];
        polarplot(x(6:10), y(6:10) , ['.', linestyles{iNoise}], 'color', ones(1,3)*.5,  'LineWidth',2, 'handlevisibility', 'off')%, 'k-', 'linewidth', 2)
    else
        y = [thresh_ave_', thresh_ave_(1)];
        x = [polar_ang, polar_ang(1)];
    end
    polarplot(x(1:5), y(1:5) , ['k.', linestyles{iNoise}],  'LineWidth', 2)%, 'k-', 'linewidth', 2)
    legends{iNoise} = sprintf('N_{eq}=%d%%', round(100*(params.extNoiseLvl(iNoise))));
end

legend(['ratio=1 (fovea)', legends])
sgtitle(sprintf('%s [%s]', participant.subjName, nn))
set(findall(gcf, '-property', 'fontsize'), 'fontsize',30)
saveas(gcf, sprintf('%s/%s_%s_polar.jpg', nameFolder_fig, participant.subjName, nn))

