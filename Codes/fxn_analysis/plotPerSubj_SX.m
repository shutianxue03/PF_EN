
%%
% if run this script with an empty var space, load Params_stair in each
% subj's folder, then run this script

%%%%%%%%
% plot_setting
%%%%%%%%
SX_analysis_setting
% nNoise = length(noiseLvl_all);
fprintf('\nnNoise=%d, nLoc=%d\n', nNoise, nLoc)
nameFileStair = sprintf('%s%s_stair.mat', nameFolder_data, subjName);
fileStair = dir(sprintf('%s%s_E1*', nameFolder_data, subjName));
nFiles_stair = length(fileStair);


%% extract ccc data
warning off
if sum(strcmp({'AB', 'AS', 'CM', 'LH', 'MJ'}, subjName))==0
    for iccc = 1:nccc
        
        fprintf('CCC (%s) file creating...\n', namesCCC{iccc})
        nameFileCCC = sprintf('%s%s_ccc_%s.mat', nameFolder_data, subjName, namesCCC{iccc});
        
        switch iccc
            case 1, nameFiles_add_all = sprintf('%s*E1_b*.mat', nameFolder_data);
            case 2, nameFiles_add_all = sprintf('%s*E3_b*.mat', nameFolder_data);
            case 3, nameFiles_add_all = sprintf('%s*E4_b*.mat', nameFolder_data);
            case 4, nameFiles_add_all = sprintf('%s*E*_b*.mat', nameFolder_data);
            case 5, nameFiles_add_all = sprintf('%s*E*_b*.mat', nameFolder_data);
        end
        dirFiles_add_all = dir(nameFiles_add_all); nFiles_ccc = length(dirFiles_add_all);
        nFilesStair = length(dir(sprintf('%s/*E1_b*', nameFolder_data)));
        % only look at data after titration
        if iccc==4, dirFiles_add_all = dirFiles_add_all(nFilesStair+1:end); nFiles_ccc = nFiles_ccc-nFilesStair; end
        if (iccc==1) && (nFiles_ccc>0), constant.expMode=1; end
        if (iccc==2) && (nFiles_ccc>0), constant.expMode=3; end
        if (iccc==3) && (nFiles_ccc>0), constant.expMode=4; end
        if (iccc==4) && (nFiles_ccc>0), constant.expMode=4; end
        
        ccc = [];
        if strcmp(subjName, 'SP')
            load(sprintf('%s%s_ccc_stair.mat', nameFolder_data, subjName), 'ccc')
            fprintf('SP: loaded\n')
        end
        for ifile = 1:nFiles_ccc
            load(dirFiles_add_all(ifile).name, 'real_sequence')
            ccc = [ccc;...
                real_sequence.targetLoc(real_sequence.trialDone==1)'...
                real_sequence.extNoiseLvl(real_sequence.trialDone==1)'...
                real_sequence.scontrast(real_sequence.trialDone==1)'...
                real_sequence.iscor(real_sequence.trialDone==1)'...
                real_sequence.stair(real_sequence.trialDone==1)'...
                real_sequence.stimOri(real_sequence.trialDone==1)'];
        end % ifile
        
        switch iccc
            case 1, ccc_stair = ccc; save(nameFileCCC, 'ccc_stair')
            case 2, ccc_const = ccc; save(nameFileCCC, 'ccc_const')
            case 3, ccc_manual = ccc; save(nameFileCCC, 'ccc_manual')
            case 4, ccc_nonS = ccc; save(nameFileCCC, 'ccc_nonS')
            case 5, ccc_all = ccc; save(nameFileCCC, 'ccc_all')
        end
    end % iccc
else
    nameFileCCC = sprintf('%s/%s_ccc_all.mat', nameFolder_data, subjName);
    load(nameFileCCC), if ~exist('ccc_all', 'var'), ccc_all= ccc; end
end
fprintf('DONE\n')

%% fitting PMF - fit & get PSE
curveX = fit.curveX;
nameFile_fitPMF = sprintf('%s/%s_fitPMF_%s.mat',nameFolder_data, subjName, folderName_extraAnalysis);

% if  sum(strcmp({'AB', 'AS', 'CM', 'LH', 'MJ', 'SP'}, subjName))==0
%     iccc_fit = [1,4,5];
% else
%     iccc_fit = [5];
% end
iccc_fit = 5;

if isempty(dir(nameFile_fitPMF))
    for iccc = iccc_fit
        switch iccc
            case 1, ccc = ccc_stair;
            case 2, ccc = ccc_const;
            case 3, ccc = ccc_manual;
            case 4, ccc = ccc_nonS;
            case 5, ccc = ccc_all;
        end
        if isempty(ccc), ccc=ccc_stair; end
        if iccc == 3
            fprintf('\n\nCCC (%s): %d data points in total...', namesCCC{iccc}, size(ccc, 1))
        else
            fprintf('\n\nCCC (%s): %d data points per loc per noise...', namesCCC{iccc}, round(size(ccc, 1)/nLoc/nNoise))
        end
        
        % empty containers
        cst_log_unik_all = cell(nLoc, nNoise);
        nData_all = cst_log_unik_all;
        nCorr_all = cst_log_unik_all;
        pC_all = cst_log_unik_all;
        
        yfit_allB = cell(nLoc, nNoise, nModels);
        PSE_allB = nan(fit.nBoot, nLoc, nNoise, nModels, nPerf);
        slope_allB = nan(fit.nBoot, nLoc, nNoise, nModels);
        guess_allB = slope_allB;
        lapse_allB = slope_allB;
        LL_allB = slope_allB;
        converged_allB = slope_allB;
        estP_allB = nan(fit.nBoot, nLoc, nNoise, nModels, 4);
        
        for iLoc = iLoc_tgt_all
            for iNoise = 1:nNoise
                fprintf('\nLoc#%d N#%d: ', iLoc, iNoise)
                indLocNoise = ccc(:, 1)==iLoc & ccc(:, 2)==iNoise;
                ccc_full = ccc(indLocNoise, :);
                
                %%%%%%%%%%%%%%
                fxn_fitPMF
                %%%%%%%%%%%%%%
                
            end % iNoise
        end % iLoc
        
        % compile
        cst_log_unik_allC{iccc} = cst_log_unik_all;
        nData_allC{iccc} = nData_all;
        nCorr_allC{iccc} = nCorr_all;
        pC_allC{iccc} = pC_all;
        
        yfit_allC{iccc} = yfit_allB;
        PSE_allC{iccc} = PSE_allB;% nLoc x nNoise x nPerf (70,75,79,82)
        slope_allC{iccc} = slope_allB;
        guess_allC{iccc} = guess_allB;
        lapse_allC{iccc} = lapse_allB;
        LL_allC{iccc} = LL_allB;
        estP_allC{iccc} = estP_allB;
        converged_allC{iccc} = converged_allB;
        
    end % iccc
    % check *allC
    save(nameFile_fitPMF,'*_allC', 'curveX_log')
    fprintf('\nPSE saved\n')
else
    fprintf('\nLoading...')
    load(nameFile_fitPMF)
    fprintf(' DONE\n')
end

%% Get best PSE across all models, and replace nan by titration endpoints
iccc_all = 5;
thresh_best_all = nan(nLoc9, nNoise, nPerf);
imodel_best_all = nan(nLoc9, nNoise);
slope_best_all = imodel_best_all;
lapse_best_all = imodel_best_all;
guess_best_all = imodel_best_all;

if nFiles_stair==0, ccc_stair = ccc; end
for iLoc = iLoc_tgt_all
    for iNoise = 1:nNoise
        iModel_notNaN = [];
        for iModel = 1:nModels
            if isnan(getCI(PSE_allC{iccc_all}(:, iLoc, iNoise, iModel, 3), 1, 1)), continue
            else, iModel_notNaN = [iModel_notNaN, iModel];
            end
        end
        fprintf('L%dN%d: %s\n', iLoc, iNoise, num2str(iModel_notNaN))
        if isempty(iModel_notNaN), iModel_notNaN = 1; end
        [~, imodel_best] = max(getCI(LL_allC{iccc_all}(:, iLoc, iNoise, iModel_notNaN), 1, 1));
        imodel_best = iModel_notNaN(imodel_best);
        imodel_best_all(iLoc, iNoise) = imodel_best;
        
        thresh_best_all(iLoc, iNoise, :) = getCI(PSE_allC{iccc_all}(:, iLoc, iNoise, imodel_best, :));
        slope_best_all(iLoc, iNoise) = getCI(slope_allC{iccc_all}(:, iLoc, iNoise, imodel_best));
        lapse_best_all(iLoc, iNoise) = getCI(lapse_allC{iccc_all}(:, iLoc, iNoise, imodel_best));
        guess_best_all(iLoc, iNoise) = getCI(guess_allC{iccc_all}(:, iLoc, iNoise, imodel_best));
        
    end %iNoise
end % iLoc

%% PLOT IDVD DATA
if flag_plot==1
    %     if subjName == 'SP'
    %         cst_manual = input('Enter the manual cst levels: ');
    %     end
    
    iPerf_plot = 3; % 75, 79, 82
    perfThresh_plot = perfPSE_all(iPerf_plot)/100;
    %     for flag_noStair=0% 0=all trials, 1=only look at trials after titration; , 2=only look at staircase data (fit using logistic function)
    
    %         switch flag_noStair
    %             case 0,
    iccc = 5; text_noStair = '_allTrials';
    %             case 1, iccc=4; text_noStair = '_noStair';
    %             case 2, iccc=1; text_noStair = '_onlyStair';
    %         end
    
    % extract data
    cst_log_unik_all = cst_log_unik_allC{iccc};
    nData_all = nData_allC{iccc};
    nCorr_all = nCorr_allC{iccc};
    pC_all = pC_allC{iccc};
    
    yfit_allB = yfit_allC{iccc};
    PSE_allB = PSE_allC{iccc};% nLoc x nNoise x nPerf (70,75,79,82)
    slope_allB = slope_allC{iccc};
    guess_allB = guess_allC{iccc};
    lapse_allB = lapse_allC{iccc};
    LL_allB = LL_allC{iccc};
    
    %% Figure 0: plot PMF in one figure
    if nNoise<=2, figure('Position', [3e3 0 nNoise*600 nLoc*300]), end
    for iNoise = 1:nNoise
        
        if nNoise>2, figure('Position', [0 0 2e3 2e3]), end
        for iLoc = iLoc_tgt_all
            iplot = 1;
            
            if nNoise>2
                if nLoc==9, subplot(5,5, iplots9(iLoc))
                elseif nLoc==5, subplot(3,3, iplots5(iLoc))
                end
            else, subplot(nLoc, nNoise, iNoise+(find(iLoc== iLoc_tgt_all)-1)*nNoise)
            end
            hold on
            scaling=1/2;
            %%%%%%%%%%
            fxn_plotPMF
            %%%%%%%%%%
            
        end % iLoc_tgt
        
        if nNoise>2
            set(findall(gcf, '-property', 'fontsize'), 'fontsize',10)
            set(findall(gcf, '-property', 'LineWidth'), 'LineWidth',1.5)
            sgtitle(sprintf('%s (SF=%d, N=%.0f%%) - %s [%s]', subjName, SF, noiseLvl_all(iNoise)*100, text_noStair(2:end), folderName_extraAnalysis))
            saveas(gcf, sprintf('%s/PMF_N%.0f%s.jpg', nameFolder_fig, noiseLvl_all(iNoise)*100, text_noStair))
        end
    end % iNoise
    
    if nNoise<=2
        set(findall(gcf, '-property', 'fontsize'), 'fontsize',12)
        set(findall(gcf, '-property', 'LineWidth'), 'LineWidth',1.5)
        sgtitle(sprintf('%s (SF=%d) - %s [%s]', subjName, SF, text_noStair(2:end), folderName_extraAnalysis))
        saveas(gcf, sprintf('%s/PMF_allM%s.jpg', nameFolder_fig, text_noStair))
    end
    
    %% Figure 1: plot PMF of each cond in a single panel
    if flag_plotSinglePanel
        iplot=nan;
        scaling = 1;
        for iNoise = 1:nNoise
            for iLoc = iLoc_tgt_all
                figure('Position', [0 0 1e3 500]), hold on
                
                %%%%%%%%%%
                fxn_plotPMF
                %%%%%%%%%%
                
                xticks_log = -3:.1:0;
                yticks([0, .4, .5, .6, .7, perfPSE_all/100, .9, 1])
                
                xlim(xticks_log([1,end]))
                xticks(xticks_log)
                xticklabels(round(10.^xticks_log*100, 1)), xtickangle(90)
                ylim([0, 1])
                set(findall(gcf, '-property', 'fontsize'), 'fontsize',20)
                set(findall(gcf, '-property', 'LineWidth'), 'LineWidth',2)
                title(sprintf('%s (Loc %d, N=%.0f%%) - %s [%s]', ...
                    subjName, iLoc, noiseLvl_all(iNoise)*100, text_noStair(2:end), folderName_extraAnalysis))
                if isempty(dir([nameFolder_fig, '/singleCond'])), mkdir([nameFolder_fig, '/singleCond']), end
                saveas(gcf, sprintf('%s/singleCond/PMF_L%dN%.0f%s.jpg', nameFolder_fig, iLoc, noiseLvl_all(iNoise)*100, text_noStair))
            end % iLoc_tgt
            close all
        end % iNoise
    end
    % end % for flag_noStair
    
    %% figure 2. plot staircase
    %     if flag_filterData +flag_binData == 0 % only plot once
    if nFiles_stair==0, ccc_stair = ccc; end
    if nNoise==2, ccc_stair = ccc_all; end
    for iNoise=1:nNoise
        if nNoise==2, figure('Position',[0 0 1200 400])
        else, figure('Position', [0 0 2e3 2e3]),
        end
        
        for iLoc = iLoc_tgt_all
            iiLoc = find(iLoc == iLoc_tgt_all);
            if nNoise==7
                if nLoc==9, subplot(5,5, iplots9(iLoc))
                elseif nLoc==5, subplot(3,3, iplots5(iLoc))
                end
            else, subplot(1, nLoc, iiLoc)
            end
            hold on, grid on
            for istair=1:nstairs
                if istair<=2, color = 'r'; % staircase for left-tilted
                elseif istair<=4, color = 'b'; % staircase for left-tilted
                else , color = 'k'; % staircase for left-tilted
                end
                staircase_log = log10(ccc_stair(ccc_stair(:, 1)==iLoc & ccc_stair(:, 2)==iNoise & ccc_stair(:, 5)==istair, 3));
                plot(staircase_log, '.-', 'Color', color)
                if istair<=4, endpoints(istair)=staircase_log(end); end
            end % istair
            yline(mean(endpoints(1:2)), 'r-', 'LineWidth',2);
            yline(mean(endpoints(3:4)), 'b-', 'LineWidth',2);
            yline(mean(endpoints), 'k-', 'LineWidth',3);
            xlabel('trial#')
            ylabel('log contrast')
            yticks(-3:.5:0)
            yticklabels(round(10.^(-3:.5:0)*100))
            ylim([-3, 0]);
            endpoints = 100*10.^(endpoints);
            title(sprintf('[L%d]  %.1f%%\nL: %.1f%% // R: %.1f%%', iLoc, mean(endpoints), mean(endpoints([1,2])), mean(endpoints([3,4]))))
        end % iLoc
        sgtitle(sprintf('%s [SF=%d, Noise=%.0f%%]', subjName, SF, noiseLvl_all(iNoise)*100))
        
        if nNoise==2, set(findall(gcf, '-property', 'fontsize'), 'fontsize',20), end
        
        saveas(gcf, sprintf('%s/%.0f_staircase.jpg', nameFolder_fig, noiseLvl_all(iNoise)*100))
    end % iNoise
    %     end
    
    %% Fig 3. PSE as a fxn of all loc
    if nNoise==2
        iccc = 5; % 1=stair, 2=constim, 3=manul, 4=non-staircase; 5=all trials
        if constant.expMode==1, iccc = 1; end
        % iLoc_Fovea_Peri_HM_VM_LVM_UVM = input(sprintf('Current locs are %s\nwhat is your indices of fovea, peri, HM, VM, LVM, UVM (put in a cell): ', num2str(constant.iLoc_tgt_all)));
        
        iLoc_Fovea_Peri_HM_VM_LVM_UVM = {1, 3:5, 4, [3,5], 5, 3};
        
        figure('Position', [0 0 2*450 150])
        for iNoise = [1, nNoise]
            subplot(1,2,find(iNoise==[1, nNoise])), hold on
            text_HVA=[];
            text_VMA=[];
            for iperf = 1:nPerf
                
                HM = mean(thresh_best_all(iLoc_Fovea_Peri_HM_VM_LVM_UVM{3}, iNoise, iperf));
                VM = mean(thresh_best_all(iLoc_Fovea_Peri_HM_VM_LVM_UVM{4}, iNoise, iperf));
                LVM = mean(thresh_best_all(iLoc_Fovea_Peri_HM_VM_LVM_UVM{5}, iNoise, iperf));
                UVM = mean(thresh_best_all(iLoc_Fovea_Peri_HM_VM_LVM_UVM{6}, iNoise, iperf));
                
                x=iperf+nPerf+.5;
                buffer=.2;
                x=[iperf-buffer, iperf+buffer, x-buffer, x+buffer];
                
                bar(x, 10.^([HM, VM, LVM, UVM]))
                xticks(x), xticklabels({'HM', 'VM', 'LVM', 'UVM'})
                
                HVA = (HM-VM)/(HM+VM);
                VMA = (LVM-UVM)/(LVM+UVM);
                text_HVA=sprintf('%s//%.2f', text_HVA, HVA);
                text_VMA=sprintf('%s//%.2f', text_VMA, VMA);
                text_legends{iperf}=num2str(perfPSE_all(iperf));
            end % iperf
            
            %         xticklabels({'Fov', 'Peri', 'HM', 'VM', 'LVM', 'UVM'})
            legend(text_legends, 'NumColumns', nPerf, 'Location', 'southwest')
            ylabel('Thresh')
            set(findall(gcf, '-property', 'fontsize'), 'fontsize',12)
            %     ylim([0, 20])
            title(sprintf('[%s] SF=%d, Noise=%.0f%% [%s] \nHVA=%s; VMA=%s', ...
                subjName, SF, 100*noiseLvl_all(iNoise), folderName_extraAnalysis, text_HVA, text_VMA))
            
        end% iNoise
        saveas(gcf, sprintf('%s/compLoc.jpg', nameFolder_fig))
    end
    
    %% Fig 4: cross locations, whether noise=0% is diff from noise=44%
    close all
    iccc = 5; % all trials
    for flag_plotEnergy = [0,1] % 1=plot energy (i.e., cst^2); 0=plot cst
        if nNoise>1
            %     y_log_min = log10(floor(10.^min(PSE_allC{nccc}, [], 'all')*100)/100); %if y_log_min==-Inf, y_log_min=-3;end
            %     y_log_max = log10(ceil(10.^max(PSE_allC{nccc}, [], 'all')*100)/100);
            y_log_min = log10(.03); %if y_log_min==-Inf, y_log_min=-3;end
            y_log_max = log10(.6);
            yticks_log = linspace(y_log_min, y_log_max, 5);
            yticks_ln = 10.^yticks_log;
            x_log = [-2, log10(noiseLvl_all(2:end))]; % set log10(0)=-2 because log10(0) is Inf
            
            %             x_log = [-2, log10(noiseLvl_all(end))];
            
            buffer = .5;
            text_itv = [-.3, .1];
            for iperf = 1:nPerf
                figure('Position', [0 0 500 300]), hold on, grid on
                for iLoc = iLoc_tgt_all%1:nLoc
                    if flag_plotEnergy
                        plot(log10((10.^x_log).^2), log10((10.^thresh_best_all(iLoc, :, iperf)).^2), 'o-', 'Color', colors9(iLoc, :), 'MarkerSize', 10, 'MarkerFaceColor', 'w')
                    else
                        plot(x_log, thresh_best_all(iLoc, :, iperf), 'o-', 'Color', colors9(iLoc, :), 'MarkerSize', 10, 'MarkerFaceColor', 'w')
                        xticks(x_log)
                        xticklabels(noiseLvl_all)
                    end
                end
                
                if flag_plotEnergy
                    ylabel('threshold energy (c^2)')
                    xlabel('External noise energy (c^2)')
                else
                    ylim(yticks_log([1, end]))
                    yticks(yticks_log)
                    yticklabels(round(yticks_ln*100, 1))
                    ylabel('Contrast threshold (%)')
                    xlabel('External noise (%)')
                end
                
                title(sprintf('%s [SF%d] [%s] %d%%', subjName, SF, folderName_extraAnalysis, perfPSE_all(iperf)))
                set(findall(gcf, '-property', 'fontsize'), 'fontsize',15)
                set(findall(gcf, '-property', 'LineWidth'), 'LineWidth',2)
                
                saveas(gcf, sprintf('%s/compNoise_%d_mode%d.jpg', nameFolder_figStair, perfPSE_all(iperf), flag_plotEnergy))
            end % iperf
        end
        
    end %     for flag_plotEnergy
end % if flag_plot
