
switch SF
    case 6
        SF_str = '6';
        if flag_n9
            subjList = {'AD', 'DT', 'HH', 'HL', 'LL', 'MD', 'RC',  'SX', 'ZL'}; % SF=6, n=12s % ASM is Ajay (Male)
        else
            subjList = {'AD', 'DT', 'HH', 'HL', 'LL', 'MD', 'RC',  'SX', 'ZL',         'ASM', 'JY', 'RE'}; % SF=6, n=12s % ASM is Ajay (Male)
        end
        % subjList = {'AD', 'ASM', 'HH', 'HL', 'LL', 'SX',  'JY',    'RE', 'ZL', 'DT', 'MD', 'RC'}; % prioritize plotting of problematic subjects
        % subjList = {'JY', 'HL'}; % SF=6, n=12s % ASM is Ajay (Male)
        nNoise=9; nLocSingle=9; nLocHM=2;iLoc_tgt_all=1:nLocSingle;
        noiseSD_full_doubled = [0 .055 .11 .165 .22 .33 .44 .66 .88];
        noiseSD_full = noiseSD_full_doubled/2;
        nNoise_save = nNoise;

    case 61
        SF_str = '6';
        subjList = {'AD', 'DT', 'HH', 'HL', 'LL', 'MD', 'RC',  'SX', 'ZL'};
        nNoise=9; nLocSingle=9; nLocHM=2;iLoc_tgt_all=1:nLocSingle;
        noiseSD_full_doubled = [0 .055 .11 .165 .22 .33 .44 .66 .88];
        noiseSD_full = noiseSD_full_doubled/2;
        nNoise_save = nNoise;

    case 4
        SF_str = '4';
        subjList = {'AD', 'DT', 'HH', 'HL', 'LL', 'MD', 'RC',  'SX', 'ZL'};
        nNoise=9; nLocSingle = 9; nLocHM = 2;iLoc_tgt_all=1:nLocSingle;
        noiseSD_full_doubled = [0 .055 .11 .165 .22 .33 .44 .66 .88];
        noiseSD_full = noiseSD_full_doubled/2;
        nNoise_save = nNoise;

    case 5
        SF_str = '5_AB';
        subjList = {'AB', 'ASF', 'CM', 'LH', 'MJ', 'SP'}; % ASF is Angela Shen (Female)
        nNoise=7; nLocSingle = 9; nLocHM = 2;iLoc_tgt_all=1:nLocSingle;
        noiseSD_full = [0 .055 .11 .165 .22 .33 .44]/2; % in ccc_all, col#2 is index (1-7), not real values!
        nNoise_save = nNoise;

    case 51
        SF_str = '5_JA';
        %         subjList = {'fc', 'ja', 'jfa', 'zw', 'ab',  'kae', 'ec', 'il', 'aw', 'mg', 'mr', 'dc'};
        subjList = {'fc', 'ja', 'jfa', 'zw'};  % only those who have a data at all 9 locations
        nNoise=7; nLocSingle=9; nLocHM=2;iLoc_tgt_all=1:nLocSingle;
        noiseSD_full = [0 .055 .11 .165 .22 .275 .33]/2; % in ccc_all, col#2 is index (1-7), not real values!
        nNoise_save = nNoise;

    case 52
        SF_str = '5_JAAB';
        subjList = {'fc', 'ja', 'jfa', 'zw',    'AB', 'ASF', 'CM', 'LH', 'MJ', 'SP'};  % only those who have a data at all 9 locations
        nNoise=7; nLocSingle=9; nLocHM=2;iLoc_tgt_all=1:nLocSingle;
        noiseSD_full = [0 .055 .11 .165 .22 .275 .33, .44]/2; % combine JA (has .275 but no .44) and AB (has .44 but no .275)
        nNoise_save = 8;
end

nsubj = length(subjList);

%% Basic settings
flag_combineMode = 0;%input('        >>> Enter Combine Mode (0=not combine, 1=ecc4, 2=ecc8, 3=ecc48): ');
flag_combineEcc4 = 0; flag_combineEcc8 = 0;flag_combineEcc48 = 0;
% switch flag_combineMode
%     case 1, flag_combineEcc4 = 1;
%     case 2, flag_combineEcc8 = 1;
%     case 3, flag_combineEcc48 = 1;
% end
% if flag_combineMode, SF = nan; else, SF = input('        >>> Enter SF (4, 5, 6, 51): '); end
% nNoise = input('        >>> Enter nNoise: ');

