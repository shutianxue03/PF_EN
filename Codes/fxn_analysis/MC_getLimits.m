function [params0_vec, ub_vec, lb_vec] = MC_getLimits(indParamVary, params0_full, ub_full, lb_full, nLoc)
% MC_getLimits: Constructs parameter limits and initial values for a model.
%
% Inputs:
%   - indParamVary: Specifies how each parameter varies across locations.
%       For nLoc = 2:
%         - 0: Parameter is fixed between the two locations (shared).
%         - 1: Parameter varies between the two locations (two parameters to fit).
%       For nLoc = 3:
%         - 0: Parameter is fixed across all three locations (one parameter to fit).
%         - 1: Parameter is fixed for the 2nd & 3rd locations but may differ for the 1st (two parameters to fit).
%         - 2: Parameter is fixed for the 1st & 3rd locations but may differ for the 2nd (two parameters to fit).
%         - 3: Parameter is fixed for the 1st & 2nd locations but may differ for the 3rd (two parameters to fit).
%         - 4: Parameter varies freely across all three locations (three parameters to fit).
%   - params0_full: Full set of initial parameter values.
%   - ub_full: Full set of upper bounds for parameters.
%   - lb_full: Full set of lower bounds for parameters.
%   - nLoc: Number of locations or conditions for each parameter.
%
% Outputs:
%   - params0: Initial parameter values for the active parameters.
%   - ub: Upper bounds for the active parameters.
%   - lb: Lower bounds for the active parameters.

% Compute the total number of parameters in the model
nParams_full = length(indParamVary);

% Initialize outputs as cell arrays to handle parameters separately
params0_cell = cell(1, nParams_full);
ub_cell = params0_cell;
lb_cell = params0_cell;

% Process each parameter based on its variation specification
for iParam = 1:nParams_full
    switch nLoc
        % Two locations
        case 2
            switch indParamVary(iParam)
                case 0
                    % Parameter is fixed between two locations (shared)
                    params0_cell{iParam} = params0_full(iParam);
                    ub_cell{iParam} = ub_full(iParam);
                    lb_cell{iParam} = lb_full(iParam);
                case 1
                    % Parameter varies between two locations
                    params0_cell{iParam} = repmat(params0_full(iParam), 1, nLoc);
                    ub_cell{iParam} = repmat(ub_full(iParam), 1, nLoc);
                    lb_cell{iParam} = repmat(lb_full(iParam), 1, nLoc);
            end

            % Three locations
        case 3
            switch indParamVary(iParam)
                case 0
                    % Parameter is fixed across three locations (shared)
                    params0_cell{iParam} = params0_full(iParam);
                    ub_cell{iParam} = ub_full(iParam);
                    lb_cell{iParam} = lb_full(iParam);
                case 4
                    % Parameter varies freely across three locations
                    params0_cell{iParam} = repmat(params0_full(iParam), 1, nLoc);
                    ub_cell{iParam} = repmat(ub_full(iParam), 1, nLoc);
                    lb_cell{iParam} = repmat(lb_full(iParam), 1, nLoc);
                otherwise
                    % Parameter is fixed for some locations but may vary for others
                    % 2: Fixed for 1st & 3rd, may differ for 2nd
                    % 3: Fixed for 1st & 2nd, may differ for 3rd
                    % 4: Free to vary across three locations
                    params0_cell{iParam} = repmat(params0_full(iParam), 1, nLoc-1);
                    ub_cell{iParam} = repmat(ub_full(iParam), 1, nLoc-1);
                    lb_cell{iParam} = repmat(lb_full(iParam), 1, nLoc-1);
            end
        otherwise % Parameter varies freely across three locations
            switch indParamVary(iParam)
                case 1
                    params0_cell{iParam} = repmat(params0_full(iParam), 1, nLoc);
                    ub_cell{iParam} = repmat(ub_full(iParam), 1, nLoc);
                    lb_cell{iParam} = repmat(lb_full(iParam), 1, nLoc);
            end
    end % switch nLoc
end % for iParam

params0_vec = cell2mat(params0_cell);
ub_vec = cell2mat(ub_cell);
lb_vec = cell2mat(lb_cell);

end