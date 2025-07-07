
flag_plotNestedMC = 0; % Whether to plot results

% Ensure the location type is 'combLoc' for stable fitting
% assert(strcmp(text_locType, 'combLoc'), 'text_locType must be "combLoc".');

% Default parameter values and bounds
% [Nmul, Gamma, Nadd, Beta]
params0_def = params0_PTM; % Initial guesses for parameters
lb_def = lb_PTM; % Lower bounds
ub_def = ub_PTM; % Upper bounds

%% Generate candidate models based on parameter inclusion
nParams = nLF_PTM; % Total number of parameters
iCond_all = [0,1]; % Binary inclusion: 0 = excluded, 1 = included
nConds = length(iCond_all);
%---------------------------------------------------------------------------%
indParamIncl_allCand = fxn_getIndParamIncl(nParams, iCond_all); % Generate inclusion combinations
%---------------------------------------------------------------------------%
nCand = size(indParamIncl_allCand, 1); % Total number of candidate models

%% Initialize Storage for Results
RSS_nestedMC_allLoc = nan(nIndLoc_s, nCand);
R2_nestedMC_allLoc = RSS_nestedMC_allLoc;
nData_nestedMC_allLoc = nan(1, nIndLoc_s);
nParams_nestedMC_allCand = nan(1, nCand);

% Estimated Params and predicted TvCs
R2_criterion = 0.7; % only candidates with R2 higher than this criterion will have their estP and pred saved
est_PTM_nestedMC_allLoc = nan(nIndLoc_s, nCand_max, nLoc_s_max, nParams);

%% Loop Over Each Group of Locations
close all
fprintf('Running Nested MC: ')
for iiIndLoc_s = 1:nIndLoc_s % NOT include the 7-loc group
    fprintf('%d ', iiIndLoc_s)
    % Extract the current location group
    indLoc_s = indLoc_s_all{iiIndLoc_s};
    nLoc_s = length(indLoc_s); % Number of locations in the group
    namesCombLoc_s = namesCombLoc(indLoc_s);
    str_LocSelected = strjoin(namesCombLoc_s, '');
    
    % fprintf('\n[%s SF%d S%d/%d] Fitting %d %s (%s) with %d Candidate Models\n', subjName, SF, isubj, nsubj, nLoc_s, text_locType, str_LocSelected, nCand);    
    
    % Loop Over Each Candidate Model
    for iCand = 1:nCand
        indParamIncl = indParamIncl_allCand(iCand, :); % Current inclusion configuration
        RSS_PTM = nan; R2 = nan; params_est = []; % Initialize fit metrics
        
        % Ensure at least two parameter is included
        if sum(indParamIncl) > 0
            flag_repeat = 1; % Retry flag for invalid fits
            nRepeat = 0; % Retry counter
            
            % Filter parameters based on inclusion
            params0 = params0_def(indParamIncl == 1);
            lb = lb_def(indParamIncl == 1);
            ub = ub_def(indParamIncl == 1);
                        
            % Retry loop for fitting
            while flag_repeat
                %--------------------------------------------------------------------------------%
                % Fit the model
                [params_est, threshEnergy_pred, RSS_PTM, R2] = fitTvC_PTM_nestedMC(indParamIncl, noiseEnergy_true, threshEnergy(indLoc_s, :, :), dprimes, SF_fit, params0, lb, ub, flag_weightedFitting, nData_perLoc(indLoc_s, :), 0);
                %--------------------------------------------------------------------------------%
                
                % Check if parameter estimates are valid
                if all(~isnan(params_est) & ~isinf(params_est))
                    flag_repeat = 0; % Exit retry loop
                else
                    nRepeat = nRepeat + 1;
                    fprintf('NaN detected in params_est for iLoc = %d. Retrying... (Attempt %d)\n', iiIndLoc_s, nRepeat);
                end
                
                % Prevent infinite retries
                if nRepeat > 5
                    fprintf('Too many retries for iLoc = %d. Skipping...\n', iiIndLoc_s);
                    flag_repeat = false; % Exit retry loop with NaNs
                end
            end
        end
        
        % Store fit metrics for the current candidate
        RSS_nestedMC_allLoc(iiIndLoc_s, iCand) = RSS_PTM;
        R2_nestedMC_allLoc(iiIndLoc_s, iCand) = mean(R2(:));
        nParams_nestedMC_allCand(iCand) = length(params_est(:));
        
        % Store estimated params for Cand 15 and 16 
        % convert params_est to a saveable format
