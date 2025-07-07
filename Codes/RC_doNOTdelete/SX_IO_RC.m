
clear all, clc, close all
format compact
warning off
addpath(genpath('SX_toolbox/')); % SX
addpath(genpath('fxn_exp/'));
addpath(genpath('fxn_analysis/')); % SX
addpath(genpath('Data_IdealObserver/')); % SX

%%
SF = 6;%input('        >>> Enter SF: ');
noiseMode = 3;% input('        >>> Enter noise mode (1=max is 0.33, 2=max is 0.44): ');
%------------------%
SX_analysis_setting
%------------------%

nBatch = 1; % number of batchs
nsubjPerBatch = 10; % number of simulated subj per batch
nsubjTotal = nBatch*nsubjPerBatch;

switch noiseMode
    case 1, params.extNoiseLvl = [0, .055, .11, .165, .22, .275, .33];
    case 2, params.extNoiseLvl = [0 .055 .11 .165 .22 .33 .44];
    case 3, params.extNoiseLvl = [0, 5:5:20, 30, 40, 50, 65, 80]/100;%sqrt(linspace(.01^2, .8^2, 10));
end
nNoise = length(params.extNoiseLvl);

nameFolder_fig_IO = sprintf('Fig/IO/SF%d_NoiseMax%d', SF, noiseMode); if isempty(dir(nameFolder_fig_IO)), mkdir(nameFolder_fig_IO), end

for iModel = 1:nModels%input('         >>> Which model (enter nan if choose the best model): ');
    % noiseEnergy = nan(nsubj_total, nNoise);
    threshEnergy_AllSubj = nan(nsubjTotal, nNoise);
    Neq_PMF_AllSubj = nan(nsubjTotal,1);
    Neq_stair_AllSubj = Neq_PMF_AllSubj;
    DIdeal_PMF_AllSubj = Neq_PMF_AllSubj;
    DIdeal_stair_AllSubj = Neq_PMF_AllSubj;
    R2_PMF_AllSubj = Neq_PMF_AllSubj;
    R2_stair_AllSubj = Neq_PMF_AllSubj;
    
    nameFolder = sprintf('Data_IdealObserver/SF%d_NoiseMax%d', SF, noiseMode);
    
    for isubjBatch = 1:nBatch
        nameFile = sprintf('%s/S%d', nameFolder, isubjBatch);
        load(nameFile)
        
        isubj_start = (isubjBatch-1)*nsubjPerBatch+1;
        isubj_end = isubj_start+nsubjPerBatch-1;
        
        threshEnergy_stair_AllSubj(isubj_start: isubj_end, :) = threshEnergy_stair_allSubj;
        Neq_stair_AllSubj(isubj_start: isubj_end) = Neq_stair_allSubj;
        DIdeal_stair_AllSubj(isubj_start: isubj_end) = DIdeal_stair_allSubj;
        R2_stair_AllSubj(isubj_start: isubj_end) = R2_stair_allSubj;
        
        threshEnergy_AllSubj(isubj_start: isubj_end, :) = threshEnergy_PMF_allSubj(:, iModel, :);
        Neq_PMF_AllSubj(isubj_start: isubj_end, :) = Neq_PMF_allSubj(:, iModel);
        DIdeal_PMF_AllSubj(isubj_start: isubj_end, :) = DIdeal_PMF_allSubj(:, iModel);
        R2_PMF_AllSubj(isubj_start: isubj_end, :) = R2_PMF_allSubj(:, iModel);
    end
    
    %%%%%%%% PLOT %%%%%%%%
    %     load(sprintf('Data/nNoise%d/SF%d/IdealObserver_B%d', nNoise, SF, nsubj), '*_allSubj')
    close all, clc
    
    title_DIdeal = 'Distribution of Ideal D (slope)';
    title_Neq = 'Distribution of Neq';
    
    figure('Position', [0 200 2e3 300])
    x = noiseEnergy;
    for ii = 1:2 % 1=from staircase, 2=threshold estimated from PMF
        switch ii
            case 1, y=threshEnergy_stair_AllSubj; Neq_allSubj = Neq_stair_AllSubj; DIdeal_allSubj = DIdeal_stair_AllSubj; R2_allSubj = R2_stair_AllSubj; color = 'r';title_ = 'Stair';
            case 2, y=threshEnergy_AllSubj; Neq_allSubj = Neq_PMF_AllSubj; DIdeal_allSubj = DIdeal_PMF_AllSubj; R2_allSubj = R2_PMF_AllSubj; color = 'k';title_ = 'PMF';
        end
        
        Neq_allSubj = log10(sqrt(Neq_allSubj));% convert to log cst
        [Neq_med, Neq_lb, Neq_ub] = getCI(Neq_allSubj, 1, 1);
        [DIdeal_med, DIdeal_lb, DIdeal_ub] = getCI(DIdeal_allSubj, 1, 1);
        [R2_med, R2_lb, R2_ub] = getCI(R2_allSubj, 1, 1);
        
        switch ii, case 1, R2_med_stair = R2_med; case 2, R2_med_PMF = R2_med; end
        
        %     x = noiseEnergy;
       [x_med, x_lb, x_ub] = getCI(x, 1, 1);
        [y_med, y_lb, y_ub] = getCI(y, 1, 1);
        
        subplot(1,3,1), hold on
        plot(x_med, y_med, ['-o', color], 'LineWidth', 2)
        patch([x_lb, flip(x_ub)], [y_lb, flip(y_ub)], color, 'FaceAlpha', .2, 'linestyle', 'none', 'handlevisibility', 'off')
        xticks(x_med)
        xticklabels(params.extNoiseLvl)
        ylim([0, .01])
        xlabel('External noise (energy)')
        ylabel('Ideal threshold (energy)')
        title(sprintf('[SF=%d, Model#%d-%s] nsubj = %d', SF, iModel, PMF_models{iModel},nsubjTotal))
        if ii==2
            legend({sprintf('Stair (R^2=%.0f%%)', R2_med_stair*100), sprintf('PMF (R^2=%.0f%%)', R2_med_PMF*100)}, 'Location', 'best')
        end
        
        subplot(1,3,2), hold on
        histogram(DIdeal_allSubj, 'FaceColor', color, 'FaceAlpha', .3, 'Normalization', 'probability')
        xline(DIdeal_med, color, 'linewidth', 2);
        title_DIdeal = [title_DIdeal, sprintf('\n%s: %.4f [%.4f, %.4f]', title_, DIdeal_med, DIdeal_lb, DIdeal_ub)];
        title(title_DIdeal)
        
        subplot(1,3,3), hold on
        histogram(Neq_allSubj, 'FaceColor', color, 'FaceAlpha', .3, 'Normalization', 'probability')
        xline(Neq_med, color, 'linewidth', 2);
        title_Neq= [title_Neq, sprintf('\n%s: %.4f [%.4f, %.4f]', title_, Neq_med, Neq_lb, Neq_ub)];
        title(title_Neq)
        
    end
    set(findall(gcf, '-property', 'fontsize'), 'fontsize',15)
    
    saveas(gcf, sprintf('%s/M%d.jpg', nameFolder_fig_IO, iModel))
    fprintf('\n\nSF=%d, Max. noise = %.2f, ideal slope = %.4f\n\n', SF, max(params.extNoiseLvl), DIdeal_med)
    
end % iModel

close all


