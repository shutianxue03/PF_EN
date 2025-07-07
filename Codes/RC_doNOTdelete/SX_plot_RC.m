%%%% PERFORMANCE FIELDS ? EQUIVALENT NOISE %%%%

% 2018 by Antoine Barbot
% started to be adapted by Shutian Xue in Feb, 2023

%%%%%%%%%%%%%%%%%%
% PRESENT STUDY: %
%%%%%%%%%%%%%%%%%%
% Use equivalent noise method and LAM model to characterize the functional
% sources of perceptual inefficiencies as a function of eccentricity and polar angle

% clear all
clear all, close all, clc, format compact, commandwindow; % SX; force the cursor to go automatically to command window

% generate paths
addpath(genpath('Data/')); % SX
addpath(genpath('SX_toolbox/')); % SX
addpath(genpath('fxn_exp/'));
addpath(genpath('fxn_analysis/')); % SX

global constant scr visual participant sequence stimulus response confidence timing params
% do NOT globalized design because it's huge
load('Data/params.mat')

clc, format compact

% generate paths
addpath(genpath('Data/')); % SX
addpath(genpath('SX_toolbox/')); % SX
addpath(genpath('fxn_exp/'));
addpath(genpath('fxn_analysis/')); % SX

%%
nNoise = input('        >>> Enter nNoise: ');
flag_combineEcc4 = input('        >>> Combine ecc=4 (1=YES, 0=NO): ');
if flag_combineEcc4, SF = nan; else, SF = input('        >>> Enter SF: '); end
flag_collapseHM = input('        >>> Collapse HM (1=YES, 0=NO): ');
ianalysisMode = input('        >>> Analysis mode (1=Bin1Filter1, 4=Bin0Filter0): ');

SX_analysis_setting
D_ideal_all = [.0103, .0101, .0087];

switch SF
    case 6
        SF='6';
        subjList= {'SX', 'DT', 'RC', 'HL', 'HH', 'JY', 'MD', 'ZL', 'AD'}; nLoc=5;
        subjList= {'SX', 'DT', 'RC',         'HH', 'JY', 'MD', 'ZL', 'AD'}; nLoc=5;
        noiseLvl_all = [0 .055 .11 .165 .22 .33 .44];
        D_ideal = D_ideal_all(3);
    case 5
        SF='5';
        subjList= {'AB', 'MJ', 'LH', 'SP',  'AS', 'CM'}; nLoc=9;
        noiseLvl_all = [0 .055 .11 .165 .22 .33 .44];
        D_ideal = D_ideal_all(2);
    case 51
        SF='5_JA';
        subjList = {'ec', 'fc', 'il', 'ja', 'jfa', 'zw'}; nLoc=9;
        subjList = {        'fc',      'ja', 'jfa', 'zw'}; nLoc=9;
        noiseLvl_all = [0, 0.055, 0.11, 0.165, 0.22, 0.275, 0.33];
        D_ideal = D_ideal_all(1);
end

if flag_combineEcc4
%     subjList = {'AB', 'MJ', 'LH', 'SP',  'AS', 'CM',       'SX', 'DT', 'RC', 'HL', 'HH', 'JY', 'MD', 'ZL', 'AD'}; nLoc=5;
    subjList = {'AB', 'MJ', 'LH', 'SP',  'AS', 'CM',         'SX', 'DT', 'RC',        'HH', 'JY', 'MD', 'ZL', 'AD'};nLoc=5;
    noiseLvl_all = [0 .055 .11 .165 .22 .33 .44];
% else, if SF=='5', D_ideal = .0068; else, D_ideal = .0088; end% generated from SX_estIdealObs
end

nsubj = length(subjList);
iLoc_tgt_all = 1:nLoc;

%% print info
fprintf('\n    =======================================\n      n=%d [SF = %s] nNoise = %d, nLoc = %d\n    =======================================\n', ...
    nsubj, SF, nNoise, nLoc)

%% load data
flag_binData = analysisModes(ianalysisMode, 1);
flag_filterData = analysisModes(ianalysisMode, 2);

if flag_combineEcc4
    nameFolder_dataOOD = sprintf('Data_OOD/nNoise%d', nNoise);
    nameFile_fitPMF_allSubj = sprintf('%s/ecc4/n%d_fitPMF_B%d_Bin%dFilter%d.mat', ...
        nameFolder_dataOOD, nsubj, fit.nBoot, flag_binData, flag_filterData);
    nameFolder_fig = sprintf('fig/nNoise%d/ecc4/n%d_collapseHM%d', nNoise, nsubj, flag_collapseHM);
else
    nameFolder_dataOOD = sprintf('Data_OOD/nNoise%d/SF%s', nNoise, SF);
    nameFile_fitPMF_allSubj = sprintf('%s/n%d_fitPMF_B%d_Bin%dFilter%d.mat', ...
        nameFolder_dataOOD, nsubj, fit.nBoot, flag_binData, flag_filterData);
    nameFolder_fig = sprintf('fig/nNoise%d/SF%s/n%d_collapseHM%d', nNoise, SF, nsubj, flag_collapseHM);
end
if isempty(dir(nameFolder_fig)), mkdir(nameFolder_fig), end
load(nameFile_fitPMF_allSubj)
fprintf('\n\n ****** LOADED ******\n\n')

%% [Collapse HM] reorganize PSE
if flag_collapseHM
    if flag_combineEcc4
        nameFile_collapseHM = sprintf('%s/ecc4/n%d_fitPMF_collapseHM_B%d_Bin%dFilter%d.mat', ...
            nameFolder_dataOOD, nsubj, fit.nBoot, flag_binData, flag_filterData);
    else
        nameFile_collapseHM = sprintf('%s/n%d_fitPMF_collapseHM_B%d_Bin%dFilter%d.mat', ...
            nameFolder_dataOOD, nsubj, fit.nBoot, flag_binData, flag_filterData);
    end
    
    load(nameFile_collapseHM, 'PSE_best_collapseHM_allSubj')
    PSE_best_allSubj(:, 2, :, :) = PSE_best_collapseHM_allSubj(:, 1, :, :);
    PSE_best_allSubj(:, 4, :, :) = PSE_best_collapseHM_allSubj(:, 1, :, :);
    if nLoc == 9
        PSE_best_allSubj(:, 6, :, :) = PSE_best_collapseHM_allSubj(:, 2, :, :);
        PSE_best_allSubj(:, 8, :, :) = PSE_best_collapseHM_allSubj(:, 2, :, :);
    end
