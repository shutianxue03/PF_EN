function str_LMM = fxn_printLMM(lmm_output, dataTable, DV, flag_printLMM, flag_plotLMM, nameFolder_fig_LMM)
% Function to extract and print Linear Mixed Model (LMM) results, perform pairwise comparisons,
% and generate relevant plots for two-way, three-way, and four-way interactions.

% Inputs:
%   - lmm_output: LinearMixedModel object
%   - dataTable: Table containing the dataset
%   - DV: Dependent variable (vector, e.g., dataTable.Thresh)
%   - flag_printLMM: Boolean, whether to print the model summary
%   - flag_plotLMM: Boolean, whether to generate plots
%   - nameFolder_fig_LMM: Folder name for saving figures

% Output:
%   - str_LMM: String containing LMM results

% Determine number of predictor variables
varIVs =  lmm_output.PredictorNames(1:end);
nVars = length(varIVs)-1; % Count number of predictors

y_limit = [min(DV(:)), max(DV(:))];

% Extract model statistics
AIC = lmm_output.ModelCriterion.AIC;
BIC = lmm_output.ModelCriterion.BIC;
LL = lmm_output.LogLikelihood;

% Extract fixed-effects estimates and statistics
[fixedEffect_table, FE_names, stats] = fixedEffects(lmm_output, 'DFMethod', 'residual');

% Initialize an empty string to store fixed-effects results
str_fixedEffect = "";
for iFE = 1:length(fixedEffect_table)
    str_fixedEffect = str_fixedEffect + sprintf("%s: slope=%.2f (%.2f) [%.2f, %.2f], t(%.0f)=%.2f, p=%.3f\n", ...
        lmm_output.CoefficientNames{iFE}, fixedEffect_table(iFE), stats.SE(iFE), stats.Lower(iFE), stats.Upper(iFE), stats.DF(iFE), stats.tStat(iFE), stats.pValue(iFE));
end
str_LMM = sprintf('\n%s:\n%s', lmm_output.Formula, str_fixedEffect);

if flag_printLMM, fprintf('%s', str_LMM); end

