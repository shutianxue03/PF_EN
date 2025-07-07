% function OOD_IO(SF, noiseMode, isubj_batch)

% estimate simulate trials of an ideal observer and estimate limiting factors
close all
clc
format compact
warning off
addpath(genpath('SX_toolbox/')); % SX
addpath(genpath('fxn_exp/'));
addpath(genpath('fxn_analysis/')); % SX

time_start = datetime('now');

%%
%--------------------%
SX_analysis_setting
%--------------------%
nsubj = 100;
flag_binData = 1;
flag_filterData = 1; % no filtering because don't know where to put the extra two points
flag_plot = 0;
switch noiseMode
    case 1, params.extNoiseLvl = [0, .055, .11, .165, .22, .275, .33];
    case 2, params.extNoiseLvl = [0 .055 .11 .165 .22 .33 .44];
    case 3, params.extNoiseLvl = [0, 5:5:20, 30, 40, 50, 65, 80]/100;%sqrt(linspace(.01^2, .8^2, 10));
end
nNoise = length(params.extNoiseLvl);

%% folder & file name
nameFolder = sprintf('Data_IdealObserver/SF%d_NoiseMax%d', SF, noiseMode);
nameFolder_fig_idvd = 'Fig/IO/IDVD'; if isempty(dir(nameFolder_fig_idvd)), mkdir(nameFolder_fig_idvd), end
if isempty(dir(nameFolder)), mkdir(nameFolder), end
%nameFile = sprintf('%s/S%d', nameFolder, isubj_batch);

nModels = length(PMF_models);
threshEnergy_stair_allSubj = nan(nsubj, nNoise);
Neq_stair_allSubj = nan(nsubj, 1);
DIdeal_stair_allSubj = Neq_stair_allSubj;
R2_stair_allSubj = Neq_stair_allSubj;

threshEnergy_PMF_allSubj = nan(nsubj, nModels, nNoise);
Neq_PMF_allSubj = nan(nsubj, nModels);
DIdeal_PMF_allSubj = Neq_PMF_allSubj;
R2_PMF_allSubj = Neq_PMF_allSubj;

%% Stimulus params
visual.bgColor = .5;
visual.ppd = 32;
visual.degPerCm = 1;
visual.fNyquist = 0.5;

params.gaborexc = 0; % only simulate at fovea
params.nLoc = 1;
params.gaborsiz = 3.3.*visual.ppd;
params.patchsiz = 3.*visual.ppd;
params.gaborenvelopedev = 1.*visual.ppd;
params.gaborangle = [135 45];
params.gaborfrequency = SF/visual.ppd;
params.gaborexc = round(params.gaborexc);
params.gaborsiz = round(params.gaborsiz/2)*2;

cst_ln_min = .1/100;
cst_ln_max = 50/100;
params.startLvl = log10([cst_ln_min, cst_ln_max, cst_ln_min, cst_ln_max]);
params.stairRule = [3 3 2 2];
params.stairStep = [.2 .1 .05]; % do NOT change to log values
nTrialsPerStair = 10;
params.catchLvl = log10([cst_ln_min, 1]);
nTrialsCatch = [30, 30]; % # of catch trials at the lowest/highest level

params.stairStopRule = 100;
params.maxVal = log10(cst_ln_max);
params.minVal = log10(cst_ln_min);

nLoc = params.nLoc;
nStairs = length(params.startLvl);
nNoise = length(params.extNoiseLvl);
nRepet = 100; % need ~5-6, but design up to 10 just to be safe

for isubj = 1:nsubj
    fprintf('\n\n    *** S%d/%d ***\n', isubj, nsubj)
    
    %% prepare trials
    [sequenceMatrix, UD] = IO_prepareTrials(nRepet, nLoc, nNoise, nStairs, ...
        nTrialsPerStair, nTrialsCatch, params); %[iLoc, iNoise, iStair, ORI]
    ntrials =  size(sequenceMatrix, 1);
    
    %% run exp and simulate responses
    correctness_all = nan(ntrials, 1);
    cst_all = correctness_all;
    internalVar_all = correctness_all;
    
    for itrial = 1:ntrials % cannot do parfor
        run = sequenceMatrix(itrial, :); %[iLoc, iNoise, iStair, ORI]
        %-------------------------------------------------------
        [correctness, cst, UD, internalVar] = IO_runTrial(UD, run, params, visual);
        %-------------------------------------------------------
        correctness_all(itrial) = correctness;
        cst_all(itrial) = cst;
        internalVar_all(itrial) = internalVar;
        
    end % itrial
    
    %% plot the distribution of Internal variable