end

%% fig 1: PSE as a fxn of loc and noise (each panel is a LOC)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PSE_best_allSubj = adjustThresh(PSE_best_allSubj, SF);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

iperf = 3;
x_noise = [-1.85, log10(noiseLvl_all(2:end))];
if nNoise==2, figure('Position', [0 0 nLoc*400 300]), ylimits = [-1.1, -.55]; namesLoc = {'UVM', 'Right', 'LVM'};
elseif nNoise==7, figure('Position', [0 0 2e3 2e3]), ylimits = [-1.8, -.3]; namesLoc = namesLoc9;
end
hold on

for iLoc = iLoc_tgt_all
    if nNoise==2, subplot(1, nLoc, find(iLoc==iLoc_tgt_all))
    elseif nNoise==7
        if nLoc==9, subplot(5,5, iplots9(find(iLoc==iLoc_tgt_all)))
        else, subplot(3,3, iplots5(find(iLoc==iLoc_tgt_all)))
        end
    end
    hold on, grid on
    % idvd data
    for isubj=1:nsubj
        plot(x_noise, squeeze(PSE_best_allSubj(isubj, iLoc, :, iperf)), ['-', markers_allSubj{isubj}], ...
            'Color', ones(1,3)/2, 'MarkerSize', 10, 'MarkerFaceColor', 'w')
    end
    %     get mean and SEM
    [PSE_best_ave, ~, ~, PSE_best_sem] = getCI(PSE_best_allSubj(:, iLoc, :, iperf), 2,1);
    %PSE_best_ave is the average of estimation
    errorbar(x_noise, PSE_best_ave', PSE_best_sem', '.-', 'Color', colors9(iLoc, :), 'MarkerSize', 10, 'MarkerFaceColor', 'w', 'CapSize', 0, 'LineWidth', 3)
    
    xticks(x_noise), xticklabels(round(noiseLvl_all*100, 1)), xlim(x_noise([1,end]))
    xlim([x_noise(1)-.1, x_noise(end)+.1])
    ylim(ylimits)
    yticks(linspace(ylimits(1), ylimits(2), 5))
    yticklabels(round(100*10.^linspace(ylimits(1), ylimits(2), 5)))
    ylabel(sprintf('Threshold (%.d%%)', perfPSE_all(iperf)))
    title(namesLoc9{iLoc})
end

legend(subjList, 'NumColumns', round(nsubj/2), 'Location', 'best')
sgtitle(sprintf('n=%d (%d%%) [collapse HM=%d]', nsubj, perfPSE_all(iperf), flag_collapseHM))

if nNoise==2, set(findall(gcf, '-property', 'fontsize'), 'fontsize',18)
else, set(findall(gcf, '-property', 'fontsize'), 'fontsize', 12),
end

saveas(gcf, sprintf('%s/TvC_%d.jpg', nameFolder_fig, perfPSE_all(iperf)))

%% fig 2: PSE as a fxn of loc and noise (each panel is a NOISE)

if nNoise==2, figure('Position', [0 0 nNoise*400 300]), indLoc = [4,5,3]; % nNoise=2, n=5
elseif nNoise==7, figure('Position', [0 0 2e3 2e3]),
    if nLoc==5, indLoc = [1,2,4,5,3]; % nNoise=7, n=6
    else, indLoc = [1,2,4,6,8,5,3,9,7]; % nNoise=7
    end
end
hold on

for iNoise=1:nNoise
    if nNoise==2, subplot(1, nNoise, iNoise)
    elseif nNoise==7, subplot(3,3, iNoise)
    end
    hold on, grid on
    
    % get mean and SEM
    [PSE_best_ave, ~, ~, PSE_best_sem] = getCI(PSE_best_allSubj(:, :, iNoise, iperf), 2,1);
    for iLoc = indLoc%iLoc_tgt_all_reordered
        bar(find(iLoc == indLoc), PSE_best_ave(iLoc), 'FaceColor', 'w', 'EdgeColor', colors9(iLoc, :), 'LineWidth', 2, 'BarWidth', .5, 'HandleVisibility', 'off')
        errorbar(find(iLoc == indLoc), PSE_best_ave(iLoc), PSE_best_sem(iLoc), '.', 'color', colors9(iLoc, :), 'MarkerSize', 10, 'MarkerFaceColor', 'w', 'CapSize', 0, 'LineWidth', 2, 'HandleVisibility', 'off')
    end
    
    % idvd data
    for isubj=1:nsubj
        plot(1:nLoc, squeeze(PSE_best_allSubj(isubj, indLoc, iNoise, iperf)), ['-', markers_allSubj{isubj}], ...
            'Color', ones(1,3)/2, 'MarkerSize', 10, 'MarkerFaceColor', 'w')
    end
    xticks(1:nLoc), xticklabels(namesLoc9(indLoc)),xlim([.5,nLoc+.5]), xtickangle(30)
    ylim(ylimits)
    yticks(linspace(ylimits(1), ylimits(2), 5))
    yticklabels(round(10.^linspace(ylimits(1), ylimits(2), 5)*100))
    ylabel(sprintf('Threshold (%.d%%)', perfPSE_all(iperf)))
    title(sprintf('noise=%.0f%%', noiseLvl_all(iNoise)*100))
end
legend(subjList, 'Location', 'best','NumColumns', round(nsubj/2))
sgtitle(sprintf('n=%d (%d%% perf)', nsubj, perfPSE_all(iperf)))

set(findall(gcf, '-property', 'fontsize'), 'fontsize',13)
saveas(gcf, sprintf('%s/threshPerLoc_%d.jpg', nameFolder_fig, perfPSE_all(iperf)))

