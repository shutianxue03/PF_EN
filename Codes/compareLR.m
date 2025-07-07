clear all, clc
SF = 4; nsubj=9;
load(sprintf('Data_OOD/nNoise9/SF%d/n%d_fitTvC_B1_constim10_Bin1Filter1_collapseHM1_combLoc.mat', SF, nsubj))

% Parameters
loc_idx = [2, 4, 6, 8]; nLoc=4;
ecc_map = containers.Map({2, 4, 6, 8}, {4, 4, 8, 8});
noise_idx = 1;
perf_idx = 2;
[nSubj, ~, ~, ~] = size(thresh_log_allB_allSubj);

% Extract data: [nSubj x 4]
data = squeeze(thresh_log_allB_allSubj(:, loc_idx, noise_idx, perf_idx));

% Create variable names and within-subject factors
colnames = cell(1, numel(loc_idx));
Location_vals = zeros(numel(loc_idx), 1);
Eccentricity_vals = zeros(numel(loc_idx), 1);

for i = 1:numel(loc_idx)
    loc = loc_idx(i);
    ecc = ecc_map(loc);
    colnames{i} = sprintf('L%d', loc);
    Location_vals(i) = loc;
    Eccentricity_vals(i) = ecc;
end

% Create data table (one row per subject)
T = array2table(data, 'VariableNames', colnames);
T.Subject = categorical(1:nSubj)';

% Create within-subjects design table
within = table(categorical(Location_vals), categorical(Eccentricity_vals), ...
               'VariableNames', {'Location','Eccentricity'});

% Fit repeated-measures model
rm = fitrm(T, sprintf('%s-%s ~ 1', colnames{1}, colnames{end}), ...
           'WithinDesign', within);

ranovatbl = ranova(rm, 'WithinModel', 'Location');

% --- Extract and print main effects and interaction ---
fprintf('\nFormatted ANOVA results:\n');

% Location main effect
F_loc = ranovatbl.F(strcmp(ranovatbl.Row, '(Intercept):Location'));
df1_loc = ranovatbl.DF(strcmp(ranovatbl.Row, '(Intercept):Location'));
df2_loc = ranovatbl.DF(strcmp(ranovatbl.Row, 'Error(Location)'));
p_loc = ranovatbl.pValue(strcmp(ranovatbl.Row, '(Intercept):Location'));
fprintf('Location: F(%d,%d) = %.2f, p = %.3f\n', df1_loc, df2_loc, F_loc, p_loc);

% Eccentricity main effect
F_ecc = ranovatbl.F(strcmp(ranovatbl.Row, '(Intercept):Eccentricity'));
df1_ecc = ranovatbl.DF(strcmp(ranovatbl.Row, '(Intercept):Eccentricity'));
df2_ecc = ranovatbl.DF(strcmp(ranovatbl.Row, 'Error(Eccentricity)'));
p_ecc = ranovatbl.pValue(strcmp(ranovatbl.Row, '(Intercept):Eccentricity'));
fprintf('Eccentricity: F(%d,%d) = %.2f, p = %.3f\n', df1_ecc, df2_ecc, F_ecc, p_ecc);

% Interaction: Location * Eccentricity
F_int = ranovatbl.F(strcmp(ranovatbl.Row, '(Intercept):Location:Eccentricity'));
df1_int = ranovatbl.DF(strcmp(ranovatbl.Row, '(Intercept):Location:Eccentricity'));
df2_int = ranovatbl.DF(strcmp(ranovatbl.Row, 'Error(Location:Eccentricity)'));
p_int = ranovatbl.pValue(strcmp(ranovatbl.Row, '(Intercept):Location:Eccentricity'));
fprintf('Location × Eccentricity: F(%d,%d) = %.2f, p = %.3f\n', df1_int, df2_int, F_int, p_int);

%%
% Prepare for plotting
mean_thresh = mean(data);                     % [1 x 4]
sem_thresh = std(data) / sqrt(nSubj);         % [1 x 4]
loc_labels = arrayfun(@(x) sprintf('Loc %d', x), loc_idx, 'UniformOutput', false);
ecc_vals = cellfun(@(x) ecc_map(str2double(x(2:end))), colnames); % [4 x 1]
ecc_labels = arrayfun(@(x) sprintf('%dº', x), ecc_vals, 'UniformOutput', false);

