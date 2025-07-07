function params_forFit_cell = MC_vec2cell(indParamVary, params_forFit_vec, nLoc)

% MC_vec2cell: Converts a vector of parameters into a cell array, 
%              where each cell contains parameters based on their 
%              variation across locations.
%
% Inputs:
%   - indParamVary: Array indicating parameter variation:
%                   (0 = fixed, 1/2/3/4 = varying in specific ways).
%   - params_forFit_vec: Vector of all parameters to be converted.
%   - nLoc: Number of locations (e.g., 2 or 3).
%
% Output:
%   - params_forFit_cell: Cell array where each cell corresponds to
%                         a parameter and its associated values.

% Number of parameters in the model
nParams_full = length(indParamVary);

% Initialize the output cell array
params_forFit_cell = cell(1, nParams_full);

% Adjust parameter variation indices for nLoc = 3
ind_nParams = indParamVary;
if nLoc == 3
    for iParam = 1:nParams_full
        if indParamVary(iParam) == 4
            ind_nParams(iParam) = 1; % Parameter varies freely across all locations
        elseif any(indParamVary(iParam) == [1, 2, 3])
            ind_nParams(iParam) = log(2) / log(nLoc); % Ensure nLoc^ind_nParams = 2
        end
    end
end

% Compute the number of values for each parameter
paramsLen = round(nLoc .^ ind_nParams); % Number of values per parameter

% Convert the parameter vector into a cell array
for iParam = 1:nParams_full
    % Determine the start index for the current parameter
    if iParam == 1
        iStart = 1;
    else
        iStart = sum(paramsLen(1:iParam-1)) + 1;
    end
    
    % Determine the end index for the current parameter
    if iParam == nParams_full
        iEnd = sum(paramsLen);
    else
        iEnd = sum(paramsLen(1:iParam));
    end
    
    % Assign the corresponding portion of the vector to the cell
    params_forFit_cell{iParam} = params_forFit_vec(iStart:iEnd);
end

end
