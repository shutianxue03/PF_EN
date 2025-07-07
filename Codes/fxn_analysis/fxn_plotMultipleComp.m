function fxn_plotMultipleComp(stats, namesIV, IV_unik, dataIdvd_allGroups, names_allGroups, y_label, flag_multComp)
% Function to visualize results of multiple comparisons with group statistics
%
% Parameters:
% stats                - Statistics object (e.g., ANOVA output)
% namesIV              - Names of independent variables
% IV_unik              - Unique levels of each independent variable (cell array)
% dataIdvd_allGroups   - Individual data for all groups (cell array)
% names_allGroups      - Names of all groups (cell array of strings)
% y_label              - Label for the y-axis in the plots

wd_bar = 0.2;            % Width of bars in the grouped plots
nSubplots = 3;           % Number of subplots
nIVs = length(namesIV);  % Number of independent variables
nGroups = length(dataIdvd_allGroups); % Total number of groups
color_lineMultComp = 'k';

% Handle case with 2 independent variables
if nIVs == 2
    nGroups1 = length(IV_unik{1}); % Number of levels for first IV
    nGroups2 = length(IV_unik{2}); % Number of levels for second IV
end

%% Conduct and string-format multiple comparison results
%----------------------------------------------------------------------
[output, ~, ~, GroupNames] = multcompare(stats, 'Dimension', 1:nIVs, 'ctype', 'bonferroni', 'Display', 'off');
%----------------------------------------------------------------------
% Ensure group names match the external organization of data
% assert(sum(strcmp(GroupNames, names_allGroups)) == nGroups, 'ERROR: GroupNames does not match how data was organized outside');

% Initialize string to store significant multiple comparison results
str_mc = '';
nComp = size(output, 1); % Number of comparisons in the output
sig_thresh = 0.05;         % Significance threshold for comparisons

% Process and format results of significant comparisons
for iRow = 1:nComp
    if output(iRow, end) < sig_thresh % Check if the comparison is significant
        % Determine comparison direction based on mean difference
        str_compSign = '>';
        if output(iRow, 3) <= 0, str_compSign = '<'; end
        % Append formatted result to the string
        str_mc = sprintf('%s\n  [%s] %s [%s] (p=%.3f)', ...
            str_mc, GroupNames{output(iRow, 1)}, str_compSign, ...
            GroupNames{output(iRow, 2)}, output(iRow, end));
    end
end

%% Visualization of multiple comparisons
figure('Position', [100, 100, nGroups * 200, 800]); % Create figure with dynamic width based on groups

%% Bar/disc plot with error bars
subplot(nSubplots, 1, 2:nSubplots); hold on; grid on; % Create subplot for bar plot

% Initialize group settings for colors and markers
color_allG = zeros(nGroups, 3); % Placeholder for group colors
marker_allG = repmat({'o'}, 1, nGroups); % Default marker for groups

% Determine bar positions based on number of independent variables
iMapping = [];
switch nIVs
    case 1
        indGroups = 1:nGroups; % Single IV: indices are group positions
        x_allBars = indGroups; % Bar positions for single IV
    case 2
        x_allBars = []; % Initialize bar positions for two IVs
        indGroups = nan(nGroups, nIVs); % Placeholder for group indices
        i = 1;
        for iBar2 = 1:nGroups2 % Loop over levels of the second IV
            for iBar1 = 1:nGroups1 % Loop over levels of the first IV
                %                 iMapping = [iMapping; iBar1, iBar2];
                indGroups(i, :) = [iBar1; iBar2]; % Assign group indices
                i = i + 1;
            end
            % Adjust bar positions for two IVs based on number of levels
            x_allBars = [x_allBars, linspace(-wd_bar, wd_bar, nGroups1) + iBar2];%[x_allBars, iBar2 - wd_bar, iBar2 + wd_bar];
        end
end
assert(~isempty(x_allBars), 'ERROR: x_allBars is empty!')

%% Create the x values of idvd dots
x_allBars_allSubj = cell(1, nGroups);
for iGroup = 1:nGroups
    x = x_allBars(iGroup) + randn(size(dataIdvd_allGroups{iGroup})) / 50;
    x_allBars_allSubj{iGroup} = x;
end

