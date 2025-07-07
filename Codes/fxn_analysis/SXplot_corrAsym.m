
flag_printLMM = 0; flag_plotLMM= 0;

str_fxnAsym = 'diffsum';
fxn_getAsym = @(x1,x2) (x1-x2)./(x2+x1+eps);
str_tail_allParam = {'two', 'right', 'right'}; % Gamma (neg expected, unsure), Nadd (pos expected), Gain (pos expected)


% str_fxnAsym = 'diff';
% fxn_getAsym = @(x1,x2) (x1-x2);
% str_tail_allParam = {'right', 'right', 'left'}; % Gamma (neg expected, unsure), Nadd (neg expected), Gain (pos expected)

for iControl = [0,1] %0=raw, 1=control for SF; 2=control for subj (ignored for now)
    switch iControl
        case 0, IV_control = 'NoControl'; str_demean = '';
        case 1, IV_control = 'ControlSF'; str_demean = '(demeaned for SF)';
        case 2, IV_control = 'ControlSubj';
    end

    figure('Position', [10 0 nParams*300 2e3])
    if nLoc_s==2, nComp=1; else, nComp=3; end
    isubplot = 1;

    for iComp = 1:nComp
        switch iComp
            case 1, iComp1=1; iComp2=2;
            case 2, iComp1=2; iComp2=3;
            case 3, iComp1=1; iComp2=3;
        end
        switch str_fxnAsym
            case 'diffsum'
                title_vs = sprintf('(%s - %s)/(%s + %s)', namesCombLoc_s{iComp1}, namesCombLoc_s{iComp2}, namesCombLoc_s{iComp1}, namesCombLoc_s{iComp2});
            case 'diff'
                title_vs = sprintf('(%s - %s)', namesCombLoc_s{iComp1}, namesCombLoc_s{iComp2});
        end

        %% LMM: Threshold asym ~ Gamma asym + Nadd Asym + Gain asym + 1|Subj
        % nameFolder_fig_ANOVA = sprintf('%s/ANOVA_%s/%s', nameFolder_Fig_Thresh, strjoin(IV_single_all, 'x'), flag_multComp);
        str_LMM = [];
        if flag_printLMM
            nameFolder_fig_LMM = sprintf('%s/LMM', nameFolder_fig); mkdir(nameFolder_fig_LMM)
            formula = sprintf('%s ~ LocComb * SF + (1|Subj)', paramName);
            %----------------------------%
            lme = fitlme(dataTable, formula);
            str_LMM = fxn_printLMM(lme, dataTable, DV, flag_printLMM, flag_plotLMM, nameFolder_fig_LMM);
        end
        for iParam = iParams_all
            subplot(nComp, nParams, isubplot)

            % Define x and y
            x = dataTable.Thresh;                      x_label = 'Threshold';
            y = dataTable.(namesLF{iParam});   y_label = namesLF_Labels{iParam};

            % draw correlation for ALL SFs
            ind1 = dataTable.LocComb==indLoc_s(iComp1);
            ind2 = dataTable.LocComb==indLoc_s(iComp2);
            indSF_xy = dataTable.SF(ind1);
            indSubj_xy = dataTable.Subj(ind1);
            x1=x(ind1); x2=x(ind2);
            y1=y(ind1); y2=y(ind2);
            x_asym = fxn_getAsym(x1, x2);
            y_asym = fxn_getAsym(y1, y2);
            %----------------------------------------%
            wd_border = 1.5;
            text_corr_allSF = basicFxn_drawCorrAsym(x_asym, y_asym, iControl, indSF_xy, str_tail_allParam{iParam}, [], [], [], [], namesLF{iParam}, 'm', '.', wd_border);
            %----------------------------------------%

            % Draw correlation for each SF
            text_corr_perSF = cell(nSF, 1);
            for SF = SF_all
                ind1 = dataTable.LocComb==indLoc_s(iComp1) & dataTable.SF==SF;
                ind2 = dataTable.LocComb==indLoc_s(iComp2) & dataTable.SF==SF;
                x1=x(ind1); x2=x(ind2);
                y1=y(ind1); y2=y(ind2);
                x_asym = fxn_getAsym(x1, x2);
                y_asym = fxn_getAsym(y1, y2);

                indSF_xy = dataTable.SF(ind1);
                indSubj_xy = dataTable.Subj(ind1);
                %----------------------------------------%
                wd_border = .8;
                text_corr_perSF{SF-3} = basicFxn_drawCorrAsym(x_asym, y_asym, iControl, indSF_xy, str_tail_allParam{iParam}, [], [], [], [], namesLF{iParam}, 'k', markers_allSF{SF-3}, wd_border);
                %----------------------------------------%
            end % SF
            xlabel(sprintf('%s %s', x_label, str_demean))
            ylabel(sprintf('%s %s', y_label, str_demean))
            title(sprintf('[%s] %s \n%s', namesLF_Labels{iParam}, title_vs, text_corr_allSF))
            isubplot = isubplot+1;
        end % iParam
    end % iComp

    % Super title
    sgtitle(sprintf('[%s] %s [%s] (Error type: %s) [fxnAsym = %s]', str_sgtitle, str_LocSelected, IV_control, namesErrorType{iErrorType}, str_fxnAsym))

    set(findall(gcf, '-property', 'fontsize'), 'fontsize',10)

    % Save figure
    saveas(gcf, sprintf('%s/corrAsym_%s_%s.jpg', nameFolder_fig, str_fxnAsym, IV_control))
end % iCorr

close all