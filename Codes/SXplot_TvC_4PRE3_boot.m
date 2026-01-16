clc
% Initialize key parameters
% nNoiseIntp = nIntp; % Number of noise interpolation points
alpha = 0.2; % Transparency for confidence intervals
wd_line = 3; % Line width
sz_marker = 25; % Marker size
wd_bar = .5;
buffer_xAxis = .01; 

if nLoc_s == 3, buffer_statsSpace = .3; else, buffer_statsSpace = 0.1; end

% Prepare for PTM prediction
switch nLoc_s
    case 2, iCond_all = [0, 1];
    case 3, iCond_all = 0:4;
end
%--------------------------------------------------------------------------------%
indParamVary_allCand = fxn_getIndParamIncl(nParams, iCond_all); % Generate all combinations
%--------------------------------------------------------------------------------%

if nLoc_s > 3
    indParamVary = ones(1,nLoc_s);
else
    iCand_groupBest = IndCand_GroupBest_vec(iiIndLoc_s);
    indParamVary = indParamVary_allCand(iCand_groupBest, :); % Current candidate
end

% Initialize containers for results
threshCST_log_allSFLoc = cell(nSF, nLoc_s); % Contrast sensitivity thresholds for each SF and location
threshCST_log_pred_allSFLoc = threshCST_log_allSFLoc; % Predicted thresholds
R2_allSFLoc = threshCST_log_allSFLoc; % R^2 values
estP_allSFLoc = threshCST_log_allSFLoc;

% Loop through spatial frequencies (SF)
for SF_load = SF_load_all
    SF = SF_load; % easy transform, since 51 is out of the picture
    if SF==51, SF=5; end
    %----------%
    fxn_loadSF; % to load noiseSD_xxlog_true
    %----------%
    load(nameFile_fitTvC_allSubj, 'thresh_log*', 'est*', 'R2*')

    % Loop through comb locations within the location group
    for iiLoc = 1:nLoc_s

        % Take median of boostrapped data (thresh, estP and R2) per subj, and store for each SF
        threshCST_log_allSFLoc{SF, iiLoc} = getCI(thresh_log_allB_allSubj(:, indLoc_s(iiLoc), :, iPerf_plot, :), 1, 5); % thresh_log_allB_allSubj: nsubj x nLocComb_max(11) x nNoise x nPerf x nBoot
        R2_allSFLoc{SF, iiLoc} = getCI(R2_BestSimplest_allB_allSubj(:, iiIndLoc_s, iiLoc, iPerf_plot, :), 1, 5); % R2_xx_allB_allSubj: nsubj x nLocGroups x nLoc_max x nPerf x nBoot
        estP_allSFLoc{SF, iiLoc} = getCI(est_BestSimplest_allB_allSubj(:, iiIndLoc_s, iiLoc, :, :), 1, 5); % est_xx_allB_allSubj: nsubj x nLocGroups x nLoc_max x nParams x nBoot

        % Make predictions
        threshEnergy_pred_allSubj = nan(nsubj, nIntp);
        for isubj=1:nsubj
            %------------------------------------------------------------------------------------------%
            threshEnergy_pred_allSubj(isubj, :) = fxn_PTM([0,1,1,1], estP_allSFLoc{SF, iiLoc}(isubj, :), noiseEnergy_intp_true, dprimes(iPerf_plot), SF_fit);
            %------------------------------------------------------------------------------------------%
        end

        threshCST_log_pred_allSFLoc{SF, iiLoc} = log10(sqrt(threshEnergy_pred_allSubj));

    end % iiLoc
end % SF

%% PLOTTING
iiLoc_all = [1];
% iiLoc_all = 1:nLoc_s;

