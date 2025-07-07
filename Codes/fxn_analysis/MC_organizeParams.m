% 
% function params_forFit_reo = MC_organizeParams(printFlag, namesParams, nParams_full, nLoc, indParamVary, params_forFit)
% params_forFit_reo = cell(1,nParams_full);
% % paramsLen = nLoc .^ indParamVary; %
% 
% if printFlag, fprintf('%s\n', num2str(indParamVary)), end
% 
% for iParam = 1:nParams_full
%     param = params_forFit{iParam};
%     switch nLoc
%         case 2
%             
%             switch indParamVary(iParam)
%                 case 0
%                     param
%                 case 1
%             end
%         case 3
%             
%     end
% end
% 
% %     % decide the start
% %     if iParam==1, iStart = 1;
% %     else, iStart = sum(paramsLen(1:iParam-1))+1;
% %     end
% %
% %     % decide the end
% %     if iParam == nParams_full, iEnd =  sum(paramsLen);
% %     else, iEnd = sum(paramsLen) - sum(paramsLen(iParam+1:end));
% %     end
% %
% %     params_fit{iParam} = params_forFit(iStart:iEnd);
% %
% %     if printFlag
% %         fprintf('%s: %s\n', namesParams{iParam}, num2str(params_fit{iParam}))
% %     end
% % end
% 
% if printFlag, fprintf('\n'), end
% 
