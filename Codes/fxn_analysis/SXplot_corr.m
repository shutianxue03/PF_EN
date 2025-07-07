
nSubj = length(dataTable.Thresh)/nLoc_s;
namesCond = {'Raw', 'ControlLoc', 'ControlSubj'};
nCond = length(namesCond);
isubplot = 1;

figure('Position', [10 0 nParams*400 2e3])
for iCond = 1:nCond
    
    for iParam = iParams_all
        switch iCond
            case 1, term_subtract = '';                                               str_title = sprintf('%s%d [%s]\n', namesTvCModel{iTvCModel}, iParam, namesLF{iParam});
            case 2, term_subtract = '(mean across SUBJ subtracted)'; str_title = '[control for LOC]';
            case 3, term_subtract = '(mean across LOC subtracted)'; str_title = '[control for SUBJ]';
        end
        
        x = dataTable.Thresh;
        y = dataTable.(namesLF{iParam});
        
        x_mat = nan(nLoc_s, length(x)/nLoc_s); y_mat = x_mat; SF_mat = x_mat;
        for iiLoc=1:nLoc_s
            x_mat(iiLoc, :) = x(dataTable.LocComb == indLoc_s(iiLoc));
            y_mat(iiLoc, :) = y(dataTable.LocComb == indLoc_s(iiLoc));
            SF_mat(iiLoc, :) = dataTable.SF(dataTable.LocComb == indLoc_s(iiLoc));
        end
        
        switch iCond
            case 1 %
                [r,p] = corr(x, y);
                x = x_mat;
                y = y_mat;
                
            case 2 % control for location, and subtract mean across subj
                [r,p] = partialcorr(x, y, dataTable.LocComb);
                x = x_mat - mean(x_mat, 2);
                y = y_mat - mean(y_mat, 2);
                
            case 3 % control for subj, and subtract mean across loc
                [r,p] = partialcorr(x, y, dataTable.Subj);
                x = x_mat - mean(x_mat, 1);
                y = y_mat - mean(y_mat, 1);
        end
        
        % PLOT
        subplot(nCond, nParams, isubplot), hold on, grid on
        for iiLoc = 1:nLoc_s
            color_ = colors_asym(indLoc_s(iiLoc), :);
            
            for isubj_acrossSF=1:nSubj
                plot(x(iiLoc, isubj_acrossSF), y(iiLoc, isubj_acrossSF), markers_allSF{SF_mat(iiLoc, isubj_acrossSF)-3}, 'color', color_),
            end
            [x_ave, ~, ~, x_sem] = getCI(x(iiLoc, :), 2, 2);
            [y_ave, ~, ~, y_sem] = getCI(y(iiLoc, :), 2, 2);
            errorbar(x_ave, y_ave, x_sem, 'horizontal', '.', 'color', color_, 'CapSize', 0, 'LineWidth', 2)
            errorbar(x_ave, y_ave, y_sem, 'vertical', '.', 'color', color_, 'CapSize', 0, 'LineWidth', 2)
            
            % linear regression for each loc
            lm = polyfit(x(iiLoc, :), y(iiLoc, :), 1);
            x_lm2 = linspace(min(x(iiLoc, :)), max(x(iiLoc, :)), 2);
            yfit = polyval(lm, x_lm2);
            
            if p<.05, plot(x_lm2, yfit,'-', 'color', color_, 'handlevisibility', 'off', 'linewidth', 1);
            elseif p<.1, plot(x_lm2, yfit,'--', 'color', color_, 'handlevisibility', 'off', 'linewidth', 1);
            end
        end % iiLoc
        
        %Ticks and Labels
        xlabel(sprintf('Log cst thresh\n%s', term_subtract))
        ylabel(sprintf('%s\n%s', namesLF_Labels{iParam}, term_subtract))
        if iCond==1
            xticks(cst_log_ticks); xticklabels(round(cst_ln_ticks)); xlim(cst_log_ticks([1, end]));
            yticks(y_ticks{iParam}); yticklabels(y_ticklabels{iParam}), ylim(y_ticks{iParam}([1,end]) + std(y_ticks{iParam})/5.*[-1,1])
        end
        % Reference line at 0
        if iCond==2, xline(0, 'k--'); yline(0, 'k--'); end
        
        % Title
        title(sprintf('%s r=%.2f, p=%.3f', str_title, r, p))
        
        isubplot = isubplot+1;
        
    end % iParam
end % iCond

% Super title
sgtitle(sprintf('[%s] %s (Error type: %s)', str_sgtitle, str_LocSelected, namesErrorType{iErrorType}))

% Save figure
saveas(gcf, sprintf('%s/corr.jpg', nameFolder_fig))
close all