function [data_CombLoc_allSubj, namesCombLoc, asym_allSubj, namesAsym] = fxn_extractAsym(data_perLoc_allSubj)

if size(data_perLoc_allSubj,2)==1, data_perLoc_allSubj = data_perLoc_allSubj'; end
[nsubj, nLoc] = size(data_perLoc_allSubj);

%% extract measurement at each loc
fov_allSubj = squeeze(data_perLoc_allSubj(:, 1));
HM4_allSubj = squeeze(nanmean(data_perLoc_allSubj(:, [2,4]), 2));
Ecc4_allSubj = squeeze(nanmean(data_perLoc_allSubj(:, 2:5), 2));
% Ecc4_allSubj = HM4_allSubj;
UVM4_allSubj = squeeze(data_perLoc_allSubj(:, 3));
LVM4_allSubj = squeeze(data_perLoc_allSubj(:, 5));
VM4_allSubj = (UVM4_allSubj+LVM4_allSubj)/2;

data_CombLoc_allSubj = {fov_allSubj, Ecc4_allSubj, HM4_allSubj, VM4_allSubj, LVM4_allSubj, UVM4_allSubj}; % 1-6
namesCombLoc = {'Fov', 'Ecc4', 'HM4', 'VM4', 'LVM4', 'UVM4'};

if nLoc>5
    HM8_allSubj = squeeze(nanmean(data_perLoc_allSubj(:, [6,8]), 2));
    Ecc8_allSubj = squeeze(nanmean(data_perLoc_allSubj(:, 6:9), 2));
    %     Ecc8_allSubj = HM8_allSubj;
    UVM8_allSubj = squeeze(data_perLoc_allSubj(:, 7));
    LVM8_allSubj = squeeze(data_perLoc_allSubj(:, 9));
    VM8_allSubj = (UVM8_allSubj+LVM8_allSubj)/2;
    
    namesCombLoc = {'Fov', 'Ecc4', 'Ecc8', 'HM4', 'VM4', 'LVM4', 'UVM4', 'HM8', 'VM8', 'LVM8', 'UVM8'};
    data_CombLoc_allSubj = {fov_allSubj, Ecc4_allSubj, Ecc8_allSubj, ... % 1-3
        HM4_allSubj, VM4_allSubj, LVM4_allSubj, UVM4_allSubj, ... % 4-7
        HM8_allSubj, VM8_allSubj, LVM8_allSubj, UVM8_allSubj};    % 8-11
end

%% get asymmetry
if nLoc==5
    EE04_allSubj = getAsym(data_CombLoc_allSubj{1}, data_CombLoc_allSubj{2});
    HVA4_allSubj = getAsym(data_CombLoc_allSubj{3}, data_CombLoc_allSubj{4});
    VMA4_allSubj = getAsym(data_CombLoc_allSubj{5}, data_CombLoc_allSubj{6});
else
    EE04_allSubj = getAsym(data_CombLoc_allSubj{1}, data_CombLoc_allSubj{2});
    HVA4_allSubj = getAsym(data_CombLoc_allSubj{4}, data_CombLoc_allSubj{5});
    VMA4_allSubj = getAsym(data_CombLoc_allSubj{6}, data_CombLoc_allSubj{7});
end
namesAsym = {'EE-04', 'HVA-Ecc4', 'VMA-Ecc4'};
asym_allSubj = 100*[EE04_allSubj, HVA4_allSubj, VMA4_allSubj];

% namesCombLoc = {'Fov', 'Ecc4', 'Ecc8', 'HM4', 'VM4', 'LVM4', 'UVM4', 'HM8', 'VM8', 'LVM8', 'UVM8'};
if nLoc>5
    EE08_allSubj = getAsym(data_CombLoc_allSubj{1}, data_CombLoc_allSubj{3});
    EE48_allSubj = getAsym(data_CombLoc_allSubj{2}, data_CombLoc_allSubj{3});
    HVA8_allSubj = getAsym(data_CombLoc_allSubj{8}, data_CombLoc_allSubj{9});
    VMA8_allSubj = getAsym(data_CombLoc_allSubj{10}, data_CombLoc_allSubj{11});
    
    namesAsym = {'EE-04', 'EE-08', 'EE-48', 'HVA-Ecc4', 'VMA-Ecc4', 'HVA-Ecc8', 'VMA-Ecc8'};
    asym_allSubj = 100*[EE04_allSubj, EE08_allSubj, EE48_allSubj, HVA4_allSubj, VMA4_allSubj, HVA8_allSubj, VMA8_allSubj];
end
