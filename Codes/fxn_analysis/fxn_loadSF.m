
if ~exist('flag_n9', 'var'), flag_n9 = 0; end % if flag_n9=1: only include the 9 shared subjects

if any(SF_load_all == 51)
    switch SF_load
        case 4, nNoise = 9; SF_str = '4';      nsubj = 9; isubj_ANOVA = 1:9;     isubj_start = 1; noiseSD_full = [0 .055 .11 .165 .22 .33 .44 .66 .88]/2; subjList = {'AD', 'DT', 'HH', 'HL', 'LL', 'MD', 'RC',  'SX', 'ZL'};
        case 51, nNoise = 7; SF_str = '5_JA'; nsubj = 4; isubj_ANOVA = 13:16; isubj_start = 10; noiseSD_full = [0 .055 .11 .165 .22 .275 .33]/2; subjList = {'fc', 'ja', 'jfa', 'zw'};
        case 5, nNoise = 7; SF_str = '5_AB';  nsubj = 6; isubj_ANOVA = 17:22; isubj_start = 14; noiseSD_full = [0 .055 .11 .165 .22 .33 .44]/2; subjList = {'AB', 'ASF', 'CM', 'LH', 'MJ', 'SP'}; % ASF is Angela Shen (Female)
        % case 6, nNoise = 9; SF_str = '6';      nsubj = 12; isubj_ANOVA = 1:12;   isubj_start = 20; noiseSD_full = [0 .055 .11 .165 .22 .33 .44 .66 .88]/2; subjList = {'AD', 'DT', 'HH', 'HL', 'LL', 'MD', 'RC',  'SX', 'ZL',         'ASM', 'JY', 'RE'}; % SF=6, n=12s % ASM is Ajay (Male)
        case 6
            if flag_n9 % only include the 9 shared subject for SF=4 and 6
                nNoise = 9; SF_str = '6';         nsubj = 9; isubj_ANOVA = 1:9;    isubj_start = 1; noiseSD_full = [0 .055 .11 .165 .22 .33 .44 .66 .88]/2; subjList = {'AD', 'DT', 'HH', 'HL', 'LL', 'MD', 'RC',  'SX', 'ZL'}; % SF=6, n=12s % ASM is Ajay (Male)
            else  % include all 12 subjects for SF=6
                nNoise = 9; SF_str = '6';         nsubj = 12; isubj_ANOVA = 1:12;    isubj_start = 20; noiseSD_full = [0 .055 .11 .165 .22 .33 .44 .66 .88]/2; subjList = {'AD', 'DT', 'HH', 'HL', 'LL', 'MD', 'RC',  'SX', 'ZL',         'ASM', 'JY', 'RE'}; % SF=6, n=12s % ASM is Ajay (Male)
            end
    end
    
else
    switch SF_load
        case 4, nNoise = 9; SF_str = '4';           nsubj = 9; isubj_ANOVA = 1:9;      isubj_start = 1; noiseSD_full = [0 .055 .11 .165 .22 .33 .44 .66 .88]/2; subjList = {'AD', 'DT', 'HH', 'HL', 'LL', 'MD', 'RC',  'SX', 'ZL'};
        case 5, nNoise = 8; SF_str = '5_JAAB'; nsubj = 10; isubj_ANOVA = 13:22; isubj_start = 10; noiseSD_full = [0 .055 .11 .165 .22 .275 .33, .44]/2; subjList = {'fc', 'ja', 'jfa', 'zw',    'AB', 'ASF', 'CM', 'LH', 'MJ', 'SP'};
        case 6
            if flag_n9 % only include the 9 shared subject for SF=4 and 6
                nNoise = 9; SF_str = '6';         nsubj = 9; isubj_ANOVA = 1:9;    isubj_start = 1; noiseSD_full = [0 .055 .11 .165 .22 .33 .44 .66 .88]/2; subjList = {'AD', 'DT', 'HH', 'HL', 'LL', 'MD', 'RC',  'SX', 'ZL'}; % SF=6, n=12s % ASM is Ajay (Male)
            else  % include all 12 subjects for SF=6
                nNoise = 9; SF_str = '6';         nsubj = 12; isubj_ANOVA = 1:12;    isubj_start = 20; noiseSD_full = [0 .055 .11 .165 .22 .33 .44 .66 .88]/2; subjList = {'AD', 'DT', 'HH', 'HL', 'LL', 'MD', 'RC',  'SX', 'ZL',         'ASM', 'JY', 'RE'}; % SF=6, n=12s % ASM is Ajay (Male)
            end
    end
end

isubj_end = isubj_start+nsubj-1;
isubj_perGroup = isubj_start:isubj_end;
assert(length(isubj_ANOVA) == nsubj)

noiseSD_full_acrossSF = sort(unique(([[0 .055 .11 .165 .22 .33 .44 .66 .88]/2, [0 .055 .11 .165 .22 .275 .33]/2, [0 .055 .11 .165 .22 .33 .44]/2])));
noiseSD_log_full_acrossSF = log10(noiseSD_full_acrossSF);
%----------------%
SX_fitTvC_setting
% need to load this for each SF because noiseSD_full differs for each SF
%----------------%

nameFolder_dataOOD_save = sprintf('Data/Data_OOD/nNoise%d/SF%s', nNoise, SF_str);

if flag_nestedMC, nameFile_nestedMC_allSubj = sprintf('%s/n%d_nestedMC_B%d_constim%d_Bin%dFilter%d_%s_%s.mat', ...
        nameFolder_dataOOD_save, nsubj, nBoot, fit.nBins, flag_binData, flag_filterData, text_collapseHM, text_locType); end
if flag_varyLocMC, nameFile_varyLocMC_allSubj = sprintf('%s/n%d_varyLocMC_%s_%s_B%d_constim%d_Bin%dFilter%d_%s_%s.mat', ...
        nameFolder_dataOOD_save, nsubj, namesTvCModel{iTvCModel}, namesErrorType{iErrorType}, nBoot, fit.nBins, flag_binData, flag_filterData, text_collapseHM, text_locType); end
% nameFile_fitTvC_allSubj = sprintf('%s/n%d_fitTvC_%s_%s_B%d_constim%d_Bin%dFilter%d_%s_%s.mat', ...
%     nameFolder_dataOOD_save, nsubj, namesTvCModel{iTvCModel}, namesErrorType{iErrorType}, nBoot, fit.nBins, flag_binData, flag_filterData, text_collapseHM, text_locType);
nameFile_fitTvC_allSubj = sprintf('%s/n%d_fitTvC_B%d_constim%d_Bin%dFilter%d_%s_%s.mat', ...
    nameFolder_dataOOD_save, nsubj, nBoot, fit.nBins, flag_binData, flag_filterData, text_collapseHM, text_locType);

