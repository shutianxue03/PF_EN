% change cst saved in the data matrix

addpath(genpath('fxn_analysis/')); % SX
subjName = 'SX';

nNoise=7;
SF=6;

nameFolder = sprintf('Data/nNoise%d/SF%d/%s', nNoise, SF, subjName);

addpath(genpath(nameFolder)); % SX

nameFiles = sprintf('%s/*E4_*b*', nameFolder);

noiseSD_wrong = [0 .055 .11 .165 .22 .33 .44];
noiseSD_all = [0 .055 .11 .165 .22 .33 .44]/2;

%%
dirFiles = dir(nameFiles);
nFiles = length(dirFiles);

for iFile = 1:nFiles
    nameFile_load = sprintf('%s/%s', dirFiles(iFile).folder, dirFiles(iFile).name);
    load(nameFile_load, 'real_sequence')
    extNoiseLvl_update = nan(size(real_sequence.extNoiseLvl));
    nTrials = length(real_sequence.trialInd);
    for itrial = 1:nTrials
        if real_sequence.extNoiseLvl(itrial)>0
        extNoiseLvl_update(itrial) = noiseSD_wrong(real_sequence.extNoiseLvl(itrial))/2;
        end
    end
    
    real_sequence.extNoiseLvl = extNoiseLvl_update;
    
    nameFile_save = nameFile_load;
    
    save(nameFile_save, 'real_sequence', '-append')
end

