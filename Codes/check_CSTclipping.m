%% Check whether external noise RMS causes 8-bit clipping (keep original variable names)
clc; close all;

% Parameters (keep original names)
nStimuli   = 1e3;   % number of simulated stimuli/frames per condition
ppd        = 32;
stimSize   = 96;    % assuming square stimuli
nFramesStim = 1;    % extend if needed
bgColor    = 255/2;

gaborSD    = 1*ppd;       % SD of Gaussian envelope (pix)
SF_pix     = 2/ppd;       % spatial frequency (cycles/pixel)
oristimOri = 45;          % orientation in degrees

% Conditions
noiseSD_all   = [0, .005, .02, .1, .44];   % NOTE: interpreted as RMS contrast (sigma_ext)
gaborCST_all  = linspace(0,1,5);           % scaling factor for signal contrast

% Output containers (keep original names)
pClippedLow_med_all  = [];
pClippedHigh_med_all = pClippedLow_med_all;

% New: effective displayed RMS (noise-only and noise+signal) after clipping
effNoiseRMS_med_all = [];     % only filled for noiseSD==.44 to match your original final plot intent
effStimRMS_med_all  = [];

rng(0); % reproducibility

% Plot setup
iplot = 1;
figure('Position',[0,0,1600,1200]);

for noiseSD = noiseSD_all
    for gaborCST = gaborCST_all

        % Preallocate (keep original names)
        pClippedLow_all  = nan(nStimuli, 1);
        pClippedHigh_all = pClippedLow_all;

        % New: store effective RMS for each simulated stimulus/frame
        effNoiseRMS_all = nan(nStimuli,1);  % noise-only
        effStimRMS_all  = nan(nStimuli,1);  % noise+signal

        % Convert RMS contrast (sigma_ext) to pixel SD
        % If your manuscript defines sigma_ext differently, edit this ONE line.
        noiseSD_pix = noiseSD * bgColor;

        for i = 1:nStimuli

            % --- Signal (Gabor) ---
            gaborPhase = 2*pi*rand;  % random phase per stimulus
            contrast   = 2 * bgColor * gaborCST;
            gabor      = CreateGabor(stimSize, gaborSD, oristimOri, SF_pix, gaborPhase, contrast);

            % --- External noise (Gaussian) ---
            noiseImg = randn(stimSize, stimSize, nFramesStim) * noiseSD_pix;

            % --- Noise-only stimulus (for effective RMS after clipping) ---
            rawNoise = noiseImg + bgColor;
            clippedNoise = min(max(rawNoise, 0), 255);
            effNoiseRMS_all(i) = std(clippedNoise(:) - bgColor) / bgColor;

            % --- Signal + noise ---
            noiseImg_ = noiseImg + gabor;
            rawStim   = noiseImg_ + bgColor;  % raw pixel values before clipping

            % Count clipped pixels (keep original logic)
            pClippedLow_all(i)  = mean(rawStim(:) < 0);
            pClippedHigh_all(i) = mean(rawStim(:) > 255);

            % Effective RMS after clipping (signal+noise)
            clippedStim = min(max(rawStim, 0), 255);
            effStimRMS_all(i) = std(clippedStim(:) - bgColor) / bgColor;
        end

        % Optional diagnostic plots (kept structure, slightly cleaned)
        if numel(gaborCST_all) < 5
            subplot(numel(noiseSD_all), numel(gaborCST_all), iplot); hold on;
            histogram(pClippedLow_all,  'Normalization','Probability');
            histogram(pClippedHigh_all, 'Normalization','Probability');

            if iplot==1
                xlabel('Proportion of pixels clipped');
                ylabel('Probability');
            end
            legend({ ...
                sprintf('<0 (med=%.3f)', median(pClippedLow_all)), ...
                sprintf('>255 (med=%.3f)', median(pClippedHigh_all))}, ...
                'Location','best');
            title(sprintf('Gabor CST=%.2f, \\sigma_{ext}=%.3f', gaborCST, noiseSD));
            iplot = iplot + 1;
        end

        % Match your original behavior: only summarize for noiseSD==.44
        if abs(noiseSD - 0.44) < 1e-12
            pClippedLow_med_all  = [pClippedLow_med_all,  median(pClippedLow_all)];
            pClippedHigh_med_all = [pClippedHigh_med_all, median(pClippedHigh_all)];

            % New: effective displayed RMS medians
            effNoiseRMS_med_all = [effNoiseRMS_med_all, median(effNoiseRMS_all)];
            effStimRMS_med_all  = [effStimRMS_med_all,  median(effStimRMS_all)];
        end

    end % gaborCST
