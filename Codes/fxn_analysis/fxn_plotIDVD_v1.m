
close all
nstairs = 6;
flag_fitThreshMode = 1; % 1=threshold is estimated from fitting PMF; 2=from staircase endpoints
nameFolder_fig_TvC = sprintf('%s/TvC', nameFolder_fig_PMF);
if isempty(dir(nameFolder_fig_TvC)), mkdir(nameFolder_fig_TvC), end

%% Figure 1: plot PMF in one figure

for iNoise = 1:nNoise
    
    figure('Position', [0 0 2e3 2e3])
    for iLoc = 1:nLocSingle
        
        if ~isempty(cst_log_unik_all{iLoc, iNoise})
            
            if nLocSingle==9, subplot(5,5, iplots9(iLoc))
            elseif nLocSingle==5, subplot(3,3, iplots5(iLoc))
            end
            hold on
            scaling=1/2;
            %-----------------------%
            fxn_plotPMF_singlePanel
            %-----------------------%
        end
    end % iLoc_tgt
    
    set(findall(gcf, '-property', 'fontsize'), 'fontsize',10)
    set(findall(gcf, '-property', 'LineWidth'), 'LineWidth',1.5)
    sgtitle(sprintf('%s (SF=%d, N=%.3f)  %.0f%% [Bin%dFilter%d]', subjName, SF, noiseLvl_all(iNoise), perfThresh_plot*100, flag_binData, flag_filterData))
    
    saveas(gcf, sprintf('%s/PMF_N%.0f.jpg', nameFolder_fig_PMF, noiseLvl_all(iNoise)*100))
    
end % iNoise

if nNoise<=2
    set(findall(gcf, '-property', 'fontsize'), 'fontsize',12)
    set(findall(gcf, '-property', 'LineWidth'), 'LineWidth',1.5)
    sgtitle(sprintf('%s (SF=%d)  [%s]', subjName, SF, folderName_extraAnalysis))
    saveas(gcf, sprintf('%s/PMF.jpg', nameFolder_fig_PMF))
end

close all

%% Figure 1a: plot PMF of each cond in a single panel
if flag_plotSinglePanel
    for iNoise = 1:nNoise
        for iLoc = 1:nLoc
            figure('Position', [0 0 1e3 500]), hold on
            
            %-----------------------%
            fxn_plotPMF_singlePanel
            %-----------------------%
            
            xticks_log = -3:.1:0;
            yticks([0, .4, .5, .6, .7, perfThresh_all/100, .9, 1])
            
            xlim(xticks_log([1,end]))
            xticks(xticks_log)
            xticklabels(round(10.^xticks_log*100, 1)), xtickangle(90)
            ylim([0, 1])
            set(findall(gcf, '-property', 'fontsize'), 'fontsize',20)
            set(findall(gcf, '-property', 'LineWidth'), 'LineWidth',2)
            title(sprintf('%s (Loc %d, N=%.0f%%) - %s [Bin%dFilter%d]', ...
                subjName, iLoc, noiseLvl_all(iNoise)*100, text_noStair(2:end),flag_binData, flag_filterData))
            if isempty(dir([nameFolder_fig, '/singleCond'])), mkdir([nameFolder_fig, '/singleCond']), end
            saveas(gcf, sprintf('%s/singleCond/PMF_L%dN%.0f%s.jpg', nameFolder_fig_PMF, iLoc, noiseLvl_all(iNoise)*100, text_noStair))
        end % iLoc_tgt
        close all
    end % iNoise
end


%% Fig 2: plot pred and estimated params of LAM/PTM
clc, close all

%-----------------%
SX_fitTvC_setting
%-----------------%