%% Plot lines connecting idvd data
try cell2mat(x_allBars_allSubj);
    nData = length(x_allBars_allSubj{1});
    x_allBars_allSubj_mat = cell2mat(x_allBars_allSubj);
    dataIdvd_allGroups_mat = cell2mat(dataIdvd_allGroups);
    for iData=1:nData
        plot(x_allBars_allSubj_mat(iData, :), dataIdvd_allGroups_mat(iData,:), '-', 'color', ones(1,3)*.8)
    end
catch
end

%% Plot individual data (circles) and group statistics
x_ticklabels = cell(1, nGroups);
for iGroup = 1:nGroups

    % Extract individual data for the group
    dataIdvd = dataIdvd_allGroups{iGroup};

    % Scatter individual data points with small random x-offset for visibility
    x = x_allBars_allSubj{iGroup};
    scatter(x, dataIdvd, 'o', 'MarkerFaceColor', ones(1, 3) / 2, 'MarkerEdgeColor', 'w', 'MarkerFaceAlpha', 0.5);

    % Calculate group statistics (median and confidence intervals)
    [ave, ~, ~, sem] = getCI(dataIdvd, 2, 1);

    % Plot group median as a marker
    plot(x_allBars(iGroup), ave, marker_allG{iGroup}, 'MarkerFaceColor', 'w', 'MarkerEdgeColor', color_allG(iGroup, :), 'LineWidth', 2, 'MarkerSize', 15);

    % Add error bars for confidence intervals
    errorbar(x_allBars(iGroup), ave, sem, '.', 'Color', color_allG(iGroup, :), 'CapSize', 0, 'LineWidth', 2);

    % Create x label for the current group: group name + number of data
    nData = length(dataIdvd);
    x_ticklabels{iGroup} = sprintf('%s(n=%d)', GroupNames{iGroup}, nData);
end % End group loop

%% Customize axis and labels
xlabel('');
xticks(x_allBars);
xticklabels(x_ticklabels);
xtickangle(30); % Rotate x-axis labels for readability
xlim([min(x_allBars) - 0.5, max(x_allBars) + 0.5]); % Set x-axis limits

ylabel(y_label);

%% Plot multiple comparison results
if nGroups<=15
subplot(nSubplots, 1, 1); hold on; grid on; % Create subplot for significant pairs
end

for iComp = 1:nComp
    group1 = output(iComp, 1); % First group index
    group2 = output(iComp, 2); % Second group index
    x1 = x_allBars(group1); % Bar position for group 1
    x2 = x_allBars(group2); % Bar position for group 2
    mean_diff = output(iComp, 4);

    switch flag_multComp
        case 'MatlabFxn' % just use the output multcompare function
            p_value = output(iComp, end); % P-value for the comparison
        case 'Manual' % manually conduct multiple comparison so that test type can be controlled
            data1 = dataIdvd_allGroups{group1};
            data2 = dataIdvd_allGroups{group2};
            % [p_value_W, ~, stats] = signrank(data1, data2); % Wilcoxon signed rank test, which does not accept different sample sizes
            [~, p_value_t, ~, stats] = ttest2(data1, data2); % t-test
            p_value = p_value_t * nComp;
    end

    if p_value<.05
        % print posthoc comparison in the command window
        % fprintf('   [%s] %s [%s] (p=%.3f)\n', GroupNames{group1}, str_compSign, GroupNames{group2}, p_value);
        
        if nGroups<=15
            % Annotate significant pair with scatter plot and line
            scatter([x1, x2], [mean_diff, mean_diff], 10, 'filled', 'MarkerFaceColor', 'k');
            plot([x1, x2], [mean_diff, mean_diff], '-', 'color', color_lineMultComp, 'LineWidth', 1.5);
            % Determine and annotate comparison direction and p-value
            if mean_diff > 0, str_compSign = '>'; else, str_compSign = '<'; end
            text(x1 - sum(x_allBars) / 50, mean_diff, sprintf('%s (p=%.3f)', str_compSign, p_value), 'HorizontalAlignment', 'center');
        end
    end
end % iComp

% Configure x-axis and labels for comparison plot
xticks(x_allBars);
xticklabels(GroupNames);
xtickangle(30); % Rotate x-axis labels
xlim([min(x_allBars) - 0.5, max(x_allBars) + 0.5]); % Set x-axis limits
ylabel('Mean Difference'); % Label for mean difference