end % noiseSD

sgtitle('Distribution of clipped pixels (8-bit), across \\sigma_{ext} and signal contrast');

%% pClipped as a function of gaborCST (noiseSD=.44)  (your original final plot)
figure; hold on; grid on;
plot(gaborCST_all, pClippedLow_med_all + pClippedHigh_med_all, 'k-o', 'LineWidth', 1.5);
xlabel('Gabor CST');
ylabel('Proportion of clipped pixels (total)');
set(findall(gcf, '-property', 'fontsize'), 'fontsize', 15);
title('Total clipping at \\sigma_{ext}=0.44');

%% New: show whether clipping reduces the effective displayed RMS (the reviewer’s key concern)
figure; hold on; grid on;
plot(gaborCST_all, effNoiseRMS_med_all, 'o-', 'LineWidth', 1.5);   % noise-only effective RMS
plot(gaborCST_all, effStimRMS_med_all,  's-', 'LineWidth', 1.5);   % signal+noise effective RMS
yline(0.44, '--'); % intended RMS contrast
xlabel('Gabor CST');
ylabel('Effective RMS contrast after 8-bit clipping');
legend({'Noise-only','Signal+noise','Intended \\sigma_{ext}=0.44'}, 'Location','best');
set(findall(gcf, '-property', 'fontsize'), 'fontsize', 15);
title('Does 8-bit clipping reduce effective \\sigma_{ext}?');

%% check the used gabor CST > 1
clc
%------------------%
SX_analysis_setting
%------------------%
nNoise=9;
SF=4; nsubj=9; % all gabor CST are below 100%
SF=6; nsubj=12;
gabor_CST_allSubj = [];

for isubj=1:nsubj
    switch SF
        case 6
            SF_str = '6';
            subjList = {'AD', 'DT', 'HH', 'HL', 'LL', 'MD', 'RC',  'SX', 'ZL', 'ASM', 'JY', 'RE'}; % SF=6, n=12s % ASM is Ajay (Male)
            nLocSingle=9; nLocHM=2;
            noiseSD_full = [0 .055 .11 .165 .22 .33 .44 .66 .88];

        case 4
            SF_str = '4';
            subjList = {'AD', 'DT', 'HH', 'HL', 'LL', 'MD', 'RC',  'SX', 'ZL'                       }; % SF=4, n=9
            nLocSingle = 9; nLocHM = 2;
            noiseSD_full = [0 .055 .11 .165 .22 .33 .44 .66 .88];

        case 5
            SF_str = '5_AB';
            subjList = {'AB', 'ASF', 'CM', 'LH', 'MJ', 'SP'}; % ASF is Angela Shen (Female)
            nLocSingle = 9; nLocHM = 2;
            noiseSD_full = [0 .055 .11 .165 .22 .33 .44]/2; % in ccc_all, col#2 is index (1-7), not real values!

        case 51
            SF_str = '5_JA';
            %         subjList = {'fc', 'ja', 'jfa', 'zw', 'ab',  'kae', 'ec', 'il', 'aw', 'mg', 'mr', 'dc'};
            subjList = {'fc', 'ja', 'jfa', 'zw'};  % only those who have a data at all 9 locations
            nLocSingle=9; nLocHM=2;
            noiseSD_full = [0 .055 .11 .165 .22 .33 .44]/2; % in ccc_all, col#2 is index (1-7), not real values!
    end

    % file name
    subjName = subjList{isubj};
    nameFolder_dataOOD = sprintf('Data_OOD/nNoise%d/SF%s', nNoise, SF_str);
    nameFileCCC_OOD = sprintf('%s/ccc/%s_ccc_all.mat', nameFolder_dataOOD, subjName);

    % load ccc data
    load(nameFileCCC_OOD, 'ccc_all');
    gabor_CST_allSubj = [gabor_CST_allSubj, max(ccc_all(:, 3))];
    % if max(ccc_all(:, 3))>=3
    %     ccc_all(ccc_all(:, 3)>=3, 3)'
    % end

end % isubj
subjList
gabor_CST_allSubj