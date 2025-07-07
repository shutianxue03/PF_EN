function str_LMM = fxn_printLMM2(lmm_output, dataTable, DV, flag_printLMM, flag_plotLMM, nameFolder_fig_LMM)
% Function to extract and print Linear Mixed Model (LMM) results, perform pairwise comparisons,
% and generate relevant plots.

% Inputs:
%   - lmm_output: LinearMixedModel object
%   - dataTable: Table containing the dataset
%   - DV: Dependent variable (e.g., dataTable.Thresh)
%   - flag_printLMM: Boolean, whether to print the model summary
%   - flag_plotLMM: Boolean, whether to generate plots
%   - nameFolder_fig_LMM: Folder name for saving figures

% Output:
%   - str_LMM: String containing LMM results

nVars = 2; % only works for two-way LMM for now

% Extract model statistics
AIC = lmm_output.ModelCriterion.AIC;
BIC = lmm_output.ModelCriterion.BIC;
LL = lmm_output.LogLikelihood;

% Extract fixed-effects estimates and statistics
[fixedEffect_table, FE_names, stats] = fixedEffects(lmm_output, 'DFMethod', 'residual');

% Extract confidence intervals for fixed effects
CI_lower = stats.Lower;
CI_upper = stats.Upper;

% Initialize an empty string to store fixed-effects results
str_fixedEffect = "";

% Loop through fixed effects (skip intercept at index 1)
for i = 2:length(fixedEffect_table)
    str_fixedEffect = str_fixedEffect + sprintf("%s: slope=%.2f, p=%.3f\n", ...
        lmm_output.CoefficientNames{i}, fixedEffect_table(i), stats.pValue(i));
end

% Format the final output string containing the model results
str_LMM = sprintf('\n%s:\n%s', lmm_output.Formula, str_fixedEffect);

% Print results to console if flag is set
if flag_printLMM, fprintf('%s', str_LMM); end

% Generate visualization if flag is set
if flag_plotLMM
    % Identify predictor variables for the x-axis and grouping variable for the legend
    predictor_vars = split(FE_names.Name{end}, ':'); % Identify main and interaction terms
    xVar = predictor_vars{end};   % Last term in interaction is chosen for the X-axis
    groupVar = predictor_vars{1}; % First term in interaction is used for grouping

    % Ensure the selected variables exist in dataTable
    if ~ismember(xVar, dataTable.Properties.VariableNames) || ~ismember(groupVar, dataTable.Properties.VariableNames)
        error('Error: Variables %s or %s not found in dataTable.', xVar, groupVar);
    end

    % Generate the scatter plot showing the raw data (DV)
    figure('Position', [0 0 1e3 500])
    hold on;

    % Define colormap based on unique groups
    groupVar_unik = unique(dataTable.(groupVar));
    nGroup_unik = length(groupVar_unik);
    colorMap = lines(nGroup_unik); % Assign unique colors to each group

    % Plot data and fitted lines per group
    for iG_unik = 1:nGroup_unik
        % Filter data for the current group
        mask_group = dataTable.(groupVar) == groupVar_unik(iG_unik);
        s = scatter(dataTable.(xVar)(mask_group), DV(mask_group), 50, 'o');  % Raw data points
        s.MarkerFaceColor = colorMap(iG_unik, :);
        s.MarkerEdgeColor = 'none';
        s.MarkerFaceAlpha = 0.2;  % Set transparency (0 = fully transparent, 1 = fully opaque)

        % Interpolate fitted values from the model
        % Generate a fine grid of x-values
        nItp = 1e2;  % Number of interpolation points
        xFine = linspace(min(dataTable.(xVar)(mask_group)), max(dataTable.(xVar)(mask_group)), nItp)';
        % Create a new table for prediction using the same structure as dataTable
        newData = repmat(dataTable(find(mask_group, 1), :), nItp, 1);  % Copy one row to maintain structure
        % Replace only the x-axis predictor variable with xFine values
        newData.(xVar) = xFine;
        % Use `predict` with the properly structured table
        fitted_fine = predict(lmm_output, newData);
        % Plot smooth fitted line
        plot(xFine, fitted_fine, '-', 'Color', colorMap(iG_unik, :), 'LineWidth', 2);

    end % iG_unik

    xlabel(strrep(xVar, '_', '\_'));  % Convert underscores for LaTeX compatibility
    ylabel(strrep(lmm_output.ResponseName, '_', '\_')); % Convert response variable name
    title(sprintf('Interaction Effect of %s and %s on %s\n%s', groupVar, xVar, lmm_output.ResponseName, str_LMM));

    % Dynamically generate legend labels based on unique grouping variable values
    legendEntries = arrayfun(@(x) sprintf('%s=%d', groupVar, x), groupVar_unik, 'UniformOutput', false);
    legend(legendEntries, 'Location', 'best');

    hold off;

    % Save the figure
    % saveas(gcf, sprintf('%s/%s.jpg', nameFolder_fig_LMM, FE_names.Name{end}));
end % flag_plotLMM
