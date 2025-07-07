function [sequence] = genSequence_Titration

if nargin < 1
    nblocs = 1;
end

% addpath('./Toolbox');

bloc           = [];
bloc.dOri      = kron([1,2],ones(1,64));
bloc.fcue      = repmat(3,[1,64]);
bloc.scue      = repmat(3,[1,64]);
bloc.fprobe    = repmat([1 1 2 2],[1,16]);
bloc.sprobe    = repmat([1 2 1 2],[1,16]);

bloc.target     = repmat([ones(1,4) zeros(1,4) ones(1,4) zeros(1,4)],[1,4]);
bloc.distractor = repmat([ones(1,4) ones(1,4) zeros(1,4) zeros(1,4)],[1,4]);

bloc.dOri      = kron([1,2],ones(1,64));
bloc.fcue       = repmat(bloc.fcue,[1,2]);
bloc.scue       = repmat(bloc.scue,[1,2]);
bloc.fprobe     = repmat(bloc.fprobe,[1,2]);
bloc.sprobe     = repmat(bloc.sprobe,[1,2]);
bloc.target     = repmat(bloc.target,[1,2]);
bloc.distractor = repmat(bloc.distractor,[1,2]);

% SPATIAL | FEATURE | TARGET | DISTR >> N
% -------------------------------

% neutral   | neutral   | signal | signal >> 32
% neutral   | neutral   | noise  | signal >> 32
% neutral   | neutral   | signal | noise  >> 32
% neutral   | neutral   | noise  | noise  >> 32


checkMatrix(1,1)   = [sum(bloc.sprobe==1 & bloc.fprobe==1 & bloc.target==1 & bloc.distractor==1)];
checkMatrix(1,2)   = [sum(bloc.sprobe==2 & bloc.fprobe==1 & bloc.target==1 & bloc.distractor==1)];
checkMatrix(1,3)   = [sum(bloc.sprobe==1 & bloc.fprobe==2 & bloc.target==1 & bloc.distractor==1)];
checkMatrix(1,4)   = [sum(bloc.sprobe==2 & bloc.fprobe==2 & bloc.target==1 & bloc.distractor==1)];
checkMatrix(2,1)   = [sum(bloc.sprobe==1 & bloc.fprobe==1 & bloc.target==1 & bloc.distractor==0)];
checkMatrix(2,2)   = [sum(bloc.sprobe==2 & bloc.fprobe==1 & bloc.target==1 & bloc.distractor==0)];
checkMatrix(2,3)   = [sum(bloc.sprobe==1 & bloc.fprobe==2 & bloc.target==1 & bloc.distractor==0)];
checkMatrix(2,4)   = [sum(bloc.sprobe==2 & bloc.fprobe==2 & bloc.target==1 & bloc.distractor==0)];
checkMatrix(3,1)   = [sum(bloc.sprobe==1 & bloc.fprobe==1 & bloc.target==0 & bloc.distractor==1)];
checkMatrix(3,2)   = [sum(bloc.sprobe==2 & bloc.fprobe==1 & bloc.target==0 & bloc.distractor==1)];
checkMatrix(3,3)   = [sum(bloc.sprobe==1 & bloc.fprobe==2 & bloc.target==0 & bloc.distractor==1)];
checkMatrix(3,4)   = [sum(bloc.sprobe==2 & bloc.fprobe==2 & bloc.target==0 & bloc.distractor==1)];
checkMatrix(4,1)   = [sum(bloc.sprobe==1 & bloc.fprobe==1 & bloc.target==0 & bloc.distractor==0)];
checkMatrix(4,2)   = [sum(bloc.sprobe==2 & bloc.fprobe==1 & bloc.target==0 & bloc.distractor==0)];
checkMatrix(4,3)   = [sum(bloc.sprobe==1 & bloc.fprobe==2 & bloc.target==0 & bloc.distractor==0)];
checkMatrix(4,4)   = [sum(bloc.sprobe==2 & bloc.fprobe==2 & bloc.target==0 & bloc.distractor==0)];
checkMatrix


sequence = [];
for ibloc = 1:nblocs
    ibloc
    
    sequence(ibloc).dOri      = [];
    sequence(ibloc).fcue       = [];
    sequence(ibloc).scue       = [];
    sequence(ibloc).fprobe     = [];
    sequence(ibloc).sprobe     = [];
    sequence(ibloc).target     = [];
    sequence(ibloc).distractor = [];

    ifilt = {
        find(bloc.target == 1 & bloc.distractor == 1), ...
        find(bloc.target == 1 & bloc.distractor == 0), ...
        find(bloc.target == 0 & bloc.distractor == 1), ...
        find(bloc.target == 0 & bloc.distractor == 0), ...
        };
    nfilt = [8,8,8,8];
    
    for iminibloc = 1:4
        iminibloc
        
        while true
            iperm = [];
            for i = 1:length(ifilt)
                k = randperm(length(ifilt{i}));
                iperm = [iperm,ifilt{i}(k(1:nfilt(i)))];
            end
            iperm = iperm(randperm(32));
            if ...
                    ~HasConsecutiveValues(bloc.target(iperm),4)
                ~HasConsecutiveValues(bloc.distractor(iperm),4)
                break
            end
        end
        
        sequence(ibloc).dOri       = [sequence(ibloc).dOri,bloc.dOri(iperm)];
        sequence(ibloc).fcue       = [sequence(ibloc).fcue,bloc.fcue(iperm)];
        sequence(ibloc).scue       = [sequence(ibloc).scue,bloc.scue(iperm)];
        sequence(ibloc).fprobe     = [sequence(ibloc).fprobe,bloc.fprobe(iperm)];
        sequence(ibloc).sprobe     = [sequence(ibloc).sprobe,bloc.sprobe(iperm)];
        sequence(ibloc).target     = [sequence(ibloc).target,bloc.target(iperm)];
        sequence(ibloc).distractor = [sequence(ibloc).distractor,bloc.distractor(iperm)];
        
        for i = 1:length(ifilt)
            ifilt{i} = setdiff(ifilt{i},iperm);
        end
        
    end
    
end

end