%% PLOT
if flag_plotLMM

    % Extract predictor variable names from the LMM
    varIVs = lmm_output.PredictorNames;

    % Assign predictors based on the number of IVs
    var_x = varIVs{end-1}; % X-axis variable (last predictor)
    var_group = ''; var_facet1 = ''; var_facet2 = ''; % Default empty

    if nVars >= 2, var_group = varIVs{2}; end % First predictor is group variable
    if nVars >= 3, var_facet1 = varIVs{3}; end % Second predictor is first facet
    if nVars == 4, var_facet2 = varIVs{4}; end % Third predictor is second facet

    % Extract unique groups correctly
    if ~isempty(var_group) && ismember(var_group, dataTable.Properties.VariableNames)
        groups_unik = unique(dataTable.(var_group));
        nGroups_unik = length(groups_unik);
        colorMap = lines(nGroups_unik);
    else
        groups_unik = {''}; % No groups for simple models
        nGroups_unik = 1;
        colorMap = [0 0 0];
    end

    % Extract unique facets correctly
    if nVars >= 3 && ismember(var_facet1, dataTable.Properties.VariableNames)
        facet1_unik = unique(dataTable.(var_facet1));
        nFacets1_unik = length(facet1_unik);
    else
        facet1_unik = {''}; % No facets for simple models
        nFacets1_unik = 1;
    end

    if nVars >= 4 && ismember(var_facet2, dataTable.Properties.VariableNames)
        facet2_unik = unique(dataTable.(var_facet2));
        nFacets2_unik = length(facet2_unik);
    else
        facet2_unik = {''}; % No second facet for simpler models
        nFacets2_unik = 1;
    end

    
    figure('Position', [0 0 1200 800]);

    for iFacet2 = 1:nFacets2_unik
        for iFacet1 = 1:nFacets1_unik
            subplot(nFacets2_unik, nFacets1_unik, (iFacet2 - 1) * nFacets1_unik + iFacet1); hold on;

            % Corrected facet masking logic
            if nVars == 3
                mask_facet = dataTable.(var_facet1) == facet1_unik(iFacet1);
            elseif nVars == 4
                mask_facet = (dataTable.(var_facet1) == facet1_unik(iFacet1)) & (dataTable.(var_facet2) == facet2_unik(iFacet2));
            else
                mask_facet = true(height(dataTable), 1);
            end

            dataTable_facet = dataTable(mask_facet, :);
            DV_facet = DV(mask_facet);

            % Debugging check for facets
            disp(['Facet1 ', num2str(iFacet1), ', Facet2 ', num2str(iFacet2)]);

            for iGroup = 1:nGroups_unik
                c = colorMap(iGroup, :);
                if nVars >= 2
                    mask_group = dataTable_facet.(var_group) == groups_unik(iGroup);
                else
                    mask_group = ones(size(DV_facet));
                end

                % Scatter plot of raw data
                s = scatter(dataTable_facet.(var_x)(mask_group), DV_facet(mask_group), 50, c, 'o');
                s.MarkerFaceColor = c;
                s.MarkerFaceAlpha = 0.2;
                s.MarkerEdgeColor = 'none';

                % **Handling categorical vs continuous IV for predictions**
                if iscategorical(dataTable.(var_x))
                    xFine = unique(dataTable_facet.(var_x));
                else
                    xFine = linspace(min(dataTable_facet.(var_x)(mask_group)), max(dataTable_facet.(var_x)(mask_group)), 100)';
                end

                % **Create newData table for model prediction**
                newData = repmat(dataTable_facet(find(mask_group, 1), :), length(xFine), 1);
                newData.(var_x) = xFine;

                % Ensure categorical variables are retained
                if iscategorical(dataTable.(var_x))
                    newData.(var_x) = categorical(newData.(var_x), categories(dataTable.(var_x)));
                end

                % **Compute predicted values**
                fitted_fine = predict(lmm_output, newData);

                % **Handle sorting for categorical vs. continuous IVs**
                if iscategorical(xFine)
                    sortedX = xFine;
                    sortedFitted = fitted_fine;
                else
                    [sortedX, sortIdx] = sort(xFine);
                    sortedFitted = fitted_fine(sortIdx);
                end

                % **Plot model-fitted trend**
                plot(sortedX, sortedFitted, '-', 'Color', colorMap(iGroup, :), 'LineWidth', 2, 'HandleVisibility', 'off');
            end % iGroup

            xlabel(strrep(var_x, '_', '\_'));
            ylabel(lmm_output.ResponseName);

            % **Title Formatting**
            switch nVars
                case 2
                    title(sprintf('%s = %s', var_facet1, string(facet1_unik(iFacet1))));
                case 3
                    title(sprintf('%s = %s', var_facet1, string(facet1_unik(iFacet1))));
                case 4
                    title(sprintf('%s = %s, %s = %s', var_facet1, string(facet1_unik(iFacet1)), var_facet2, string(facet2_unik(iFacet2))));
            end

            % **Legend**
            str_legends = arrayfun(@(x) sprintf('%s=%s', var_group, string(x)), groups_unik, 'UniformOutput', false);
            legend(str_legends, 'Location', 'best');
            hold off;

            % xlim(x_limit);
            ylim(y_limit);
        end % iFacet1
    end % iFacet2

    % **Super title for entire figure**
    sgtitle(sprintf('Interaction Effect of %s, %s, %s, and %s on %s\n%s', ...
        var_group, var_facet1, var_facet2, var_x, lmm_output.ResponseName, str_LMM));

    % **Save figure**
    saveas(gcf, sprintf('%s/[%s]%s.jpg', nameFolder_fig_LMM, lmm_output.ResponseName, FE_names.Name{end}));

end % if flag_plotLMM
