
%% FOLDERS




% this needs to be modoified!!
% SF_ExtractData is not needed!!



% 
% SF_ExtractData = ['/SF', num2str(SF)];
% if flag_combineMode && isnan(SF)
%     if any(strcmp(subjName, subjList_AB)), SF_ExtractData = '/SF5_AB';
%     elseif any(strcmp(subjName, subjList_SX)), SF_ExtractData = '/SF6';
%     elseif any(strcmp(subjName, subjList_JA)), SF_ExtractData = '/SF5_JA';
%     end
%     if flag_combineEcc4, SF_SaveData = '/ecc4'; end
%     if flag_combineEcc8, SF_SaveData = '/ecc8'; end
%     if flag_combineEcc48, SF_SaveData = '/ecc48'; end
% else
%     SF_SaveData = SF_ExtractData;
% end

% nameFolder_dataOOD_extract = sprintf('Data_OOD/nNoise%d%s', nNoise, SF_ExtractData);
% nameFolder_dataOOD_save = sprintf('Data_OOD/nNoise%d%s', nNoise, SF_SaveData); if isempty(dir(nameFolder_dataOOD_save)), mkdir(nameFolder_dataOOD_save), end

%% FILES
% nameFile_fitPMF_allSubj = sprintf('%s/n%d_fitPMF_B%d_constim%d_Bin%dFilter%d_%s.mat', ...
%     nameFolder_dataOOD_save, nsubj, nBoot, fit.nBins, flag_binData, flag_filterData, text_collapseHM);

%% figure folders

% if flag_combineEcc4, nameFolder_fig = sprintf('Fig/nNoise%d/ecc4', nNoise); end
% if flag_combineEcc8, nameFolder_fig = sprintf('Fig/nNoise%d/ecc8', nNoise); end
% if flag_combineEcc48, nameFolder_fig = sprintf('Fig/nNoise%d/ecc48', nNoise); end


