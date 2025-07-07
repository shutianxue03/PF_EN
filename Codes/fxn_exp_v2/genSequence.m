function [sequence] = genSequence


% training
fbaSequence = [randperm(2)];
nblocs = length(fbaSequence);

sequence = [];
for ibloc = 1:nblocs
    ibloc
    fba = fbaSequence(ibloc);
    sequence(ibloc).dOri       = [];
    sequence(ibloc).fcue       = [];
    sequence(ibloc).scue       = [];
    sequence(ibloc).fprobe     = [];
    sequence(ibloc).sprobe     = [];
    sequence(ibloc).target     = [];    
    sequence(ibloc).distractor = [];    
    
    bloc        = [];
    bloc.fcue   = fba.*ones(1,72); % 1:tilt-L 2:tilt-R 3:neutral
    if fba==3
        bloc.fprobe = [1 1 1 1 1 1 2 2 1 1 2 2 1 1 1 1 2 2 2 2 2 2 2 2 1 1 2 2 1 1 2 2 2 2 1 1];
    elseif fba==1
        bloc.fprobe = repmat([1 1 2],[1,24]);
    elseif fba==2
        bloc.fprobe = repmat([2 2 1],[1,24])
    end
    bloc.scue       = repmat([1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 1 1 1],[1,4]); % 1:pos-L 2:pos-R 3:neutral
    bloc.sprobe     = repmat([1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2],[1,4]);
    
    bloc.target     = [ones(1,18) zeros(1,18) ones(1,18) zeros(1,18)];
    bloc.distractor = [zeros(1,18) ones(1,18) ones(1,18) zeros(1,18)];
    
    bloc.dOri       = kron([1,2],ones(1,72));
    bloc.fcue       = repmat(bloc.fcue,[1,2]);
    bloc.scue       = repmat(bloc.scue,[1,2]);
    bloc.fprobe     = repmat(bloc.fprobe,[1,2]);
    bloc.sprobe     = repmat(bloc.sprobe,[1,2]);
    bloc.target     = repmat(bloc.target,[1,2]);
    bloc.distractor = repmat(bloc.distractor,[1,2]);
        
    
    
    % SPATIAL | FEATURE | TARGET | DISTR >> N
    % -------------------------------
    
    % valid   | valid   | signal | signal >> 16
    % valid   | valid   | noise  | signal >> 16
    % valid   | valid   | signal | noise  >> 16
    % valid   | valid   | noise  | noise  >> 16
    
    % valid   | invalid | signal | signal >> 8
    % valid   | invalid | noise  | signal >> 8
    % valid   | invalid | signal | noise  >> 8
    % valid   | invalid | noise  | noise  >> 8
    
    % invalid | valid   | signal | signal >> 8
    % invalid | valid   | noise  | signal >> 8
    % invalid | valid   | signal | noise  >> 8
    % invalid | valid   | noise  | noise  >> 8
    
    % invalid | invalid | signal | signal >> 4
    % invalid | invalid | noise  | signal >> 4
    % invalid | invalid | signal | noise  >> 4
    % invalid | invalid | noise  | noise  >> 4
    

    checkMatrix(1,1)   = [sum(bloc.scue==bloc.sprobe & bloc.fcue==bloc.fprobe & bloc.target==1 & bloc.distractor==1)];
    checkMatrix(1,2)   = [sum(bloc.scue==bloc.sprobe & bloc.fcue==bloc.fprobe & bloc.target==0 & bloc.distractor==1)];
    checkMatrix(1,3)   = [sum(bloc.scue==bloc.sprobe & bloc.fcue==bloc.fprobe & bloc.target==1 & bloc.distractor==0)];
    checkMatrix(1,4)   = [sum(bloc.scue==bloc.sprobe & bloc.fcue==bloc.fprobe & bloc.target==1 & bloc.distractor==0)];
    
    checkMatrix(2,1)   = [sum(bloc.scue==bloc.sprobe & bloc.fcue~=bloc.fprobe & bloc.target==1 & bloc.distractor==1)];
    checkMatrix(2,2)   = [sum(bloc.scue==bloc.sprobe & bloc.fcue~=bloc.fprobe & bloc.target==0 & bloc.distractor==1)];
    checkMatrix(2,3)   = [sum(bloc.scue==bloc.sprobe & bloc.fcue~=bloc.fprobe & bloc.target==1 & bloc.distractor==0)];
    checkMatrix(2,4)   = [sum(bloc.scue==bloc.sprobe & bloc.fcue~=bloc.fprobe & bloc.target==1 & bloc.distractor==0)];
    
    checkMatrix(3,1)   = [sum(bloc.scue~=bloc.sprobe & bloc.fcue==bloc.fprobe & bloc.target==1 & bloc.distractor==1)];
    checkMatrix(3,2)   = [sum(bloc.scue~=bloc.sprobe & bloc.fcue==bloc.fprobe & bloc.target==0 & bloc.distractor==1)];
    checkMatrix(3,3)   = [sum(bloc.scue~=bloc.sprobe & bloc.fcue==bloc.fprobe & bloc.target==1 & bloc.distractor==0)];
    checkMatrix(3,4)   = [sum(bloc.scue~=bloc.sprobe & bloc.fcue==bloc.fprobe & bloc.target==1 & bloc.distractor==0)];
    
    checkMatrix(4,1)   = [sum(bloc.scue~=bloc.sprobe & bloc.fcue~=bloc.fprobe & bloc.target==1 & bloc.distractor==1)];
    checkMatrix(4,2)   = [sum(bloc.scue~=bloc.sprobe & bloc.fcue~=bloc.fprobe & bloc.target==0 & bloc.distractor==1)];
    checkMatrix(4,3)   = [sum(bloc.scue~=bloc.sprobe & bloc.fcue~=bloc.fprobe & bloc.target==1 & bloc.distractor==0)];
    checkMatrix(4,4)   = [sum(bloc.scue~=bloc.sprobe & bloc.fcue~=bloc.fprobe & bloc.target==1 & bloc.distractor==0)];
    
    checkMatrix
    predictedValidity = round(100.*[.666*.666; .666.*.333; .333.*.666; .333.*.333])
    checkValidity     = round(100.*(sum(checkMatrix,2)./sum(sum(checkMatrix))))
    if ~predictedValidity==checkValidity
        error('check validity!!')
    end
    
    ifilt = {
        find(bloc.fprobe == bloc.fcue & bloc.sprobe == bloc.scue & bloc.target == 1 & bloc.distractor == 1), ...
        find(bloc.fprobe == bloc.fcue & bloc.sprobe == bloc.scue & bloc.target == 0 & bloc.distractor == 1), ...
        find(bloc.fprobe == bloc.fcue & bloc.sprobe == bloc.scue & bloc.target == 1 & bloc.distractor == 0), ...
        find(bloc.fprobe == bloc.fcue & bloc.sprobe == bloc.scue & bloc.target == 0 & bloc.distractor == 0), ...
        find(bloc.fprobe == bloc.fcue & bloc.sprobe ~= bloc.scue & bloc.target == 1 & bloc.distractor == 1), ...
        find(bloc.fprobe == bloc.fcue & bloc.sprobe ~= bloc.scue & bloc.target == 0 & bloc.distractor == 1), ...
        find(bloc.fprobe == bloc.fcue & bloc.sprobe ~= bloc.scue & bloc.target == 1 & bloc.distractor == 0), ...
        find(bloc.fprobe == bloc.fcue & bloc.sprobe ~= bloc.scue & bloc.target == 0 & bloc.distractor == 0), ...
        find(bloc.fprobe ~= bloc.fcue & bloc.sprobe == bloc.scue & bloc.target == 1 & bloc.distractor == 1), ...
        find(bloc.fprobe ~= bloc.fcue & bloc.sprobe == bloc.scue & bloc.target == 0 & bloc.distractor == 1), ...
        find(bloc.fprobe ~= bloc.fcue & bloc.sprobe == bloc.scue & bloc.target == 1 & bloc.distractor == 0), ...
        find(bloc.fprobe ~= bloc.fcue & bloc.sprobe == bloc.scue & bloc.target == 0 & bloc.distractor == 0), ...
        find(bloc.fprobe ~= bloc.fcue & bloc.sprobe ~= bloc.scue & bloc.target == 1 & bloc.distractor == 1), ...
        find(bloc.fprobe ~= bloc.fcue & bloc.sprobe ~= bloc.scue & bloc.target == 0 & bloc.distractor == 1), ...
        find(bloc.fprobe ~= bloc.fcue & bloc.sprobe ~= bloc.scue & bloc.target == 1 & bloc.distractor == 0), ...
        find(bloc.fprobe ~= bloc.fcue & bloc.sprobe ~= bloc.scue & bloc.target == 0 & bloc.distractor == 0)};
    nfilt = [4,4,4,4,2,2,2,2,2,2,2,2,1,1,1,1];
    nminibloc = 4;
    
    for iminibloc = 1:nminibloc
        iminibloc
        
        while true
            iperm = [];
            for i = 1:length(ifilt)
                k = randperm(length(ifilt{i}));
                iperm = [iperm,ifilt{i}(k(1:nfilt(i)))];
            end
            iperm = iperm(randperm(36));
            if ...
                    ~HasConsecutiveValues(bloc.scue(iperm),4) && ...
                    ~HasConsecutiveValues(bloc.sprobe(iperm) ~= bloc.scue(iperm),4,[false]) && ...
                    ~HasConsecutiveValues(bloc.target(iperm),4)
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