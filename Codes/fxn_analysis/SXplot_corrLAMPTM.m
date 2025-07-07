
indLoc_s_all = {[1,2,3], [1,4,8], [1,5,9], [4,5], [6,7], [8,9], [10,11]}; nIndLoc_s = length(indLoc_s_all);
iParam_LAMPTM_all = {[2, 2], [1,3], [1,1],  [2,1]};
nCorr_LAMPTM = length(iParam_LAMPTM_all);
iPerf_plot = 2;
nsubj_full = 31;
SF_load_all = [4,51,5,6];

% Loop through each factor to control
for iControl = [0,1,2]
    switch iControl
        case 0, IV_control = 'NoControl'; str_demean = '';
        case 1, IV_control = 'ControlLoc'; str_demean = '(subtracted of mean across Subj)';
        case 2, IV_control = 'ControlSubj'; str_demean = '(subtracted of mean across Loc)';
    end
    
    % Loop through each correlation correspondnce
    for iCorr = 1:nCorr_LAMPTM % 1=LAM?s Neq and PTM?s Nadd; 2=LAM?s Eff and PTM?s Gain
        
        figure('Position', [0 0 2e3 2e3])
        isubplot = 1;
        
        % Loop through each location group
        for iiIndLoc_s = 1:nIndLoc_s
            clc
            indLoc_s = indLoc_s_all{iiIndLoc_s};
            
            nLoc_s = length(indLoc_s);
            namesCombLoc_s = namesCombLoc(indLoc_s);
            str_LocSelected = strjoin(namesCombLoc_s, ''); % Concatenate location names
            fprintf('\n-------%s------\n', str_LocSelected)
            
            estP_allSubj_LAM_acrossSF = nan(nsubj_full, nLoc_s, nLF_LAM);
            estP_allSubj_PTM_acrossSF = nan(nsubj_full, nLoc_s, nLF_PTM-1);
            indSF_acrossSF = nan(nsubj_full, 1);
            indSubj_acrossSF = indSF_acrossSF;
            
            % Loop through each SF
            for SF_load = SF_load_all
                
                % Load and process LAM params
                iTvCModel = 1;
                %------------
                fxn_loadSF
                %------------
                load(nameFile_fitTvC_allSubj,'est_BestSimplest_allSubj')
                % convert Slope to Efficiency
                estP_allSubj_LAM_acrossSF(isubj_start: isubj_end, :, 1) = squeeze(D_ideal./est_BestSimplest_allSubj(:, iiIndLoc_s, 1:nLoc_s, 1, iPerf_plot)*100);
                % convert Slope to beta (according to LD2008, p10, right below Eq4)
