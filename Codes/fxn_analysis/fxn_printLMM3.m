function str_LMM = fxn_printLMM3(lmm_output, dataTable, DV, flag_printLMM, flag_plotLMM, nameFolder_fig_LMM)
% Function to extract and print Linear Mixed Model (LMM) results, perform pairwise comparisons,
% and generate relevant plots for three-way interactions.

% Inputs:
%   - lmm_output: LinearMixedModel object
%   - dataTable: Table containing the dataset
%   - DV: Dependent variable (vector, e.g., dataTable.Thresh)
%   - flag_printLMM: Boolean, whether to print the model summary
%   - flag_plotLMM: Boolean, whether to generate plots
%   - nameFolder_fig_LMM: Folder name for saving figures

% Output:
%   - str_LMM: String containing LMM results

nVars = 3; % Updated for three-way LMM

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
    % Identify predictor variables for the x-axis, grouping, and faceting
    predictor_vars = split(FE_names.Name{end}, ':'); % Extract terms from last interaction
    if length(predictor_vars) < 3
        error('Error: Expected three predictors in the interaction term.');
    end
    xVar = predictor_vars{end};      % X-axis variable
    groupVar = predictor_vars{1};    % Grouping variable (color)
    facetVar = predictor_vars{2};    % Faceting variable (subplot)

    % Ensure variables exist in dataTable
    missingVars = ~ismember({xVar, groupVar, facetVar}, dataTable.Properties.VariableNames);
    if any(missingVars)
        error('Error: Variables %s, %s, or %s not found in dataTable.', xVar, groupVar, facetVar);
    end

    % Extract fitted values from the model
    fittedValues = fitted(lmm_output);

    % Generate faceted scatter plot
    uniqueFacets = unique(dataTable.(facetVar));
    numFacets = length(uniqueFacets);
    figure('Position', [0 0 1000 500]);

    % Define colormap based on the number of unique groups
    uniqueGroups = unique(dataTable.(groupVar));
    numGroups = length(uniqueGroups);
    colorMap = lines(numGroups);  % Change to 'parula(numGroups)' or 'jet(numGroups)' for variation

    for i = 1:numFacets
        subplot(1, numFacets, i);
        hold on;

        % Filter data for the current facet
        facetMask = dataTable.(facetVar) == uniqueFacets(i);
        dataSubset = dataTable(facetMask, :);
        DV_subset = DV(facetMask);  % Extract DV for this facet
        fittedSubset = fittedValues(facetMask);  % Extract fitted values for this facet

        % Plot data and fitted lines per group
        for j = 1:numGroups
            % Filter data for the current group
            groupMask = dataSubset.(groupVar) == uniqueGroups(j);

            % Scatter plot: Raw data points
            scatter(dataSubset.(xVar)(groupMask), DV_subset(groupMask), 50, colorMap(j, :), 'o');

            % Create a fine grid of x-values for smooth interpolation
            nItp = 100; % Number of interpolation points
            xFine = linspace(min(dataSubset.(xVar)(groupMask)), max(dataSubset.(xVar)(groupMask)), nItp)';

            % Create a new table for prediction with the same structure
            newData = repmat(dataSubset(find(groupMask, 1), :), nItp, 1);
            newData.(xVar) = xFine; % Replace only xVar

            % Predict fitted values for the fine grid
            fitted_fine = predict(lmm_output, newData);

            % Sort x-values and fitted values before plotting
            [sortedX, sortIdx] = sort(xFine);
            sortedFitted = fitted_fine(sortIdx);

            % Plot smooth fitted trend line
            plot(sortedX, sortedFitted, '-', 'Color', colorMap(j, :), 'LineWidth', 2);
        end

        xlabel(strrep(xVar, '_', '\_'));
        ylabel('Threshold');  % Adjust label if needed
        title(sprintf('%s = %s', facetVar, string(uniqueFacets(i))));

        % Create a legend mapping groups to colors
        legendEntries = arrayfun(@(x) sprintf('%s=%s', groupVar, string(x)), uniqueGroups, 'UniformOutput', false);
        legend(legendEntries, 'Location', 'best');

        hold off;
    end
    sgtitle(sprintf('Interaction Effect of %s, %s, and %s on %s\n%s', ...
        groupVar, facetVar, xVar, lmm_output.ResponseName, str_LMM));

    saveas(gcf, sprintf('%s/%s.jpg', nameFolder_fig_LMM, FE_names.Name{end}));
end % flag_plotLMM

