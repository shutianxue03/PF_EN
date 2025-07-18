%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plotDiagrams_forSlides.m
% Last updated by Shutian Xue on 07/18/2025

% Purpose:
%   Generates and saves a series of illustrative diagrams for slides and papers, including:
%     - Blurred images (e.g., NYC with Gaussian blur)
%     - Psychometric function (PMF) curves with varying thresholds
%     - Schematic plots for model parameters (e.g., gain, nonlinearity, noise)
%     - Spatial frequency (SF) diagrams
%     - Visual performance field (VPF) diagrams for different location groups
%
% Usage:
%   Run as a script. Figures are saved to the specified output directory.
%
% Inputs:
%   - Requires 'NYC.png' in the working directory for blur demonstration
%
% Outputs:
%   - Figures saved in subfolders of 'Figures/PF_diagram' under the server directory


clear all, clc, close all

% Define the path to the folder where the figures will be saved
nameFolder_server = '/Volumes/purplab/EXPERIMENTS/1_Current_Experiments/Shutian_server/PF_EN'; % the server directory of the Data and Figures folders

nameFolder_Figures_diagrams = sprintf('%s/Figures/PF_diagram', nameFolder_server);
if ~exist(nameFolder_Figures_diagrams, 'dir'), mkdir(nameFolder_Figures_diagrams); end

addpath(genpath('fxn_analysis/')); 

%% Diagram of NYC with different levels of blur
sd=15;

img = imread('NYC.png');

img = im2double(img);  % Convert to double for processing

img_blur = zeros(size(img));
n=100;

filter = normpdf(1:n, n/2, sd);
filter2d = filter.*filter';

filter2d=filter2d/sum(filter2d(:));
for c = 1:3
    img_blur(:,:,c) = conv2(img(:,:,c), filter2d, 'same');
end

imwrite(img_blur, sprintf('%s/NYC_blurred_sd%d.png', nameFolder_Figures_diagrams, sd));

figure('Position', [0 0 2e3 2e3])
subplot(2,1,1); imshow(img); title('Original');
subplot(2,1,2); imshow(img_blur); title('Gaussian Blurred');

%% Diagrams fo PMF
lw_ref = 1.5;
y_lb = .45;
% Parameters
x_PMF_log = linspace(-3, 0, 1e3);  % Stimulus intensity (e.g., contrast)
x_PMF_ln = 10.^x_PMF_log;
beta = 2.5;               % Slope parameter (common across functions)
gamma = 0.5;              % Guess rate (e.g., for 2AFC task)
lambda = 0.02;            % Lapse rate

% Thresholds (alpha values) to simulate
nThresh = 5;
thresh_log_all = linspace(-2, -1, nThresh);
thresh_log_all = [-2.2, -1.8, -1.4, -1.2, -.5];
thresh_ln_all = 10.^thresh_log_all;
colors_grey = linspace(log10(0.5), log10(0.9), nThresh);  % from dark to light
colors_grey = 10.^colors_grey;

colors_grey = linspace(0.2, 0.9, nThresh);

% Weibull function definition
weibull = @(x, alpha, beta, gamma, lambda) ...
    gamma + (1 - gamma - lambda) .* (1 - exp(-(x ./ alpha) .^ beta));

% Plot
figure; hold on;
for iThresh = 1:nThresh
    thresh_log = thresh_log_all(iThresh);
    thresh_ln = thresh_ln_all(iThresh);
    y_PMF = weibull(x_PMF_ln, thresh_ln, beta, gamma, lambda);

    plot(x_PMF_log, y_PMF, 'LineWidth', 2, 'Color', ones(1,3)*colors_grey(iThresh), 'linewidth',5);
end

for iThresh = 1:nThresh
    thresh_log = thresh_log_all(iThresh);
    thresh_ln = thresh_ln_all(iThresh);
    y_PMF = weibull(x_PMF_ln, thresh_ln, beta, gamma, lambda);

    diff_log = abs(x_PMF_log-thresh_log);
    y_thresh = y_PMF(min(diff_log)==diff_log);
    plot([thresh_log, thresh_log], [y_lb, y_thresh(1)], '--', 'LineWidth', 2, 'Color', ones(1,3)*colors_grey(iThresh), 'linewidth', lw_ref)
    plot(thresh_log, y_lb, 'o', 'MarkerFaceColor', ones(1,3)*colors_grey(iThresh), 'MarkerEdgeColor','w', 'MarkerSize', 20, 'linewidth', 3)
end
yline(y_thresh(1), 'k--', 'linewidth', lw_ref)
ylim([y_lb, 1])
axis off

saveas(gcf, sprintf('%s/PMF_multipleNadd.jpg', nameFolder_Figures_diagrams))

%% Diagrams of parameters
close all
figure('Position', [0 0 300 200]), hold on, axis off,
x=linspace(-3,3,1e3);
y=normpdf(x, 0, 1);
plot(x,y,'k-', 'LineWidth',10)
saveas(gcf, sprintf('%s/Gain.jpg', nameFolder_Figures_diagrams)) % save the figure for Gain

