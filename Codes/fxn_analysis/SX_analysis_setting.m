
nameFolder_server = '/Volumes/purplab/EXPERIMENTS/1_Current_Experiments/Shutian_server/PF_EN';

markers_allSubj = {'o', 's', 'd', 'p', 'h', '^', 'v', '<', '>', '+', 'x', '*'};
gaborCST_ub = 100/100;

%% params
namesCCC = {'stair', 'const', 'manual', 'nonS' 'all'}; nccc = length(namesCCC);
% perfThresh_all = 75:5:85; nPerf = length(perfThresh_all);
perfThresh_all = [65, 70, 75]; nPerf = length(perfThresh_all); 
dprimes = 2*norminv(perfThresh_all/100); % matching LuDosher2008; the same as z(pHit)-z(pFA)
iPerf_plot = 2; % plot which threshold? index the vector above
PMF_models = {'Logistic', 'CumNorm', 'Gumbel',  'Weibull'}; nModels = length(PMF_models); 
colors_allM = {'r', 'g', 'c', 'b'};
iplots9 = [13, 12, 8, 14, 18, 11, 3, 15, 23];

%% TvC
nIntp=1e3; % number of x ticks when predicting TvCs
namesErrorType = {'ErrLogCst', 'ErrLnCst', 'ErrLnEg'}; nErrorType = length(namesErrorType);

% Define location groups
% indLoc_s_all = {[1,2,3], [1,4,8], [1,5,9], [4,5], [6,7], [8,9], [10,11]}; nIndLoc_s = length(indLoc_s_all); % Total number of location groups

%% PMF fitting
analysisModes = [1,1; 1,0; 0,1; 0,0]; % left col: whether to bin data; right column: whether ti filter data (see OOD_fitPMF)

fit.nBins = 10;
fit.nBoot_PMF = 100; % bootstrapping, using PAL_PFML_BootstrapParametric() or PAL_PFML_BootstrapNonParametric()
fit.curveX_log = linspace(-3, log10(gaborCST_ub), 1e2); % log cst
fit.curveX_ln = 10.^(fit.curveX_log); % ln cst
fit.options.MaxIter = 1e5;
fit.options.MaxFunEvals = 1e5;

fit.paramsFree = [1 1 1 1]; % 1=free to vary, 0=fixed
fit.nParams = length(fit.paramsFree);

% range
fit.alphaguess = linspace(log10(1/100), log10(gaborCST_ub), 1e3);
fit.betaguess = 10.^[-3:.1:3];
fit.gammaguess = .45:.01:.55;
fit.lambdaguess = 0:.01:.1;

% limits
fit.alphaLimits = fit.alphaguess([1, end]);
fit.betaLimits = fit.betaguess([1, end]);
fit.guessLimits = fit.gammaguess([1, end]); % different naming...
fit.lapseLimits = fit.lambdaguess([1, end]);

% Define search grid 
fit.searchGrid = struct('alpha', fit.alphaguess,'beta', fit.betaguess,'gamma',fit.gammaguess, 'lambda',fit.lambdaguess);

% lower/upper bound and initial points for fitting using fmincon()
fit.PMF_lb = [fit.alphaguess(1), fit.betaguess(1), fit.gammaguess(1), fit.lambdaguess(1)];
fit.PMF_ub = [fit.alphaguess(end), fit.betaguess(end), fit.gammaguess(end), fit.lambdaguess(end)];
fit.PMF_param0 = [mean(fit.alphaguess), mean(fit.betaguess), mean(fit.gammaguess), mean(fit.lambdaguess)];
fit.PMF_options = optimoptions(@fmincon, ...
    'Display', 'off', ...          % or 'iter', 'final', 'none'
    'MaxIterations', 1000, ...
    'MaxFunctionEvaluations', 5000, ...
    'OptimalityTolerance', 1e-6, ...
    'StepTolerance', 1e-6);

%% names
namesSingleLoc = {'Fovea', 'LHM4', 'UVM4', 'RHM4', 'LVM4', 'LHM8', 'UVM8', 'RHM8', 'LVM8'}; nLocSingle = length(namesSingleLoc);
namesCombLoc = {'Fov', 'Ecc4', 'Ecc8', 'HM4', 'VM4', 'LVM4', 'UVM4', 'HM8', 'VM8', 'LVM8', 'UVM8'};nLocComb = length(namesCombLoc);
namesLF_short = {'Neq', 'Eff'};
namesLocComb = {'Fovea', 'Left', 'UVM', 'Right', 'LVM', 'HM', 'VM', 'Peri'};
namesAsym = {'Ecc effect', 'HVA', 'VMA', 'L/R diff'};

%% colors
g1 = .5; % dark green
g2 = .65;
g3 = .9;

colors_single = [0,0,0; ...,     % 1. fovea; black
    0, g2, 0; ..., % 2. LHM4: light green
    0, 0, 1,; ...,   % 3. UVM4: blue
    0, g1, 0; ..., % 4. RHM4: dark green
    1, 0, 0; ...     % 5. LVM4: red
    0, g3, 0;...    % 6. LHM8: lighter green
    .5, .75, 1;...     % 7. UVM8: light blue
    0, g2, 0;...   % 8. RHM8: light green
    1, .5, .5];    % 9. LVM8: light red

colors_asym = [
    ones(1,3)*0; ..., % 1. fovea: black
    ones(1,3)*.4; ..., % 2. Ecc 4: grey
    ones(1,3)*.6; ...,   % 3. Ecc 8: lighter grey
    0, g1, 0; ..., % 4. HM4: dark green
    .5, 0, 1; ...,    % 5. VM4: purple
    1, 0, 0; ...     % 6. LVM4: red
    0, 0, 1,; ...,   % 7. UVM4: blue
    0, .9, .25; ...,   % 8. HM8: light green
    .75, .6, .95; ...      % 9. VM8: light purple
    1, .5, .5; ...    % 10. LVM8: light red
    .5, .75, 1];    % 11. UVM8: light blue


shapes_SF = {'o', 's', '^'};

%% compare across loc
getAsym = @(a,b) (a-b)./(a+b);

%%
namesTvCModel = {'LAM', 'PTM'}; markers_allTvCs = {'o', '+'}; nTvC = length(namesTvCModel);

flag_plotLAM =1;
flag_plotPTM = 1;

% LAM fitting
namesLF_LAM_beforeConversion = {'Slope', 'Neq (Energy)'};
namesLF_Labels_LAM = {'Efficiency (%)', 'Neq (log cst)'};
namesLF_LAM = {'Eff', 'NeqLog'};
nLF_LAM = length(namesLF_LAM);

% PTM fitting
namesLF_PTM = {'Nmul', 'Gamma', 'Nadd', 'Gain'};
namesLF_Labels_PTM = namesLF_PTM;
nLF_PTM = length(namesLF_PTM);

%% Functions to calculate information criteria
% RSS is error of log contrast
fxn_getAIC = @(RSS, nData, nParams) nData .* log(RSS ./ nData) + nParams * 2;
fxn_getBIC = @(RSS, nData, nParams) nData .* log(RSS ./ nData) + nParams .* log(nData);
% fxn_getAIC = @(RSS, nData, nParams) 2*RSS + nParams * 2;
% fxn_getBIC = @(RSS, nData, nParams) 2*RSS  + nParams .* log(nData);
fxn_getAICc = @(RSS, nData, nParams) fxn_getAIC(RSS, nData, nParams) + (2 * nParams .* (nParams + 1)) ./ (nData - nParams - 1);

fxn_getBIC_LL = @(LL, nData, nParams) nParams .* log(nData) + 2 * LL;