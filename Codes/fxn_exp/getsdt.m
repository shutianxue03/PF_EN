function [out] = getsdt(s,r)
if nargin < 2, error('Not enough input arguments.'); end

hr = nnz(s == 1 & r == 1)/nnz(s == 1);
fa = nnz(s == 0 & r == 1)/nnz(s == 0);

hr_bnd = min(max(hr,0.5/nnz(s == 1)),1-0.5/nnz(s == 1));
fa_bnd = min(max(fa,0.5/nnz(s == 0)),1-0.5/nnz(s == 0));
dprime = +normalz(hr_bnd)-normalz(fa_bnd);
lambda = -normalz(fa_bnd);
lambdc = -0.5*(normalz(fa_bnd)+normalz(hr_bnd));
logbta = 0.5*(normalz(fa_bnd)^2-normalz(hr_bnd)^2);
hr_bnd_var = hr_bnd*(1-hr_bnd)/nnz(s == 1);
fa_bnd_var = fa_bnd*(1-fa_bnd)/nnz(s == 0);
dprime_var = fa_bnd_var/normalpdf(lambda)^2+hr_bnd_var/normalpdf(dprime-lambda)^2;
lambda_var = fa_bnd_var/normalpdf(lambda)^2;
logbta_var = fa_bnd_var*lambda^2/normalpdf(lambda)^2+hr_bnd_var*(dprime-lambda)^2/normalpdf(dprime-lambda)^2;

out            = struct;
out.hr         = hr;
out.fa         = fa;
out.dprime     = dprime;
out.lambda     = lambda;
out.lambdc     = lambdc;
out.logbta     = logbta;
out.dprime_std = sqrt(dprime_var);
out.lambda_std = sqrt(lambda_var);
out.logbta_std = sqrt(logbta_var);

end