for iTvCModel=1:2 % 1=LAM; 2=PTM
    
    for iPerf = 1:nPerf
        
        figure('Position', [0 0 1320 1e3]), hold on
        
        for flag_plotEnergy = [0,1] % 1=plot energy (i.e., cst^2); 0=plot cst
            
            switch flag_plotEnergy
                case 1 % plot threshEnergy as a fxn of noise Energy
                    x_label = 'External noise energy (c^2)';
                    y_label = 'Threshold energy (c^2)';
                    
                    x = noiseEnergy_true;
                    y = threshEnergy;
                    
                    x_1k = noiseEnergy_intp_true;
                    switch iTvCModel
                        case 1, y_1k = threshEnergy_LAM_pred_allPerf;
                        case 2, y_1k = threshEnergy_PTM_pred_allPerf;
                    end
                    
                    x_ticks = noiseEnergy_true;
                    x_tickslabels = noiseEnergy_true;
                    y_ticks = cstEnergy_ticks;
                    y_ticklabels = round(y_ticks,2);
                    
                case 0 % plot log thresh as a fxn of log noise SD
                    y_label = 'Contrast threshold (%)';
                    x_label = 'External noise SD';
                    x = noiseSD_log_all;
                    y = thresh_log;
                    
                    x_1k = noiseSD_intp_log_true;
                    switch iTvCModel
                        case 1, y_1k = log10(sqrt(threshEnergy_LAM_pred_allPerf));
                        case 2, y_1k = log10(sqrt(threshEnergy_PTM_pred_allPerf));
                    end
                    
                    x_ticks = noiseSD_log_all;
                    x_ticklabels = noiseSD_ln_all;
                    y_ticks = cst_log_ticks;
                    y_ticklabels = round(cst_ln_ticks);
            end
            
            % plot TvC and fitted model
            iLoc_notNan = ~isnan(threshEnergy(:, 1, 1));
            iiLoc = 1;
            str_R2 = cell(nLocSingle, 1);
            
            subplot(nParams_PTM, 3, (1:3:10)+flag_plotEnergy), hold on % here, use nParams_PTM rather than nParams_LAM on purpose
            
            switch iTvCModel
                case 1
                    est_allPerf = est_LAM_allPerf;
                    namesParams = namesParams_LAM;
                    nParams = nParams_LAM;
                    R2_allPerf=R2_LAM_allPerf;
                case 2
                    est_allPerf = est_PTM_allPerf;
                    nParams = nParams_PTM;
                    namesParams = namesParams_PTM; 
                    R2_allPerf=R2_PTM_allPerf;
            end
            assert(nParams == length(namesParams))
            
            for iLoc = 1:nLocSingle
                if iLoc_notNan(iLoc)
                    plot(x, squeeze(y(iLoc, :, iPerf)), 'o--', 'color', colors_single(iLoc, :), 'MarkerSize', 10)
                    plot(x_1k, squeeze(y_1k(iLoc, iPerf, :)).', '-', 'color', colors_single(iLoc, :), 'HandleVisibility', 'off')
                    
                    str_R2{iiLoc} = sprintf('%s [%.0f%%]\n', namesLoc9{iLoc}, R2_allPerf(iLoc, iPerf)*100);
                    iiLoc = iiLoc+1;
                end
            end
            
            xlim(x_ticks([1, end]))
            xticks(x_ticks)
            xticklabels(x_ticklabels), xtickangle(90)
            xlabel(x_label)
            
            ylim(y_ticks([1, end]))
            yticks(y_ticks)
            yticklabels(y_ticklabels)
            ylabel(y_label)
            
            if flag_plotEnergy, legend(str_R2(1:nLocSingle), 'Location', 'best', 'NumColumns', 3), end
            
        end % flag_plotEnergy
        
        %%% PLOT estimated params %%%
        for iLF = 1:nParams 
            LF_allLoc = est_allPerf(:, iLF);
            if iTvCModel==1  % LAM
                switch iLF
                    case 1 % convert slope to efficiency
                        LF_allLoc = D_ideal./LF_allLoc*100;
                    case 2 % convert Neq to lof step
                        LF_allLoc = log10(LF_allLoc);
                end
            end
            switch iTvCModel
                case 1
                    switch iLF
                        case 1,  y_ticks = linspace(0, 10, 5); % slope in %
                        case 2, y_ticks = linspace(-3, 0, 5); % Neq, in logstep
                    end
                case 2
                    switch iLF
                        case 1,  y_ticks = linspace(0, 6, 5); % N-mul
                        case 2, y_ticks = linspace(0, 6, 5); % gamma
                        case 3,  y_ticks = linspace(0, .1, 5); % SD-add
                        case 4,  y_ticks = linspace(0, 3, 5); % beta
                    end
            end
            
            subplot(nParams_PTM, 3, iLF*3), hold on % here, use nParams_PTM rather than nParams_LAM on purpose
            [LF_CombLoc, namesCombLoc, LF_asym, namesAsym] = fxn_extractAsym(LF_allLoc);
            
            if nLocSingle == 5 %any(strcmp(subjName, sub_LAMjList_SX))
                x=[1:2, (3:4)+.5, (5:6)+1]; % fov, ecc4, // HM4, VM4, LVM4, UVM4
                x_color = [colors_comb([1, 2, 4, 5], :); colors_single([5,3], :)];
                xline(2.75, 'color', ones(1,3)/2);
                xline(5.25, 'color', ones(1,3)/2);
            else
                x=[1:3, (4:7)+.5, (8:11)+1]; % fov, ecc4, ecc8, // HM4, VM4, LVM4, UVM4, // HM8, VM8, LVM8, UVM8
                x_color = [colors_comb(1:5, :); colors_single([5,3], :); colors_comb(6:7, :); colors_single([9, 7], :)];
                xline(3.75, 'color', ones(1,3)/2);
                xline(8.25, 'color', ones(1,3)/2);
            end
            
            nLocComb = length(x);
            for iLocComb = 1:nLocComb
                plot(x(iLocComb), LF_CombLoc{iLocComb}, 'o', 'markerfacecolor', x_color(iLocComb, :),'MarkerEdgeColor', 'w', 'MarkerSize', 15)
            end
            xticks(sort(x))
            xticklabels(namesCombLoc), xtickangle(45)
            
            xlim([min(x)-.5, max(x)+.5])
            ax = gca;ax.YGrid = 'on';
            title(namesParams{iLF})
            yticks(y_ticks), ylim([min(y_ticks), max(y_ticks)]),
            %             switch iLF, case 1, yticklabels(round(10.^y_ticks*100, 1)), case 2, yticklabels(round(y_ticks_log, 1)), end
            
        end % iLF
        %%%%%%%
        % title
        title_ = sprintf('%s [SF%s] [Bin%dFilter%d] collapseHM=%d', subjName, SF, flag_binData, flag_filterData, flag_collapseHM);
        sgtitle(sprintf('%s [PMF%d%% - %s]', title_, perfThresh_all(iPerf), namesTvCModel{iTvCModel}))
        
        set(findall(gcf, '-property', 'fontsize'), 'fontsize',12)
        set(findall(gcf, '-property', 'LineWidth'), 'LineWidth',2)
        
        % save
        saveas(gcf, sprintf('%s/TvC_PMF%.0f_%s.jpg', nameFolder_fig_TvC, perfThresh_all(iPerf), namesTvCModel{iTvCModel}))
    end % iPerf
end % iTvCModel

%% Fig 3. replot TvC and fitting, but by location (5x5)
close all

y_log_1k_LAM = log10(sqrt(threshEnergy_LAM_pred_allPerf));
y_log_1k_PTM = log10(sqrt(threshEnergy_PTM_pred_allPerf));

for iPerf = 1:nPerf
    
    figure('Position', [0 0 2e3 2e3])
    for iLoc = 1:nLocSingle
        
        subplot(5,5, iplots9(iLoc)), hold on
        a = squeeze(thresh_log(iLoc, :, :)); a = a(:);
        b = squeeze(y_log_1k_LAM(iLoc, :, :)); b = b(:); b(b==Inf)=nan;
        c = squeeze(y_log_1k_PTM(iLoc, :, :)); c = real(c(:));c(c==Inf)=nan;
        
        max_  = max([a;b;c]); if max([a;b;c])>0, max_ = 0;end
        cst_log_ticks_perLoc = linspace(min([a;b;c]), max_, 5);
        %         cst_log_ticks_perLoc = log10([2, 5:5:30]/100);
        
        cst_ln_ticks_perLoc = round(10.^(cst_log_ticks_perLoc)*100);
        
        plot(noiseSD_log_all, squeeze(thresh_log(iLoc, :, iPerf)), markers_allSubj{isubj}, 'color', colors_single(iLoc, :), 'MarkerSize', 10)
        plot(noiseSD_intp_log_true, squeeze(y_log_1k_LAM(iLoc, iPerf, :)).', '-', 'color', colors_single(iLoc, :), 'HandleVisibility', 'off')
        plot(noiseSD_intp_log_true, squeeze(y_log_1k_PTM(iLoc, iPerf, :)).', '--', 'color', colors_single(iLoc, :), 'HandleVisibility', 'off')
        
        % plot Neq
        xline(est_LAM_allPerf(iLoc, iPerf), '-', 'color', colors_single(iLoc, :));
        
        xlim(noiseSD_log_all([1, end]) + [-.1, .1])
        xticks(noiseSD_log_all)
        xticklabels(noiseSD_ln_all)
        xtickangle(90)
        
        yticks(cst_log_ticks_perLoc)
        yticklabels(cst_ln_ticks_perLoc)
        ylim(cst_log_ticks_perLoc([1, end]))
        
        grid on
        title(sprintf('L%d R^2=%.0f%% // %.0f%%', iLoc, R2_LAM_allPerf(iLoc, iPerf)*100, R2_PTM_allPerf(iLoc, iPerf)*100))
    end % iLoc_tgt
    
    set(findall(gcf, '-property', 'fontsize'), 'fontsize',10)
    set(findall(gcf, '-property', 'LineWidth'), 'LineWidth',1)
    
    sgtitle(sprintf('%s [SF=%d]  [Bin%dFilter%d] %d%%', subjName, SF, flag_binData, flag_filterData, perfThresh_all(iPerf)))
    saveas(gcf, sprintf('%s/TvC/TvC_%d.jpg', nameFolder_fig_PMF, perfThresh_all(iPerf)))
end