%                 estP_allSubj_LAM_acrossSF(isubj_start: isubj_end, :, 1) = squeeze(dprimes(iPerf_plot)./sqrt(est_BestSimplest_allSubj(:, iiIndLoc_s, 1:nLoc_s, 1, iPerf_plot)));
                % convert Neq from energy unit to log contrast unit
                estP_allSubj_LAM_acrossSF(isubj_start: isubj_end, :, 2) = squeeze(log10(sqrt(est_BestSimplest_allSubj(:, iiIndLoc_s, 1:nLoc_s, 2, iPerf_plot))));
                
                % Load  and process PTM params
                iTvCModel = 2;
                %------------
                fxn_loadSF
                %------------
                load(nameFile_fitTvC_allSubj, 'est_BestSimplest_allSubj')
                estP_allSubj_PTM_acrossSF(isubj_start: isubj_end, :, :) = squeeze(est_BestSimplest_allSubj(:, iiIndLoc_s, 1:nLoc_s, :));
                % convert Nadd from contrast unit to log contrast unit
                estP_allSubj_PTM_acrossSF(isubj_start: isubj_end, :, 2) = log10(estP_allSubj_PTM_acrossSF(isubj_start: isubj_end, :, 2));
                
                SF = SF_load; SF(SF==51)=5;
                % Record SF index
                indSF = ones(nsubj, 1)*SF;
                indSF_acrossSF(isubj_start: isubj_end) = indSF;
                
                % Record subj index
                indSubj_acrossSF(isubj_start: isubj_end) = isubj_ANOVA';
                
            end % SF_load
            
            iParam_LAM = iParam_LAMPTM_all{iCorr}(1);
            iParam_PTM = iParam_LAMPTM_all{iCorr}(2);
            
            x_mat = squeeze(estP_allSubj_LAM_acrossSF(:, :, iParam_LAM));
            y_mat = squeeze(estP_allSubj_PTM_acrossSF(:, :, iParam_PTM));
            x = x_mat(:);
            y = y_mat(:);
            indVAR_Loc = repmat(1:nLoc_s, nsubj_full, 1); indVAR_Loc = indVAR_Loc(:);
            indVAR_Subj = repmat(indSubj_acrossSF, 1, nLoc_s); indVAR_Subj = indVAR_Subj(:);
            
            switch iControl
                case 0 %
                    [r,p] = corr(x, y);
                    x = x_mat;
                    y = y_mat;
                    
                case 1 % control for location
                    [r,p] = partialcorr(x, y, indVAR_Loc);
                    x = x_mat - mean(x_mat, 1);
                    y = y_mat - mean(y_mat, 1);
                    
                case 2 % control for subj
                    [r,p] = partialcorr(x, y, indVAR_Subj);
                    x = x_mat - mean(x_mat, 2);
                    y = y_mat - mean(y_mat, 2);
            end
            
            % PLOT
            subplot(2,4, isubplot), hold on, grid on
            
            % Loop through each single location within the location group
            for iiLoc = 1:nLoc_s
                color_ = colors_asym(indLoc_s(iiLoc), :);
                
                % Plot group ave and sem
                [x_ave, ~, ~, x_sem] = getCI(x(:, iiLoc), 2, 1);
                [y_ave, ~, ~, y_sem] = getCI(y(:, iiLoc), 2, 1);
                errorbar(x_ave, y_ave, x_sem, 'horizontal', '.', 'color', color_, 'CapSize', 0, 'LineWidth', 2)
                errorbar(x_ave, y_ave, y_sem, 'vertical', '.', 'color', color_, 'CapSize', 0, 'LineWidth', 2)
                
                % Plot idvd data
                for isubj=1:nsubj_full
                    plot(x(isubj, iiLoc), y(isubj, iiLoc), markers_allSF{indSF_acrossSF(isubj)-3}, 'markerfacecolor', color_, 'markeredgecolor', 'w', 'markersize', 10);
                end
                
                % Plot linear regression for each loc
                lm = polyfit(x(:, iiLoc), y(:, iiLoc), 1);
                x_lm2 = linspace(min(x(:, iiLoc)), max(x(:, iiLoc)), 2);
                yfit = polyval(lm, x_lm2);
                if p<.05, plot(x_lm2, yfit,'-', 'color', color_, 'handlevisibility', 'off', 'linewidth', 1);
                elseif p<.1, plot(x_lm2, yfit,'--', 'color', color_, 'handlevisibility', 'off', 'linewidth', 1);
                end
                
            end % iiLoc
            isubplot = isubplot+1;
            
            % Add reference line at 0
            if iControl, xline(0, 'k--'); yline(0, 'k--'); end
            
            % Labels
            xlabel(sprintf('LAM %s\n%s', namesLF_Labels_LAM{iParam_LAM}, str_demean))
            ylabel(sprintf('PTM %s\n%s', namesLF_Labels_PTM{iParam_PTM+1}, str_demean))
            
            % Title
            title(sprintf('%s (r=%.2f, p=%.3f)', str_LocSelected, r, p))
            
        end % iiIndLoc_s
        
        % Super title
        sgtitle(sprintf('LAM %s vs. PTM %s (Perf=%d%%) [%s]',...
            namesLF_Labels_LAM{iParam_LAM}, namesLF_Labels_PTM{iParam_PTM+1}, perfThresh_all(iPerf_plot), IV_control))
        
        % Save figure
        nameFolder_fig = sprintf('Fig/acrossSFs/SF456/corr_LAMPTM_params');
        if isempty(dir(nameFolder_fig)), mkdir(nameFolder_fig), end
        str_figTitle = sprintf('LAM(%s)_vs_PTM(%s)', namesLF_LAM{iParam_LAM}, namesLF_PTM{iParam_PTM+1});
        saveas(gcf, sprintf('%s/%s_%s.jpg', nameFolder_fig, str_figTitle, IV_control))
    end %iCorr
    close all
end % iControl