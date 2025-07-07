function fxn_printANOVA_MulComp(dataTable, IV_single_all, DV, y_label, title_, nameFolder_fig, flag_multComp)
% Function to perform ANOVA on all combinations of factors, generate plots for 1-way and 2-way ANOVAs,
% and save the results as figures.
%
% Parameters:
% dataTable       - Table containing independent variables and dependent variable
% IV_single_all   - Names of independent variables (cell array of strings)
% DV              - Dependent variable (vector)
% y_label         - Label for the y-axis in plots (string)
% nameFolder_fig  - Folder name to save output figures (string)

if nargin <= 6, flag_multComp = 'Manual'; end % default; defined in fxn_plotMultipleComp

%% Settings
nIV_single = length(IV_single_all); % Number of independent variables

% Initialize a cell array to store ANOVA results
nSave = 4; % Number of elements to save for each ANOVA
ANOVA_results_all = cell(2^nIV_single - 1, nSave); % Preallocate for all combinations of IVs

%% Loop over combinations of factors
iANOVA = 1; % Counter for storing results
for nIV_involved = 1:nIV_single % Iterate over the number of IVs involved in the ANOVA
    
    % Generate all combinations of the factors of size 'nIV_involved'
    namesIV_comb = nchoosek(IV_single_all, nIV_involved); % Generate combinations
    nIVComb = size(namesIV_comb, 1); % Number of combinations
    for iIVComb = 1:nIVComb
        % Extract the current combination of factors
        namesIV = namesIV_comb(iIVComb, :); % Current combination of IVs
        nIV = length(namesIV); % Number of IVs in the current combination
        
        % Create index arrays for ANOVA based on current factors
        indANOVA = cell(1, nIV); % Preallocate index array
        for iIV = 1:nIV
            indANOVA{iIV} = dataTable.(namesIV{iIV}); % Extract data for each IV
        end
        
        % Perform the ANOVA
        [~, tbl, stats] = anovan(DV, indANOVA, 'model', 'full', 'varnames', namesIV, 'display', 'off');
        str_ANOVA = fxn_strANOVA(tbl); % Format ANOVA table into a string
        
        % Save results for the current ANOVA
        ANOVA_results_all{iANOVA, 1} = namesIV; % Save IV names
        ANOVA_results_all{iANOVA, 2} = str_ANOVA; % Save formatted ANOVA table
        ANOVA_results_all{iANOVA, 3} = stats; % Save ANOVA stats
        ANOVA_results_all{iANOVA, 4} = indANOVA; % Save index array
        iANOVA = iANOVA + 1; % Increment counter
    end % iIVComb
end % nIV_involved

%% Display results
nANOVAResults = size(ANOVA_results_all, 1); % Total number of ANOVAs

for iANOVA = 1:nANOVAResults
    
    % Extract information for the current ANOVA
    namesIV = ANOVA_results_all{iANOVA, 1}; % Names of factors
    str_ANOVA = ANOVA_results_all{iANOVA, 2}; % Formatted ANOVA results
    stats = ANOVA_results_all{iANOVA, 3}; % ANOVA stats
    indANOVA = ANOVA_results_all{iANOVA, 4}; % Index arrays
    nIVs = length(namesIV); % Number of IVs involved
    
    if nIVs <= 2 % For 1-way and 2-way ANOVAs, plot results
        
        switch nIVs
            case 1 % Single IV
                iIV = 1; % Index for the single IV
                IV_unik = unique(indANOVA{iIV}); % Unique levels of the IV
                
                nGroups = length(IV_unik); % Number of groups
                dataIdvd_allGroups = cell(1, nGroups); % Preallocate individual data
                names_allGroups = dataIdvd_allGroups; % Preallocate group names
                
                for iGroup = 1:nGroups
                    % Extract data for each group
                    dataIdvd_allGroups{iGroup} = DV(indANOVA{iIV} == IV_unik(iGroup));
                    names_allGroups{iGroup} = sprintf('%s=%d', namesIV{iIV}, IV_unik(iGroup));
                end
                IV_unik = {IV_unik}; % Wrap in a cell array for consistency
                
            case 2 % Two IVs
                IV1_unik = unique(indANOVA{1}); % Unique levels of the first IV
                IV2_unik = unique(indANOVA{2}); % Unique levels of the second IV
                
                nGroups1 = length(IV1_unik); % Number of groups for IV1
                nGroups2 = length(IV2_unik); % Number of groups for IV2
                dataIdvd_allGroups = cell(1, nGroups1 * nGroups2); % Preallocate individual data
                names_allGroups = dataIdvd_allGroups; % Preallocate group names
                
                i = 1; % Group counter
                for iGroup2 = 1:nGroups2
                    for iGroup1 = 1:nGroups1
                        % Extract data for each group
                        dataIdvd_allGroups{i} = DV(indANOVA{1} == IV1_unik(iGroup1) & indANOVA{2} == IV2_unik(iGroup2));
                        names_allGroups{i} = sprintf('%s=%d,%s=%d', namesIV{1}, IV1_unik(iGroup1), namesIV{2}, IV2_unik(iGroup2));
                        i = i + 1;
                    end
                end
                IV_unik = {IV1_unik, IV2_unik}; % Combine unique levels into a cell array
        end
        
        % Plot multiple comparisons and group data
        str_title = sprintf('\n%s [Var: %s]\n%s', y_label, strjoin(namesIV, ' x '), str_ANOVA);
        fprintf(str_title)
        %------------------------------------------------------------------------------------%
        fxn_plotMultipleComp(stats, namesIV, IV_unik, dataIdvd_allGroups, names_allGroups, y_label, flag_multComp);
        %------------------------------------------------------------------------------------%
        
    else % For >2 IVs, only print the ANOVA table
        figure('Position', [100, 100, 500, 500]);
        str_title = sprintf('%s [Var: %s]\n%s', y_label, strjoin(namesIV, ' x '));
        text(0, 1, str_ANOVA, 'fontsize', 15), ylim([-5, 10]), xlim([-.5, 2]);
        xticks([]), yticks([]);
    end
    
    % Set plot title
    title(sprintf('%s\n%s [Posthoc MC: %s]', title_, str_title, flag_multComp));
    set(findall(gcf, '-property', 'FontSize'), 'FontSize', 12); % Standardize font size
    
    % Save the figure
    if ~isnan(nameFolder_fig)
        if isempty(dir(nameFolder_fig)), mkdir(nameFolder_fig); end % Create folder if it doesn't exist
        saveas(gcf, sprintf('%s/[%s]%s.jpg', nameFolder_fig, y_label, strjoin(namesIV, '_')));
    end
    
end % iANOVA

close all % Close all figures