figure('Position', [0 0 300 200]), hold on, axis off,
x=linspace(0,3,1e3);
y=x.^2;
plot(x,y,'k-', 'LineWidth',10)
saveas(gcf, sprintf('%s/nonL.jpg', nameFolder_Figures_diagrams)) % save the figure for nonL

figure('Position', [0 0 300 200]), hold on, axis off,
x=linspace(0,2*pi,1e3);
y=sin(x*5).*normpdf(x, mean(x), 1);
plot(x,y,'k-', 'LineWidth',10)
saveas(gcf, sprintf('%s/Nadd.jpg', nameFolder_Figures_diagrams)) % save the figure for Nadd
close all

%% Diagrams of SF
close all

for SF = [4,6]
    figure('Position', [0 0 500 500], 'Color', 'w'); hold on;
    axis square, axis off;
    xlim([-2, 2]), ylim([-2, 2])

    % plot(0,0, [shapes_SF{SF-3}, 'k'], 'Markersize', 200, 'linewidth', 5);

    diag_all = linspace(-10, 10, SF^2);
    nDiag = length(diag_all);
    for iDiag = 1:nDiag
        x_diag = diag_all(iDiag);
        plot([-2, 2], [-2, 2]+x_diag, '-k', 'linewidth', 5);
    end
    saveas(gcf, sprintf('%s/SF%d.jpg', nameFolder_Figures_diagrams, SF))
end

%% Diagram of VPF
%------------------%
SX_analysis_setting
%------------------%

outline_ecc = [1, 2];

sz_marker_all = [70, 90];
sz_line = 10;

% EE-HM
str_locgroup = 'EEHM';
x_ref = {[-2,2]};
y_ref = {[0,0]};
x_allLoc = [0, -1, 1, -2, 2];
y_allLoc = [0,0,0,0,0];
colors_allLoc = colors_asym([1, 4,4,8,8], :);
strParts_all = {'full', 'Fov', 'HM4', 'HM8'};
indParts_all = {1:5, 1, [2,3], [4,5]};
%------------------------------------%
fxn_plotPF_diagram(str_locgroup, sz_marker_all,  x_ref, y_ref, x_allLoc, y_allLoc, colors_allLoc, strParts_all, indParts_all, outline_ecc, sz_line, nameFolder_Figures_diagrams);
%------------------------------------%

% EE-VM
str_locgroup = 'EEVM';
x_ref = {[0,0]};
y_ref = {[-2,2]};
x_allLoc = [0,0,0,0,0];
y_allLoc = [0, -1, 1, -2, 2];
colors_allLoc = colors_asym([1, 5, 5, 9, 9], :);
strParts_all = {'full', 'Fov', 'VM4', 'VM8'};
indParts_all = {1:5, 1, [2,3], [4,5]};
%------------------------------------%
fxn_plotPF_diagram(str_locgroup, sz_marker_all,  x_ref, y_ref, x_allLoc, y_allLoc, colors_allLoc, strParts_all, indParts_all, outline_ecc, sz_line, nameFolder_Figures_diagrams);
%------------------------------------%

% HVA 4&8
str_locgroup = 'HVA48';
x_ref = {[-2,2], [0,0]};
y_ref = {[0,0], [-2,2]};
x_allLoc = [-1, 0, 1, 0, -2, 0, 2, 0];
y_allLoc = [0, 1, 0, -1, 0, 2, 0, -2];
colors_allLoc = colors_asym([4, 5, 4, 5, 8, 9, 8, 9], :);
strParts_all = {'full'};
indParts_all = {1:8};
%------------------------------------%
fxn_plotPF_diagram(str_locgroup, sz_marker_all,  x_ref, y_ref, x_allLoc, y_allLoc, colors_allLoc, strParts_all, indParts_all, outline_ecc, sz_line, nameFolder_Figures_diagrams);
%------------------------------------%

% VMA 4&8
str_locgroup = 'VMA48';
x_ref = {[0,0]};
y_ref = {[-2,2]};
x_allLoc = [0, 0, 0, 0];
y_allLoc = [1, -1, 2, -2];
colors_allLoc = colors_asym([7, 6, 11, 10], :);
% 4:HM4, 7: UVM4, 6: LVM4, 8:HM8, 10: UVM
strParts_all = {'full'};
indParts_all = {1:4};
%------------------------------------%
fxn_plotPF_diagram(str_locgroup, sz_marker_all,  x_ref, y_ref, x_allLoc, y_allLoc, colors_allLoc, strParts_all, indParts_all, outline_ecc, sz_line, nameFolder_Figures_diagrams);
%------------------------------------%


