% 
% if constant.expMode ~= 1, error('ALERT: wrong expMode (%d), should be 1\n', constant.expMode), end
% %%%%%%%%
% % plot_setting
% %%%%%%%%
% % SX_analysis_setting
% 
% % % nNoise = length(params.extNoiseLvl);
% % design.nNoise = nNoise;
% % % design.nLoc = params.nLoc;
% % nLoc = design.nLoc;
% % % nLoc=5; % only look at fovea and 4 deg ecc
% 
% if flag_plotPMF
%     %% Fig 1. plot staircase
%     colors_stair = {'c','c', 'm', 'm'};
%     figure('Position', [0 0 nNoise*400 nLoc*300])
%     for iLoc = 1:nLoc
%         for iNoise = 1:nNoise
%             subplot(nLoc, nNoise, iNoise+(iLoc-1)*nNoise), hold on
%             for iStair = 1:design.nStairs
%                 stair = params.UD{iLoc, iNoise, iStair}.xStaircase;
%                 nsteps = length(stair);
%                 plot(1:nsteps, stair, ['-',colors_stair{iStair}], 'linewidth', 2)
%                 
%                 xlim([1, design.nStairs * params.nTrialsPerStair + design.nStairCatch*params.nTrialsCatch])
%                 yticks(-2:.5:0)
%                 yticklabels(round(10.^(-2:.5:0)*100))
%                 ylim([-2.5, 0])
%             end % iStair
%             if iNoise==1, ylabel(namesLoc9{iLoc}), end
%             title(sprintf('[%d%%] [70%%] %d%% [79%%] %d%%', ...
%                 round(params.extNoiseLvl(iNoise)*100), ...
%                 round(100*10^thresh_all(iLoc, iNoise, 1)), round(100*10^thresh_all(iLoc, iNoise, 3))))
%         end % iNoise
%     end % iLoc
%     sgtitle(participant.subjName)
%     saveas(gcf, sprintf('%s/%s_stair.jpg', nameFolder_fig, participant.subjName))
%     
%     %% demo (to put in grant)
%     iLoc = 1;
%     iNoise = 2;
%     figure('Position', [0 0 1e3 1e3]), hold on, box on
%     for iStair = 1:design.nStairs
%         if iStair == 1||iStair == 3, style = '-'; else, style = '--'; end
%         stair = params.UD{iLoc, iNoise, iStair}.xStaircase;
%         nsteps = length(stair);
%         plot(1:nsteps, stair, [style,colors_stair{iStair}], 'linewidth', 2)
%         
%         xlim([1, design.nStairs * params.nTrialsPerStair + design.nStairCatch*params.nTrialsCatch])
%         yticks(-2:.5:0)
%         yticklabels(round(10.^(-2:.5:0)*100))
%         ylim([-2.5, 0])
%     end % iStair
%     xlabel('Session #')
%     ylabel('Gabor contrast (%)')
%     legend({'1U3D #1','1U3D #2', '1U2D #1', '1U2D #2'})
%     set(findall(gcf, '-property', 'fontsize'), 'fontsize',60)
%     set(findall(gcf, '-property', 'LineWidth'), 'LineWidth',4)
%     %
%     % %% Fig 1c. compare titrated thresh across locations
%     % nn = 'stair70';
%     % y_all = squeeze(thresh_all(:, :, 1)); % input to plotThreshAcrossLoc
%     % plotThreshAcrossLoc
%     %
%     % nn = 'stair79';
%     % y_all = squeeze(thresh_all(:, :, 3)); % input to plotThreshAcrossLoc
%     % plotThreshAcrossLoc
%     
%     %% fitting PMF - get CCC
%     warning off
%     nameFile_CCC_stair = sprintf('%s/%s_ccc_stair.mat', constant.nameFolder, participant.subjName);
%     dir_CCC_stair = dir(nameFile_CCC_stair);
%     
%     if isempty(dir_CCC_stair)
%         nameFiles_all = sprintf('%s/%s_E1_b*.mat', constant.nameFolder, participant.subjName);
%         dirFiles_all = dir(nameFiles_all);
%         nFiles = length(dirFiles_all);
%         fprintf('CCC1 (staircase) file creating (%d files)...', nFiles)
%         ccc_stair = [];
%         for ifile = 1:nFiles
%             load(dirFiles_all(ifile).name)
%             ccc_stair = [ccc_stair;...
%                 real_sequence.targetLoc(real_sequence.trialDone==1)'...
%                 real_sequence.extNoiseLvl(real_sequence.trialDone==1)'...
%                 real_sequence.scontrast(real_sequence.trialDone==1)'...
%                 real_sequence.iscor(real_sequence.trialDone==1)'];
%         end % ifile
%         save(nameFile_CCC_stair, 'ccc_stair')
%         fprintf('DONE\n')
%     else
%         load(nameFile_CCC_stair)
%         fprintf('CCC (staircase)  file loaded\n')
%     end
%     
%     %% fitting PMF - fit & get PSE
%     % load PSE data
%     if flag_oldData
%         ccc_stair = ccc;
%         nameFile_PSE_stair = sprintf('%s/%s_PSE_stair.mat', constant.nameFolder, participant.subjName);
%     else
%         nameFile_PSE_stair = sprintf('%s/%s_PSE_all.mat', constant.nameFolder, participant.subjName);
%     end
%     dir_PSE_stair = dir(nameFile_PSE_stair);
%     
%     if isempty(dir_PSE_stair)
%         fprintf('PSE (staircase) creating...')
%         iLoc_all = ccc_stair(:,1);
%         iNoise_all = ccc_stair(:,2);
%         icor_all = ccc_stair(:,4);
%         
%         % empty containers
%         PSE_all = nan(nLoc, nNoise, nperf);
%         LL_all = nan(nLoc, nNoise);
%         R2_all = LL_all;
%         
%         yfit_all = cell(nLoc, nNoise);
%         cst_all = yfit_all;
%         nData_all = yfit_all;
%         nCorr_all = yfit_all;
%         pC_all = yfit_all;
%         
%         ccc = ccc_stair;
%         for iLoc = 1:nLoc
%             for iNoise = 1:nNoise
%                 %%%%%%%%%%%%%%%%%%%%%%%%
%                 fxn_fitPMF % produces PSE_all (nLoc x nNoise x nPerf)
%                 %%%%%%%%%%%%%%%%%%%%%%%%
%             end % iNoise
%         end % iLoc
%         curveX = fit.curveX;
%         
%         %%%%%%%%%%%%%%%%%%%%%%%%
%         fxn_getAsym
%         %%%%%%%%%%%%%%%%%%%%%%%%
%         save(nameFile_PSE_stair, 'thresh70_all', 'thresh79_all', 'PSE_all', 'cst_all', 'nCorr_all', 'nData_all','pC_all','R2_all',  'curveX', 'yfit_all')
%         fprintf('DONE\n')
%     else
%         load(nameFile_PSE_stair); fprintf('PSE (staircase) file loaded\n')
%     end
%     
%     % %% get asym
%     % if flag_oldData
%     %     fxn_getAsym
%     % end
%     
%     
%     %% Fig 2. plot PMF
%     % SX_analysis_setting
%     figure('Position', [0 0 nNoise*400 nLoc*300])
%     % plot raw data
%     for iLoc = 1:nLoc
%         for iNoise = 1:nNoise
%             subplot(nLoc, nNoise, iNoise+(iLoc-1)*nNoise), hold on
%             
%             cst = cst_all{iLoc, iNoise};
%             nCorr = nCorr_all{iLoc, iNoise};
%             nData = nData_all{iLoc, iNoise};
%             pC = pC_all{iLoc, iNoise};
%             %%%%%%%%%%%%%%%%%%%%%%%%
%             fxn_plotPMF % used PSE_all (nLoc x nNoise x nPerf)
%             %%%%%%%%%%%%%%%%%%%%%%%%
%             
%             if iNoise==1, ylabel(namesLoc9{iLoc}), end
%             
%             % title
%             %         title(sprintf('Noise=%d%%\nThresh=%d%% (R^2=%d%%)', ...
%             %             round(params.extNoiseLvl(iNoise)*100), ...
%             %             round(100*PSE), round(100*R2_all(iLoc, iNoise))))
%             if iLoc == 1, title(sprintf('Noise=%d%%', round(params.extNoiseLvl(iNoise)*100))), end
%             text(log10(0.35), .5, sprintf('%d%%', round(100*PSE)), 'color', 'r')
%             %         title(sprintf('PSE=%.3f/%.3f/%.3f', pse_thresh_med3))
%         end % iNoise
%     end % iLoc
%     
%     sgtitle(participant.subjName)
%     saveas(gcf, sprintf('%s/%s_PMF_stair.jpg', nameFolder_fig, participant.subjName))
%     
%     %         save('grantFig_AB', 'cst_all', 'nCorr_all', 'nData_all', 'fit', 'yfit_all', 'PSE_all')
%     
%     %% compare thresh and PSE
%     min_ = min(thresh_all(:));
%     max_ = max(thresh_all(:));
%     ticks = linspace(min_, max_, 5);
%     
%     figure('Position', [0 0 1200 600])
%     for iPerf = [1,3] % 70 and 79%
%         subplot(1,2, find(iPerf ==[1,3])), hold on
%         pp = log10(squeeze(PSE_all(:, :, iPerf)));
%         
%         plot([ticks(1), ticks(end)], [ticks(1), ticks(end)], '-', 'color', ones(1,3)*.5)
%         
%         for iLoc = 1:nLoc
%             plot(thresh_all(iLoc, :, iPerf), pp(iLoc, :), '-o', 'color', colors9(iLoc, :), 'markersize', 10)
%         end
%         
%         xlabel('Threshold from staircase (contrast %)')
%         ylabel('PSE from PMF (contrast %)')
%         xticks(ticks), xticklabels(round(10.^ticks*100)), xlim(ticks([1, end]))
%         yticks(ticks), yticklabels(round(10.^ticks*100)), ylim(ticks([1, end]))
%         axis square
%         title(sprintf('%d%% accuracy', perfPSE_all(iPerf)))
%     end
%     sgtitle(participant.subjName)
%     set(findall(gcf, '-property', 'fontsize'), 'fontsize',18)
%     set(findall(gcf, '-property', 'linewidth'), 'linewidth',2)
%     saveas(gcf, sprintf('%s/%s_comp_thresh_PMF.jpg', nameFolder_fig, participant.subjName))
% end % if flag_plot
% 
% %% NOTE
% % the figures below is for pilot purpose
% 
% %% Fig 1: at noise = 0%, whether HVA and VMA are sig
% iPerf = 1;
% iNoise = 1;
% for iccc = 1:3
%     PSE_perLoc = 1./PSE_allC{iccc}(:, iNoise, iPerf);
%     HM = mean(PSE_perLoc([2,4]));
%     VM = mean(PSE_perLoc([3,5]));
%     figure
%     bar([1,2,4,5], [HM, VM, PSE_perLoc([5,3])'])
%     xticks([1,2,4,5])
%     xticklabels({'HM', 'VM', 'LVM', 'UVM'})
%     ylabel('contrast sensitivity (70% acc)')
%     set(findall(gcf, '-property', 'fontsize'), 'fontsize',20)
%     ylim([0, 20])
% end
% 
% 
% %% Fig 2: cross locations, whether noise=0% is diff from noise=44%
% iPerf = 1;
% buffer = .3;
% for iccc = 1:3
%     
%     figure, hold on
%     for iLoc = 1:nLoc
%         bar([iLoc-buffer, iLoc+buffer], PSE_allC{iccc}(iLoc, [1,end], iPerf))
%     end
%     xticks(1:nLoc)
%     xticklabels(namesLocComb(1:nLoc))
% end
% 
% %%  Fig 3. plot TvC
% iPerf = 1; % 70%
% % x = [floor(log10(params.extNoiseLvl(2))), log10(params.extNoiseLvl(2:end))]; % linear cst, on log scale
% x_log = [-1.5, log10(params.extNoiseLvl(2:end))]; % linear cst, on log scale
% x_sq = params.extNoiseLvl.^2;
% x = x_sq;
% 
% iplots9 = [13, 12, 8, 14, 18, 11, 3, 15, 23];
% 
% for iFIT = 1:2 % 1=fit TvC by LAM
%     figure('Position', [0 0 1e3 1e3])
%     for iPerf = 1%:nPerf
%         
%         for iLoc = 1:nLoc
%             subplot(5,5, iplots9(iLoc)), hold on
%             % raw data
%             plot(x, PSE_all(iLoc, :, iPerf).^2, 'ko')
%             % fitted data
%             %             plot(x, squeeze(TvC_pred_sq_all(iLoc, iperf, :, iFIT)), '.k-', 'handlevisibility', 'off')
%             plot(x_sq_1K, squeeze(TvC_pred_sq_1K_all(iLoc, iPerf, :)), '.k-', 'handlevisibility', 'off')
%             %             if find(iLoc == 3:2:9),  ylim([0, .4]), else,  ylim([0, .15]), end
%             %             xlim(x([1, end]))
%             %         xticks(x([1:3,5,7]))
%             %         xticklabels(round(100*params.extNoiseLvl([1:3,5,7])))
%             %         xticklabels(1:7)
%         end % iLoc
%     end % iperf
%     %     fprintf('All figures generated\n')
%     set(findall(gcf, '-property', 'fontsize'), 'fontsize',20)
%     sgtitle(sprintf('%s [%d%%]', subjName, perfPSE_all(iPerf)))
%     
% end % iFIT