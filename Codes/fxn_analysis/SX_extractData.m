
if constant.expMode ~= 1, error('ALERT: wrong expMode (%d), should be 1\n', constant.expMode), end

%% 1. obtain thresh (the endpoint of staircase)
thresh_all = nan(nLoc, nNoise, nPerf);
thresh_all_ = nan(nLoc, nNoise, design.nStairs);

for iLoc = 1:nLoc
    for iNoise = 1:nNoise
        for iStair = 1:design.nStairs
            stair = params.UD{iLoc, iNoise, iStair}.xStaircase;
            % collect endpoints (do NOT include catch trials)
            if iStair <= design.nStairs, thresh_all_(iLoc, iNoise, iStair)= stair(end); end
        end % iStair
    end % iNoise
end % iLoc
thresh_all(:, :, 3) = mean(thresh_all_(:, :, 1:2), 3); % get the average of endpoints, on log scale (two 1up3down staircases, acc=79%)
thresh_all(:, :, 1) = mean(thresh_all_(:, :, 3:4), 3); % get the average of endpoints, on log scale (two 1up2down staircases, acc=70%)

%% 2. get CCC (to fit PMF)
warning off
nameFile_CCC_stair = sprintf('%s/%s_ccc_stair.mat', constant.nameFolder, participant.subjName);
dir_CCC_stair = dir(nameFile_CCC_stair);

if isempty(dir_CCC_stair)
    nameFiles_all = sprintf('%s/%s_E1_b*.mat', constant.nameFolder, participant.subjName);
    dirFiles_all = dir(nameFiles_all);
    nFiles = length(dirFiles_all);
    fprintf('CCC1 (staircase) file creating (%d files)...', nFiles)
    ccc_stair = [];
    for ifile = 1:nFiles
        load(dirFiles_all(ifile).name)
        ccc_stair = [ccc_stair;...
            real_sequence.targetLoc(real_sequence.trialDone==1)'...
            real_sequence.extNoiseLvl(real_sequence.trialDone==1)'...
            real_sequence.scontrast(real_sequence.trialDone==1)'...
            real_sequence.iscor(real_sequence.trialDone==1)'];
    end % ifile
    save(nameFile_CCC_stair, 'ccc_stair')
    fprintf('DONE\n')
else
    load(nameFile_CCC_stair)
    fprintf('CCC (staircase)  file loaded\n')
end

%% 2. fit PMF & get PSE
% load PSE data
if flag_oldData
    ccc_stair = ccc;
    nameFile_PSE_stair = sprintf('%s/%s_PSE_stair.mat', constant.nameFolder, participant.subjName);
else
    nameFile_PSE_stair = sprintf('%s/%s_PSE_all.mat', constant.nameFolder, participant.subjName);
end
dir_PSE_stair = dir(nameFile_PSE_stair);

if isempty(dir_PSE_stair)
    fprintf('PSE (staircase) creating...')
    iLoc_all = ccc_stair(:,1);
    iNoise_all = ccc_stair(:,2);
    icor_all = ccc_stair(:,4);
    
    % empty containers
    PSE_all = nan(nLoc, nNoise, nPerf);
    LL_all = nan(nLoc, nNoise);
    R2_all = LL_all;
    
    yfit_all = cell(nLoc, nNoise);
    cst_all = yfit_all;
    nData_all = yfit_all;
    nCorr_all = yfit_all;
    pC_all = yfit_all;
    
    ccc = ccc_stair;
    for iLoc = 1:nLoc
        for iNoise = 1:nNoise
            %%%%%%%%%%%%%%%%%%%%%%%%
            fxn_fitPMF % produces PSE_all (nLoc x nNoise x nPerf)
            %%%%%%%%%%%%%%%%%%%%%%%%
        end % iNoise
    end % iLoc
    curveX = fit.curveX;
%     save(nameFile_PSE_stair, 'thresh70_all', 'thresh79_all', 'PSE_all', 'cst_all', 'nCorr_all', 'nData_all','pC_all','R2_all',  'curveX', 'yfit_all')
    save(nameFile_PSE_stair, 'PSE_all', 'cst_all', 'nCorr_all', 'nData_all','pC_all','R2_all',  'curveX', 'yfit_all')
    fprintf('DONE\n')
else
    load(nameFile_PSE_stair); fprintf('PSE (staircase) file loaded\n')
end

%%  3. estimate Neq and eff from fitting TvF
if nNoise>4
    x_sq = params.extNoiseLvl.^2;
    
    slope_all = nan(nLoc, nPerf, 2); % 2 stands for two ways of estimating slope and Neq
    Neq_sq_all = slope_all;
    TvC_R2_all = Neq_sq_all;
    TvC_pred_sq_all = nan(nLoc, nPerf, nNoise, 2);
    TvC_pred_sq_1K_all = nan(nLoc, nPerf, 1e3);
    
    for iperf = 1:nPerf
        for iLoc = 1:nLoc
            y_sq = squeeze(PSE_all(iLoc, :, iperf)).^2;
            % way 1: fit LAM
            [est_slope1, est_Neq_sq1, ypred_sq1, Rsquared1] = lam_tvcFit([1 2], x_sq, y_sq);
            ypred_sq_1K = lam_tvc([est_slope1, est_Neq_sq1], x_sq_1K);
            
            % way 2: fit linear regression on squared values
            [coeff, bint, residual, rint, stats] = regress(y_sq',[ones(nNoise,1), x_sq']); % stats: R2, F , p , estimate of the error variance
            itcpt_sq = coeff(1); est_slope2 = coeff(2);
            x_sq_end = x_sq(end); y_sq_end = est_slope2.* x_sq_end + itcpt_sq;
            est_Neq_sq2 = (itcpt_sq/(y_sq_end-itcpt_sq))*x_sq_end;
