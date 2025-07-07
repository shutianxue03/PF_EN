
function threshEnergy_pred = fxn_PTM(indParamIncl, params, noiseEnergy, dprime, SF_fit)

nParams = length(indParamIncl);
params_ = zeros(1, nParams);
iParam_=1;
for iParam = 1:nParams
    if indParamIncl(iParam), params_(iParam) = params(iParam_); iParam_=iParam_+1;end
end

params_(isnan(params_)) = 0;

% Nmul
Nmul = 10.^params_(1);
if indParamIncl(1)==0, Nmul=0; end

% Gamma
Gamma = params_(2);
if indParamIncl(2)==0, Gamma=1; end

% Nadd
Nadd = 10.^params_(3); % Nadd is converted to log form when fitting
if indParamIncl(3)==0, Nadd=0; end

% Gain
Gain = params_(4)/SF_fit; % Gain is converted to log form when fitting % divided by SF, because gain decreased with SF
if indParamIncl(4)==0, Gain=1; end

% if length(params_)==5, beta2 = params_(5); end

%% equation from Lu&Dosher 2008, E14, p16
% several changes
% 2. divide dprime^2 from numerator and denominator
% 3. to have contrast energy on the left side, squared both sides

% in Eq14, sigma_ext is noise SD; hence here, since we are using the energy (noiseEnergy), the squared sign is removed.
threshCST1 = dprime^2 *((1+Nmul^2) * noiseEnergy.^Gamma + Nadd^2);

threshCST2 = Gain^(2*Gamma) - Nmul^2 * Gain^(2*Gamma)*dprime^2/2; 
assert(threshCST2>=0, 'ALERT: the denominator of PTM function is negative!!!')

threshCST_pred_LD  = (threshCST1/threshCST2).^(1/(2*Gamma));

%% equation from Barbot_etal_Yoon 2021, Eq 4, p20 (also Cavanaugh_etal2015, Eq 3, p7)
% in Eq20, N_ext is noise SD; hence here, since we are using the energy (noiseEnergy), the squared sign is removed.
% threshCST1 = (1+Nmul^2) * noiseEnergy.^(2*Gamma) + Nadd^2;
% threshCST2 = 1/dprime^2 - Nmul^2; % has to be positive 
% threshCST_pred_AB = (threshCST1/threshCST2).^(1/(2*Gamma))/Gain;

%%
threshCST_pred = threshCST_pred_LD;
% threshCST_pred = threshCST_pred_AB; 
threshEnergy_pred = threshCST_pred.^2; % use the real() function to ensure the code can run in nested MC, when the reduced function is doomed dysfunctional
