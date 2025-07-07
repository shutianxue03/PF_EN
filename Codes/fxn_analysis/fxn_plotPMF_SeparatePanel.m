% for iNoise = 1:nNoise
%         for iLoc = 1:nLoc
%             figure('Position', [0 0 1e3 500]), hold on
%             
%             %-----------------------%
%             fxn_plotPMF_singlePanel
%             %-----------------------%
%             
%             xticks_log = -3:.1:0;
%             yticks([0, .4, .5, .6, .7, perfThresh_all/100, .9, 1])
%             
%             xlim(xticks_log([1,end]))
%             xticks(xticks_log)
%             xticklabels(round(10.^xticks_log*100, 1)), xtickangle(90)
%             ylim([0, 1])
%             set(findall(gcf, '-property', 'fontsize'), 'fontsize',20)
%             set(findall(gcf, '-property', 'LineWidth'), 'LineWidth',2)
%             title(sprintf('%s (Loc %d, N=%.0f%%) - %s [Bin%dFilter%d]', ...
%                 subjName, iLoc, noiseLvl_all(iNoise)*100, text_noStair(2:end),flag_binData, flag_filterData))
%             if isempty(dir([nameFolder_fig, '/singleCond'])), mkdir([nameFolder_fig, '/singleCond']), end
%             saveas(gcf, sprintf('%s/singleCond/PMF_L%dN%.0f%s.jpg', nameFolder_fig_PMF, iLoc, noiseLvl_all(iNoise)*100, text_noStair))
%         end % iLoc_tgt
%         close all
%     end % iNoise