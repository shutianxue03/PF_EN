
SF=5;
subjName = 'SP';

nameFolder = sprintf('%s/SF%d/%s/', folder_extension, SF, subjName);
nameFolder_data = sprintf('Data%s', nameFolder);
nameFolder_fig = sprintf('fig%s%s/', nameFolder, folderName_extraAnalysis(2:end)); if isempty(dir(nameFolder_fig)), mkdir(nameFolder_fig), end

nameFiles_add_all = sprintf('%s*E4_b*', nameFolder_data);
dirFiles_add_all = dir(nameFiles_add_all); nFiles_ccc = length(dirFiles_add_all);

ccc_new = [];
for ifile = 1:nFiles_ccc
    load(dirFiles_add_all(ifile).name, 'real_sequence')
    ccc_new = [ccc_new;...
        real_sequence.targetLoc(real_sequence.trialDone==1)'...
        real_sequence.extNoiseLvl(real_sequence.trialDone==1)'...
        real_sequence.scontrast(real_sequence.trialDone==1)'...
        real_sequence.iscor(real_sequence.trialDone==1)'...
        real_sequence.stair(real_sequence.trialDone==1)'...
        real_sequence.stimOri(real_sequence.trialDone==1)'];
end % ifile

load('Data/nNoise7/SF5/SP/SP_ccc_all.mat', 'ccc')
ccc_all_old = ccc;
ccc = [ccc_all_old; ccc_new];
save('Data/nNoise7/SF5/SP/SP_ccc_all_new.mat', 'ccc')