%     iNoise = 10;
%     IV_L = internalVar_all(sequenceMatrix(:, 2)==iNoise & sequenceMatrix(:, 4)==1);
%     IV_R = internalVar_all(sequenceMatrix(:, 2)==iNoise & sequenceMatrix(:, 4)==2);
%     
%     nBins=20;
%     figure, hold on
%     histogram(-IV_L, nBins, 'FaceColor', 'r','FaceAlpha',.3, 'Normalization', 'probability')
%     histogram(IV_R,  nBins, 'FaceColor', 'b','FaceAlpha',.3,'Normalization', 'probability')
%     xlim([-2, 2])
    
    %% fit PMF
    % sequenceMatrix: [iLoc, iNoise, iStair, ORI]
    ccc = [sequenceMatrix(:, [1,2]), cst_all, correctness_all, sequenceMatrix(:,3)];
    
    SX_analysis_setting
    
    fit.gammaguess = [.49, .51];
    fit.lambdaguess = [0, .01];
    fit.paramsFree = [1 1 1 1]; % 1=free to vary, 0=fixed
    fit.guessLimits = fit.gammaguess;
    fit.lapseLimits =fit.lambdaguess;
    fit.searchGrid = struct('alpha', fit.alphaguess,'beta', fit.betaguess,'gamma',fit.gammaguess, 'lambda',fit.lambdaguess);
    
    yfit_allB = cell(nNoise, nModels);
    thresh_allB = nan(fit.nBoot, nNoise, nModels, nPerf);
    iLoc = 1;
    
    for iNoise = 1:nNoise
        fprintf('\n Noise #%d: ', iNoise)
        ccc_full = ccc(ccc(:, 2)==iNoise, :);
        
        %------------%
        fxn_fitPMF_IO
        %------------%
    end % iNoise
    fprintf('\n')
    
    %% plot
    iPerf_plot = 3;
    
    if flag_plot, figure('Position', [0 0 2e3 600]), end
    
    for iNoise=1:nNoise
        
        if flag_plot
            subplot(2,nNoise,iNoise), hold on
            %------------%
            fxn_plotPMF_IO
            %------------%
            
            subplot(2,nNoise,iNoise+nNoise), hold on
        end
        
        %------------%
        fxn_plotStair_IO
        %------------%
        
    end % iNoise
    
    if flag_plot
        set(findall(gcf, '-property', 'LineWidth'), 'LineWidth',1.5)
        set(findall(gcf, '-property', 'fontsize'), 'fontsize',12)
        saveas(gcf, sprintf('%s/S%d_PMF_stair.jpg', nameFolder_fig_idvd, isubj))
    end
    
    %% fit LAM
    % combine staircase and 4 models
    namesData = ['Stair', PMF_models];
    nData = length(namesData);
    colors = ['k', colors_allM];
    thresh_log = nan(nData, nNoise);
    str_legend = cell(1, nData);
    
    thresh_log(1, :) = thresh_log_stair;
    for iModel = 1:nModels
        thresh_log(iModel+1, :)= getCI(thresh_allB(:, :, iModel, iPerf_plot), 1, 1);
    end
    
    noiseEnergy = params.extNoiseLvl.^2;
    xlabels_all = {'Noise cst (%)', 'Noise energy (c^2)'};
    ylabels_all = {'Thresh cst (%)', 'Thresh energy (c^2)'};
    
    for flag_plotEnergy = [1,0] % 1=energy as a fxn of energy, 0=cst as a fxn of cst
        switch flag_plotEnergy
            case 1, fxn_conv = @(x) x;
            case 0, fxn_conv = @(x) sqrt(x)*100;
        end
        
        if flag_plot, figure, hold on, end
        
        for iData = 1:nData
            if isnan(thresh_log(iData, 1)), thresh_log(iData, 1)=-3; end
                
            if any(isnan(thresh_log(iData, :)))
                continue % if there is any nan values, just skip
            else
                threshEnergy = (10.^thresh_log(iData, :).^2);
                [D_est, Neq_energy_est, pred, R2] = lam_tvcFit(noiseEnergy, threshEnergy, params0, lb, ub); % inputs have to be energy!!
                Neq_cst_est = sqrt(Neq_energy_est);
                
                if iData==1
                    threshEnergy_stair_allSubj(isubj, :) = threshEnergy;
                    Neq_stair_allSubj(isubj) = Neq_energy_est;
                    DIdeal_stair_allSubj(isubj) = D_est;
                    R2_stair_allSubj(isubj) = R2;
                else
                    iModel = iData-1;
                    threshEnergy_PMF_allSubj(isubj, iModel, :) = threshEnergy;
                    Neq_PMF_allSubj(isubj, iModel) = Neq_energy_est;
                    DIdeal_PMF_allSubj(isubj, iModel) = D_est;
                    R2_PMF_allSubj(isubj, iModel) = R2;
                end
                
                if flag_plot
                    plot(fxn_conv(noiseEnergy), fxn_conv(threshEnergy), ['o', colors{iData}], 'MarkerFaceColor', 'w', 'HandleVisibility', 'off')
                    plot(fxn_conv(noiseEnergy), fxn_conv(pred), ['-',colors{iData}])
                    xline(fxn_conv(Neq_energy_est), colors{iData});
                end
                str_legend{iData} = sprintf('%s: Neq=%.2f%%, D=%.4f (R^2=%.0f%%)\n', ...
                    namesData{iData}, Neq_cst_est*100, D_est, R2*100);
            end
        end % iData
        if flag_plot
            xticks(fxn_conv(noiseEnergy)), xticklabels(round(params.extNoiseLvl*100))
            %             yticks(y_ticks), yticklabels(round(sqrt(y_ticks)*100, 1))
            xlabel(xlabels_all{flag_plotEnergy+1})
            ylabel(ylabels_all{flag_plotEnergy+1})
            set(findall(gcf, '-property', 'fontsize'), 'fontsize',15)
            set(findall(gcf, '-property', 'linewidth'), 'linewidth',2)
            legend(str_legend, 'Location', 'best')
            saveas(gcf, sprintf('%s/S%d_TvC.jpg', nameFolder_fig_idvd, isubj))
        end
    end % flag_
end % isubj

%% save for each batch of simulated subj
save(nameFile, '*_allSubj', 'noiseEnergy')

time_end = datetime('now');

time_end - time_start