for SF_load = SF_load_all
    figure('Position', [0, 0, 1.2e3, 1e3]); hold on;
    ax = gca;
    ax.YGrid = 'on';
    str_legends = {}; % Initialize legends for the current subplot

    SF=SF_load; SF(SF==51)=5;

    str_loc = sprintf('%s%s', namesCombLoc_s{iiLoc_all});
    threshCST_log_ave_all = nan(nLoc_s, 1);
    for iiLoc = 1:nLoc_s
        
        nameVar = namesCombLoc_s{iiLoc};
        color_ = colors_asym(indLoc_s(iiLoc), :); % Color for location

        if sum(iiLoc == iiLoc_all)==0, color_ = ones(1,3)*.95; end
        % Axis and title
        %----------%
        fxn_loadSF; % to load noiseSD_xxlog_true
        %----------%
        xlabel('External noise SD');
        x_ticks = noiseSD_log_all; x_ticklabels = round(noiseSD_full, 3);
        % x_ticks = [noiseSD_log_all(1), noiseSD_log_full_acrossSF(2:end)]; x_ticklabels = round(noiseSD_full_acrossSF, 3); % defined in fxn_loadSF
        
        xlim([x_ticks(1) - buffer_statsSpace, x_ticks(end) + buffer_statsSpace]); xticks(x_ticks); xticklabels(x_ticklabels); xtickangle(90)
        ylabel('Contrast threshold (%)');
        yticks(cst_log_ticks); yticklabels(round(cst_ln_ticks)); ylim(cst_log_ticks([1, end]));

        % Loop through performance levels
        for iiPerf = 1:length(iPerf_plot)
            iPerf = iPerf_plot(iiPerf);
            switch iiPerf, case 1, lineStyle = '-';  case 2, lineStyle = '--'; end

            % Plot idvd data
            for isubj=1:nsubj
                % plot(noiseSD_log_all + buffer, threshCST_log_allSFLoc{SF_load, iiLoc}(isubj, :), '-', 'Color', color_, 'HandleVisibility', 'off', 'LineWidth', wd_line/3);
                % plot(noiseSD_log_all(1) + buffer, threshCST_log_allSFLoc{SF_load, iiLoc}(isubj, 1), markers_allSubj{isubj} , 'Color', color_, 'HandleVisibility', 'off', 'LineWidth', wd_line/2, 'markersize', sz_marker/2, 'markerfacecolor', 'w');
                % pause(.5)
            end

            % Calculate group averages and SEM
            [threshCST_log_ave, ~, ~, threshCST_log_SEM] = getCI(threshCST_log_allSFLoc{SF_load, iiLoc}, 2, 1);
            [threshCST_log_pred_ave, ~, ~, threshCST_log_pred_SEM] = getCI(threshCST_log_pred_allSFLoc{SF_load, iiLoc}, 2, 1);
            [R2_ave, ~, ~, R2_sem] = getCI(R2_allSFLoc{SF_load, iiLoc}, 2, 1);
            threshCST_log_ave_all(iiLoc)=threshCST_log_ave(1);
            % Plot the fitted line
            plot(noiseSD_intp_log_true, threshCST_log_pred_ave, lineStyle, 'Color', color_, 'HandleVisibility', 'off', 'LineWidth', wd_line);

            % Plot confidence intervals
            patch([noiseSD_intp_log_true, flip(noiseSD_intp_log_true)], [threshCST_log_pred_ave - threshCST_log_pred_SEM, flip(threshCST_log_pred_ave + threshCST_log_pred_SEM)], ...
                color_, 'FaceAlpha', alpha, 'LineStyle', 'none', 'HandleVisibility', 'off');

            % Plot SEM as error bars
            errorbar(noiseSD_log_all + buffer_xAxis, threshCST_log_ave, threshCST_log_SEM, '.', 'Color', color_, 'CapSize', 0, 'HandleVisibility', 'off', 'LineWidth', wd_line);

            % Plot group average with markers
            markerStyle = shapes_SF{SF-3};

            plot(noiseSD_log_all + buffer_xAxis, threshCST_log_ave, markerStyle, 'Color', color_, 'MarkerFaceColor', color_, 'MarkerEdgeColor', 'w', 'MarkerSize', sz_marker, 'LineWidth', wd_line);

            % Add R^2 values to legend
            % str_legends = [str_legends, sprintf('%s %d%% (R^2=%.2f±%.2f)', nameVar, perfThresh_all(iPerf_plot(iiPerf)), R2_ave, R2_sem)];
            % str_legends = [str_legends, sprintf('%s (R^2=%.2f±%.2f)', nameVar, R2_ave, R2_sem)];
            str_legends = [str_legends, sprintf('%.2f', R2_ave)];

        end % iiPerf
    end % iiLoc

    % draw comparison line for comparing thresholds/performance (vertical)

    buffer_statsLine = .02;
    if nLoc_s == 3 % 3 loc, 2 lines
        x_line1 = x_ticks(1) - buffer_statsSpace/1.8;
        x_line2 = x_ticks(1) - buffer_statsSpace/4;

        yline1_lb = threshCST_log_ave_all(1);
        yline1_ub = threshCST_log_ave_all(3);
        yline2_lb = threshCST_log_ave_all(2)+buffer_statsLine;
        yline2_ub = threshCST_log_ave_all(3)-buffer_statsLine;
        yline3_lb = threshCST_log_ave_all(1)+buffer_statsLine;
        yline3_ub = threshCST_log_ave_all(2)-buffer_statsLine;
        plot([x_line1, x_line1], [yline1_lb, yline1_ub], 'k-')
        plot([x_line2, x_line2], [yline2_lb, yline2_ub], 'k-')
        plot([x_line2, x_line2], [yline3_lb, yline3_ub], 'k-')
    % elseif nLoc_s==2
    %     x_line = x_ticks(1) - space4PerfComp/4;
    %     yline1_lb = threshCST_log_ave_all(1);
    %     yline1_ub = threshCST_log_ave_all(2);
    %     plot([x_line, x_line], [yline1_lb, yline1_ub], 'k-')
    end

    set(findall(gcf, '-property', 'fontsize'), 'fontsize', 40*scaling);
    title(sprintf('SF%d (n=%d) (nBoot=%d) [%s]\n', SF, nsubj, nBoot, str_loc), 'fontsize', 20*scaling);
    % Add legends (smaller font)
    lgd=legend(str_legends, 'Orientation', 'horizontal', 'NumColumns', length(iPerf_plot), 'Location', 'southeast', 'fontsize', 35*scaling);
    set(lgd, 'Box', 'off');  % ✅ removes the border
    title(lgd, 'Ave. R^2', 'FontSize', 30 * scaling);
    set(findall(gcf, '-property', 'linewidth'), 'linewidth',3*scaling)
    % Save figure
    nameFolder_fig_TvCperSF = sprintf('%s/TvCperSF', nameFolder_fig_PF);
    if isempty(dir(nameFolder_fig_TvCperSF)), mkdir(nameFolder_fig_TvCperSF), end
    saveas(gcf, sprintf('%s/TvC_SF%d_nBoot%d_%s.jpg', nameFolder_fig_TvCperSF, SF, nBoot, str_loc));

    % close all

end % SF_load

close all