%% polar plot
% if nNoise==2, figure('Position', [0 0 nNoise*400 300]), indLoc = [2,3,1]; % nNoise=2, n=5
% elseif nNoise==7, figure('Position', [0 0 2e3 2e3]), indLoc = 1:nLoc; % nNoise=7, n=6
% end
% for iNoise=1:nNoise
%     if nNoise==2, subplot(1, nNoise, iNoise)
%     elseif nNoise==7, subplot(3,3, iNoise)
%     end
%     % get mean and SEM
%     [PSE_best_ave, ~, ~, PSE_best_sem] = getCI(PSE_best_allSubj(:, :, iNoise, iperf), 2,1);
%
%     polarplot([polar_ang, polar_ang(1)], PSE_best_ave([2:5,2]), 'k-'), hold on
%     polarplot([polar_ang, polar_ang(1)], PSE_best_ave([6:9,6]), 'k-'), hold on
%     for iLoc = 2:5, polarplot(polar_ang(iLoc-1), PSE_best_ave(iLoc), 'o', 'color', colors9(iLoc, :), 'LineWidth', 2, 'HandleVisibility', 'off'), hold on, end
%     for iLoc = 6:9, polarplot(polar_ang(iLoc-5), PSE_best_ave(iLoc), 'o', 'color', colors9(iLoc, :), 'LineWidth', 2, 'HandleVisibility', 'off'), hold on, end
%
%     thetaticks(0:90:270)
%     rlim([-2, -.5])
%     rticks(linspace(-2, .5, 3))
%     rticklabels(round(10*10.^linspace(-2, .5, 3)))
%     title(sprintf('noise=%.0f%%', noiseLvl_all(iNoise)*100))
% end
%
% sgtitle(sprintf('n=%d (%d%% perf)', nsubj, perfPSE_all(iperf)))
%
% set(findall(gcf, '-property', 'fontsize'), 'fontsize',15)
% saveas(gcf, sprintf('%s/PSE_polar_%d.jpg', folder_extension, perfPSE_all(iperf)))
%

%% fig 3: quantify asymmetries in thresh
iperf = 3;

thresh_asym_allSubj = nan(nsubj, nNoise, 10);
for iNoise = 1:nNoise
    %=====================================================================================
    [thresh_CombLoc_allSubj, namesAsym, asym_perNoise] = fxn_extractAsym(squeeze(PSE_best_allSubj(:, :, iNoise, iperf)));
    %=====================================================================================
    thresh_asym_allSubj(:, iNoise, 1:length(namesAsym)) = asym_perNoise;
end

figure('Position', [0 0 2e3 2e3])

nasym = length(namesAsym);

for iasym = 1:nasym
    if nsubj==1, thresh_asym_ave= thresh_asym_allSubj(:, iasym); thresh_asym_sem = zeros(nNoise, 1);
    else, [thresh_asym_ave, ~, ~, thresh_asym_sem] = getCI(thresh_asym_allSubj(:, :, iasym), 2, 1);
    end
    
    if nasym<=4, subplot(1,nasym ,iasym)
    else, subplot(2,4 ,iasym),
    end
    hold on
    
    if nsubj>1
        for isubj=1:nsubj%, plot(1:4, HVA_allSubj(isubj, :), '-'),
            plot(1:nNoise, squeeze(thresh_asym_allSubj(isubj, :, iasym)), ['-', markers_allSubj{isubj}], 'Color', ones(1,3)/2, 'MarkerSize', 10, 'MarkerFaceColor', 'w')
        end
    end
    errorbar(1:nNoise, thresh_asym_ave, thresh_asym_sem, 'ok', 'CapSize', 0, 'LineWidth', 2, 'HandleVisibility', 'off')
    
    xticklabels_ = cell(nNoise, 1);
    for iNoise = 1:nNoise
        [~, p, ~, stats] = ttest(squeeze(thresh_asym_allSubj(:, iNoise, iasym)));
        p = p*nNoise;
        pstar=''; if p<.001, pstar='***'; elseif p<.01, pstar = '**'; elseif p<.05, pstar='*';end
        xticklabels_{iNoise} = sprintf('%.0f%%%s', noiseLvl_all(iNoise)*100, pstar);
    end
    xticks(1:nNoise), xticklabels(xticklabels_),xlim([.5,nNoise+.5]), xtickangle(45)
    yline(0, 'color', [.5, .5, .5] ,'linewidth', 2);
    ylim([-15, 30])
    xlabel('Noise (%)')
    ylabel('Asymmetry (%)')
    title(namesAsym{iasym})
    
    if iasym == 1, legend(subjList, 'NumColumns', round(nsubj/3), 'Location', 'best'), end
end

sgtitle(sprintf('n=%d (%d%%)', nsubj, perfPSE_all(iperf)))
set(findall(gcf, '-property', 'fontsize'), 'fontsize',15)

saveas(gcf, sprintf('%s/asym_%d.jpg', nameFolder_fig, perfPSE_all(iperf)))

%% fig 4: asked by Antoine: HVA/VMA as a fxn of CS on HM
% for iasym=1:2 % HVA and VMA
%     if iasym==1, asym=HVA4_allSubj;else, asym=VMA4_allSubj;end
%     figure('Position', [0 0 600 300])
%     for iSF=1:nSF
%         subplot(1,iSF), hold on, grid on
%         for isubj=1:nsubj
%             plot(HM4_allSubj(isubj, iSF), asym(isubj, iSF), ['-', markers_allSubj{isubj}], 'Color', ones(1,3)/2, 'MarkerSize', 10, 'MarkerFaceColor', 'w')
%         end
%         yline(0, 'color', ones(1,3)/2);
%         axis square
%         xlabel('CS on HM')
%         if iasym==1, ylabel('HVA'), ylim([0, 2.5]), yticks([0:.8:2.4])
%         else, ylabel('VMA'), ylim([-.5, 1]), yticks([-.5:.5:1])
%         end
%         xlim([0, 30])
%
%         title(sprintf('SF=%s', SF_all(iSF)))
%     end
%     set(findall(gcf, '-property', 'fontsize'), 'fontsize',15)
%     set(findall(gcf, '-property', 'linewidth'), 'linewidth',2)
%     sgtitle(sprintf('n=%d (%d%%)', nsubj, perfPSE_all(iperf)))
%     if iasym==1, saveas(gcf, sprintf('fig/HVA_CS_n%d_%d.jpg', nsubj, perfPSE_all(iperf)))
%     else, saveas(gcf, sprintf('fig/VMA_CS_n%d_%d.jpg', nsubj, perfPSE_all(iperf)))
%     end
% end

%% fit LAM
clc
noise_energy = noiseLvl_all.^2; % noise energy

Neq_energy_allSubj = nan(nsubj, nLoc);
Eff_allSubj = Neq_energy_allSubj;
R2_allSubj = Neq_energy_allSubj;
TvC_allSubj = cell(nsubj, nLoc);
curveX_energy = linspace(noise_energy(1), noise_energy(end), 1e4);