%         params_save = nan(nLoc_s_max, nParams_full);
%         switch nLoc_s
%             case 2
%                 switch iCand
%                     case 15, params_save = [params_est; nan(1, length(params0))]; params_save = [nan(nLoc_s_max, 1), params_save];
%                     case 16, params_save = [params_est; nan(1, length(params0))];
%                 end
%             case 3
%                 switch iCand
%                     case 15, params_save = [nan(nLoc_s, 1), params_est];
%                     case 16, params_save = params_est;
%                 end
%         end
%         est_PTM_nestedMC_allLoc(iiIndLoc_s, iCand, 1:size(params_save,1), 1:size(params_save,2)) = params_save;
        
        %% Plot data and pred in three scales
        if flag_plotNestedMC && R2_nestedMC_allLoc(iiIndLoc_s, iCand)>.7
            
            %------------------------------------------------------------------------------------%
            % predict interpolated TvC (for plotting)
            threshEnergy_pred_intp = fxn_PTM_nestedMC(indParamIncl, dprimes, noiseEnergy_intp_true, params_est, SF_fit);
            %------------------------------------------------------------------------------------%
            threshEnergy_pred_intp = reshape(threshEnergy_pred_intp, [nLoc_s, nIntp, nPerf]);
            
            figure('Position', [100 100 1.2e3 800])
            for iiLoc = 1:nLoc_s
                subplot(3, nLoc_s, iiLoc), hold on, grid on
                xlabel('Noise Energy'), ylabel('Thresh Energy')
                plot((10.^noiseSD_log_all).^2, squeeze(threshEnergy(indLoc_s(iiLoc), :, :)), '--ko')
                plot(noiseEnergy_intp_true, squeeze(threshEnergy_pred_intp(iiLoc, :, :)), 'b-')
                % title(sprintf('[%s] R2=%.2f %.2f %.2f\nEst Params: [%s]', namesCombLoc_s{iiLoc}, R2(iiLoc, :), num2str(round(params_save(iiLoc, :), 2))))
                str_R2 = strjoin(arrayfun(@(x) sprintf('%.2f', x), R2(iiLoc, :), 'UniformOutput', false), ' ');
                str_estP = strjoin(arrayfun(@(x) sprintf('%.2f', x), params_save(iiLoc, :), 'UniformOutput', false), ' ');
                title(sprintf('[%s] R2 = [%s]\nEst Params: [%s]', namesCombLoc_s{iiLoc}, str_R2, str_estP))

                subplot(3, nLoc_s, iiLoc + nLoc_s), hold on, grid on
                xlabel('Noise SD (ln cst)'), ylabel('Thresh SD (lnr cst)')
                plot(10.^noiseSD_log_all, sqrt(squeeze(threshEnergy(indLoc_s(iiLoc), :, :))), '--ko')
                plot(sqrt(noiseEnergy_intp_true), sqrt(squeeze(threshEnergy_pred_intp(iiLoc, :, :))), 'b-')

                subplot(3, nLoc_s, iiLoc+ nLoc_s*2), hold on, grid on
                xlabel('Noise SD (log cst)'), ylabel('Thresh SD (log cst)')
                plot(noiseSD_log_all, log10(sqrt(squeeze(threshEnergy(indLoc_s(iiLoc), :, :)))), '--ko')
                plot(noiseSD_intp_log_true, log10(sqrt(squeeze(threshEnergy_pred_intp(iiLoc, :, :)))), 'b-')
                
            end % iiLoc
            sgtitle(sprintf('[%s] %s\nPTM M%d [%s] R^2=%.2f', subjName, str_LocSelected, iCand, num2str(indParamIncl), R2_nestedMC_allLoc(iiIndLoc_s, iCand)))
            
            % save figure
            nameFolder_fig = sprintf('Fig/acrossSFs/SF456/MC/MC_Nested/IdvdFits/%s', str_LocSelected);
            if isempty(dir(nameFolder_fig)), mkdir(nameFolder_fig); end
            saveas(gcf, sprintf('%s/%s_SF%d_M%d.jpg', nameFolder_fig, subjName, SF, iCand));
        end % if flag_plot && any(iCand == [15, 16])
        
    end % iCand (parfor)
    
    % Store results for nested model comparison
    nData_nestedMC_allLoc(iiIndLoc_s) = nLoc_s * nNoise * nPerf;
    close all
end % iIndLoc_s

% fprintf('\n ================== NESTED MC DONE ==================\n\n')

fprintf('\n')
