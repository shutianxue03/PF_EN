function params_mat = MC_cell2mat(indParamVary, params_cell, nLoc)
nParams_full = length(indParamVary);

% Initialize the output cell array
params_mat = nan(nLoc, nParams_full);

for iLoc = 1:nLoc
    for iParam = 1:nParams_full
        switch nLoc
            case 2
                switch indParamVary(iParam)
                    case 0 % fixed
                        params_mat(:, iParam) = ones(1,nLoc)*params_cell{iParam};
                    case 1
                        params_mat(:, iParam) = params_cell{iParam};
                end

            case 3
                switch indParamVary(iParam)
                    case 0 % fixed
                        params_mat(:, iParam) = ones(1,nLoc)*params_cell{iParam};
                    case 4
                        params_mat(:, iParam) = params_cell{iParam};

                    otherwise
                        % Handle partially shared parameters
                        % 1: Fixed for 2nd & 3rd, may differ for 1st
                        % 2: Fixed for 1st & 3rd, may differ for 2nd
                        % 3: Fixed for 1st & 2nd, may differ for 3rd
                        if iLoc == indParamVary(iParam)
                            params_mat(iLoc, iParam) = params_cell{iParam}(1);
                        else
                            switch iLoc
                                case 1, iLoc_non = [2,3];
                                case 2, iLoc_non = [1,3];
                                case 3, iLoc_non = [1,2];
                            end
                            params_mat(iLoc_non, iParam) = ones(1,nLoc-1)*params_cell{iParam}(2); % Default to shared value
                        end
                end % switch indParamVary(iParam)
            otherwise
                switch indParamVary(iParam)
                    case 1
                        params_mat(:, iParam) = params_cell{iParam};
                end
        end % switch nLoc
    end % iParam
end % iLoc
