clc % Clear command window

% Select the subset of locations being analyzed
indLoc_s = indLoc_s_all{iiIndLoc_s};
nLoc_s = length(indLoc_s); % Number of selected locations
namesCombLoc_s = namesCombLoc(indLoc_s); % Get location names
str_LocSelected = strjoin(namesCombLoc_s, ''); % Concatenate location names into a single string
fprintf('\n-------%s------\n', str_LocSelected) % Print the selected location name

% Extract the optimal model index for the given parameters
IndCand_GroupBest = [(IndCand_GroupBest_all4{iTvCModel, iiIndLoc_s, iErrorType, iGoF_inUse})];

% Define folder structure for saving figures
nameFolder_Fig_Main = sprintf('Fig/acrossSFs/SF%s', str_SF);
nameFolder_fig_PF = sprintf('%s/PF', nameFolder_Fig_Main);
nameFolder_fig = sprintf('%s/%s_%s_%s/%s', nameFolder_fig_PF, nameModel, namesTvCModel{iTvCModel}, namesErrorType{iErrorType}, str_LocSelected);
if isempty(dir(nameFolder_fig)), mkdir(nameFolder_fig); end % Create folder if it does not exist

% Initialize placeholders for data across spatial frequencies (SF)
indSubj_allSF = []; % Stores subject indices
indSF_allSF = indSubj_allSF; % Stores SF values
indLocComb_s_allSF = indSubj_allSF; % Stores location combinations
threshN0_log_allSF = indSubj_allSF; % Stores threshold values
estP_mat_allSF = indSubj_allSF; % Stores estimated model parameters
threshCST_log_allSF = cell(nSF, 1);
threshEnergy_pred_allSF = threshCST_log_allSF;
TvC_energy_aveSF = threshEnergy_pred_allSF;
R2_allSF = threshEnergy_pred_allSF;

