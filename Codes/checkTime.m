clear all
clc
design.fixDur = 0.400;  % fixation duration [s] % originally .2
design.fixNoise = 0.050;  % noise duration [s] % originally .05
design.preCueDur1 = 0.050;  % fixation duration [s]
design.preCueDur2 = 0.100;  % preCue duration [s]
design.preISIDur  = 0.100;  % preISI duration [s]
design.stimDur  = 0.050;  % target duration [s]
design.postISIDur = 0.300;  % postISI  duration [s] % originally .3

%%
close all
nNoise = 9;
SF = 6;
if nNoise == 7, nameFolder = sprintf('Data/nNoise%d/SF%d', nNoise, SF); end
if nNoise == 9;  nameFolder = sprintf('Data/nNoise%d', nNoise); end
% nameFolder = 'Data_old/AB_PF_LAM_forSX_original/Data/NOCUE';
for subjName = {'AD'}%{'SX', 'DT', 'RC', 'HL', 'HH', 'JY', 'MD', 'ZL', 'AD', 'AJ'}
    subjName = subjName{1};
    nameFiles = sprintf('%s/%s/%s_E1*2023*', nameFolder, subjName, subjName); % unfortunately timing of other exp modes were not saved
%     nameFiles = sprintf('%s/S%s/PF_LAM*_s*_b*.mat', nameFolder, subjName);
    nameDir = dir(nameFiles);
    nFiles = length(nameDir);
    
    nEvents = 7;
    timing_ave = nan(nFiles, nEvents);
    
    for iFile=1:nFiles
        load(nameDir(iFile).name, 'timing', 'real_sequence')
        
        
        if class(timing) == 'struct', iFile_ = iFile;
        else, 
            iFile_=1; 
        end
       
        trialDone = real_sequence.trialDone;

        timing1 = mean(timing(iFile_).fixDur(boolean(trialDone)));
        timing2 = mean(timing(iFile_).fixNoise(boolean(trialDone)));
        timing3 = mean(timing(iFile_).preCueDur1(boolean(trialDone)));
        timing4 = mean(timing(iFile_).preCueDur2(boolean(trialDone)));
        timing5 = mean(timing(iFile_).ISIDur(boolean(trialDone)));
        timing6 = mean(timing(iFile_).stimDur(boolean(trialDone)));
        timing7 = mean(timing(iFile_).postISIDur(boolean(trialDone)));

        timing_ave(iFile, :) = [timing1/design.fixDur, ...
            timing2/design.fixNoise, ...
            timing3/design.preCueDur1, ...
            timing4/design.preCueDur2, ...
            timing5/design.preISIDur, ...
            timing6/design.stimDur, ...
            timing7/design.postISIDur];
    end
    
    ratio = nan(1, nEvents);
    figure
    for iEvent = 1:nEvents
        subplot(2,4, iEvent), hold on
        histogram(timing_ave(:, iEvent))
        title(sprintf('Med=%.2f, SD=%.2f', median(timing_ave(:, iEvent)), std(timing_ave(:, iEvent))))
        ratio(iEvent) = median(timing_ave(:, iEvent));
    end
    sgtitle(subjName)
    % fprintf('%s: %.0f, %.0f, %.0f\n', subjName, [mean(ratio(2:5))*300, ratio(6:7).*[50, 300]])
    fprintf('%s: %.2f, %.2f, %.2f\n', subjName, [mean(ratio(2:5)), ratio(6:7)])
    
end