% Assign group colors by eccentricity
ecc_colors = lines(2); % 2 colors for 4º and 8º
group_colors = arrayfun(@(e) ecc_colors(e/4, :), ecc_vals, 'UniformOutput', false);

% Grouped bar plot with error bars
figure;hold on;box on;grid on;

% Plot bars and error bars
for i = 1:numel(loc_idx)
    bar_handle = bar(i, mean_thresh(i), 'FaceColor', group_colors{i});
    errorbar(i, mean_thresh(i), sem_thresh(i), 'k', 'LineStyle', 'none', 'LineWidth', 1, 'CapSize', 0);
end

for isubj=1:nSubj
    plot(1:nLoc, data(isubj, :), '-k')
end

% Customize axes
xticks(1:numel(loc_idx));
xticklabels(loc_labels);
ylim([-1.7, -.6])
xlabel('Location');
ylabel('Threshold (log units)');
xticklabels({'Left 4º', 'Right 4º', 'Left 8º', 'Right 8º'})
title(sprintf('Thresholds by Location and Eccentricity (SF = %d, Noise = 0, Perf = 75%)', SF));
% legend({'4º eccentricity', '8º eccentricity'}, 'Location', 'NorthEast');

%%
% --- Pairwise comparisons between Locations ---
fprintf('\nPost hoc pairwise comparisons between Locations:\n');
alpha = 0.05;
loc_labels = arrayfun(@(x) sprintf('Loc %d', x), loc_idx, 'UniformOutput', false);
nPairs = 0;
p_vals = [];

for i = 1:numel(loc_idx)-1
    for j = i+1:numel(loc_idx)
        [~, p, ~, stats] = ttest(data(:,i), data(:,j));
        nPairs = nPairs + 1;
        p_vals(end+1) = p;
        fprintf('%s vs %s: t(%d) = %.2f, p = %.3f\n', ...
                loc_labels{i}, loc_labels{j}, stats.df, stats.tstat, p);
    end
end

% Bonferroni correction
fprintf('\nBonferroni-corrected significance threshold: %.3f\n', alpha / nPairs);
sig_flags = p_vals < (alpha / nPairs);

if any(sig_flags)
    fprintf('Significant pairs after correction:\n');
    pair_idx = 0;
    for i = 1:numel(loc_idx)-1
        for j = i+1:numel(loc_idx)
            pair_idx = pair_idx + 1;
            if sig_flags(pair_idx)
                fprintf('  %s vs %s (p = %.3f)\n', loc_labels{i}, loc_labels{j}, p_vals(pair_idx)*nPairs);
            end
        end
    end
else
    fprintf('No significant location pairs after correction.\n');
end

%% one-way anova on left vs. right
% Define locations and parameters
left_locs = [2, 4];
right_locs = [6, 8];
perf_idx = 2;
noise_idx = 1;

% Extract data for Noise=1 and Perf=2
data_all = squeeze(thresh_log_allB_allSubj(:, [left_locs, right_locs], noise_idx, perf_idx)); % [nSubj x 4]

% Average across location groups
left_data = mean(data_all(:, 1:2), 2);
right_data = mean(data_all(:, 3:4), 2);

% Create table for ANOVA
T = table(left_data, right_data);
T.Subject = categorical(1:size(data_all,1))';

% Define within-subject factor
within = table(categorical({'Left'; 'Right'}), 'VariableNames', {'Side'});

% Run repeated-measures ANOVA
rm = fitrm(T, 'left_data-right_data ~ 1', 'WithinDesign', within);
ranovatbl = ranova(rm);

% Print ANOVA results
fprintf('\nOne-way repeated-measures ANOVA: Left vs Right\n');
F_val = ranovatbl.F(1);
df1 = ranovatbl.DF(1);
df2 = ranovatbl.DF(2);
p_val = ranovatbl.pValue(1);
fprintf('F(%d,%d) = %.2f, p = %.3f\n', df1, df2, F_val, p_val);

% --- Post hoc paired t-test ---
fprintf('\nPost hoc paired t-test: Left vs Right\n');
[~, p_ttest, ~, stats] = ttest(left_data, right_data);
fprintf('t(%d) = %.2f, p = %.3f\n', stats.df, stats.tstat, p_ttest);

% --- Cohen''s d ---
diffs = left_data - right_data;
cohens_d = mean(diffs) / std(diffs);
fprintf("Cohen's d = %.2f\n", cohens_d);
