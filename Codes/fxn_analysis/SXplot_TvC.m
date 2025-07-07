% Initialize key parameters
iPerf_plot = [1,3]; % Performance levels to plot
iPerf_plot = [2]; % Performance levels to plot
nNoiseIntp = nIntp; % Number of noise interpolation points
alpha = 0.2; % Transparency for confidence intervals
wd_line = 1.5; % Line width
sz_marker = 15; % Marker size

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

%%%%%%%%
%% PLOTTING
%%%%%%%%
figure('Position', [0, 0, 2e3, 2e3]);
isubplot = 1; % Initialize subplot counter

for iSubplotRow = 1:2
    % Determine the variables for rows and columns in the subplots
    switch iSubplotRow
        case 1
            Var1_all = SF_load_all; % Row 1: All locations for one SF
            Var2_all = 1:nLoc_s;
        case 2
            Var1_all = 1:nLoc_s; % Row 2: All SFs for one location
            Var2_all = SF_load_all;
    end
    
    % Iterate over Var1 (SF or location depending on the row)
    for Var1 = Var1_all
        str_legends = {}; % Initialize legends for the current subplot
        
        % Set up subplot
        subplot(2, nSF, isubplot); hold on; grid on;
        
        switch iSubplotRow
            case 1, title(sprintf('SF%d (n=%d)', Var1, nsubj));
            case 2, title(namesCombLoc_s(Var1));
        end
        
        % Iterate over Var2 (locations or SFs)
        for Var2 = Var2_all
            % Load relevant data based on subplot row
            switch iSubplotRow
                case 1
                    SF_load = Var1;
                    iiLoc = Var2;
                    nameVar = namesCombLoc_s{Var2};
                    color_ = colors_asym(indLoc_s(Var2), :); % Color for location
                case 2
                    SF_load = Var2;
                    iiLoc = Var1;
                    nameVar = namesSF{Var2==SF_load_all};
                    color_ = colors_asym(indLoc_s(Var1), :); % Color for SF
            end
            
            % Axis and title
            %----------%
            fxn_loadSF; % to load noiseSD_xxlog_true
            %----------%
            xlabel('External noise SD');
            x_ticks = noiseSD_log_all; x_ticklabels = round(noiseSD_full, 3); xlim([x_ticks(1) - 0.1, x_ticks(end) + 0.1]); xticks(x_ticks); xticklabels(x_ticklabels);, xtickangle(90)
            
            ylabel('Contrast threshold');
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
                switch iSubplotRow
                    case 1, markerStyle = markers_allSF{Var1==SF_load_all};
                    case 2, markerStyle = markers_allSF{Var2==SF_load_all};
                end
                plot(noiseSD_log_all + buffer, threshCST_log_ave, markerStyle, 'Color', color_, 'MarkerFaceColor', color_, 'MarkerEdgeColor', 'w', 'MarkerSize', sz_marker, 'LineWidth', wd_line);
                yline(log(1), '--k');
                % Add R^2 values to legend
                str_legends = [str_legends, sprintf('%s %d%% (R^2=%.2f±%.2f)', nameVar, perfThresh_all(iPerf_plot(iiPerf)), R2_ave, R2_sem)];
            end % iiPerf
        end % Var2
        
        isubplot = isubplot + 1;
        legend(str_legends, 'Orientation', 'horizontal', 'NumColumns', length(iPerf_plot), 'Location', 'best');
    end % Var1
end % iSubplotRpw

% Add overall title
sgtitle(sprintf('[%s] %s (Error type: %s)', str_sgtitle, str_LocSelected, namesErrorType{iErrorType}));
set(findall(gcf, '-property', 'fontsize'), 'fontsize', 12);

% Save figure
saveas(gcf, sprintf('%s/TvC.jpg', nameFolder_fig));

close all
