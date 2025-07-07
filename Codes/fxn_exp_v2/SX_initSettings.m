

constant.expMode= input('         >>> Enter exp mode (2=practice, 1=titration, 3=constim, 4=manual, 5=remedy): ');%8;
constant.demo = 0; if constant.expMode==2, constant.demo = input('         >>> Show demo (1=yes, 0=no): '); end
if constant.expMode==2, participant.subjName = 'practice';
else, participant.subjName = string(input('         >>> Enter initial: '));%'SX';
end
constant.SF = input('         >>> Enter SF (cpd) (4 or 6): ');%8;
constant.screenMode = 1; % 1 = 1280x960;2=800x600;3=400x300
constant.EYETRACK =  input('         >>> Eyetracker on? (1=ON, 0=OFF): '); % 0=NO eyetracking
constant.flagSimulate = 0;%input('         >>> Simulate? (1=YES, 0=NO): ');
constant.CUE = 0; %input('>>>> CUE (no: 0; exo: 1; endo: 2): ');

if constant.expMode == 2 % practice
    constant.EYETRACK=0; 
    constant.nTrialsPerStair = 5;
    params.extNoiseLvl = [0, .88];
else
%     constant.ind_Neq = 1:9;% input('         >>> Enter index of noise in a vector: ');%[1:7]; % these are noise levels just for piloting
    params.extNoiseLvl = input('         >>> Enter noise SD doubled (usualy [0, .055, .11, .165, .22, .33, .44, .66, .88]): '); 
    if constant.expMode~=4
        constant.nTrialsPerStair = input('         >>> Number of trials per staircase (default 12): '); % default is 12
    end
end

constant.nNoiseSD = length(params.extNoiseLvl);

% Location
constant.iLoc_tgt_all = input('         >>> Enter index of locations (default 1:9): ');%[1:9]; %these are locations just for piloting
constant.nLoc_tgt = length(constant.iLoc_tgt_all); % the number of loc at which Gabor will show up (always starts from fovea=1)

constant.nRepet = 2; % default is 5-6; has to be an even number!!
constant.ntrialsPerConstim3 = 40;
constant.ntrialsPerConstim4 =input('         >>> Number of trials per point (default 40): ');%40;
% if constant.expMode == 4, constant.ntrialsPerConstim4 = input('         >>> Enter the number trials per added cst level (40 or 50): ');end

%% processing of settings
if constant.screenMode~=1, constant.EYETRACK = 0; end
constant.names_expModes = {'Experiment', 'Practice', 'Additional Data-Anchoring points', 'Additional Data-Staircase', 'Exp'};
constant.names_expModes_save = {'stair', '', 'const', 'stair'};
constant.namesConfidence = {'Low', 'High'};
constant.names_elModes = {'OFF', 'ON'};
constant.names_datName = {'NOCUE', 'ENDO', 'EXO'};
constant.datName = constant.names_datName{constant.CUE+1};
constant.nameFolder = sprintf('Data/nNoise%d/SF%d/%s', constant.nNoiseSD, constant.SF, participant.subjName);

% 
% 
% constant.expMode= input('         >>> Enter exp mode (2=practice, 1=titration, 3=constim, 4=manual, 5=remedy): ');%8;
% constant.demo = 0; if constant.expMode==2, constant.demo = input('         >>> Show demo (1=yes, 0=no): '); end
% if constant.expMode==2, participant.subjName = 'practice';
% else, participant.subjName = string(input('         >>> Enter initial: '));%'SX';
% end
% constant.SF = input('         >>> Enter SF (cpd): ');%8;
% constant.screenMode = 1; % 1 = 1280x960;2=800x600;3=400x300
% constant.EYETRACK =  input('         >>> Eyetracker on? (1=ON, 0=OFF): '); % 0=NO eyetracking
% constant.flagSimulate =0;%input('         >>> Simulate? (1=YES, 0=NO): ');
% constant.CUE = 0; %input('>>>> CUE (no: 0; exo: 1;a endo: 2): ');
% 
% %%
% if constant.expMode == 2 % practice
%     constant.EYETRACK=0; 
%     constant.nTrialsPerStair = 5;
%     constant.ind_Neq = [1,7];
% else
%     constant.ind_Neq = 1:9;% input('         >>> Enter index of noise in a vector: ');%[1:7]; % these are noise levels just for piloting
%     constant.nNoiseSD = 9;
%     constant.nTrialsPerStair = input('         >>> Number of trials per staircase: '); % default is 15
% end
% constant.nNoiseSD = length(constant.ind_Neq);
% 
% % Location
% constant.iLoc_tgt_all = input('         >>> Enter index of locations: ');%[1:9]; %these are locations just for piloting
% constant.nLoc_tgt = length(constant.iLoc_tgt_all); % the number of loc at which Gabor will show up (always starts from fovea=1)
% 
% constant.nRepet = 2; % default is 5-6; has to be an even number!!
% constant.ntrialsPerConstim3 = 40;
% constant.ntrialsPerConstim4 =input('         >>> Number of trials per point: ');%40;
% % if constant.expMode == 4, constant.ntrialsPerConstim4 = input('         >>> Enter the number trials per added cst level (40 or 50): ');end
% 
% %% processing of settings
% if constant.screenMode~=1, constant.EYETRACK = 0; end
% constant.names_expModes = {'Experiment', 'Practice', 'Additional Data-Anchoring points', 'Additional Data-Staircase', 'Exp'};
% constant.names_expModes_save = {'stair', '', 'const', 'stair'};
% constant.namesConfidence = {'Low', 'High'};
% constant.names_elModes = {'OFF', 'ON'};
% constant.names_datName = {'NOCUE', 'ENDO', 'EXO'};
% constant.datName = constant.names_datName{constant.CUE+1};
% constant.nameFolder = sprintf('Data/nNoise%d/SF%d/%s', length(constant.ind_Neq), constant.SF, participant.subjName);