% HVA4
str_locgroup = 'HVA4';
x_ref = {[-1,1], [0,0]};
y_ref = {[0,0], [-1,1]};
x_allLoc = [-1, 1, 0,0];
y_allLoc = [0,0, -1, 1];
colors_allLoc = colors_asym([4,4,5,5], :);
strParts_all = {'full', 'HM4', 'VM4'};
indParts_all = {1:4, [1,2], [3,4]};
%------------------------------------%
fxn_plotPF_diagram(str_locgroup, sz_marker_all,  x_ref, y_ref, x_allLoc, y_allLoc, colors_allLoc, strParts_all, indParts_all, outline_ecc, sz_line, nameFolder_Figures_diagrams);
%------------------------------------%

% VMA4
str_locgroup = 'VMA4';
x_ref = {[0,0]};
y_ref = {[-1,1]};
x_allLoc = [0,0];
y_allLoc = [-1, 1];
colors_allLoc = colors_asym([6,7], :);
strParts_all = {'full', 'LVM4', 'UVM4'};
indParts_all = {1:2, 1,2};
%------------------------------------%
fxn_plotPF_diagram(str_locgroup, sz_marker_all,  x_ref, y_ref, x_allLoc, y_allLoc, colors_allLoc, strParts_all, indParts_all, outline_ecc, sz_line, nameFolder_Figures_diagrams);
%------------------------------------%

% HVA8
str_locgroup = 'HVA8';
x_ref = {[-2,2], [0,0]};
y_ref = {[0,0], [-2,2]};
x_allLoc = [-2,2, 0,0];
y_allLoc = [0,0, -2,2];
colors_allLoc = colors_asym([8,8,9,9], :);
strParts_all = {'full', 'HM8', 'VM8'};
indParts_all = {1:4, [1,2], [3,4]};
%------------------------------------%
fxn_plotPF_diagram(str_locgroup, sz_marker_all,  x_ref, y_ref, x_allLoc, y_allLoc, colors_allLoc, strParts_all, indParts_all, outline_ecc, sz_line, nameFolder_Figures_diagrams);
%------------------------------------%

% VMA8
str_locgroup = 'VMA8';
x_ref = {[0,0]};
y_ref = {[-2,2]};
x_allLoc = [0,0];
y_allLoc = [-2,2];
colors_allLoc = colors_asym([10,11], :);
strParts_all = {'full', 'LVM8', 'UVM8'};
indParts_all = {1:2, 1,2};
%------------------------------------%
fxn_plotPF_diagram(str_locgroup, sz_marker_all,  x_ref, y_ref, x_allLoc, y_allLoc, colors_allLoc, strParts_all, indParts_all, outline_ecc, sz_line, nameFolder_Figures_diagrams);
%------------------------------------%

fprintf('Diagrams for VPF have been generated and saved in \n.  %s\n', nameFolder_Figures_diagrams);

%%
function fxn_plotPF_diagram(str_locgroup, sz_marker_all,  x_ref, y_ref, x_allLoc, y_allLoc, colors_allLoc, strParts_all, indParts_all, outline_ecc, sz_line, nameFolder_Figures_diagrams)
nParts = length(indParts_all);

for sz_marker = sz_marker_all

    if sz_marker == sz_marker_all(1), str_size = 'small'; else, str_size = 'big'; end
    for iPart = 1:nParts
        strParts = strParts_all{iPart};
        indParts = indParts_all{iPart};
        %%%%%%%%
        x_allLoc_part = x_allLoc(indParts);
        y_allLoc_part = y_allLoc(indParts);
        colors_allLoc_part = colors_allLoc(indParts, :);
        nNodes = length(x_allLoc_part);
        nRef = length(x_ref);

        figure('Position', [0 0 500 500], 'Color', 'w'); hold on;
        axis square, axis off;
        xlim([-2, 2])
        ylim([-2, 2])

        % Draw arcs
        theta = linspace(0, 2*pi, 200);
        for r = outline_ecc
            x = r * cos(theta);
            y = r * sin(theta);
            plot(x, y, 'k-', 'LineWidth', sz_line);
        end

        % Draw vertical dashed line
        for iRef = 1:nRef
            plot(x_ref{iRef}, y_ref{iRef}, 'k-', 'LineWidth', sz_line);
        end

        % Draw nodes
        for iNode = 1:nNodes
            x = x_allLoc_part(iNode);
            y = y_allLoc_part(iNode);
            plot(x, y, 'o', 'MarkerFaceColor', colors_allLoc_part(iNode, :), 'MarkerEdgeColor', 'w', 'MarkerSize', sz_marker, 'LineWidth', sz_line)
        end

        % Define the name of the folder
        nameFolder = sprintf('%s/Size_%s', nameFolder_Figures_diagrams, str_size);
        if isempty(dir(nameFolder)), mkdir(nameFolder), end
        % Save the figure
        saveas(gcf, sprintf('%s/%s_%s.jpg', nameFolder, str_locgroup, strParts))

    end % iPart
    close all
end
end