
% fix this code by sorting the GoF first then show part of the model
clc
R2_criterion=.8;
nCand_show = 10; if nCand_show>=nCand, nCand_show=nCand; end
indParamExist_PTM = [0,1,1,1];

iCand_all = 1:nCand; % iCand_s = iCand_s(ind_s);
RSS_varyLocMC_allCand = squeeze(RSS_varyLocMC_allLoc(iiIndLoc_s, iCand_all, 1:nLoc_s, :));
RSS_varyLocMC_allCand = mean(RSS_varyLocMC_allCand, [2,3]);
nData_varyLocMC_allCand = nData_varyLocMC_allLoc(iiIndLoc_s, iCand_all);
nParams_varyLocMC_allCand = nParams_varyLocMC_allLoc(iiIndLoc_s, iCand_all);
R2_varyLocMC_allCand = squeeze(R2_varyLocMC_allLoc(iiIndLoc_s, iCand_all, 1:nLoc_s, :));
R2_varyLocMC_allCand = mean(R2_varyLocMC_allCand, [2,3]);
est_varyLocMC_allCand = squeeze(est_varyLocMC_allLoc(iiIndLoc_s, iCand_all, 1:nLoc_s, :));

AIC_varyLocMC_allCand = fxn_getAIC(RSS_varyLocMC_allCand', nData_varyLocMC_allCand, nParams_varyLocMC_allCand);
AICc_varyLocMC_allCand = fxn_getAICc(RSS_varyLocMC_allCand', nData_varyLocMC_allCand, nParams_varyLocMC_allCand);
BIC_varyLocMC_allCand = fxn_getBIC(RSS_varyLocMC_allCand', nData_varyLocMC_allCand, nParams_varyLocMC_allCand);

% Calculate delta ICs
AIC_varyLocMC_allCand = AIC_varyLocMC_allCand-min(AIC_varyLocMC_allCand);
AICc_varyLocMC_allCand = AICc_varyLocMC_allCand-min(AICc_varyLocMC_allCand);
BIC_varyLocMC_allCand = BIC_varyLocMC_allCand-min(BIC_varyLocMC_allCand);

GoF_allCand = {R2_varyLocMC_allCand, AIC_varyLocMC_allCand, AICc_varyLocMC_allCand, BIC_varyLocMC_allCand};
[R2_s, iOrder_R2] = sort(R2_varyLocMC_allCand, 'descend');
[AIC_s, iOrder_AIC] = sort(AIC_varyLocMC_allCand, 'ascend');
[AICs_s, iOrder_AICc] = sort(AICc_varyLocMC_allCand, 'ascend');
[BIC_s, iOrder_BIC] = sort(BIC_varyLocMC_allCand, 'ascend');

iOrder_allGoF = {iOrder_R2, iOrder_AIC, iOrder_AICc, iOrder_BIC};

nGoF = length(iGoF_select);

for iiGoF = 1:nGoF
    iGoF = iGoF_select(iiGoF);

    iOrder = iOrder_allGoF{iGoF}(1:nCand_show);
    iCand_opt = iOrder(1);
    indParamVary_opt = indParamVary_allCand(iCand_opt, :);
    params_est_opt = squeeze(est_varyLocMC_allCand(iCand_opt, :, :)); % nLoc_s x nParams

    if iGoF==1, str_delta=''; else, str_delta='Delta'; end
    figure('Position', [0, 0, nLoc_s*300, 1e3]);

    %% Plot sorted GoF
    subplot(nErrorType+1, nLoc_s, 1:nLoc_s), hold on
    bar(GoF_allCand{iGoF}(iOrder))
    if iGoF==1, ylim([0, 1]), yline(R2_criterion, 'k--', 'linewidth', 2);
    else, %ylim([0, 500])%ylim([-100, 150])
    end
    xticks(1:nCand_show)
    x_ticklabels = cell(1, nCand_show); for iiCand=1:nCand_show, x_ticklabels{iiCand} = sprintf('#%d [%s]', iOrder(iiCand), num2str(indParamVary_allCand(iOrder(iiCand), :))); end
    xticklabels(x_ticklabels)
    xtickangle(90)
    ylabel(sprintf('%s %s', str_delta, namesGoF{iGoF}))

    %% plot data & pred of the best model of the current GoF
    % predicted TvCs
    switch iTvCModel
        case 1 % LAM
            threshEnergy_intp_pred = nan(nLoc_s, nIntp, nPerf);
            for iPerf=1:nPerf
                %--------------------------------------------------------------------------------%
                % threshEnergy_pred_ = fxn_predTvC_varyLocMC(iTvCModel, indParamVary_opt, dprimes, SF_fit, noiseEnergy_intp_true, nLoc_s);
                threshEnergy_pred_ = fxn_predTvC_varyLocMC(iTvCModel, indParamVary_opt, dprimes, SF_fit, noiseEnergy_intp_true, params_est_opt, nLoc_s);
                %--------------------------------------------------------------------------------%
                threshEnergy_intp_pred(:, :, iPerf) = reshape(threshEnergy_pred_, [nLoc_s, nIntp]);
            end % iPerf

        case 2 % PTM
            threshEnergy_intp_pred = nan(nLoc_s, nIntp, nPerf);
            for iiLoc = 1:nLoc_s
                for iPerf=1:nPerf
                    %--------------------------------------------------------------------------------%
                    threshEnergy_intp_pred(iiLoc, :, iPerf) = fxn_PTM(indParamExist_PTM, params_est_opt(iiLoc, :), noiseEnergy_intp_true, dprimes(iPerf), SF_fit);
                    %--------------------------------------------------------------------------------%
                end
            end
    end

    for iiLoc = 1:nLoc_s
        R2_allPerf = squeeze(R2_varyLocMC_allLoc(iiIndLoc_s, iCand_opt, iiLoc, :));
        %%% Linear energy %%%
        subplot(nErrorType+1, nLoc_s, iiLoc + nLoc_s), hold on, grid on
        plot((10.^noiseSD_log_all).^2, squeeze(threshEnergy(indLoc_s(iiLoc), :, :)), '--ko')
        plot(noiseEnergy_intp_true, squeeze(threshEnergy_intp_pred(iiLoc, :, :)), 'b-')
        xlabel('Noise Energy'), ylabel('Thresh Energy')

        % Add title
        switch iTvCModel
            case 1, params = squeeze(params_est_opt(iiLoc, :, :));
                str_params = [];
                for iPerf=1:nPerf
                    str_params = [str_params, sprintf('Perf Level %d%%: [%s]\n', perfThresh_all(iPerf), num2str(round(params(:, iPerf)', 3)))];
                end
            case 2, params = params_est_opt(iiLoc, :); str_params = sprintf('Est Params: [%s]', num2str(round(params, 3)));
        end
        title(sprintf('[%s] R2 of each perf=%.3f %.3f %.3f\n%s', namesCombLoc_s{iiLoc}, R2_allPerf, str_params))

        %%% Linear contrast %%%
        subplot(nErrorType+1, nLoc_s, iiLoc + nLoc_s*2), hold on, grid on
        plot(10.^noiseSD_log_all, sqrt(squeeze(threshEnergy(indLoc_s(iiLoc), :, :))), '--ko')
        plot(sqrt(noiseEnergy_intp_true), sqrt(squeeze(threshEnergy_intp_pred(iiLoc, :, :))), 'b-')
        xlabel('Noise SD (linear scale)'), ylabel('Thresh SD (ln scale)')

        %%% Log contrast %%%
        subplot(nErrorType+1, nLoc_s, iiLoc+ nLoc_s*3), hold on, grid on
        plot(noiseSD_log_all, log10(sqrt(squeeze(threshEnergy(indLoc_s(iiLoc), :, :)))), '--ko')
        plot(noiseSD_intp_log_true, log10(sqrt(squeeze(threshEnergy_intp_pred(iiLoc, :, :)))), 'b-')
        xlabel('Noise SD (log scale)'), ylabel('Thresh SD (log scale)')
    end % iiLoc

    sgtitle(sprintf('[%s] %s (%s-%s) (%d/%d models)\nBased on %s: M#%d [%s] R^2=%.3f', ...
        subjName, str_LocSelected, namesTvCModel{iTvCModel}, namesErrorType{iErrorType}, nCand_show, nCand, ...
        namesGoF{iGoF}, iCand_opt, num2str(indParamVary_opt), R2_varyLocMC_allCand(iCand_opt)))
    %     set(findall(gcf, '-property', 'fontsize'), 'fontsize',15)
    %     set(findall(gcf, '-property', 'linewidth'), 'linewidth',1.2)

    nameFolder_fig = sprintf('Fig/acrossSFs/SF456/VaryLocMC_%s/MCrunning/%s_SF%d', namesTvCModel{iTvCModel}, subjName, SF);
    if isempty(dir(nameFolder_fig)), mkdir(nameFolder_fig); end
    saveas(gcf, sprintf('%s/%s_%s.jpg', nameFolder_fig, str_LocSelected, namesGoF{iGoF}));
end % iGoF