for isubj = 1:nsubj
    fprintf('    %d/%d %s...', isubj, nsubj, subjList{isubj})
    for iLoc = iLoc_tgt_all
        iiLoc = find(iLoc == iLoc_tgt_all);
        for iperf = 1:nPerf

            PSE_log = squeeze(PSE_best_allSubj(isubj, iLoc, :, iperf)).';
            thresh_energy = (10.^PSE_log).^2; % threshold energy
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % estimate
            [D_est, Neq_energy_est, ~, R2]= lam_tvcFit([1 2], noise_energy, thresh_energy);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            Neq_energy_allSubj(isubj, iiLoc, iperf) = Neq_energy_est;
            if flag_combineEcc4
                if any(strcmp( {'ec', 'fc', 'il', 'ja', 'jfa', 'zw', 'ab', 'aw', 'dc', 'kae', 'mg', 'mr'},subjList{isubj})), D_ideal = D_ideal_all(1); 
                elseif any(strcmp( {'AB', 'MJ', 'LH', 'SP', 'AS', 'CM'},subjList{isubj})), D_ideal = D_ideal_all(2); 
                elseif any(strcmp( {'SX', 'DT', 'RC', 'HL', 'HH', 'JY', 'MD', 'ZL', 'AD'},subjList{isubj})), D_ideal = D_ideal_all(3); 
                end
            end
            Eff_allSubj(isubj, iiLoc, iperf) = D_ideal/D_est;
            R2_allSubj(isubj, iiLoc, iperf) = R2;
            TvC_allSubj{isubj, iiLoc, iperf} = lam_tvc([D_est Neq_energy_est], curveX_energy);
            %[A, ~, ~,B] = getCI(TvC_allSubj{isubj, iiLoc, iperf}, 2, 1);
        end % iperf
    end % iLoc
    fprintf(' DONE\n')
end % isubj


%% RACHEL: fit LAM to average across 8 subjects
clc
noise_energy_avg = noiseLvl_all.^2; % noise energy

Neq_energy_allSubj_avg = nan(1, nLoc);
Eff_allSubj_avg = Neq_energy_allSubj_avg;
R2_allSubj_avg = Neq_energy_allSubj_avg;
TvC_allSubj_avg = cell(1, nLoc);
curveX_energy_avg = linspace(noise_energy_avg(1), noise_energy_avg(end), 1e4);

for iLoc = iLoc_tgt_all
    iiLoc = find(iLoc == iLoc_tgt_all);
    for iperf = 1:nPerf

        %PSE_log = squeeze(PSE_best_allSubj(isubj, iLoc, :, iperf)).';
        PSE_log_mean_avg = squeeze(mean(PSE_best_allSubj(:, iLoc, :, iperf),1,'omitmissing')).';
        thresh_energy_avg = (10.^PSE_log_mean_avg).^2; % threshold energy
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % estimate
        [D_est_avg, Neq_energy_est_avg, ~, R2_avg]= lam_tvcFit([1 2], noise_energy_avg, thresh_energy_avg);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        Neq_energy_allSubj_avg(1, iiLoc, iperf) = Neq_energy_est_avg;
        D_ideal_avg = 0.0087;
        Eff_allSubj_avg(:, iiLoc, iperf) = D_ideal_avg/D_est_avg;
        R2_allSubj_avg(:, iiLoc, iperf) = R2_avg;
        TvC_allSubj_avg{:, iiLoc, iperf} = lam_tvc([D_est_avg Neq_energy_est_avg], curveX_energy_avg);
    end % iperf
end % iLoc
fprintf(' DONE\n')

Neq_log_allSubj_avg = log10(sqrt(Neq_energy_allSubj_avg));
Neq_allSubj_avg = Neq_log_allSubj_avg;

%% Rachel: Plotting TvC after fitting LAM
close all
% Define colors and markers for each participant
colors = lines(nsubj);
for flagEnergy = 1%[1,0]
% Prepare figure
figure('Position', [0 0 2e3 2e3]);
hold on;

for iLoc = 1:nLoc
    % Subplot for each location
    if nLoc == 9
        subplot(5, 5, iplots9(iLoc));
    else
        subplot(3, 3, iplots5(iLoc));
    end
    hold on;grid on;

    % Plot TvC for each participant at the current location
    for isubj = 1:nsubj
        for iperf = 3  % If multiple performances, loop through them
            % Extract TvC data
            PSE_log = squeeze(PSE_best_allSubj(isubj, iLoc, :, iperf)).';
            if flagEnergy
                x_HVA4 = [-3, log10(noise_energy(2:end))]; y_HVA4 = log10((10.^PSE_log).^2); X = log10(curveX_energy); ypred = log10(TvC_allSubj{isubj, iLoc, iperf});
                ylim([-5, 0])
            else
                x_HVA4 = [-2, log10(noiseLvl_all(2:end))]; y_HVA4 = PSE_log; X = log10(sqrt(curveX_energy)); ypred = log10(sqrt(TvC_allSubj{isubj, iLoc, iperf}));
                ylim([-2.4, -.4])
            end

             plot(x_HVA4, y_HVA4, markers_allSubj{isubj}, 'color',colors(isubj,:)); 
             plot(X, ypred, '--','LineWidth', 0.5,'color',colors(isubj,:))

        end %iperf
    end %isub

    % Plot TvC for group average at the current location
    for iperf = 3
        % Extract TvC data for group average
        ypred_avg = log10(TvC_allSubj_avg{1, iLoc, iperf}); % Group average prediction
        % Plot group average prediction
        plot(X, ypred_avg, 'k-', 'LineWidth', 3); % 'k-' denotes a solid black line
    end


    % Set x-ticks, x-labels, and x-limits
    xticks(x_HVA4), xticklabels(round(noiseLvl_all*100)), xlim(x_HVA4([1,end]) + [-.1, .1])
    title(namesLoc9{iLoc});

    hold off;
end %iLoc

% Super title and legend
sgtitle('TvC after fitting LAM for all participants');
legend(subjList, 'NumColumns', round(nsubj / 2), 'Location', 'best');
set(findall(gcf, '-property', 'fontsize'), 'fontsize', 15);
end %flagEnergy

%% RACHEL: Plotting group averaged estimates on top of estimation based on group average for TvC curve
close all;
% Define colors and markers for each participant
colors = lines(nsubj);

