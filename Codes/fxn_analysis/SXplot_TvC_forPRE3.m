% Initialize key parameters
iPerf_plot = 2; % Performance levels to plot
nNoiseIntp = nIntp; % Number of noise interpolation points
alpha = 0.2; % Transparency for confidence intervals
wd_line = 1.5; % Line width
sz_marker = 25; % Marker size
wd_bar = .5; buffer = .01;

% Initialize containers for results
threshCST_log_allSFLoc = cell(nSF, nLoc_s); % Contrast sensitivity thresholds for each SF and location
threshCST_log_pred_allSFLoc = threshCST_log_allSFLoc; % Predicted thresholds
R2_allSFLoc = threshCST_log_allSFLoc; % R^2 values

% Loop through spatial frequencies (SF)
for SF = SF_load_all
    for iiLoc = 1:nLoc_s % Loop through locations

        % Store observed thresholds for each location and SF
        threshCST_log_allSubj = squeeze(threshCST_log_allSF{SF}(:, iiLoc, :, :));
        threshCST_log_allSFLoc{SF, iiLoc} = threshCST_log_allSubj;

        % Select predictions and R2  for each location and SF
        switch iTvCModel
            case 1
                threshCST_log_pred_allSubj = log10(sqrt(threshEnergy_pred_allSF{SF}));
                R2_allSubj = R2_allSF{SF};
            case 2
                threshCST_log_pred_allSubj = log10(sqrt(threshEnergy_pred_allSF{SF}));
                R2_allSubj = R2_allSF{SF};
        end
        threshCST_log_pred_allSFLoc{SF, iiLoc} = squeeze(threshCST_log_pred_allSubj(:, iiLoc, :, :));
        R2_allSFLoc{SF, iiLoc} = squeeze(R2_allSubj(:, iiLoc, :));
    end % iiLoc
end % SF

%% PLOTTING
iiLoc_all = [1,3];
iiLoc_all = 1:nLoc_s;

for SF_load = SF_load_all
    figure('Position', [0, 0, 1.2e3, 1e3]); hold on; grid on;
    str_legends = {}; % Initialize legends for the current subplot

    SF=SF_load; SF(SF==51)=5;

    str_loc = sprintf('%s%s', namesCombLoc_s{iiLoc_all});
    
    for iiLoc = 1:nLoc_s
        nameVar = namesCombLoc_s{iiLoc};
        color_ = colors_asym(indLoc_s(iiLoc), :); % Color for location

        if sum(iiLoc == iiLoc_all)==0, color_ = ones(1,3)*.95; end
        % Axis and title
        %----------%
        fxn_loadSF; % to load noiseSD_xxlog_true
        %----------%
        xlabel('External noise SD');
        % x_ticks = noiseSD_log_all; x_ticklabels = round(noiseSD_full, 3);
        x_ticks = [noiseSD_log_all(1), noiseSD_log_full_acrossSF(2:end)]; x_ticklabels = round(noiseSD_full_acrossSF, 3); % defined in fxn_loadSF
        xlim([x_ticks(1) - 0.1, x_ticks(end) + 0.1]); xticks(x_ticks); xticklabels(x_ticklabels);, xtickangle(90)

        ylabel('Contrast threshold (%)');
        yticks(cst_log_ticks); yticklabels(round(cst_ln_ticks)); ylim(cst_log_ticks([1, end]));

        % Loop through performance levels
        for iiPerf = 1:length(iPerf_plot)
            iPerf = iPerf_plot(iiPerf);
            switch iiPerf, case 1, lineStyle = '-';  case 2, lineStyle = '--'; end

            % Extract thresholds and R^2 values
            threshCST_log_allSubj = threshCST_log_allSFLoc{SF_load, iiLoc}(:, :, iPerf);
            threshCST_log_pred_allSubj = threshCST_log_pred_allSFLoc{SF_load, iiLoc}(:, :, iPerf);
            R2_allSubj = R2_allSFLoc{SF_load, iiLoc}(:, iPerf);
            % Set negative R^2 values to 0
            R2_allSubj(R2_allSubj < 0) = 0;

            % Calculate group averages and SEM
            [threshCST_log_ave, ~, ~, threshCST_log_SEM] = getCI(threshCST_log_allSubj, 2, 1);
            [threshCST_log_pred_ave, ~, ~, threshCST_log_pred_SEM] = getCI(threshCST_log_pred_allSubj, 2, 1);
            [R2_ave, ~, ~, R2_sem] = getCI(R2_allSubj, 2, 1);

            % Plot the fitted line
            plot(noiseSD_intp_log_true, threshCST_log_pred_ave, lineStyle, 'Color', color_, 'HandleVisibility', 'off', 'LineWidth', wd_line);

            % Plot confidence intervals
            patch([noiseSD_intp_log_true, flip(noiseSD_intp_log_true)], [threshCST_log_pred_ave - threshCST_log_pred_SEM, flip(threshCST_log_pred_ave + threshCST_log_pred_SEM)], ...
                color_, 'FaceAlpha', alpha, 'LineStyle', 'none', 'HandleVisibility', 'off');

            % Plot SEM as error bars
            errorbar(noiseSD_log_all + buffer, threshCST_log_ave, threshCST_log_SEM, '.', 'Color', color_, 'CapSize', 0, 'HandleVisibility', 'off', 'LineWidth', wd_line);

            % Plot group average with markers
            markerStyle = markers_allSF{SF_load==SF_load_all};

            plot(noiseSD_log_all + buffer, threshCST_log_ave, markerStyle, 'Color', color_, 'MarkerFaceColor', color_, 'MarkerEdgeColor', 'w', 'MarkerSize', sz_marker, 'LineWidth', wd_line);

            % Add R^2 values to legend
            str_legends = [str_legends, sprintf('%s %d%% (R^2=%.2f±%.2f)', nameVar, perfThresh_all(iPerf_plot(iiPerf)), R2_ave, R2_sem)];
        end % iiPerf
    end % iiLoc

    set(findall(gcf, '-property', 'fontsize'), 'fontsize', 30);
    title(sprintf('SF%d (n=%d) [%s]\n', SF, nsubj, str_loc), 'fontsize', 20);
    % Add legends (smaller font)
    % legend(str_legends, 'Orientation', 'horizontal', 'NumColumns', length(iPerf_plot), 'Location', 'best', 'fontsize', 30);

    % Save figure
    nameFolder_fig_TvCperSF = sprintf('%s/TvCperSF', nameFolder_fig);
    if isempty(dir(nameFolder_fig_TvCperSF)), mkdir(nameFolder_fig_TvCperSF), end
    saveas(gcf, sprintf('%s/TvC_SF%d_%s.jpg', nameFolder_fig_TvCperSF, SF, str_loc));

    close all

end % SF_load



