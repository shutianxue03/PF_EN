
function threshEnergy_pred = fxn_PTM_energy(indParamIncl, params, noiseEnergy, dprime)

% archived; 
% This script fits PTM on energy (not contrast)

nParams = length(indParamIncl);
params_ = zeros(1, nParams);
iParam_=1;
for iParam = 1:nParams
    if indParamIncl(iParam), params_(iParam) = params(iParam_); iParam_=iParam_+1;end
end

params_(isnan(params_)) = 0;

Nmul = params_(1);
gamma = params_(2);
sigma_add = params_(3);
beta = params_(4);

if length(params_)==5, beta2 = params_(5); end

%% equation from Lu&Dosher 2008, E14, p16
% several changes
% 2. divide dprime^2 from numerator and denominator
% 3. to have contrast energy on the left side, squared both sides

% in Eq14, sigma_ext is noise SD; hence here, since we are using the energy (noiseEnergy), the squared sign is removed.
threshEnergy1 = dprime^2 *((1+Nmul^2) * noiseEnergy.^gamma + sigma_add^2);
threshEnergy2 = beta^(2*gamma) - Nmul^2 * beta^(2*gamma)*dprime^2/2;
threshEnergy_pred = (threshEnergy1/threshEnergy2).^(1/(2*gamma));
threshEnergy_pred_LD = threshEnergy_pred.^2;

%% equation from Barbot_etal_Yoon 2021, Eq 4, p20
% in Eq20, N_ext is noise SD; hence here, since we are using the energy (noiseEnergy), the squared sign is removed.
threshEnergy1 = (1+Nmul^2) * noiseEnergy.^gamma + sigma_add^2;
threshEnergy2 = 1/dprime^2 - Nmul^2; % has to be positive and non-zero!!
threshEnergy_pred = (threshEnergy1/threshEnergy2).^(1/(2*gamma))/beta;
threshEnergy_pred_AB = threshEnergy_pred.^2;

% threshEnergy_pred = threshEnergy_pred_LD;
threshEnergy_pred = threshEnergy_pred_AB; % it seems that AB's equation missed a xx/2

