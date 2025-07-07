
%                           Gamma,                          Nadd_log,                       Gain
y_limit_allParam = {[lb_PTM(2), ub_PTM(2)], [lb_PTM(3), ub_PTM(3)], [lb_PTM(4), ub_PTM(4)]};

for iParam = iParams_all
    iCol = iParam+4;
    paramName = dataTable.Properties.VariableNames{iCol};
    paramData = dataTable{:, iCol};

    % Initialize Variables
    y_limit = y_limit_allParam{iParam};
    y_ticks = linspace(y_limit(1), y_limit(end), 6);
    y_label = paramName;
    wd_bar = 0.35;  % Width of bars for visualization
    x_allBars = nan(nSF, nLoc_s);  % Initialize bar positions for spatial frequency (SF) and location (Loc)
    x_allBars_allSubj = cell(nSF, nLoc_s);  % Store x positions for each subject
    data_allBars_allSubj = cell(nSF, nLoc_s);  % Store data values for each subject

    % Compute Bar Positions and Organize Data
    for iiSF = 1:nSF
        % Define x positions for bars with small offsets
        x_allBars(iiSF, :) = linspace(-wd_bar, wd_bar, nLoc_s) + iiSF;

        for iiLoc = 1:nLoc_s
            % Find indices for current spatial frequency and location
            indANOVA = (dataTable.LocComb == indLoc_s(iiLoc) & dataTable.SF == SF_load_all(iiSF));

            % Extract parameter data for selected indices
            data_allBars_allSubj{iiSF, iiLoc} = paramData(indANOVA);

            % Introduce slight jitter for x positions to avoid overlap in plots
            x_allBars_allSubj{iiSF, iiLoc} = x_allBars(iiSF, iiLoc) + randn(size(data_allBars_allSubj{iiSF, iiLoc})) / 50;
        end
    end

    % Configure Figure Properties
    sz_marker = 40;  % Marker size for scatter plots
    figure('Position', [0, 0, 1000, 1000]); hold on;% grid on;
    ylabel(y_label);
    title(sprintf('%s %s', str_LocSelected, y_label));

    % Set y-axis ticks and labels
    yticks(y_ticks(1:end-1));
    yticklabels(y_ticks(1:end-1));
    ylim(y_ticks([1, end]));

    % Set x-axis limits and remove ticks
    xticks('');
    xlabel('');
    buffer = 0.5;
    xlim([min(x_allBars(:))-buffer, max(x_allBars(:))+buffer]);

    % Loop Through Spatial Frequencies
    for SF_load = SF_load_all

        % Load necessary parameters for the current SF
        %------------
        fxn_loadSF; % This loads noiseSD_xxlog_true (external function call)
        %------------
        iiSF = find(SF_load == SF_load_all);
        SF = SF_load; SF(SF == 51) = 5; % Adjust SF value for specific cases
        marker_style = markers_allSF{SF-3}; % Define marker style based on SF

        % Plot Individual Subject Data Across Locations
        for isubj = 1:nsubj
            if nLoc_s == 2
                % Connect data points for two locations
                plot([x_allBars_allSubj{iiSF, 1}(isubj), x_allBars_allSubj{iiSF, 2}(isubj)], ...
                    [data_allBars_allSubj{iiSF, 1}(isubj), data_allBars_allSubj{iiSF, 2}(isubj)], ...
                    '-', 'color', ones(1,3) * 0.8); % Light gray lines
            else
                % Connect data points for three locations
                plot([x_allBars_allSubj{iiSF, 1}(isubj), x_allBars_allSubj{iiSF, 2}(isubj), x_allBars_allSubj{iiSF, 3}(isubj)], ...
                    [data_allBars_allSubj{iiSF, 1}(isubj), data_allBars_allSubj{iiSF, 2}(isubj), data_allBars_allSubj{iiSF, 3}(isubj)], ...
                    '-', 'color', ones(1,3) * 0.8);
            end
        end

        % Plot Error Bars for Differences Between Locations
        y_errDiff = mean([y_ticks(end), y_ticks(end-1)]); % Position for error bar
        errDiff = withinSubjErr([data_allBars_allSubj{iiSF, 1}, data_allBars_allSubj{iiSF, 2}]);
        if nLoc_s == 2
            plot(x_allBars(iiSF, :), [y_errDiff, y_errDiff], 'k-');
            errorbar(mean(x_allBars(iiSF, :)), y_errDiff, errDiff, '.k', 'CapSize', 0);
        end

        % Plot Individual Data and Group Statistics
        for iiLoc = 1:nLoc_s
            nameVar = namesCombLoc_s{iiLoc};
            color_ = colors_asym(indLoc_s(iiLoc), :); % Define color based on location
            % if sum(iiLoc == iiLoc_all) == 0, color_ = ones(1,3) * 0.9; end

            % Extract individual data for current condition
            dataIdvd = data_allBars_allSubj{iiSF, iiLoc};

            % Scatter individual data points with small x-jitter
            x = x_allBars_allSubj{iiSF, iiLoc};
            scatter(x, dataIdvd, 'o', 'MarkerFaceColor', ones(1, 3) / 2, 'MarkerEdgeColor', 'w', 'MarkerFaceAlpha', 0.5);

            % Compute group statistics (median and confidence intervals)
            [ave, ~, ~, sem] = getCI(dataIdvd, 2, 1);

            % Plot group median as a marker
            plot(x_allBars(iiSF, iiLoc), ave, marker_style, 'MarkerFaceColor', 'w', 'MarkerEdgeColor', color_, 'LineWidth', 2, 'MarkerSize', sz_marker);

            % Add error bars for confidence intervals
            errorbar(x_allBars(iiSF, iiLoc), ave, sem, '.', 'Color', color_, 'CapSize', 0, 'LineWidth', 2);
        end % iiLoc
    end % SF_load

    % Formatting Enhancements
    set(findall(gcf, '-property', 'linewidth'), 'linewidth', 3);
    set(findall(gcf, '-property', 'fontsize'), 'fontsize', 40);

    % Save Figure
    saveas(gcf, sprintf('%s/LocxSF_%s.jpg', nameFolder_fig, paramName));
    close all
end % iParam