for flagEnergy = 1%[1,0]
    % Prepare figure
    figure('Position', [0 0 2e3 2e3]);
    hold on;

    for iLoc = 1:nLoc
        % Subplot for each location
        if nLoc == 9
            subplot(5, 5, iplots9(iLoc));
        else
            subplot(3, 3, iplots5(iLoc));
        end
        hold on; grid on;

        % Plot TvC for each participant at the current location
        for isubj = 1:nsubj
            for iperf = 3  % If multiple performances, loop through them
                % Extract TvC data
                PSE_log = squeeze(PSE_best_allSubj(isubj, iLoc, :, iperf)).';
                if flagEnergy
                    x_HVA4 = [-3, log10(noise_energy(2:end))]; y_HVA4 = log10((10.^PSE_log).^2); X = log10(curveX_energy); ypred = log10(TvC_allSubj{isubj, iLoc, iperf});
                    ylim([-5, 0])
                else
                    x_HVA4 = [-2, log10(noiseLvl_all(2:end))]; y_HVA4 = PSE_log; X = log10(sqrt(curveX_energy)); ypred = log10(sqrt(TvC_allSubj{isubj, iLoc, iperf}));
                    ylim([-2.4, -.4])
                end

                %plot(x_HVA4, y_HVA4, markers_allSubj{isubj}, 'color',colors(isubj,:));
                plot(X, ypred, '--','LineWidth', 0.5,'color',colors(isubj,:))
                hold on;
            end
        end

        % Get mean and SEM for group data
        [PSE_best_ave, ~, ~, PSE_best_sem] = getCI(PSE_best_allSubj(:, iLoc, :, iperf), 2, 1);
        % Convert noise levels to the appropriate scale
        if flagEnergy
            x_noise = [-3, log10(noise_energy(2:end))];
        else
            x_noise = log10(noiseLvl_all);
        end
        errorbar(x_noise, PSE_best_ave', PSE_best_sem', '.-', 'Color', colors9(iLoc, :), 'MarkerSize', 10, 'MarkerFaceColor', 'w', 'CapSize', 0, 'LineWidth', 3);

        % Plot group average TvC
        ypred_avg = log10(TvC_allSubj_avg{1, iLoc, iperf}); % Group average prediction
        plot(log10(curveX_energy), ypred_avg, 'k-', 'LineWidth', 3);

        % Set x-ticks, x-labels, and x-limits
        xticks(x_HVA4), xticklabels(round(noiseLvl_all*100)), xlim(x_HVA4([1,end]) + [-.1, .1]);
        title(namesLoc9{iLoc});

        hold off;
    end

    % Super title and legend
    sgtitle('TvC after fitting LAM for all participants with Group Average');
    legend(subjList, 'NumColumns', round(nsubj / 2), 'Location', 'best');
    set(findall(gcf, '-property', 'fontsize'), 'fontsize', 15);
end


%% TvC (each panel is one loc with all observers, each perf in one panel)
% close all
% for flagEnergy = 1%[1,0]
%     for isubj = 1:nsubj
% 
%         figure('Position', [0 0 2e3 2e3]), hold on
% 
%         for iLoc = 1:nLoc
%             if nLoc==9, subplot(5,5,iplots9(iLoc))
%             else, subplot(3,3,iplots5(iLoc))
%             end
%             hold on, grid on
% 
%             for iperf = 3
%             % for iperf = 1:nPerf
% 
%                 PSE_log = squeeze(PSE_best_allSubj(isubj, iLoc, :, iperf)).';
% 
%                 if flagEnergy
%                     x_HVA4 = [-3, log10(noise_energy(2:end))]; y_HVA4 = log10((10.^PSE_log).^2); X = log10(curveX_energy); ypred = log10(TvC_allSubj{isubj, iLoc, iperf});
%                     ylim([-5, 0])
%                 else
%                     x_HVA4 = [-2, log10(noiseLvl_all(2:end))]; y_HVA4 = PSE_log; X = log10(sqrt(curveX_energy)); ypred = log10(sqrt(TvC_allSubj{isubj, iLoc, iperf}));
%                     ylim([-2.4, -.4])
%                 end
%                 plot(x_HVA4, y_HVA4, markers_allSubj{isubj}, 'color', colors9(iLoc,:) * iperf/nPerf)
%                 plot(X, ypred, '-', 'color', colors9(iLoc,:) * iperf/nPerf, 'LineWidth', 2)
%             end % iperf
% 
%             xticks(x_HVA4), xticklabels(round(noiseLvl_all*100)), xlim(x_HVA4([1,end]) + [-.1, .1])
%             %title(sprintf('R^2 = %.0f%%', mean(R2_allSubj(isubj, iLoc, iperf)*100)))
%             %title(namesLoc9{iLoc})
%             combinedTitle = sprintf('R^2 = %.0f%% - %s', mean(R2_allSubj(isubj, iLoc, iperf) * 100), namesLoc9{iLoc});
%             title(combinedTitle);
% 
%         end % iLoc
%         sgtitle(sprintf('%s %d%% accu [energy %d]', subjList{isubj}, perfPSE_all(iperf), flagEnergy))
%         set(findall(gcf, '-property', 'fontsize'), 'fontsize',15)
%         %             saveas(gcf, sprintf('%s/TvC_energy%d.jpg', nameFolder_fig, flagEnergy))
%     end % isubj
% end


%% TvC (each panel is one loc with all perf levels, EACH subjects in one panel)
% close all
% for flagEnergy = 1%[1,0]
%     for iperf = 1:nPerf
%         figure('Position', [0 0 2e3 2e3]), hold on
% 
%         for iLoc = 1:nLoc
%             if nLoc==9, subplot(5,5,iplots9(iLoc))
%             else, subplot(3,3,iplots5(iLoc))
%             end
%             hold on, grid on
%             for isubj = 1:nsubj
% 
%                 PSE_log = squeeze(PSE_best_allSubj(isubj, iLoc, :, iperf)).';
% 
%                 if flagEnergy
%                     x_HVA4 = [-3, log10(noise_energy(2:end))]; y_HVA4 = log10((10.^PSE_log).^2); X = log10(curveX_energy); ypred = log10(TvC_allSubj{isubj, iLoc, iperf});
%                     ylim([-5, 0])
%                 else
%                     x_HVA4 = [-2, log10(noiseLvl_all(2:end))]; y_HVA4 = PSE_log; X = log10(sqrt(curveX_energy)); ypred = log10(sqrt(TvC_allSubj{isubj, iLoc, iperf}));
%                     ylim([-2.4, -.4])
%                 end
%                 plot(x_HVA4, y_HVA4, markers_allSubj{isubj}, 'color', colors9(iLoc,:) * iperf/nPerf)
%                 plot(X, ypred, '-', 'color', colors9(iLoc,:) * iperf/nPerf, 'LineWidth', 2)
%             end % isubj
%             xticks(x_HVA4), xticklabels(round(noiseLvl_all*100)), xlim(x_HVA4([1,end]) + [-.1, .1])
% 
%             title(sprintf('R^2=%.0f%%', mean(R2_allSubj(isubj, iLoc, iperf)*100)))
%         end % iLoc
%         sgtitle(sprintf('n=%d %d%% accu [energy %d]', nsubj, perfPSE_all(iperf), flagEnergy))
%         set(findall(gcf, '-property', 'fontsize'), 'fontsize',15)
%         %             saveas(gcf, sprintf('%s/TvC_energy%d.jpg', nameFolder_fig, flagEnergy))
%     end % iperf
% end

