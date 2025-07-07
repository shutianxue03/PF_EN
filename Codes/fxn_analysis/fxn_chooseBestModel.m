% 
% %% empty containers (for reirganizing)
% PSE_best_all = nan(nLocSingle, nNoise, nPerf);
% imodel_best_all = nan(nLocSingle, nNoise);
% slope_best_all = imodel_best_all;
% lapse_best_all = imodel_best_all;
% guess_best_all = imodel_best_all;
% 
% yfit_allB = cell(nLocSingle, nNoise, nModels);
% PSE_allB = nan(fit.nBoot, nLocSingle, nNoise, nModels, nPerf);
% LL_allB = nan(fit.nBoot, nLocSingle, nNoise, nModels);
% 
% cst_log_unik_all = cell(nLocSingle, nNoise);
% nCorr_all = cst_log_unik_all;
% nData_all = cst_log_unik_all;
% yfit_all = cst_log_unik_all;
% 
% %%
% for iLocNoise_ = 1:nLoc*nNoise
%     if flag_collapseHM % assign the entry of collapsed HM to Left and Right
%         if nLocSingle==5 
%             ind_LocNoise = ind_LocNoise5;
%             if sum(find(iLocNoise_ == 1:2:5)), iLocNoise = iLocNoise_;
%             elseif sum(find(iLocNoise_ == [2,4])), iLocNoise = 6;
%             end
%         else
%             ind_LocNoise = ind_LocNoise9;
%             if sum(find(iLocNoise_ == 1:2:9)), iLocNoise = iLocNoise_;
%             elseif sum(find(iLocNoise_ == [2,4])), iLocNoise = 10;
%             elseif sum(find(iLocNoise_ == [6,8])), iLocNoise = 11;
%             end
%         end
%         
%     else
%         if flag_combineEcc4 && SF=='5'
%             icol = mod(iLocNoise_, nLoc);
%             if icol==0, icol=nLoc;irow = iLocNoise_/nLoc;
%             else, irow = floor(iLocNoise_/nLoc)+1;
%             end
%             
%             ind_reshaped9 = reshape(1:7*9, [9,7])';
%             ind_reshaped5 = reshape(1:7*5, [5,7])';
%             
%             iLocNoise = ind_reshaped9(irow, icol);
%             ind_LocNoise = ind_LocNoise9;
%         else
%             iLocNoise = iLocNoise_;
%             if SF=='6', ind_LocNoise = ind_LocNoise5;else, ind_LocNoise = ind_LocNoise9; end
%         end
%     end
%     iLoc = ind_LocNoise(1, iLocNoise);
%     iNoise = ind_LocNoise(2, iLocNoise);
%     
%     fprintf('%d (%d)/%d: L%dN%d ', iLocNoise_, iLocNoise, nLoc*nNoise, iLoc, iNoise)
%     
%     if isempty(PSE_allLocN{iLocNoise})
%         fprintf('*NOT exist*\n')
%     else
%         fprintf('*Loaded*\n')
%         
%         iModel_notNaN = [];
%         for iModel = 1:nModels
%             if isnan(getCI(PSE_allLocN{iLocNoise}(:, iModel, :), 1, 1)), continue
%             else, iModel_notNaN = [iModel_notNaN, iModel];
%             end
%         end
%         
%         % fprintf('L%dN%d: %s\n', iLoc, iNoise, num2str(iModel_notNaN))
%         if isempty(iModel_notNaN), iModel_notNaN = 1; end
%         [~, imodel_best] = max(getCI(LL_allLocN{iLocNoise}(:, iModel_notNaN), 1, 1));
%         
%         if ~model_decide
%             model_decide = iModel_notNaN(imodel_best);
%         end
%         
%         PSE_best_all(iLoc, iNoise, :) = getCI(PSE_allLocN{iLocNoise}(:, model_decide, :));
%         slope_best_all(iLoc, iNoise) = getCI(slope_allLocN{iLocNoise}(:, model_decide));
%         lapse_best_all(iLoc, iNoise) = getCI(lapse_allLocN{iLocNoise}(:, model_decide));
%         guess_best_all(iLoc, iNoise) = getCI(guess_allLocN{iLocNoise}(:, model_decide));
%         
%         % reorganize data
%         cst_log_unik_all{iLoc, iNoise} = cst_log_unik_allLocN{iLocNoise};
%         nCorr_all{iLoc, iNoise} = nCorr_allLocN{iLocNoise};
%         nData_all{iLoc, iNoise} = nData_allLocN{iLocNoise};
%         
%         for iModel = 1:nModels, yfit_allB{iLoc, iNoise, iModel} = squeeze(yfit_allLocN{iLocNoise}(:, iModel, :)); end
%         PSE_allB(:, iLoc, iNoise, :, :) = PSE_allLocN{iLocNoise};
%         LL_allB(:, iLoc, iNoise, :)  = LL_allLocN{iLocNoise};
%     end
% end %iLocNoise
% 