% if flag_combineMode
flag_plotSinglePanel = 0; %if flag_plotIDVD, flag_plotSinglePanel = input('         >>> Whether plot single panel (1=plot): '); end
% ianalysisMode_all = 1:4;%input('         >>> Analysis mode to loop, in a vector [1,2,3,4]: ');
iccc_all = 5; % 5=fit PMF to ALL trials
flag_collapseHM = 1;%input('        >>> Collapse HM (1=YES, 0=NO): ');
PMFmodel_decide = 4;%input('         >>> Which model ({'Logistic', 'CumNorm', 'Gumbel',  'Weibull'}, enter nan if choose the best model): ');


%% ideal slope
% D_ideal = .0066; % see SX_IO_

%%
% if flag_combineMode
%     if flag_combineEcc8
%         subjList_JA = {'fc', 'ja', 'jfa', 'zw',                   'ec', 'il'}; % fovea + ecc8
%     else
%         subjList_JA = {'fc', 'ja', 'jfa', 'zw'}; % fov + ecc4+ecc8
%     end
% end
%
% if nNoise==9
%     noiseLvl_SX = [0 .055 .11 .165 .22 .33 .44, .66, .88];
% else
%     noiseLvl_SX = [0 .055 .11 .165 .22 .33 .44];
% end

% noiseLvl_AB = [0 .055 .11 .165 .22 .33 .44];
% noiseLvl_JA = [0, .055, .11, .165, .22, .275, .33];
% noiseLvl_SXABJA = unique([noiseLvl_SX, noiseLvl_AB, noiseLvl_JA]);
%
% switch SF
%     case 4
%         subjList= subjList_SX; iLoc_tgt_all = 1:9; nLocHM=2;
%         params.extNoiseLvl = noiseLvl_SX;
%     case 6
%         subjList= subjList_SX; iLoc_tgt_all = 1:9; nLocHM=2;
%         params.extNoiseLvl = noiseLvl_SX;
%         %         D_ideal = D_ideal_all(3);
%     case 5
%         subjList= subjList_AB; iLoc_tgt_all = 1:9; nLocHM=2;
%         params.extNoiseLvl = noiseLvl_AB;
%         %         D_ideal = D_ideal_all(2);
%     case 51
%         subjList = subjList_JA; iLoc_tgt_all = 1:9; nLocHM=2;
%         params.extNoiseLvl = noiseLvl_JA;
%         %         D_ideal = D_ideal_all(1);
% end

% noiseLvl_all = params.extNoiseLvl; % do not delete
% assert(length(params.extNoiseLvl) == nNoise)

% if flag_combineEcc4
%     iLoc_tgt_all = 1:5;
%     nLocHM=1;
%     subjList = [subjList_SX, subjList_AB, subjList_JA];
%     nsubj1 = length(subjList_SX)+length(subjList_AB); % number of subj who has max noise at 44%
% end

% if flag_combineEcc8
%     iLoc_tgt_all = 1:9;% though ecc4 are plotted, ignore them
%     nLocHM=2;
%     subjList = [subjList_AB, subjList_JA];
%     nsubj1 = length(subjList_AB);
% end
%
% if flag_combineEcc48
%     iLoc_tgt_all = 1:9;% though ecc4 are plotted, ignore them
%     nLocHM=2;
%     subjList = [subjList_AB, subjList_JA];
%     nsubj1 = length(subjList_AB);
% end

% nLocSingle = length(iLoc_tgt_all);
% nsubj = length(subjList);

if flag_collapseHM
    text_collapseHM = 'collapseHM1';
    nLoc = nLocSingle + nLocHM;
else
    text_collapseHM = 'collapseHM0';
    nLocHM = 0;
    nLoc = nLocSingle;
end
% text_combEcc4 = ''; if flag_combineEcc4, text_combEcc4 = 'ecc04/'; end
% text_combEcc8 = ''; if flag_combineEcc8, text_combEcc8 = 'ecc08/'; end
% text_combEcc48 = ''; if flag_combineEcc48, text_combEcc8 = 'ecc048/'; end

ind_LocNoise5 = combvec(1:5, 1:nNoise); % do not delete
ind_LocNoise9 = combvec(1:9, 1:nNoise); % do not delete
ind_LocNoise5_inUse = combvec(1:(5+1), 1:nNoise); % do not delete
ind_LocNoise9_inUse = combvec(1:(9+2), 1:nNoise); % do not delete

