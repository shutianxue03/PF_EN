
% This script creates data tables needed for LMM analysis

% Before running this script, run SX_compileOOD and stop at line#99, and
% quit debugging, so that all the needed parameters & setting are in place;
% make sure i (Line#44) is 3 for fitting (not MC) mode
clc
%--------------------------------------------
% run SX_compileOOD_v2 in the first place
%--------------------------------------------

str_folder = sprintf('Data/R_DataTable/%s%s', str_SF, str_n9); if isempty(dir(str_folder)), mkdir(str_folder), end

indLoc_s_all = {[1,2,3], [1,4,8], [1,5,9], [4,5], [6,7], [8,9], [10,11], [1, 4, 6, 7, 8, 10, 11], [4,5,8,9], [6,7,10,11]}; nIndLoc_s = length(indLoc_s_all); % Total number of location groups

fxn_getLDI = @(a,b) (a-b)./(a+b);
iNoise_thresh = 1;
indPerfLevel = 1:nPerf; nPerf = length(indPerfLevel);
flag_nestedMC=0; flag_varyLocMC=0;

nSF = length(namesSF);

ind_s_ModelnMC = 13:16; nModels_s = length(ind_s_ModelnMC);
ind_s_locGroup = 8; nLocGroups_s = length(ind_s_locGroup);

% Create folder for figures
nameFolder_Fig_Main = nameFolder_fig_PF;
iParams_all = 1:4; namesLF = [namesLF_PTM(2:4), 'GainLog']; namesLF_Labels = [namesLF_PTM(2:4), 'GainLog'];
nParams = length(iParams_all);

%% Nested Model Comparison [Subj, SF, LocGroup]
indSubj_acrossSF = []; % Stores subject indices
indSF_acrossSF = indSubj_acrossSF; % Stores SF values
indLocGroup_acrossSF = indSubj_acrossSF; % Stores location combinations
indModel_acrossSF = indSubj_acrossSF; %
indBoot_acrossSF = indSubj_acrossSF;
dBIC_nestedMC_acrossSF = indSubj_acrossSF;

% Loop through each SF to load data and compute required metrics
for SF_load = SF_load_all
    %----------
    fxn_loadSF % Load SF-specific data
    %----------
    load(nameFile_fitTvC_allSubj, 'dBIC_nestedMC_allB_allSubj')

    dBIC_nestedMC_allB_allSubj_s = dBIC_nestedMC_allB_allSubj(:, ind_s_locGroup, ind_s_ModelnMC, :);
    SF = SF_load; SF(SF == 51) = 5;

    indSubj = repmat((1:nsubj)', [1, nLocGroups_s, nModels_s, nBoot]);
    indSF = ones(size(dBIC_nestedMC_allB_allSubj_s))*SF;
    indLocGroup = repmat(reshape(ind_s_locGroup, [1, nLocGroups_s, 1, 1]), [nsubj, 1, nModels_s, nBoot]);
    indModel = repmat(reshape(ind_s_ModelnMC, [1, 1, nModels_s, 1]), [nsubj, nLocGroups_s, 1, nBoot]);
    indBoot = repmat(reshape(1:nBoot, [1, 1, 1, nBoot]), [nsubj, nLocGroups_s, nModels_s, 1]);

    indSubj_acrossSF = [indSubj_acrossSF; indSubj(:)];
    indSF_acrossSF = [indSF_acrossSF; indSF(:)];
    indLocGroup_acrossSF = [indLocGroup_acrossSF; indLocGroup(:)];
    indModel_acrossSF = [indModel_acrossSF; indModel(:)];
    indBoot_acrossSF = [indBoot_acrossSF; indBoot(:)];
    dBIC_nestedMC_acrossSF = [dBIC_nestedMC_acrossSF; dBIC_nestedMC_allB_allSubj_s(:)];

    % plot
    dBIC_med_allSubj = getCI(dBIC_nestedMC_allB_allSubj_s, 1, 4);
    [ave, ~, ~, sem] = getCI(dBIC_med_allSubj, 2, 1);
    figure, hold on
    bar(1:nModels_s, ave)
    errorbar(1:nModels_s, ave, sem, 'k.', 'CapSize',0)

end % SF_load

dataTable_PTM = table(...
    categorical(indSubj_acrossSF), ...
    categorical(indLocGroup_acrossSF), ...
    categorical(indSF_acrossSF), ...
    categorical(indModel_acrossSF), ...
    categorical(indBoot_acrossSF), ...
    dBIC_nestedMC_acrossSF, ...
    'VariableNames', {'Subj', 'LocGroup', 'SF', 'Model', 'iBoot', 'dBIC'});

% Save csv files
writetable(dataTable_PTM, sprintf('%s/NestedMC_nBoot%d.csv', str_folder, nBoot))

%% Loop through each location groups
for iiIndLoc_s = 1:nIndLoc_s
    indLoc_s = indLoc_s_all{iiIndLoc_s};
        nLoc_s = length(indLoc_s); % Number of selected locations
    namesCombLoc_s = namesCombLoc(indLoc_s); % Get location names
    str_LocSelected = strjoin(namesCombLoc_s, ''); % Concatenate location names into a single string
    fprintf('\n-------%s------\n', str_LocSelected) % Print the selected location name

    % Variation & Modulation [Subj, SF, Loc, PerfLevel | Nadd, Gamma, Gain, Thresh0]
    % Initialize placeholders for data across spatial frequencies (SF)
    indSubj_acrossSF = []; % Stores subject indices
    indSF_acrossSF = indSubj_acrossSF; % Stores SF values
    indLocComb_acrossSF = indSubj_acrossSF; % Stores location combinations
    indBoot_acrossSF = indSubj_acrossSF;
    PerfLevel_acrossSF = indSubj_acrossSF;
    ThreshN0_log_acrossSF = indSubj_acrossSF; % for the sake of calculating LDI
    ThreshN0_t_acrossSF = indSubj_acrossSF; % Stores threshold values
    estP_Gain_acrossSF = indSubj_acrossSF; % Stores estimated model parameters
    estP_GainLog_acrossSF = indSubj_acrossSF; % Stores estimated model parameters
    estP_Nadd_acrossSF = indSubj_acrossSF; % Stores estimated model parameters
    estP_Gamma_acrossSF = indSubj_acrossSF; % Stores estimated model parameters

    % Loop through each SF to load data and compute required metrics
    for SF_load = SF_load_all
        %----------
        fxn_loadSF % Load SF-specific data
        %----------
        load(nameFile_fitTvC_allSubj, '*_allB_allSubj')

        % Preallocate placeholders
        indSubj = nan(length(isubj_ANOVA), nLoc_s, nPerf, nBoot);
        indSF = indSubj;
        indLocComb = indSubj;
        PerfLevel = indSubj;
        indBoot = indSubj;
        ThreshN0_log = indSubj;
        estP_Gain = indSubj;
        estP_GainLog = indSubj;
        estP_Nadd = indSubj;
        estP_Gamma = indSubj;

        for iBoot = 1:nBoot
            % Column 1: Subject index
            indSubj(:, :, :, iBoot) = repmat(isubj_ANOVA', 1, nLoc_s, nPerf);

            % Column 2: SF values
            SF = SF_load; SF(SF == 51) = 5;
            indSF(:, :, :, iBoot) = repmat(SF, nsubj, nLoc_s, nPerf);
            if flag_PTMwithSF, SF_fit = SF; else, SF_fit = 1; end

            % Column 3: Location combinations
            % if any(iiIndLoc_s == [9,10])
            %     indLocComb(:, :, :, iBoot) = repmat([1,2,1,2], nsubj, 1, nPerf); % 1=HM or LVM; 2=VM or UVM
            % else
                indLocComb(:, :, :, iBoot) = repmat(indLoc_s, nsubj, 1, nPerf);
            % end

            % Column 4: ind of boot
            indBoot(:, :, :, iBoot) = ones(size(nsubj, nLoc_s, nPerf))*iBoot;

            % Column 5: PerfLevel
            PerfLevel(:, :, :, iBoot) = repmat(reshape(perfThresh_all(indPerfLevel)/100, [1, 1, nPerf]), nsubj, nLoc_s, 1);

            % Column 6: Threshold at no noise condition
            ThreshN0_log(:, :, :, iBoot) = squeeze(thresh_log_allB_allSubj(:, indLoc_s, iNoise_thresh, indPerfLevel, iBoot));

            % Column 7: Converted Threshold
            % ThreshN0_t_N0 = 1./10.^ThreshN0_log; % CS
            Thresh_N0_t = -ThreshN0_log; % sign flipped

            % Column 8-10: Estimated parameters from the model
            estP_Gain_ = squeeze(est_BestSimplest_allB_allSubj(:, iiIndLoc_s, 1:nLoc_s, 3, iBoot)); estP_Gain(:, :, :, iBoot) = repmat(estP_Gain_, 1, 1, nPerf);
            estP_Nadd_ = squeeze(est_BestSimplest_allB_allSubj(:, iiIndLoc_s, 1:nLoc_s, 2, iBoot)); estP_Nadd(:, :, :, iBoot) = repmat(estP_Nadd_, 1, 1, nPerf);
            estP_Gamma_ = squeeze(est_BestSimplest_allB_allSubj(:, iiIndLoc_s, 1:nLoc_s, 1, iBoot)); estP_Gamma(:, :, :, iBoot) = repmat(estP_Gamma_, 1, 1, nPerf);

        end % iBoot

        % Convert gain to log scale (because there are many gain below 1)
        estP_GainLog = log10(estP_Gain);
        
        % Store collected data across SFs
        indSubj_acrossSF = [indSubj_acrossSF; indSubj(:)];
        indSF_acrossSF = [indSF_acrossSF; indSF(:)];
        indLocComb_acrossSF = [indLocComb_acrossSF; indLocComb(:)];
        indBoot_acrossSF = [indBoot_acrossSF; indBoot(:)];
        PerfLevel_acrossSF = [PerfLevel_acrossSF; PerfLevel(:)];
        ThreshN0_log_acrossSF = [ThreshN0_log_acrossSF; ThreshN0_log(:)];
        ThreshN0_t_acrossSF = [ThreshN0_t_acrossSF; Thresh_N0_t(:)];
        estP_Gain_acrossSF = [estP_Gain_acrossSF; estP_Gain(:)];
        estP_GainLog_acrossSF = [estP_GainLog_acrossSF; estP_GainLog(:)];
        estP_Nadd_acrossSF = [estP_Nadd_acrossSF; estP_Nadd(:)];
        estP_Gamma_acrossSF = [estP_Gamma_acrossSF; estP_Gamma(:)];

    end % SF_load

    estP_mat_acrossSF = [estP_Gain_acrossSF, estP_GainLog_acrossSF, estP_Nadd_acrossSF, estP_Gamma_acrossSF]; % do NOT delete! Needed for LDI

    % Add a column for eccentricity (4º = L4,5,8,9; 8º = L6,7,10,11)
    indEcc_acrossSF = nan(size(indLocComb_acrossSF));
    indEcc_acrossSF(ismember(indLocComb_acrossSF, [1])) = 0;
    indEcc_acrossSF(ismember(indLocComb_acrossSF, [2,4:7])) = 4;
    indEcc_acrossSF(ismember(indLocComb_acrossSF, [3,8:11])) = 8;

    % for loc group that has LocxEcc design, convert iLocComb to binary values (1=HM or LVM; 2=VM or UVM)
    indLocComb_acrossSF_ = indLocComb_acrossSF;
    switch iiIndLoc_s
        case 9 % 4=HM4, 5=VM4, 8=HM8, 9=VM8
            indLocComb_acrossSF_(ismember(indLocComb_acrossSF, [4,8])) = 1;
            indLocComb_acrossSF_(ismember(indLocComb_acrossSF, [5,9])) = 2;
        case 10 % 4=LVM4, 5=UVM4, 8=LVM8, 9=UVM8
            indLocComb_acrossSF_(ismember(indLocComb_acrossSF, [6,10])) = 3;
            indLocComb_acrossSF_(ismember(indLocComb_acrossSF, [7,11])) = 4;
    end

    dataTable_PTM = table(...
        categorical(indSubj_acrossSF), ...
        categorical(indLocComb_acrossSF_), ...
        categorical(indEcc_acrossSF), ...
        categorical(indSF_acrossSF), ...
        categorical(indBoot_acrossSF), ...
        categorical(PerfLevel_acrossSF), ...
        double(ThreshN0_log_acrossSF), ...
        double(ThreshN0_t_acrossSF), ...
        double(estP_Gain_acrossSF), ...
        double(estP_GainLog_acrossSF), ...
        double(estP_Nadd_acrossSF), ...
        double(estP_Gamma_acrossSF), ...
        'VariableNames', {'Subj', 'LocComb', 'Ecc', 'SF', 'iBoot', 'PerfLevel', 'ThreshN0', 'ThreshN0_t', 'Gain', 'GainLog', 'Nadd','Gamma'});

    % Save csv files
    writetable(dataTable_PTM, sprintf('%s/%s_nBoot%d.csv', str_folder, str_LocSelected, nBoot))

    % Contribution [Subj, SF, Loc, PerfLevel | Nadd_LDI, Gamma_LDI, Gain_LDI, Thresh0_LDI]
    if nLoc_s <= 3
        % Save for each pair
        indLoc_unik_all = unique(indLocComb_acrossSF);
        nLoc_unik = length(indLoc_unik_all);
        nPairs = nchoosek(nLoc_unik,2);

        for iPair=1:nPairs
            switch iPair
                case 1, iPairAB = [1,2];
                case 2, iPairAB = [1,3];
                case 3, iPairAB = [2,3];
            end

            indA = indLocComb_acrossSF==indLoc_unik_all(iPairAB(1));
            indB = indLocComb_acrossSF==indLoc_unik_all(iPairAB(2));
            %--------------------%
            ThreshN0_LDI = fxn_getLDI(ThreshN0_log_acrossSF(indA), ThreshN0_log_acrossSF(indB)); %assert(~isempty(ThreshN0_t_acrossSF), 'ALERT: empty'), ThreshN0_t_acrossSF(isnan(ThreshN0_t_acrossSF))=0;
            ThreshN0_t_LDI = fxn_getLDI(ThreshN0_t_acrossSF(indA), ThreshN0_t_acrossSF(indB)); %assert(~isempty(ThreshN0_t_acrossSF), 'ALERT: empty'), ThreshN0_t_acrossSF(isnan(ThreshN0_t_acrossSF))=0;
            estP_LDI = fxn_getLDI(estP_mat_acrossSF(indA, :), estP_mat_acrossSF(indB, :)); %assert(~isempty(estP_LDI)), estP_mat_acrossSF(isnan(estP_mat_acrossSF))=0;
            %--------------------%

            dataTable_LDI = table(...
                indSubj_acrossSF(indA), ...
                indSF_acrossSF(indA), ...
                indBoot_acrossSF(indA), ...
                PerfLevel_acrossSF(indA), ...
                ThreshN0_LDI, ...
                ThreshN0_t_LDI, ...
                estP_LDI(:, 1), ... % Gain_LDI
                estP_LDI(:, 2), ... % GainLog_LDI
                estP_LDI(:, 3), ... % Nadd_LDI
                estP_LDI(:, 4), ... % Gamma_LDI
                'VariableNames', {'Subj', 'SF', 'iBoot', 'PerfLevel', 'ThreshN0_LDI', 'ThreshN0_t_LDI', 'Gain_LDI', 'GainLog_LDI', 'Nadd_LDI', 'Gamma_LDI'});

            writetable(dataTable_LDI, sprintf('%s/LDI_%s_Pair%d%d_nBoot%d.csv', str_folder, str_LocSelected, iPairAB, nBoot))

            %% Plot Corr Asym
            if flag_plotCorrAsym
                indPerf = dataTable_LDI.PerfLevel == .75;

                DV_LDI = dataTable_LDI.ThreshN0_t_LDI;
                str_tail_allParam = {'two', 'right', 'right', 'right'}; assert(nParams == length(str_tail_allParam)) % Gamma (neg expected, unsure), Nadd (pos expected), Gain (pos expected), GainLog

                for iControl = iControl_all % 0= raw data; 1=demean across SFs to reveal subj effect

                    figure('Position', [0 0 2e3 2e3]), hold on
                    for iParam = iParams_all 
                        % Rearrange data from long to short format (each row is a boot)
                        param_LDI_allB = nan(nBoot, nsubj_acrossSF);
                        DV_LDI_allB = param_LDI_allB;
                        SF_allB = param_LDI_allB;

                        for iBoot = 1:nBoot
                            indBoot = dataTable_LDI.iBoot == iBoot;
                            switch iParam
                                case 1, param_LDI = dataTable_LDI.Gamma_LDI(indPerf & indBoot); % matching the order of "namesLF"
                                case 2, param_LDI = dataTable_LDI.Nadd_LDI(indPerf & indBoot);
                                case 3, param_LDI = dataTable_LDI.Gain_LDI(indPerf & indBoot);
                                    case 4, param_LDI = dataTable_LDI.GainLog_LDI(indPerf & indBoot);
                            end
                            assert(length(param_LDI) == nsubj_acrossSF)
                            param_LDI_allB(iBoot, :) = param_LDI;
                            DV_LDI_allB(iBoot, :) = DV_LDI(indPerf & indBoot);
                            SF_allB(iBoot, :) = dataTable_LDI.SF(indPerf & indBoot);
                        end

                        subplot(1,nParams,iParam), hold on, box on

                        % Draw correlation across SFs
                        %----------------------------------------%
                        wd_border = 1;
                        text_corr_allSF = basicFxn_drawCorrAsym_boot(param_LDI_allB, DV_LDI_allB, SF_allB, iControl, str_tail_allParam{iParam}, [], [], [], [], namesLF{iParam}, 'm', '.', wd_border);
                        %----------------------------------------%

                        % Draw correlation for each SF
                        % text_corr_perSF = cell(nSF, 1);
                        % for SF = SF_all
                        %     % SF_ = dataTable_LDI.SF(indPerf);
                        %     % indSF = SF_==SF;
                        %     indSF = SF_allB(1, :)==SF;
                        %     %----------------------------------------%
                        %     wd_border = 1.2;
                        %     text_corr_perSF{SF-3} = basicFxn_drawCorrAsym_boot(param_LDI_allB(:, indSF), DV_LDI_allB(:, indSF), SF_allB(:, indSF), 0, str_tail_allParam{iParam}, [], [], [], [], namesLF{iParam}, 'm', '.', wd_border);
                        %     % text_corr_perSF{SF-3} = basicFxn_drawCorrAsym(param_LDI(indSF), DV_LDI(indSF), iControl, SF_(indSF), str_tail_allParam{iParam}, [], [], [], [], namesLF{iParam}, 'k', markers_allSF{SF-3}, wd_border);
                        %     %----------------------------------------%
                        % end % SF

                        str_xlabel = 'Param LDI';
                        str_ylabel = 'Thresh LDI';
                        switch iControl
                            case 0, IV_control = 'NoControl'; str_demean = '';
                            case 1, IV_control = 'ControlSF'; str_demean = '(demeaned for SF)';
                        end
                        title_vs = sprintf('(%s - %s)/(%s + %s)', namesCombLoc_s{iPairAB(1)}, namesCombLoc_s{iPairAB(2)}, namesCombLoc_s{iPairAB(1)}, namesCombLoc_s{iPairAB(2)});
                        xlabel(sprintf('%s %s', str_xlabel, str_demean))
                        ylabel(sprintf('%s %s', str_ylabel, str_demean))
                        title(sprintf('[%s] %s \n%s', namesLF_Labels{iParam}, title_vs, text_corr_allSF))

                    end % iParam

                    set(findall(gcf, '-property', 'fontsize'), 'fontsize', 12)

                    % Save figure
                    nameFolder_fig_corrAsym = sprintf('%s/corrAsym/%s', nameFolder_fig_PF, IV_control);
                    if isempty(dir(nameFolder_fig_corrAsym)), mkdir(nameFolder_fig_corrAsym), end
                    saveas(gcf, sprintf('%s/%s_Pair%d%d_nBoot%d.jpg', nameFolder_fig_corrAsym, str_LocSelected, iPairAB, nBoot))
                end
                close all
            end % if flag_plotCorrAsym
        end % iPair
    end % if nLoc_s<3
end % iiIndLoc

fprintf('\n========================== DONE ==========================\n')