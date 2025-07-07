function cE = fxn_LAM(params, nE)

%Purpose: Calculate threshold elevation as a function of noise contrast
%based upon the linear amplifier model. This is based upon the
%parameterization from Pelli (1981) and operates on threshold contrast
%energy and noise contrast energy, rather than raw contrast values. That
%is, raise a contrast threshold or a noise contrast to the power of 2 and
%then pass that to this function.

% Inputs:    params: The parameters of the LAM
%                   params(1): D, the effective signal to noise ratio
%                   params(2): Neq, the critical spectral density of the noise
%                 nE: noise energy
% Output:    threshold: a vector of thresholds (in energy)

cE = params(1) .* (nE + params(2)); %Do the LAM calculation
end