%% TvC (each panel is one loc with all observers, each perf in one panel)
% close all
% for flagEnergy = 1%[1,0]
%     for isubj = 1:nsubj
% 
%         figure('Position', [0 0 2e3 2e3]), hold on
% 
%         for iLoc = 1:nLoc
%             if nLoc==9, subplot(5,5,iplots9(iLoc))
%             else, subplot(3,3,iplots5(iLoc))
%             end
%             hold on, grid on
% 
%             for iperf = 1:nPerf
% 
%                 PSE_log = squeeze(PSE_best_allSubj(isubj, iLoc, :, iperf)).';
% 
%                 if flagEnergy
%                     x_HVA4 = [-3, log10(noise_energy(2:end))]; y_HVA4 = log10((10.^PSE_log).^2); X = log10(curveX_energy); ypred = log10(TvC_allSubj{isubj, iLoc, iperf});
%                     ylim([-5, 0])
%                 else
%                     x_HVA4 = [-2, log10(noiseLvl_all(2:end))]; y_HVA4 = PSE_log; X = log10(sqrt(curveX_energy)); ypred = log10(sqrt(TvC_allSubj{isubj, iLoc, iperf}));
%                     ylim([-2.4, -.4])
%                 end
%                 plot(x_HVA4, y_HVA4, markers_allSubj{isubj}, 'color', colors9(iLoc,:) * iperf/nPerf)
%                 plot(X, ypred, '-', 'color', colors9(iLoc,:) * iperf/nPerf, 'LineWidth', 2)
%             end % iperf
% 
%             xticks(x_HVA4), xticklabels(round(noiseLvl_all*100)), xlim(x_HVA4([1,end]) + [-.1, .1])
%             title(sprintf('R^2 = %.0f%%', mean(R2_allSubj(isubj, iLoc, iperf)*100)))
%         end % iLoc
%         sgtitle(sprintf('%s %d%% accu [energy %d]', subjList{isubj}, perfPSE_all(iperf), flagEnergy))
%         set(findall(gcf, '-property', 'fontsize'), 'fontsize',15)
%         %             saveas(gcf, sprintf('%s/TvC_energy%d.jpg', nameFolder_fig, flagEnergy))
%     end % isubj
% end

%% threshold ratio (LuDosher1999)
% ratio = pse of any perf level / pse of the highest perf level
close all
nPair = nPerf-1;
ratio_allSubj = nan(nsubj, nLoc, nNoise, nPair);
for isubj = 1:nsubj
%     figure('Position', [0 0 2e3 2e3])
    
    for iLoc = 1:nLoc
%         if nLoc==9, subplot(5,5,iplots9(iLoc))
%         else, subplot(3,3,iplots5(iLoc))
%         end
%         hold on, grid on
%         legends = {};
        for iperf = 1:nPair
            PSE_log1 = squeeze(PSE_best_allSubj(isubj, iLoc, :, iperf)).';
            PSE_log2 = squeeze(PSE_best_allSubj(isubj, iLoc, :, end)).';
            ratio= PSE_log1./PSE_log2;
            ratio_allSubj(isubj, iLoc, :, iperf) = ratio;
%             plot(1:nNoise, ratio, 'o-', 'color', colors9(iLoc,:) * iperf/nPair)
%             legends{iperf} = sprintf('%d vs. %d', perfPSE_all(iperf), perfPSE_all(end));
        end % iperf
%         xticks(1:nNoise), xticklabels(round(noiseLvl_all*100)), xlim([0, nNoise+1])
%         ylim([.8, 1.5]), yline(1, 'k-', 'linewidth', 1.5);
%         legend(legends, 'Location', 'northwest')
    end % iLoc
    
%     sgtitle(sprintf('Thresh ratio between perf levels - %s', subjList{isubj}))
%     saveas(gcf, sprintf('%sthreshRatio.jpg', nameFolder_fig))
    
end % isubj

close all

