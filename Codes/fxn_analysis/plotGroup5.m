
if SF==52, nameFolder_fig = sprintf('Fig/nNoise%d/SF%d', 7, SF);
else, nameFolder_fig = sprintf('Fig/nNoise%d/SF%d', nNoise, SF);
end
nameFolder_fig_allSubj_ = sprintf('%s/combLoc', nameFolder_fig_allSubj);  if isempty(dir(nameFolder_fig_allSubj_)), mkdir(nameFolder_fig_allSubj_), end
flag_plotIDVD = 1;
flag_plotTitle = 1;
flag_plotEnergy = 0; % 1=plot log cst and log noiseSD

% 1{'Fov'}    2{'ecc4'}    3{'ecc8'}
% 4{'HM4'}    5{'VM4'}    6{'LVM4'}    7{'UVM4'}
% 8{'HM8'}    9{'VM8'}   10{'LVM8'}    11{'UVM8'}

for iTvCModel = 1:2 % 1=LAM; 2=PTM
    for indLoc_ = {[1,2,3], [1, 4, 8], [1, 5, 9], [4,5], [6,7], [8,9], [10,11]}
        indLoc = indLoc_{1};
        %----------%
        plot_combLoc
        %----------%
    end
end
close all