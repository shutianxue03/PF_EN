function threshEnergy_pred = fxn_predTvC_varyLocMC(iTvCModel, indParamVary, dprimes, SF_fit, noiseEnergy, params_forFit_vec, nLoc)
% fxn_PTM_MC: Predicts contrast for given performance levels and noise across multiple locations, using a parameterized model.
%
% Inputs:
%   - indParamVary: Array indicating parameter variation:
%                   (0 = fixed, 1 = varies across locations).
%   - dprimes: Array of performance levels (e.g., d-prime values).
%   - noiseEnergy: Array of noise levels.
%   - params_forFit: Fitted model parameters (structured by indParamVary).
%   - nLoc: Number of locations or conditions.
%
% Output:
%   - threshEnergy_pred: Flattened vector of predicted contrast energies.

% Define the number of parameters, performance levels, and noise levels
nParams_full = length(indParamVary); % Total number of parameters in the model
switch iTvCModel
    case 1, nPerf = 1;
    case 2, nPerf = length(dprimes); % Number of d-prime levels
end
nNoise = length(noiseEnergy); % Number of noise energy levels

% convert params_forFit_vec to params_forFit_cell
%------------------------------------------------%
params_forFit_cell = MC_vec2cell(indParamVary, params_forFit_vec, nLoc);
%------------------------------------------------%

% Initialize a 3D array to store predicted contrast energies
threshEnergy_pred = nan(nLoc, nNoise, nPerf);

% Iterate over all performance levels and locations
for iPerf = 1:nPerf
    for iLoc = 1:nLoc
        % Initialize a parameter array for the current location
        params_full = nan(1, nParams_full);

        % Assign parameter values based on indParamVary and nLoc
        for iParam = 1:nParams_full
            switch nLoc
                case 1
                    params_full(iParam) = params_forFit_vec(iParam);
                case 2
                    % Handle parameters for two locations
                    switch indParamVary(iParam)
                        case 0 % Parameter is fixed for both locations (shared)
                            params_full(iParam) = params_forFit_cell{iParam};
                        case 1 % Parameter varies freely between two locations
                            params_full(iParam) = params_forFit_cell{iParam}(iLoc);
                    end
                case 3
                    % Handle parameters for three locations
                    switch indParamVary(iParam)
                        case 0 % Parameter is fixed across all three locations (shared)
                            params_full(iParam) = params_forFit_cell{iParam};
                        case 4 % Parameter varies freely across all three locations
                            params_full(iParam) = params_forFit_cell{iParam}(iLoc);
                        otherwise
                            % Handle partially shared parameters
                            % 1: Fixed for 2nd & 3rd, may differ for 1st
                            % 2: Fixed for 1st & 3rd, may differ for 2nd
                            % 3: Fixed for 1st & 2nd, may differ for 3rd
                            if iLoc == indParamVary(iParam)
                                params_full(iParam) = params_forFit_cell{iParam}(1);
                            else
                                params_full(iParam) = params_forFit_cell{iParam}(2); % Default to shared value
                            end
                    end
                case 4 % meridian/loc x ecc
                    switch indParamVary(iParam)
                        case 1 % Parameter varies freely across all three locations
                            params_full(iParam) = params_forFit_cell{iParam}(iLoc);
                    end
                case 7 % 7Single
                    % Handle parameters for three locations
                    switch indParamVary(iParam)
                        case 1 % Parameter varies freely across all three locations
                            params_full(iParam) = params_forFit_cell{iParam}(iLoc);
                    end
            end% switch nLoc
        end % iParam
        
        % Predict contrast energy for the current location and performance level
        switch iTvCModel
            case 1
                %--------------------------------------------------------------------------------%
                threshEnergy_pred(iLoc, :, iPerf) = fxn_LAM(params_full, noiseEnergy);
                %--------------------------------------------------------------------------------%
            case 2
                indParamExist = [0,1,1,1]; % Placeholder for parameter existence
                %--------------------------------------------------------------------------------%
                threshEnergy_pred(iLoc, :, iPerf) = fxn_PTM(indParamExist, params_full, noiseEnergy, dprimes(iPerf), SF_fit);
                %--------------------------------------------------------------------------------%
        end % iTvCModel
    end % iLoc
end % iPerf

% Reshape the 3D array of predicted energies into a single column vector
threshEnergy_pred = threshEnergy_pred(:);