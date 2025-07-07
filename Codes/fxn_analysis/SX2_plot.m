
SX_analysis_setting

indPos = [13 12 8 14 18 11 3 15 23];
% nLoc = size(PSE_allB, 2);

%% Figure 1. plot PMF
% get median and CI from boostrapping
[PSE_med, PSE_lb, PSE_ub] = getCI(PSE_allB, 1, 1);

for iNoise = 1:nNoise
    
    figure('Color','white','units','normalized','Position',[0 0 .5 1]);
    % Part 1: PMF of each loc
    for iLoc = 1:nLoc
        PSEplot1
    end % for iLoc
    
    % Part 2: polar plot, PSE of all loc, relative to fovea
    %         PSEplot2
    sgtitle(sprintf('%s\nNoise=%d%% [%d]', subjName, round(params.extNoiseLvl(iNoise)*100), iNoise))
    saveas(gcf, sprintf('Fig/idvd/PMF/%s_N%d.jpg', subjName, iNoise))
end % for iNoise

%% ecc effect, HVA and VMA for PSE
iperf = 1;
PSE_all = squeeze(PSE_med(1:nLoc, :, iperf));
PSEplot3 
% end

%% Figure 2. plot TvC

