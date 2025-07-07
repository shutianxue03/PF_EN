

% Filter property is controlled by three parameters:
% - ori deviance
% - SF scaling
 % - cst scaling

 % On each trial (a certain noise level), the response varaible is the stimulus (gabor+noise)
 % multiplied with the template (optimal gabor modified by the parameter),
 % plus multiplicative noise (Nmul) and addtive noise (Nadd), then going
 % through nonlinear fxn (r.g., a power function). 
 % response variable as a fuction of signal contrast --> threshold
 % threshold as a function of noise level 

 ori_dev = 5; % in deg of polar angle, [0,90]
 SF_base = 2;
 SF_scl = .8; % ratio, used on log2(SF), [0, 1.5], 0 is hard, 1.5 is soft ()
 cst_scl = .6;
 
 %% visualize corrupted SF as a fxn of base SF and scaling factor
 SF_lb=2;
 SF_ub = 8;
 SF_base_all = 2.^linspace(log2(.5), log2(16), 10); nSF_base = length(SF_base_all);
 SF_scl_all = linspace(.1, 1.5, 10); nSF_scl = length(SF_scl_all);
 SF_new_all = nan(nSF_base_all, nSF_scl_all);
 for iSF_base = 1:nSF_base
     for iSF_scl = 1:nSF_scl
         SF_base = SF_base_all(iSF_base);
         SF_scl = SF_scl_all(iSF_scl );
         SF_new_all(iSF_base, iSF_scl) = 2^(log2(SF_base)*SF_scl);

     end
 end
 figure, hold on
 imagesc(SF_base_all, SF_scl_all, SF_new_all') % transpose is needed to match x and y axis
 % Add contour at level 8 and label it
 [C_lb, hContour_lb] = contour(SF_base_all, SF_scl_all, SF_new_all', [SF_lb, SF_lb], 'LineColor', 'r', 'LineWidth', 2);
 [C_ub, hContour_ub] = contour(SF_base_all, SF_scl_all, SF_new_all', [SF_ub, SF_ub], 'LineColor', 'r', 'LineWidth', 2);
 clabel(C_lb, hContour_lb, 'FontSize', 10, 'Color', 'r')  % label the contour
 clabel(C_ub, hContour_ub, 'FontSize', 10, 'Color', 'r')  % label the contour
 xlabel("Base SF")
 ylabel("SF scaling")
 colorbar
 %%

% Generate paths
addpath(genpath('Data_OOD/')); % SX
addpath(genpath('SX_toolbox/')); % SX
addpath(genpath('fxn_analysis/')); % SX
addpath(genpath('fxn_exp/')); % SX

%% Settings
close all, clc
%------------------%
SX_analysis_setting
%------------------%
paramsPTM_true = [0, 2, 0.0001, .0001]; % Nmul, Gamma, Nadd, Gain

flag_plotPerSignalCST = 0; % !!! CAUTION !!! set this to 1 will produce a figure per signal contrast
flag_simPMF = 1;
flag_plotPMF = 1;
flag_plotTvC = 0;
iTvCModel = 2;

SF_all = [4,5,6];
nSF = length(SF_all); markers_allSF = {'s', 'pentagram', 'hexagram'};

perfThresh_all = 75:5:85;
% perfThresh_all = 65:5:85;
nPerf = length(perfThresh_all);

template_cst = 100/100;
template_phase = 0;

signalCST_ln_min = .1/100; signalCST_ln_max = 10/100; % needs to be a tiny range starting from very very low cst, because the threshold of an IO is very low
nSignalCst = 10; signalCst_log_all = linspace(log10(signalCST_ln_min), log10(signalCST_ln_max), nSignalCst); signalCst_ln_all = 10.^signalCst_log_all;
signalCst_ticks = linspace(signalCst_log_all(1), signalCst_log_all(end), 5); signalCst_ticklabels = round(10.^signalCst_ticks, 3);

noise_ln_min = 1/100; noise_ln_max = 44/100;
nNoise = 10; noise_log_all = linspace(log10(noise_ln_min), log10(noise_ln_max), nNoise); noise_ln_all = 10.^noise_log_all;
noise_ticks = linspace(noise_log_all(1), noise_log_all(end), 5); noise_ticklabels = round(10.^noise_ticks, 3);

noiseSD_full = [0 .055 .11 .165 .22 .33 .44 .66 .88]/2;
ORI_deg_all = [135 45];
iORI_theo = 2; % for theoretical prediction, only one orientation is needed; setting it to 1 or 2 should not make any difference

% Setting of simulation
nTrials = 1e3;
ORI_allTrials = [ones(nTrials/2, 1); ones(nTrials/2, 1)*2];
criterion = 0;
visual.bgColor = .5;
visual.ppd = 32;
sz_px = 3.3.*visual.ppd;
sz_px = round(sz_px/2)*2;
env_px = 1.*visual.ppd;

% Setting of fitting LAM
%----------------%
SX_fitTvC_setting
%----------------%
switch iTvCModel
    case 1
        indParamVary = [1,1];
        params0 = params0_LAM;
        lb = lb_LAM;
        ub = ub_LAM;
    case 2
        indParamVary = [1,1,1,1];
        params0 = params0_PTM;
        lb = lb_PTM;
        ub = ub_PTM;
end
flag_weightedFitting = 1;
dprimes = nan;
ErrorTypes_all = {'ErrLogCst', 'ErrLnCst', 'ErrLnEg'}; nErrorTypes = length(ErrorTypes_all);
iErrorType_all = 1;

% Initiate placeholders for LAM fitting
threshEnergy_all = cell(nSF, nPerf, nErrorTypes);
estP_all = threshEnergy_all;
RSS_all = threshEnergy_all;
R2_all = threshEnergy_all;

% Create template (difference of two Gabors)
% Note that the contrast is doubled because cst is divided by 2 in CreateGabor()
template_L = CreateGabor(sz_px, env_px, ORI_deg_all(1)+ori_dev, 2^(log2(SF)*SF_scl)/visual.ppd, template_phase, 2*template_cst*cst_scl);
template_R = CreateGabor(sz_px, env_px, ORI_deg_all(2)-ori_dev, 2^(log2(SF)*SF_scl)/visual.ppd, template_phase, 2*template_cst*cst_scl);
template_diff_2D =  template_L-template_R;
template_diff =  template_L(:)-template_R(:);

%% Loop through each SF
clc
for iSF = 1:nSF
    SF = SF_all(iSF);
    
    SF_px = SF/visual.ppd;
    
    % Loop through each perf level / difficulty
    for iPerf = 1:nPerf
        
        fprintf('nTrials = %d, SF = %d, PerfLevel = %d%%\n', nTrials, SF, perfThresh_all(iPerf))
        
        perfThresh = perfThresh_all(iPerf)/100;
        dprime = 2*norminv(perfThresh/100); % matching LuDosher2008
        
        % Initiate placefolder for signal and thresholds for each noise level
        sigma_sim_allN = nan(1, nNoise);
        sigma_theo_allN = sigma_sim_allN;
        thresh_ln_theo_allN = sigma_sim_allN;
        
        % Loop through each noise level to obtain the contrast threshold
        for iNoise = 1:nNoise
            
            % Extract noise level (linear contrast, or SD)
            noise_ln = noise_ln_all(iNoise);
            
            % Print
            % fprintf('  #%d/%d Noise SD = %.3f ...\n', iNoise, nNoise, noise_ln)
            
            % Calculate the theoretical SD
            sigma_theo = sqrt(sumsqr(template_diff))*noise_ln; % only depends on noiseSD
            sigma_theo_allN(iNoise) = sigma_theo;
            
            % Initiate placefolder for pC for each signal contrast
            pC_theo_all = nan(nSignalCst, 1);
            mu_theo_all =  pC_theo_all;
            if flag_simPMF
                pC_sim_all = nan(nSignalCst, 1);
                mu_sim_all =  pC_theo_all;
                sigma_sim_all = mu_sim_all;
            end
            
            % Loop through signal contrast to obtain the response (pC)
            for iSignalCst = 1:nSignalCst
                
                % Extract signal contrast (linear contrast unit)
                signalCst_ln = signalCst_ln_all(iSignalCst);
                
                % Create a target Gabot
                % Note that the contrast is doubled because cst is divided by 2 in CreateGabor()
                gabor = CreateGabor(sz_px, env_px, ORI_deg_all(iORI_theo), SF_px, template_phase, signalCst_ln *2);
                
                % Calculate the theoretical pC
                mu_theo = sum(gabor(:) .*template_diff);
                mu_theo_all(iSignalCst) = mu_theo;
                
                % Calculate the theoretical PMF
                if iORI_theo==1
                    pC_theo_all(iSignalCst) = 1-normcdf(0, mu_theo, sigma_theo);
                else
                    pC_theo_all(iSignalCst) = normcdf(0, mu_theo, sigma_theo);
                end
                
                % Estimate threshold based on theoretical pC
                [~, iopt] = min(abs(pC_theo_all - perfThresh));
                thresh_ln_theo_allN(iNoise) = signalCst_ln_all(iopt);
                
                % Simulate PMF: create noise patches, calculate Internal Variable and derive responses on each trial
                if flag_simPMF
                    
                    % Initiate placeholders for each trial
                    internalVar_allT = nan(1, nTrials);
                    correctness_allT = internalVar_L_allT;
                    
                    % Loop through each trial
                    for iTrial = 1:nTrials                        
                        % Create a noise patch
                        noisePatch = randn(sz_px, sz_px).*noise_ln;
                        
                        % Create a noisy image
                        stimImg = noisePatch+gabor;
                        
                        % Calculate internal variable
                        internalVar = sum(stimImg(:).*template_diff, 'all');
                        switch iTvCModel
                            case 1
                            case 2                                
                                internalVar_matched = (internalVar*paramsPTM_true(4))^paramsPTM_true(2);
                                noise_mul = randn*internalVar_matched*paramsPTM_true(1);
                                noise_add = randn*paramsPTM_true(3);
                                internalVar = internalVar_matched+noise_mul+noise_add;
                        end
                        
                        % Decide response by comparing the IV to criterion
                        if iORI_theo==1, correctness = internalVar > criterion;  
                        else, correctness = internalVar < criterion;  
                        end
                        %---------------------------------------------------------------------------
                        internalVar_allT(iTrial) = internalVar;
                        correctness_allT(iTrial) = correctness;
                    end %iTrial
                    
                    % Store the simulated mu, sigma and pC
                    mu_sim_all(iSignalCst) = median(internalVar_allT);
                    sigma_sim_all(iNoise) = std(internalVar_allT);
                    pC_sim_all(iSignalCst) = nanmean(correctness_allT);
                    % plot the distribution of IVs
                    if iTvCModel==2
%                         figure, hold on, histogram(internalVar_allT, 'Normalization', 'probability'), xline(0, 'r-', 'linewidth', 2); title(sprintf('Params:[%.2f, %.1f, %.3f, %.1f]\nSignal CST=%.2f, pC=%.2f', paramsPTM_true, signalCst_ln, pC_sim_all(iSignalCst))), ylim([0, .2]), %xlim([-20, 10]), 
                    end
                end %if flag_simPMF
                
            end % iCST
            
            %% Plot simulated and theoretical PMF
            if flag_plotPMF% && iNoise == round(nNoise/2)
                figure, hold on
                % Plot simulated PMF
                if flag_simPMF, plot(signalCst_log_all, pC_sim_all, '-bo'), end
                
                % Plot theoretical PMF and estimated threshold
                plot(signalCst_log_all, pC_theo_all, 'r--', 'LineWidth', 2)
                xline(log10(thresh_ln_theo_allN(iNoise)), 'r-');
                
                % Limits, ticks and labels
                xlabel('Signal contrast')
                xticks(signalCst_ticks), xticklabels(signalCst_ticklabels), xlim(signalCst_log_all([1,end]))
                
                ylabel('Accuracy (pC)')
                ylim([.45, 1]), yline(.5, 'k-'); yline(perfThresh, 'r-');
                
                % Legend
                if flag_simPMF, legend({'Simulated pC', 'Theoretical pC'}), else, legend({'Theoretical pC'}), end
                
                % Title
                title(sprintf('nTrials = %d, SF = %d, PerfLevel = %d%%\nNoise SD = %.2f, Theoretical CST Threshold = %.2f', ...
                    nTrials, SF, perfThresh_all(iPerf), noise_ln, thresh_ln_theo_allN(iNoise)))
            end
            
        end % iNoise
        
        %% fit LAM/PTM for each perf level and SF
        noiseEnergy_true = noise_ln_all.^2;
        threshEnergy = thresh_ln_theo_allN.^2; %this is using predicted threshold, NOT simulated thresholds
        
        % Fit LAM to TvC and estimate params
        nData_perLoc = ones(size(threshEnergy))*nTrials;
        
        for iErrorType = iErrorType_all
            %-----------------------------------------------------------------%
            [estP, ~, RSS, R2] = fitTvC_varyLocMC(iTvCModel, indParamVary, noiseEnergy_true, threshEnergy, dprime, params0, lb, ub, iErrorType, flag_weightedFitting, nData_perLoc, flag_plotTvC);
            %-----------------------------------------------------------------%
            threshEnergy_all{iSF, iPerf, iErrorType} = threshEnergy;
            estP_all{iSF, iPerf, iErrorType} = estP;
            RSS_all{iSF, iPerf, iErrorType} = RSS;
            R2_all{iSF, iPerf, iErrorType} = R2;
            
        end % flag_errorType
    end % iPerf
end % SF

fprintf('\n\n============== DONE ============== \n\n')


%% Plot TvC of each error type, perflevel, and SF
iErrorType_ideal = 1;
fprintf('\nThe ideal slope was caluclated based on %s\n', ErrorTypes_all{iErrorType_ideal})
slope_ideal = nan(nSF, nPerf); % Turns out, ideal slope does not change with SF

wd_line = 2;
sz_marker = 10;color_ = 'k';
lineStyles = {'-', '--', ':'};

noiseEnergy_true = noise_ln_all.^2;

figure('Position', [0 0 2e3 2e3])
isubplot = 1;

for iSF = 1:nSF
    SF = SF_all(iSF);
    
    for iPerf = 1:nPerf
        perfThresh = perfThresh_all(iPerf);
        dprime = 2*norminv(perfThresh/100); % matching LuDosher2008

        subplot(nSF, nPerf, isubplot), hold on, grid on
        
        % Labels and ticks
%         xlabel('External noise SD')
%         x_ticks = noise_ticks;
%         x_ticklabels = noise_ticklabels;
%         xlim([x_ticks(1)-.1, x_ticks(end)+.1]), xticks(x_ticks), xticklabels(x_ticklabels)%, xtickangle(90)
%         
%         ylabel('Contrast threshold');
%         yticks(signalCst_ticks), yticklabels(signalCst_ticklabels),
%         ylim(signalCst_ticks([1, end])) % mute this line to free the range of y-axis
        
        % Title
        title(sprintf('nTrials = %d, SF = %d, PerfLevel = %d%%', nTrials, SF, perfThresh))
        
        str_legends = [];
        
        for iErrorType = iErrorType_all
            
            % Extract Info
            threshEnergy = threshEnergy_all{iSF, iPerf, iErrorType} ;
            estP = estP_all{iSF, iPerf, iErrorType};
            RSS = RSS_all{iSF, iPerf, iErrorType};
            R2 = R2_all{iSF, iPerf, iErrorType};
            
            % To extract the ideal slope based on iErrorType_ideal
            slope_ideal(iSF, iPerf) = estP_all{iSF, iPerf, iErrorType_ideal}(1);
            
            % Predict TvC
            switch iTvCModel
                %-----------------------------------------------------------------%
                case 1, threshEnergy_pred = fxn_LAM(estP, noiseEnergy_intp_true);
                case 2, threshEnergy_pred = fxn_PTM(indParamVary, estP, noiseEnergy_intp_true, dprime);
                    %-----------------------------------------------------------------%
            end
            
            % Fitting line
            plot(noiseSD_intp_log_true, threshEnergy_pred, lineStyles{iErrorType}, 'color', color_, 'LineWidth', wd_line)
            % Data
            plot(noise_log_all, log10(sqrt(threshEnergy)), [lineStyles{iErrorType}, markers_allSF{iSF}], 'color', color_, 'MarkerFaceColor', color_, 'MarkerEdgeColor', 'w', 'MarkerSize', sz_marker, 'LineWidth', wd_line/3, 'HandleVisibility', 'off')
            % Reference lines
            if iTvCModel==1
                xline(log10(sqrt(estP(2))), lineStyles{iErrorType}, 'LineWidth', wd_line/1.5, 'HandleVisibility', 'off');
            end
            
            % legends: errortype, R2, estP
            switch iTvCModel
                case 1, str_estP = sprintf('Slope=%.4f, NeqCst=%.3f', estP(1), sqrt(estP(2)));
                case 2, str_estP = sprintf('Nmul=%.2f, Gamma=%.1f, Nadd=%.4f, Beta=%.1f', estP);
            end
            str_legends = [str_legends, {sprintf('%s (%s) [(R2=%.2f) %s]', ErrorTypes_all{iErrorType}, lineStyles{iErrorType}, R2, str_estP )}];
        end % flag_errorType
        
        % Legend
        legend(str_legends, 'Location', 'best');
        
        isubplot = isubplot+1;
    end % iPerf
end % SF