%% %%%% Group average
%%% ANOVA
indLoc_ANOVA = nan(size(ratio_allSubj));indNoise_ANOVA = indLoc_ANOVA; indPair_ANOVA = indLoc_ANOVA;
for isubj = 1:nsubj
    indLoc_ANOVA(isubj, :, :, :) = repmat((1:nLoc)', [1, nNoise, nPair]);
    indNoise_ANOVA(isubj, :, :, :) = repmat(1:nNoise, [nLoc, 1, nPair]);
    for iLoc = 1:nLoc
        indPair_ANOVA(isubj, iLoc, :, :) = repmat(1:nPair, [nNoise, 1]);
    end
end
text_ANOVA = print_nANOVA({'Loc', 'Noise', 'Pair'}, ratio_allSubj(:), {indLoc_ANOVA(:), indNoise_ANOVA(:), indPair_ANOVA(:)}, nsubj);

[ratio_ave, ~, ~, ratio_SEM] = getCI(ratio_allSubj, 2, 1);
figure('Position', [0 0 2e3 2e3])

for iLoc = 1:nLoc
    if nLoc==9, subplot(5,5,iplots9(iLoc))
    else, subplot(3,3,iplots5(iLoc))
    end
    hold on, grid on
    legends = {};
    for iperf = 1:nPair
        errorbar(1:nNoise, ratio_ave(iLoc, :, iperf), ratio_SEM(iLoc, :, iperf), '.-', 'color', colors9(iLoc,:) * iperf/nPerf, 'CapSize', 0, 'HandleVisibility', 'off')
        plot(1:nNoise, ratio_ave(iLoc, :, iperf), 'o-', 'color', colors9(iLoc,:) * iperf/nPair, 'MarkerFaceColor', 'w')
        legends{iperf} = sprintf('%d vs. %d', perfPSE_all(iperf), perfPSE_all(end));
    end % iperf
    xticks(1:nNoise), xticklabels(round(noiseLvl_all*100)), xlim([0, nNoise+1])
    ylim([.95, 1.1]), yline(1, 'k-', 'linewidth', 1.5);
    legend(legends, 'Location', 'northwest')
end % iLoc

sgtitle(sprintf('Thresh ratio between perf levels - n=%d', nsubj))
saveas(gcf, sprintf('%s/threshRatio_group.jpg', nameFolder_fig))

%%  plot Eeq and eff as a fxn of LOC (all subjects)
iperf = 3;
figure('Position', [0 0 1e3 400]), hold on
for iLF=1:2
    switch iLF
        case 1, LF_allSubj = Neq_allSubj(:, indLoc, iperf);
        case 2, LF_allSubj = Eff_allSubj(:, indLoc, iperf)*100;
    end
    subplot(1,2,iLF), hold on
    for isubj = 1:nsubj
        plot(1:nLoc, LF_allSubj(isubj, :), ['-', markers_allSubj{isubj}], 'Color', ones(1,3)/2, 'MarkerSize', 10, 'MarkerFaceColor', 'w')
    end
    for iLoc = 1:nLoc
        [data_ave, ~, ~, data_sem] = getCI(LF_allSubj(:, iLoc), 2, 1);
        errorbar(iLoc, data_ave, data_sem, 'o', 'Color', colors9(indLoc(iLoc), :),'CapSize', 0, 'LineWidth', 3)
    end
    if iLF==1, yline(0, 'k-'); end
    xticks(1:nLoc), xticklabels(namesLoc(indLoc)), xtickangle(45), xlim([0, nLoc+1])
    %         ylim([0, .3])
    legend(subjList, 'NumColumns', 3, 'Location', 'best')
    title(namesINE{iLF})
end
set(findall(gcf, '-property', 'fontsize'), 'fontsize',15)
saveas(gcf, sprintf('%s/LF_perLoc.jpg', nameFolder_fig))

%% TESTTEST plot Eeq and eff as a fxn of LOC (average)
iperf = 3; indLoc = [1,2,4,5,3]; namesLoc = namesLoc9;
figure('Position', [0 0 1e3 400]), hold on
for iLF=1:2
    switch iLF
        case 1, LF_allSubj_avg = Neq_allSubj_avg(:, indLoc, iperf);
        case 2, LF_allSubj_avg = Eff_allSubj_avg(:, indLoc, iperf)*100;
    end
    ylim ([-6 1])
    subplot(1,2,iLF), hold on
 
        plot(1:nLoc, LF_allSubj_avg(:, :), ['-', markers_allSubj{1}], 'Color', ones(1,3)/2, 'MarkerSize', 10, 'MarkerFaceColor', 'w')
    
    for iLoc = 1:nLoc
        [data_ave, ~, ~, data_sem] = getCI(LF_allSubj_avg(:, iLoc), 2, 1);
        errorbar(iLoc, data_ave, data_sem, 'o', 'Color', colors9(indLoc(iLoc), :),'CapSize', 0, 'LineWidth', 3)
    end
    if iLF==1, yline(0, 'k-'); end
    xticks(1:nLoc), xticklabels(namesLoc(indLoc)), xtickangle(45), xlim([0, nLoc+1])
    %         ylim([0, .3])
    %legend(subjList, 'NumColumns', 3, 'Location', 'best')
    title(namesINE{iLF})
     ylim ([0 45])
end
set(findall(gcf, '-property', 'fontsize'), 'fontsize',15)
saveas(gcf, sprintf('%s/LF_perLoc_average.jpg', nameFolder_fig))

%%  RACHEL: plot Eeq and eff as a fxn of LOC (average on top of individuals)

iperf = 3; indLoc = [1,2,4,5,3]; namesLoc = namesLoc9;
figure('Position', [0 0 1e3 400]), hold on

for iLF=1:2
    subplot(1,2,iLF), hold on

    % Plot for all subjects
    switch iLF
        case 1, LF_allSubj = Neq_allSubj(:, indLoc, iperf);
        case 2, LF_allSubj = Eff_allSubj(:, indLoc, iperf)*100;
    end

    for isubj = 1:nsubj
        plot(1:nLoc, LF_allSubj(isubj, :), ['-', markers_allSubj{isubj}], 'Color', ones(1,3)/2, 'MarkerSize', 10, 'MarkerFaceColor', 'w')
    end

    % Plot the average
    switch iLF
        case 1, LF_allSubj_avg = Neq_allSubj_avg(:, indLoc, iperf);
        case 2, LF_allSubj_avg = Eff_allSubj_avg(:, indLoc, iperf)*100;
    end

    plot(1:nLoc, LF_allSubj_avg, ['-', markers_allSubj{1}], 'Color', 'black', 'MarkerSize', 10, 'MarkerFaceColor', 'red', 'LineWidth', 2)

    % Add error bars for average
    for iLoc = 1:nLoc
        [data_ave, ~, ~, data_sem] = getCI(LF_allSubj_avg(:, iLoc), 2, 1);
        errorbar(iLoc, data_ave, data_sem, 'o', 'Color', colors9(indLoc(iLoc), :), 'CapSize', 0, 'LineWidth', 3)
    end

    if iLF==1, yline(0, 'k-'); end
    xticks(1:nLoc), xticklabels(namesLoc(indLoc)), xtickangle(45), xlim([0, nLoc+1])
    legend([subjList, 'Average'], 'NumColumns', 4, 'Location', 'best')
    title(namesINE{iLF})

end

set(findall(gcf, '-property', 'fontsize'), 'fontsize',15)
saveas(gcf, sprintf('%s/LF_perLoc_combined.jpg', nameFolder_fig))


%% quatify asymmetries in limiting factors (LF)
close all, clc
iNoise_noNoise = 1;
iperf = 3;
thresh_CombLoc_allSubj = fxn_extractAsym(squeeze(PSE_best_allSubj(:, :, iNoise_noNoise, iperf)));

for iLF=1:2
    switch iLF
        case 1, LF_allSubj = Neq_allSubj;
        case 2, LF_allSubj = Eff_allSubj*100;
    end
    nameFolder_fig_ = [nameFolder_fig, '/', namesINE_short{iLF}];
    if isempty(dir(nameFolder_fig_)), mkdir(nameFolder_fig_), end
    %=====================================================================================
    [LF_CombLoc_allSubj, namesAsym, LF_asym_allSubj] = fxn_extractAsym(squeeze(LF_allSubj(:, :, iperf)));
    %=====================================================================================
    switch iLF
        case 1, Neq_CombLoc_allSubj = LF_CombLoc_allSubj; Neq_asym_allSubj = LF_asym_allSubj;
        case 2, Eff_CombLoc_allSubj = LF_CombLoc_allSubj; Eff_asym_allSubj = LF_asym_allSubj;
    end
    
    nasym = length(namesAsym);
    [LF_asym_ave, ~, ~, LF_asym_sem] = getCI(LF_asym_allSubj, 2, 1);
    
    %% plot three asymmetries (ecceffect, HVA, VMA)
    plot1_asym
    
    %% group and plot Neq and Eff according to location (like AB's slide)
    plot2_compLoc
    
    %% correlate between limiting factor and thresh (noise=0) across 4 locations
    flag_zeroMean = 1;
    if nLoc==5
        basicFxn_drawCorr([thresh_CombLoc_allSubj{1}, thresh_CombLoc_allSubj{2},thresh_CombLoc_allSubj{4},thresh_CombLoc_allSubj{5}], ...
            [LF_CombLoc_allSubj{1}, LF_CombLoc_allSubj{2},LF_CombLoc_allSubj{4},LF_CombLoc_allSubj{5}], ...
            colors_comb([1,6,5,3], :), [],[],[],[], flag_zeroMean, 'pearson', 'both', namesINE{iLF});
        %saveas(gcf, sprintf('%s/corr_L1653.jpg', nameFolder_fig_))
    else
        basicFxn_drawCorr([thresh_CombLoc_allSubj{1}, thresh_CombLoc_allSubj{2},thresh_CombLoc_allSubj{4},thresh_CombLoc_allSubj{5},thresh_CombLoc_allSubj{7},thresh_CombLoc_allSubj{9},thresh_CombLoc_allSubj{10}], ...
            [LF_CombLoc_allSubj{1}, LF_CombLoc_allSubj{2},LF_CombLoc_allSubj{4},LF_CombLoc_allSubj{5}, LF_CombLoc_allSubj{7}, LF_CombLoc_allSubj{9}, LF_CombLoc_allSubj{10}], ...
            colors9([1,6,5,3, 6, 5, 3], :), [],[],[],[], flag_zeroMean, 'pearson', 'both', namesINE{iLF});
        %saveas(gcf, sprintf('%s/corr_L_fovHM48VM48.jpg', nameFolder_fig_))
    end
    %% correlate between asymmetry in thresh (noise=0) and in internal noise/effeciency
    plot4_corrAsym
    
end % iLF

close all


%% Linear mixed model - test whether Neq and Eff can predict thresh
clc
fprintf('*** Threshold predicted by Neq (+) and Eff (-) ***\n')
for iasym = 1:nasym
    tbl = table(thresh_CombLoc_allSubj{iasym}, Neq_CombLoc_allSubj{iasym}, Eff_CombLoc_allSubj{iasym},...
        'VariableNames',{'Thresh','Neq', 'Eff'});
    lme = fitlme(tbl, 'Thresh~Neq + Eff');
    fprintf('\n%s:\n     %s: slope = %.2f, p = %.3f\n     %s: slope = %.2f, p = %.3f\n', ...
        namesAsym{iasym}, ...
        namesINE_short{1}, lme.Coefficients.Estimate(2),lme.Coefficients.pValue(2), ...
        namesINE_short{2}, lme.Coefficients.Estimate(3), lme.Coefficients.pValue(3))
end

%% with random effect
clc
for iasym = 1:nasym
    tbl = table(thresh_CombLoc_allSubj{iasym}, Neq_CombLoc_allSubj{iasym}, Eff_CombLoc_allSubj{iasym}, (1:nsubj)',...
        'VariableNames',{'Thresh','Neq', 'Eff', 'indSubj'});
    lme = fitlme(tbl, 'Thresh~Neq + Eff + (1|indSubj)');
    fprintf('\n%s:\n     %s: slope = %.2f, p = %.3f\n     %s: slope = %.2f, p = %.3f\n', ...
        namesAsym{iasym}, ...
        namesINE_short{1}, lme.Coefficients.Estimate(2),lme.Coefficients.pValue(2), ...
        namesINE_short{2}, lme.Coefficients.Estimate(3), lme.Coefficients.pValue(3))
end

%% Linear mixed model - test whether ASYMMETRY in Neq and Eff can predict that of thresh
clc
fprintf('*** Asym of Threshold predicted by that of Neq (+) and Eff (-) ***\n')

% for iasym = 1:nasym
%     tbl = table(squeeze(thresh_asym_allSubj(:, 1, iasym)), Neq_asym_allSubj(:, iasym), Eff_asym_allSubj(:, iasym),...
%         'VariableNames',{'Thresh_Asym','Neq_Asym', 'Eff_Asym'});
%     lme = fitlme(tbl, 'Thresh_Asym ~ Neq_Asym + Eff_Asym + Neq_Asym * Eff_Asym');
%     fprintf('\n%s:\n     %s: slope = %.2f, p = %.3f\n     %s: slope = %.2f, p = %.3f\n     %s: slope = %.2f, p = %.3f\n', ...
%         namesAsym{iasym}, ...
%         namesINE_short{1}, lme.Coefficients.Estimate(2),lme.Coefficients.pValue(2), ...
%         namesINE_short{2}, lme.Coefficients.Estimate(3), lme.Coefficients.pValue(3), ...
%         'Interaction', lme.Coefficients.Estimate(4), lme.Coefficients.pValue(4))
% end

for iasym = 1:nasym
    tbl = table(squeeze(thresh_asym_allSubj(:, 1, iasym)), Neq_asym_allSubj(:, iasym), Eff_asym_allSubj(:, iasym),...
        'VariableNames',{'Thresh_Asym','Neq_Asym', 'Eff_Asym'});
    lme = fitlme(tbl, 'Thresh_Asym ~ Neq_Asym + Eff_Asym');
    fprintf('\n%s:\n     %s: slope = %.2f, p = %.3f\n     %s: slope = %.2f, p = %.3f\n', ...
        namesAsym{iasym}, ...
        namesINE_short{1}, lme.Coefficients.Estimate(2),lme.Coefficients.pValue(2), ...
        namesINE_short{2}, lme.Coefficients.Estimate(3), lme.Coefficients.pValue(3))
end

%% fit PTM


