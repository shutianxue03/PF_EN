
%% Logarithmic and Linear Contrast Thresholds
cst_ln_min = 1/100; % Minimum contrast threshold in linear scale (1% contrast)
cst_ln_max = gaborCST_ub;%gaborCST_ub; % Maximum contrast threshold in linear scale (100% contrast)
nIntp = 1e3; % Number of interpolation points for smooth curves

% Logarithmic contrast threshold settings
ncst_log = 5; % Number of logarithmic contrast threshold ticks

% Convert contrast thresholds from linear to logarithmic scale
cst_log_min = log10(cst_ln_min); % Logarithm of minimum contrast (1%)
cst_log_max = log10(cst_ln_max); % Logarithm of maximum contrast (100%)

% Generate logarithmic contrast threshold ticks
if cst_ln_max==100/100
    cst_log_ticks = linspace(cst_log_min, cst_log_max, ncst_log);
else
    cst_log_ticks = [linspace(cst_log_min, log10(100/100), ncst_log), cst_log_max];
end
cst_ln_ticks = round(10.^cst_log_ticks * 100); % Convert back to linear scale and round

%% Contrast Energy (Squared Linear Contrast)
cstEnergy_min = 1e-3; % Minimum contrast energy (corresponding to 1% contrast)
cstEnergy_max = 0.5; % Maximum contrast energy (corresponding to 100% contrast)

% Generate contrast energy ticks for plotting
cstEnergy_ticks = linspace(cstEnergy_min, cstEnergy_max, ncst_log);

% Noise standard deviation in log scale (for plotting)
noiseSD_log_min_fake = -1.8; % Fake minimum value for visualization

% Log-scale representation of noise standard deviation, excluding the first entry
noiseSD_log_all = [noiseSD_log_min_fake, log10(noiseSD_full(2:end))];

% Interpolated log-scale noise standard deviation values for fitting
noiseSD_intp_log_true = linspace(noiseSD_log_all(1), noiseSD_log_all(end), nIntp);

% Compute noise energy (square of noise standard deviation)
noiseEnergy_true = noiseSD_full.^2;
noiseEnergy_intp_true = (10.^noiseSD_intp_log_true).^2; % Convert interpolated values back to squared energy

%% LAM (Linear Amplifier Model) Parameter Settings
nTicks = 5; % Number of tick marks for visualization

% Ideal slopes for different performance levels (75%, 80%, 85%)
% These values are derived from SX_IO and are consistent across spatial frequencies (4, 5, 6 cpd)
slope_ideal = [.001, .0017, .0025; 
               .001, .0017, .0025; 
               .001, .0017, .0025]; 

% Initial parameters, lower and upper bounds for LAM fitting
% Parameters: [Slope, Equivalent Noise (Neq) in energy]
params0_LAM = [1, (25/100)^2]; % Initial values
lb_LAM = [0, (1/100)^2]; % Lower bounds
ub_LAM = [10, (100/100)^2]; % Upper bounds

% Generate tick marks for LAM parameters
% - First set: Slope values (efficiency percentage)
% - Second set: Equivalent noise values in log scale
ticks_LAM = {linspace(0, 12, nTicks), round(linspace(log10(1/100), log10(44/100), nTicks), 2)};

% Convert tick labels back to linear scale for readability
ticklabels_LAM = ticks_LAM;
ticklabels_LAM{2} = round(10.^ticklabels_LAM{2}, 2);

%% PTM (Perceptual Template Model) Parameter Settings
nTicks = 5; % Number of tick marks for visualization

% Initial parameters, lower and upper bounds for PTM fitting
% Parameters: [Nmul, Gamma, Nadd, Gain]
% params0_PTM = [log10(sqrt(2)/min(dprimes)),  2,   log10(.05),   1.5/SF_fit]; % Nmul, Gamma, Nadd, Gain
% % lb_PTM = [log10(1e-4), 1, log10(1e-10), 1/SF_fit]; % lb of gain and gamma are 1
% lb_PTM = [log10(1e-4), 0, log10(1e-7), 0/SF_fit]; % lb of gain and gamma are 0
% ub_PTM = [log10(sqrt(2)/max(dprimes)), 5, log10(gaborCST_ub), 5/SF_fit]; % ub of Gamma and Gain are 5; % Increasing Gamma's ub to 10 sabotages fitting...

params0_PTM = [log10(sqrt(2)/min(dprimes)),  2,   log10(.05),   1.5]; % Nmul, Gamma, Nadd, Gain
lb_PTM = [log10(1e-5), 0, log10(1e-8), 0]; % lb of gain and gamma are 0
ub_PTM = [log10(sqrt(2)/max(dprimes)), 5, log10(gaborCST_ub), 5]; % ub of Gamma and Gain are 5


% Generate tick marks for PTM parameters in log scale
ticks_PTM = {linspace(lb_PTM(1), ub_PTM(1), nTicks), ...
                    linspace(lb_PTM(2), ub_PTM(2), nTicks), ...
                    linspace(lb_PTM(3), ub_PTM(3), nTicks), ...
                   linspace(lb_PTM(4), ub_PTM(4), nTicks)};

% Convert tick labels back to linear scale for better interpretation
ticklabels_PTM = ticks_PTM;
ticklabels_PTM{1} = 10.^ticklabels_PTM{1}; % Nmul
ticklabels_PTM{2} = ticklabels_PTM{2}; % Gamma
ticklabels_PTM{3} = 10.^ticklabels_PTM{3}; % Nadd
ticklabels_PTM{4} = ticklabels_PTM{4}; % Gain