%             if est_Neq_sq2<=0, pause, error('Neq <=0!!'), end
            Rsquared2 = stats(1);
            ypred_sq2 = y_sq+residual';
%             ypred_sq_1K= est_slope2.* (x_sq_1K + est_Neq_sq2); % x_1K is in unit c^2
            
            % plot
            if flag_quickPlot && (iperf==1)
                quickPlot(x_sq, y_sq, ypred_sq1, ypred_sq2, x_sq_1K, ypred_sq_1K, x1_sq_pseudo)
                title(sprintf('Loc%d thresh=%d%%\n Neq: %.3f // %.3f\n slope:%.3f // %.3f\nR^2: %.2f%% // %.2f%%', ...
                    iLoc, perfPSE_all(iperf), ...
                    est_Neq_sq1, est_Neq_sq2, est_slope1, est_slope2, Rsquared1*100, Rsquared2*100))
            end           
            
            %%% compile
            slope_all(iLoc, iperf, :) = [est_slope1, est_slope2];
            Neq_sq_all(iLoc, iperf, :) = [est_Neq_sq1, est_Neq_sq2];
            TvC_R2_all(iLoc, iperf, :) = [Rsquared1, Rsquared2];
            TvC_pred_sq_all(iLoc, iperf,:, :) = [ypred_sq1', ypred_sq2'];
            TvC_pred_sq_1K_all(iLoc, iperf, :) = ypred_sq_1K;
        end % iLoc
    end % iperf
end

function quickPlot(x_sq, y_sq, ypred_sq1, ypred_sq2, x_sq_1K, ypred_sq_1K, x1_sq_pseudo)
% x1_sq_pseudo = x_sq_1K(1);
x_sq = [x1_sq_pseudo, x_sq(2: end)];

figure('Position', [0 0 1200 600])
subplot(1,2,1), hold on
plot(x_sq, y_sq, 'ko'),
plot(x_sq, ypred_sq1, 'r-'),
plot(x_sq, ypred_sq2, 'b--')
plot(x_sq_1K, ypred_sq_1K, 'k-', 'linewidth', 2)
legend({'data', 'fitted by LAM', 'fitted by regression'})
xlabel('External noise (c^2)')
ylabel('Contrast threshold (c^2)')

subplot(1,2,2), hold on
loglog(x_sq, y_sq, 'ko'),
loglog(x_sq, ypred_sq1, 'r-'),
loglog(x_sq, ypred_sq2, 'b--')
loglog(x_sq_1K, ypred_sq_1K, 'k-', 'linewidth', 2)
set(gca,'Layer','top','XScale','log','YScale','log','Linewidth',3,'Box','off','PlotBoxAspectRatio',[1,1,1],'TickDir','out','TickLength',[1,1]*0.02/max(1,1));
legend({'data', 'fitted by LAM', 'fitted by regression'})
xlabel('External noise (c^2)')
ylabel('Contrast threshold (c^2)')
xlim([x1_sq_pseudo*.9, 10^0])
ylim([10^-4, 10^-1]);
end