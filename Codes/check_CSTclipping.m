% Parameters
nStimuli = 1e3;
ppd=32;
stimSize = 96;  % assuming square stimuli
nFramesStim = 1; % you can extend to multiple frames if needed
bgColor = 255/2;
gaborSD = 1*ppd;        % standard deviation of Gaussian envelope
SF_pix = 2/ppd;    % spatial frequency (cycles/pixel)
oristimOri = 45;        % orientation in degrees

iplot = 1;
figure('Position', [0,0,2e3,2e3])
noiseSD_all = [0, .005, .02, .1, 0.44];
gaborCST_all =  [.1, .9, 1, 1.5, 2, 3];
pClippedLow_med_all = [];
pClippedHigh_med_all = pClippedLow_med_all;

for noiseSD = noiseSD_all    % SD of Gaussian noise (scales the randn distribution)
    for gaborCST = gaborCST_all  % this is scaling factor to test (>1 will cause clipping)

        % Preallocate
        pClippedLow_all = nan(nStimuli, 1);
        pClippedHigh_all = pClippedLow_all;

        % Loop through simulated stimuli
        for i = 1:nStimuli
            % Create Gabor
            gaborPhase = 2*pi*rand; % random phase per stimulus
            contrast = 2 * bgColor * gaborCST;
            gabor = CreateGabor(stimSize, gaborSD, oristimOri, SF_pix, gaborPhase, contrast);

            % Create Gaussian noise
            noiseImg = randn(stimSize, stimSize, nFramesStim) * noiseSD * bgColor;

            % Combine signal and noise
            noiseImg_ = noiseImg + gabor;
            rawStim = noiseImg_ + bgColor;  % raw pixel values before normalization

            % Count clipped pixels
            pClippedLow = mean(rawStim(:) < 0);
            pClippedHigh = mean(rawStim(:) > 255);
            pClippedLow_all(i) = pClippedLow;
            pClippedHigh_all(i) = pClippedHigh;

        end

        % Plot histogram before clipping
        if length(gaborCST_all)<5
            subplot(length(noiseSD_all), length(gaborCST_all), iplot), hold on
            histogram(pClippedLow_all, 'Normalization', 'Probability');
            histogram(pClippedHigh_all, 'Normalization', 'Probability');

            if iplot==1
                xlabel('Proportion of pixel being clipped');
                ylabel('Probability');
            end
            legend({...
                sprintf('<0 (med=%.2f)', median(pClippedLow_all)), ...
                sprintf('>1 (med=%.2f)', median(pClippedHigh_all))}),
            iplot = iplot+1;
            title(sprintf('Gabor CST=%.2f, Noise SD=%.2f', gaborCST, noiseSD));
        end

        if noiseSD==.44
            pClippedLow_med_all = [pClippedLow_med_all, median(pClippedLow_all)];
            pClippedHigh_med_all = [pClippedHigh_med_all, median(pClippedHigh_all)];
        end
    end % gaborCST
end % noiseSD
sgtitle('Distribution of Clipped Pixels');

%% pClipped as a fxn of gaborCST (noiseSD=.44)
figure, hold on, grid on
plot(gaborCST_all, pClippedLow_med_all+pClippedHigh_med_all, 'k-')
xlabel('Gabor CST')
ylabel('Proportion of clipped pixels (total)')
set(findall(gcf, '-property', 'fontsize'), 'fontsize',15)

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