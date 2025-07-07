function [est_D, est_Neq, pred, r2]=lam_tvcFit(params,nE,cE)
%Purpose: Fit the LAM to data that are the contrast energy at threshold as
%a function of noise energy.
%Inputs:    params: The parameters of the LAM
%                   params(1): a, the constant of proportionality
%                   params(2): b, the critical spectral density of the noise
%           nE: the noise energy (i.e., noise rms contrast ^ 2)
%           cE: the contrast energy at threshold (actual data)
%Outputs:   est_D: an estimate of D, the effective signal to noise ratio
%           est_Neq: an estimate of Neq, the critical spectral density of the
%           noise
%           r2: an r^2 value to serve as the goodness-of-fit
%[coeff,r,J]=nlinfit(nE,cE,@lam_tvc,params); %Non-linear regression
%Stopped using nlinfit because the parameters kept trying to go negative
%without boundaries

warning off
lb = [0 0]; ub = [100 100]; %Lower and upper bounds for the parameters
[coeff, resN, residual] = lsqcurvefit(@lam_tvc, params, nE, cE, lb, ub); %Non-linear regression % edit lam_tvc
est_D   = coeff(1);   %The estimate of D is the first coefficient
est_Neq = coeff(2);   %The estimate of Neq is the second coefficient
pred = cE+residual;
r2=1-sum(residual.^2)/sum(((cE-mean(cE)).^2)); %Calculate r^2 of the fit based on the residuals

