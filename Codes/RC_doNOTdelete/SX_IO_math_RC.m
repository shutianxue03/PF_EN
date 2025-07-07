close all
cst_ln = 20/100;
cst_log = log10(cst_ln); % in %, decides the center of the distribution
noiseSD_ext = .1; % in SD, decides the width of the distribution
noiseSD_int = 0;
noiseSD_comb = sqrt(sumsqr([noiseSD_ext, noiseSD_int]));

axis_x_log = linspace(-3, 3, 1e3); % spectrum of log cst
axis_x_ln = linspace(-1, 1, 1e3); % spectrum of log cst
dist_L = normpdf(axis_x_log, -cst_log, noiseSD_comb); % internal distribution of the left-tilted target
dist_L = normpdf(axis_x_ln, -cst_ln, noiseSD_comb); % internal distribution of the left-tilted target
dist_L = dist_L/sum(dist_L);
dist_R = normpdf(axis_x_log, cst_log, noiseSD_comb); % internal distribution of the right-tilted target
dist_R = normpdf(axis_x_ln, cst_ln, noiseSD_comb); % internal distribution of the right-tilted target
dist_R = dist_R/sum(dist_R);

figure, hold on
plot(axis_x_ln, dist_L, 'r')
plot(axis_x_ln, dist_R, 'b')
xline(-cst_ln, 'r-');
xline(cst_ln, 'b-');
xlim(axis_x_ln([1, end]))
legend({'-45', '45'})
xlabel('Contrast')
ylabel('Density')
title(sprintf('CST=%.0f%%; Noise SD=%.2f', cst_ln*100, noiseSD_ext))

%%
noiseSD_int = 0;
perf = .75;

% noiseSD_ext = .1; % in SD, decides the width of the distribution
noiseSD_ext_all = linspace(0, .5, 10);
nNoise =  length(noiseSD_ext_all);

thresh_log_est_all = nan(1, nNoise);

cst_log_ticks = linspace(-3, 0, 5);
cst_ln_ticks = round(10.^cst_log_ticks*100,1);
c_ideal = 0; % ideal criterion (non-biased)
cst_log_all = linspace(cst_log_ticks(1), cst_log_ticks(end), 1e2);
cst_ln_all = 10.^cst_log_all;
nCST = length(cst_log_all);


figure, hold on

for iNoise = 1:nNoise
    noiseSD_comb = sqrt(sumsqr([noiseSD_ext_all(iNoise), noiseSD_int]));
    pC_allCST = nan(1, nCST);pC_allCST_ = pC_allCST;
    for iCST = 1:nCST
        
        %     pC_allCST_(iCST) = normcdf(c_ideal, -cst_ln_all(iCST), noiseSD_comb) - normcdf(c_ideal, cst_ln_all(iCST), noiseSD_comb);
        
        fxn_norm_L = @(x) normpdf(x, -cst_ln_all(iCST), noiseSD_comb);
        fxn_norm_R = @(x) normpdf(x, cst_ln_all(iCST), noiseSD_comb);
        
        fxn_getpC = @(x) integral(fxn_norm_L(x), -inf, 0) - integral(fxn_norm_R(x), -inf, 0);
        pC_allCST(iCST) = fxn_getpC(0);
    end
    
%     x = fmincon(@(x) abs(fxn_getpC(x) - perf), min(cst_log_all), [], []);
%         thresh_log_est_all(iNoise) = x;
    
    plot(cst_log_all, pC_allCST, '.')
    
    yline(perf, 'r-');
    
end

ylim([0, 1])
xticks(cst_log_ticks)
xticklabels(cst_ln_ticks)
xlim(cst_log_ticks([1, end]))