% Loop through each SF to load data and compute required metrics
for SF_load = SF_load_all
    %----------
    fxn_loadSF % Load SF-specific data
    %----------
    load(nameFile_fitTvC_allSubj, 'thresh_log_allSubj', '*BestSimplest*')

    % Column 1: Subject index
    indSubj = repmat(isubj_ANOVA', 1, nLoc_s);
    indSubj = indSubj(:);

    % Column 2: SF values
    SF = SF_load; SF(SF == 51) = 5;
    indSF = ones(size(indSubj)) * SF;
    indSF = indSF(:);

    if flag_PTMwithSF, SF_fit = SF; else, SF_fit = 1; end

    % Column 3: Location combinations
    indLocComb_s = repmat(indLoc_s, nsubj, 1);
    indLocComb_s = indLocComb_s(:);

    % Column 4: Threshold at no noise condition
    threshN0_log = getCI(thresh_log_allSubj(:, indLoc_s, iNoise_thresh, :), 2, 4);
    threshN0_log = threshN0_log(:);

    % Column 5-8: Estimated parameters from the model
    estP_mat = [];
    for iParam = iParams_all
        estP = squeeze(est_BestSimplest_allSubj(:, iiIndLoc_s, 1:nLoc_s, iParam));
        estP_mat = [estP_mat, estP(:)];
    end

    % Store collected data across SFs
    indSubj_allSF = [indSubj_allSF; indSubj];
    indSF_allSF = [indSF_allSF; indSF];
    indLocComb_s_allSF = [indLocComb_s_allSF; indLocComb_s];
    threshN0_log_allSF = [threshN0_log_allSF; threshN0_log];
    estP_mat_allSF = [estP_mat_allSF; estP_mat];

    % Extract measured thresholds
    threshCST_log_allSF{SF} = thresh_log_allSubj(:, indLoc_s, :, :);

    % Compute model-based predictions
    switch iTvCModel
        case 1 % LAM Model
            threshEnergy_pred = nan(nsubj, nLoc_s, nIntp, nPerf);
            for iisubj = 1:nsubj
                for iiLoc = 1:nLoc_s
                    for iPerf = 1:nPerf
                        t = fxn_LAM(squeeze(est_BestSimplest_allSubj(iisubj, iiIndLoc_s, iiLoc, :, iPerf)), noiseEnergy_intp_true);
                        assert(mean(abs(t) == Inf) == 0, 'ERROR: Inf in predicted threshold detected.')
                        threshEnergy_pred(iisubj, iiLoc, :, iPerf) = t;
                    end
                end
            end
            R2_allSF{SF} = squeeze(R2_BestSimplest_allSubj(:, iiIndLoc_s, 1:nLoc_s, :, :));

        case 2 % PTM Model
            threshEnergy_pred = nan(nsubj, nLoc_s, nIntp, nPerf);
            for iisubj = 1:nsubj
                for iiLoc = 1:nLoc_s
                    for iPerf = 1:nPerf
                        threshEnergy_pred(iisubj, iiLoc, :, iPerf) = fxn_PTM([0,1,1,1], squeeze(est_BestSimplest_allSubj(iisubj, iiIndLoc_s, iiLoc, :)).', noiseEnergy_intp_true, dprimes(iPerf), SF_fit);
                    end
                end
            end
            R2_allSF{SF} = squeeze(R2_BestSimplest_allSubj(:, iiIndLoc_s, 1:nLoc_s, :));
    end
    threshEnergy_pred_allSF{SF} = threshEnergy_pred;
end % End loop over SF_load

% Construct table for linear mixed model (LMM) analysis
switch iTvCModel
    case 1 % LAM Model
        Eff = D_ideal ./ estP_mat_allSF(:, 1) * 100; % Convert slope to efficiency
        NeqLog = log10(sqrt(estP_mat_allSF(:, 2))); % Convert Neq to log contrast
        dataTable = table(indSubj_allSF, indSF_allSF, indLocComb_s_allSF, threshN0_log_allSF, Eff, NeqLog, ...
            'VariableNames', ['Subj', 'SF', 'LocComb', 'Thresh', namesLF]);
    case 2 % PTM Model
        switch nameModel
            case 'FullModel'
                dataTable = table(indSubj_allSF, indSF_allSF, indLocComb_s_allSF, threshN0_log_allSF, estP_mat_allSF(:, 1), estP_mat_allSF(:, 2), estP_mat_allSF(:, 3), estP_mat_allSF(:, 4), ...
                    'VariableNames', ['Subj', 'SF', 'LocComb', 'Thresh', namesLF]);
            case 'NoNmul'
                dataTable = table(...
                    indSubj_allSF, ...
                    indLocComb_s_allSF, ...
                    indSF_allSF, ...
                    double(threshN0_log_allSF), ...
                    double(estP_mat_allSF(:, 1)), ...
                    double(estP_mat_allSF(:, 2)), ...
                    double(estP_mat_allSF(:, 3)), ...
                    'VariableNames', ['Subj','LocComb', 'SF', 'Thresh', namesLF]);
                % writetable(dataTable, sprintf('Rscripts/dataTable/dataTable_PTM_%s.csv', str_LocSelected))

                %% Create the table for location difference index
                % getAsym = @(a,b) (a-b)./(a+b);
                indLoc_unik_all = unique(indLocComb_s_allSF);
                nLoc_unik = length(indLoc_unik_all);
                nPairs = nchoosek(nLoc_unik,2);
                for iPair=1:nPairs
                    switch iPair
                        case 1, iPairAB = [1,2];
                        case 2, iPairAB = [1,3];
                        case 3, iPairAB = [2,3];
                    end

                    indA = indLocComb_s_allSF==indLoc_unik_all(iPairAB(1));
                    indB = indLocComb_s_allSF==indLoc_unik_all(iPairAB(2));
                    threshN0_log_asym = getAsym(threshN0_log_allSF(indA), threshN0_log_allSF(indB)); assert(~isempty(threshN0_log_asym), 'ALERT: empty'), threshN0_log_asym(isnan(threshN0_log_asym))=0;
                    estP_asym = getAsym(estP_mat_allSF(indA, :), estP_mat_allSF(indB, :)); assert(~isempty(estP_asym)), estP_mat_allSF(isnan(estP_mat_allSF))=0;
                    
                    dataTable_asym = table(...
                        indSubj_allSF(indA), ...
                        indSF_allSF(indA), ...
                        double(threshN0_log_asym), ...
                        double(estP_asym(:, 1)), ...
                        double(estP_asym(:, 2)), ...
                        double(estP_asym(:, 3)), ...
                        'VariableNames', {'Subj', 'SF', 'Thresh_asym', 'Gamma_asym', 'Gain_asym', 'Nadd_asym'});
                    % writetable(dataTable_asym, sprintf('Rscripts/dataTable/dataTable_asym_%s_Pair%d%d.csv', str_LocSelected, iPairAB))
                end % iPair
        end % switch nameModel
end % switch iTvCModel

% Store table to CSV