% function str_LMM = fxn_printLMM3(lmm_output, dataTable, DV, flag_printLMM, flag_plotLMM, nameFolder_fig_LMM)
% % Function to extract and print Linear Mixed Model (LMM) results, perform pairwise comparisons,
% % and generate relevant plots for three-way interactions.
%
% % Inputs:
% %   - lmm_output: LinearMixedModel object
% %   - dataTable: Table containing the dataset
% %   - DV: Dependent variable (vector, e.g., dataTable.Thresh)
% %   - flag_printLMM: Boolean, whether to print the model summary
% %   - flag_plotLMM: Boolean, whether to generate plots
% %   - nameFolder_fig_LMM: Folder name for saving figures
%
% % Output:
% %   - str_LMM: String containing LMM results
%
% nVars = 3; % Updated for three-way LMM
%
% % Extract model statistics
% AIC = lmm_output.ModelCriterion.AIC;
% BIC = lmm_output.ModelCriterion.BIC;
% LL = lmm_output.LogLikelihood;
%
% % Extract fixed-effects estimates and statistics
% [fixedEffect_table, FE_names, stats] = fixedEffects(lmm_output, 'DFMethod', 'residual');
%
% % Extract confidence intervals for fixed effects
% CI_lower = stats.Lower;
% CI_upper = stats.Upper;
%
% % Initialize an empty string to store fixed-effects results
% str_fixedEffect = "";
%
% % Loop through fixed effects (skip intercept at index 1)
% for i = 2:length(fixedEffect_table)
%     str_fixedEffect = str_fixedEffect + sprintf("%s: slope=%.2f, p=%.3f\n", ...
%         lmm_output.CoefficientNames{i}, fixedEffect_table(i), stats.pValue(i));
% end
%
% % Format the final output string containing the model results
% str_LMM = sprintf('\n%s:\n%s', lmm_output.Formula, str_fixedEffect);
%
% % Print results to console if flag is set
% if flag_printLMM, fprintf('%s', str_LMM); end
%
% % Generate visualization if flag is set
% if flag_plotLMM
%     % Identify predictor variables for the x-axis, grouping, and faceting
%     predictor_vars = split(FE_names.Name{end}, ':'); % Extract terms from last interaction
%     if length(predictor_vars) < 3
%         error('Error: Expected three predictors in the interaction term.');
%     end
%     xVar = predictor_vars{end};      % X-axis variable
%     groupVar = predictor_vars{1};    % Grouping variable (color)
%     facetVar = predictor_vars{2};    % Faceting variable (subplot)
%
%     % Ensure variables exist in dataTable
%     missingVars = ~ismember({xVar, groupVar, facetVar}, dataTable.Properties.VariableNames);
%     if any(missingVars)
%         error('Error: Variables %s, %s, or %s not found in dataTable.', xVar, groupVar, facetVar);
%     end
%
%     % Extract fitted values from the model
%     fittedValues = fitted(lmm_output);
%
%     % Generate faceted scatter plot
%     uniqueFacets = unique(dataTable.(facetVar));
%     numFacets = length(uniqueFacets);
%     figure('Position', [0 0 1e3 500])
%
%     % Define colormap based on the number of unique groups
%     uniqueGroups = unique(dataTable.(groupVar));
%     numGroups = length(uniqueGroups);
%     colorMap = lines(numGroups);  % Change to 'parula(numGroups)' or 'jet(numGroups)' for variation
%
%     for i = 1:numFacets
%         subplot(1, numFacets, i);
%         hold on;
%
%         % Filter data for the current facet
%         facetMask = dataTable.(facetVar) == uniqueFacets(i);
%         dataSubset = dataTable(facetMask, :);
%         DV_subset = DV(facetMask);  % Extract DV for this facet
%         fittedSubset = fittedValues(facetMask);  % Extract fitted values for this facet
%
%         % Plot data and fitted lines per group
%         for j = 1:numGroups
%             % Filter data for the current group
%             groupMask = dataSubset.(groupVar) == uniqueGroups(j);
%
%             % Scatter plot: Raw data points
%             scatter(dataSubset.(xVar)(groupMask), DV_subset(groupMask), 50, colorMap(j, :), 'o');
%
%             % Sort data for smooth line plotting
%             [sortedX, sortIdx] = sort(dataSubset.(xVar)(groupMask));  % Sort x-values
%             sortedFitted = fittedSubset(groupMask);  % Extract fitted values
%             sortedFitted = sortedFitted(sortIdx);  % Apply sorting
%
%             % Plot smooth fitted trend line
%             % plot(sortedX, sortedFitted, '-', 'Color', colorMap(j, :), 'LineWidth', 2, 'HandleVisibility','off');
%         end
%
%         xlabel(strrep(xVar, '_', '\_'));
%         ylabel('Threshold');  % Adjust label if needed
%         title(sprintf('%s = %s', facetVar, string(uniqueFacets(i))));
%
%         % Create a legend mapping groups to colors
%         legendEntries = arrayfun(@(x) sprintf('%s=%s', groupVar, string(x)), uniqueGroups, 'UniformOutput', false);
%         legend(legendEntries, 'Location', 'best');
%
%         hold off;
%     end
%     sgtitle(sprintf('Interaction Effect of %s, %s, and %s on %s\n%s', ...
%         groupVar, facetVar, xVar, lmm_output.ResponseName, str_LMM));
%
%     saveas(gcf, sprintf('%s/%s.jpg', nameFolder_fig_LMM, FE_names.Name{end}));
% end % flag_plotLMM
