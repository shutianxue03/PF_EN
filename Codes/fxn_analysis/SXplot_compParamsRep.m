
% What does this script do???

% Define the number of parameters to analyze (likely model parameters)
nParams = 3; % size(est_BestSimplest_allSubj, 4) might be another way to define it dynamically

% Define the total number of subjects
nsubj_full = 31;

% Define the spatial frequency (SF) conditions to load
SF_load_all = [4,51,5,6]; 
nSF = 3; % Number of spatial frequency conditions considered

% Construct the folder path where figures for parameter comparison will be saved
nameFolder_fig_compParamsRep = sprintf('%s/%s_%s_%s', ...
    nameFolder_fig_PF, nameModel, namesTvCModel{iTvCModel}, namesErrorType{iErrorType});

% Define different groups of locations for analysis
% Each cell contains indices referring to locations in the dataset
iLocGroup_all = {[1,2,3], [2,4], [3,4], [2,6], [3,6]};
% Corresponding indices for different groups
iiLoc_all = {[1,1,1], [2,1], [2,2], [3,1], [3,2]};

% Number of location groups to analyze
nLocRep = length(iLocGroup_all);

% Loop over each location group
for iLocRep = 1:nLocRep
    
    % Extract the indices of locations for the current group
    iLocGroup = iLocGroup_all{iLocRep};
    iiLoc = iiLoc_all{iLocRep};
    
    % Loop over each model parameter
    for iParam = 1:nParams
        % Determine the number of repetitions for the location group
        nRep = length(iLocGroup);
        
        % Initialize variables for ANOVA
        estP_ANOVA = []; % Stores estimated parameters for ANOVA
        indSubj_ANOVA = estP_ANOVA; % Subject indices
        indRep_ANOVA = estP_ANOVA; % Repetition indices
        indSF_ANOVA = estP_ANOVA; % Spatial frequency indices
        
        % Loop over each spatial frequency condition
        for SF_load = SF_load_all
            % Load spatial frequency-specific data
            %----------%
            fxn_loadSF
            %----------%
            
            % Load fitted parameters from the saved file
            load(nameFile_fitTvC_allSubj, 'est_BestSimplest_allSubj')
            
            % Adjust SF indices: Convert SF=51 to 5, then adjust index
            SF = SF_load; 
            SF(SF == 51) = 5; 
            iSF = SF - 3;
            
            % Loop over each repetition
            for iRep = 1:nRep
                % Extract parameter estimates for the current repetition and append them
                estP_ANOVA = [estP_ANOVA; squeeze(est_BestSimplest_allSubj(:, iLocGroup(iRep), iiLoc(iRep), iParam))];
                
                % Create corresponding indices for ANOVA
                indSubj_ANOVA = [indSubj_ANOVA; isubj_ANOVA']; % Subject indices
                indRep_ANOVA = [indRep_ANOVA; ones(nsubj,1) * iRep]; % Replication indices
                indSF_ANOVA = [indSF_ANOVA; ones(nsubj,1) * SF]; % Spatial frequency indices
            end % iRep
            
        end % SF_load
        
        % Create a table to store data for ANOVA
        dataTable = table(indSubj_ANOVA(:), indRep_ANOVA(:), indSF_ANOVA(:), estP_ANOVA(:), ...
            'VariableNames', {'Subj', 'Rep', 'SF', 'estP'});
        
        % Define independent variable(s) for ANOVA
        IV_single_all = {'Rep'};
        
        % Set plot labels and title
        y_label = namesLF_PTM{iParam+1}; % Dependent variable name
        title_ = y_label;
        
        % Generate folder name for saving figures
        nn = namesCombLoc(indLoc_s_all{iLocGroup(1)});
        nameFolder_fig = sprintf('%s/CompParamsRep/%s', nameFolder_fig_compParamsRep, nn{iiLoc(1)});
        
        %------------------------------------------------------------%
        % Perform ANOVA and multiple comparisons, then save results
        fxn_printANOVA_MulComp(dataTable, IV_single_all, dataTable.estP, y_label, title_, nameFolder_fig)
        %------------------------------------------------------------%
    end % iParam
end % iLocRep
