
%%
% if run this script with an empty var space, load Params_stair in each
% subj's folder, then run this script
%%%%%%%%
% plot_setting
%%%%%%%%
SX_analysis_setting
nLoc = length(constant.iLoc_tgt_all);
nNoiseLvl = length(params.extNoiseLvl);
fprintf('nNoise=%d, nLoc=%d\n', nNoiseLvl, constant.nLoc_tgt)
flag_logCST=1;

%% create fig folder for each idvd
% nameFolder_fig = sprintf('fig/SF%d/', constant.SF);
nameFolder_fig = sprintf('fig/%s/', participant.subjName);
if isempty(dir(nameFolder_fig)), mkdir(nameFolder_fig), end

%% extract data ccc
warning off
namesCCC = {'stair', 'const', 'manual', 'all'}; nccc=length(namesCCC);

for iccc = 1:nccc
    
    fprintf('CCC (%s) file creating...\n', namesCCC{iccc})
    nameFileCCC = sprintf('%s/%s_ccc_%s.mat', constant.nameFolder, participant.subjName, namesCCC{iccc});
    
    switch iccc
        case 1, nameFiles_add_all = sprintf('%s/*E1_b*', constant.nameFolder);
        case 2, nameFiles_add_all = sprintf('%s/*E3_b*', constant.nameFolder);
        case 3, nameFiles_add_all = sprintf('%s/*E4_b*', constant.nameFolder);
        case 4, nameFiles_add_all = sprintf('%s/*E*_b*', constant.nameFolder);
    end
    dirFiles_add_all = dir(nameFiles_add_all); nFiles = length(dirFiles_add_all);
    if (iccc==1) && (nFiles>0), constant.expMode=1; end
    if (iccc==2) && (nFiles>0), constant.expMode=3; end
    if (iccc==3) && (nFiles>0), constant.expMode=4; end
    
    ccc = [];
    for ifile = 1:nFiles
        load(dirFiles_add_all(ifile).name, 'real_sequence')
%         fprintf('\n%d: %d/%d', ifile, sum(real_sequence.trialDone), length(real_sequence.trialDone))
        ccc = [ccc;...
            real_sequence.targetLoc(real_sequence.trialDone==1)'...
            real_sequence.extNoiseLvl(real_sequence.trialDone==1)'...
            real_sequence.scontrast(real_sequence.trialDone==1)'...
            real_sequence.iscor(real_sequence.trialDone==1)'];
    end % ifile
    
    switch iccc
        case 1, ccc_stair = ccc; save(nameFileCCC, 'ccc_stair')
        case 2, ccc_const = ccc; save(nameFileCCC, 'ccc_const')
        case 3, ccc_manual = ccc; save(nameFileCCC, 'ccc_manual')
        case 4, ccc_all = ccc; save(nameFileCCC, 'ccc_all')
    end
end % iccc
fprintf('DONE\n')

%% fitting PMF - fit & get PSE
nLoc_tgt = constant.nLoc_tgt;
curveX = fit.curveX;
nameFile_PSE = sprintf('%s/%s_PSE.mat', constant.nameFolder, participant.subjName);

for iccc = 1:nccc
    switch iccc
        case 1, ccc = ccc_stair;
        case 2, ccc = ccc_const; if isempty(ccc), ccc=ccc_stair; end
        case 3, ccc = ccc_manual; if isempty(ccc), ccc=ccc_stair; end
        case 4, ccc = ccc_all; if isempty(ccc), ccc=ccc_stair; end
    end
    if iccc==3
        fprintf('\nCCC (%s): %d data points in total...', namesCCC{iccc}, size(ccc, 1))
    else
        fprintf('\nCCC (%s): %d data points per loc per noise...', namesCCC{iccc}, round(size(ccc, 1)/nLoc_tgt/nNoiseLvl))
    end
    iLoc_all = ccc(:,1); % target locations, 1-9
    iNoise_all = ccc(:,2);
    icor_all = ccc(:,4);
    
    % empty containers
    yfit_all = cell(params.nLoc_PH, nNoiseLvl);
    cst_all = yfit_all;
    nData_all = yfit_all;
    nCorr_all = yfit_all;
    pC_all = yfit_all;
    
    PSE_all = nan(params.nLoc_PH, nNoiseLvl, nPerf);
    slope_all = nan(params.nLoc_PH, nNoiseLvl);
    LL_all = slope_all;
    R2_all = slope_all;
    
    for iLoc_tgt = constant.iLoc_tgt_all
        for iNoise = 1:nNoiseLvl
            %%%%%%%
            fxn_fitPMF_postExp
            %%%%%%%
        end % iNoise
    end % iLoc
    if flag_logCST, PSE_all=10.^PSE_all;end % nLoc x nNoise x nPerf (70,75,79,82)
    % compile
    yfit_allC{iccc} = yfit_all;
    cst_allC{iccc} = cst_all;
    nData_allC{iccc} = nData_all;
    nCorr_allC{iccc} = nCorr_all;
    pC_allC{iccc} = pC_all;
    PSE_allC{iccc} = PSE_all;% nLoc x nNoise x nPerf (70,75,79,82)
    slope_allC{iccc} = slope_all;
    LL_allC{iccc} = LL_all;
    R2_allC{iccc} = R2_all;
end % iccc
save(nameFile_PSE,'PSE_allC', 'cst_allC', 'nCorr_allC', 'nData_allC','pC_allC','R2_allC', 'slope_allC',  'curveX', 'yfit_all')
fprintf('\nPSE saved\n')
% else
%     load(nameFile_PSE); fprintf('PSE (%s) loaded\n', nameMode)
% end

%% figure 0. plot staircase
fileStair = dir(sprintf('Data/SF%d/%s/%s_E1*', constant.SF, participant.subjName, participant.subjName));
% fileStair = dir('Data/SF6/SX/SX_E1*');

nF = length(fileStair);
% iLoc_all = 3:5; nLoc = length(iLoc_all);

nstair = 6;
cst_all = cell(nLoc, nNoiseLvl, nstair);
signalORI_all = cst_all;
iscor_all =cst_all;
% nNoiseLvl = length(params.extNoiseLvl);
for iLoc = constant.iLoc_tgt_all
    for iNoise = 1:nNoiseLvl
        for istair=1:nstair
            cst  =[]; signalORI=[];iscor=[];
            for iF=1:nF
                load(fileStair(iF).name)
                ind =  (real_sequence.targetLoc==iLoc) &  (real_sequence.extNoiseLvl==iNoise) & (real_sequence.stair==istair) & (real_sequence.trialDone==1);
                cst = [cst, real_sequence.scontrast(ind)];
                signalORI =[signalORI, real_sequence.stimOri(ind)];
                iscor = [iscor, real_sequence.iscor(ind)];
            end
            cst_all{iLoc, iNoise, istair} = cst;
            signalORI_all{iLoc, iNoise, istair} =signalORI;
            iscor_all{iLoc, iNoise, istair} =iscor;
        end
    end
end

%%
for iNoise=1:nNoiseLvl
    figure('Position',[0 0 1200 400])
    for iLoc = constant.iLoc_tgt_all
        subplot(1, nLoc, iLoc-2), hold on
        for istair=1:nstair
            plot(1:length(cst_all{iLoc, iNoise, istair}), log10(cst_all{iLoc,iNoise,  istair}), '.-')
            if istair<=4, endpoints(istair)=log10(cst_all{iLoc, iNoise, istair}(end)); end
        end
        xlabel('trial#')
        ylabel('log contrast')
        yticks(-2:.5:0)
        yticklabels(round(10.^(-2:.5:0), 2))
        ylim([-2, 0])
        title(sprintf('L%d  %.0f%%(%.0f%%)', iLoc, 100*10^mean(endpoints), 100*std(10.^endpoints)))
    end
    sgtitle(sprintf('%s [SF=%d, Noise=%.0f%%]', participant.subjName, constant.SF, params.extNoiseLvl(iNoise)*100))
    set(findall(gcf, '-property', 'fontsize'), 'fontsize',20)
    set(findall(gcf, '-property', 'LineWidth'), 'LineWidth',2)
    saveas(gcf, sprintf('%sSF%d_%.0f_staircase.jpg', nameFolder_fig, constant.SF, params.extNoiseLvl(iNoise)*100))
end

%% Figure 1. plot PMF
SX_analysis_setting
switch constant.expMode
    case 1, ind_iccc = 1;
    case 3, ind_iccc = [1,2,4]; 
    case 4, ind_iccc = 1:nccc;
end
colors_allCCC=[0,0,1;1,0,0; 0,1,0;.5,0,1]; % stair is blue, const is red, all is purple

figure('Position', [3e3 0 nNoiseLvl*400 nLoc_tgt*300])

for iLoc_tgt = constant.iLoc_tgt_all%1:nLoc
    for iNoise = 1:nNoiseLvl
        subplot(nLoc_tgt, nNoiseLvl, iNoise+(find(iLoc_tgt==constant.iLoc_tgt_all)-1)*nNoiseLvl), hold on
        
        for iccc = ind_iccc % on top of all data, highlight constant stim data
            cst = cst_allC{iccc}{iLoc_tgt, iNoise};
            nCorr = nCorr_allC{iccc}{iLoc_tgt, iNoise};
            nData = nData_allC{iccc}{iLoc_tgt, iNoise};
            pC = pC_allC{iccc}{iLoc_tgt, iNoise};
            
            if iccc~=nccc % plot data points of the current ccc
                for icst = 1:length(cst)
                    plot(log10(cst(icst)), pC(icst), 'o','Color', colors_allCCC(iccc, :),'MarkerSize',1+round(nData(icst)/5),'Linewidth',1);
                end
            end
            if (iccc==nccc) || (constant.expMode==1)% plot PMF
                %                     if ~isempty(yfit_all{iLoc_tgt,iNoise})
                plot(log10(fit.curveX), yfit_allC{iccc}{iLoc_tgt,iNoise},'-', 'color', colors_allCCC(iccc, :), 'Linewidth', 2); % SX
                %                     end
                % get and plot PSE
                text_thresh=[];
                for iperf = 1:nPerf
                    p.perfPSE = perfPSE_all(iperf)/100;
                    PSE = PSE_allC{iccc}(iLoc_tgt, iNoise, iperf);
                    plot(log10([PSE, PSE]), [0, p.perfPSE], '-', 'color', colors_allCCC(iccc, :), 'linewidth', 1);%SX
                    plot([log10(.001), log10(PSE)], [p.perfPSE, p.perfPSE], '-', 'color', colors_allCCC(iccc, :), 'linewidth', 1);
                    text_thresh=sprintf('%s//%.3f', text_thresh, PSE);
                end
            end
            
        end % iccc

        if iNoise==1, ylabel(namesLoc9{iLoc_tgt}), end
        
        xlim([-2, 0])
        xticks(-2:.2:0)
        xticklabels(round(10.^(-2:.2:0)*100, 1))
        ylim([.4, 1])
        yticks([.5, .6, .7, perfPSE_all/100, .9, 1])
        yline(.5, 'color', ones(1,3)*.5);
        grid on
        
        % title
        title(sprintf('Noise=%.0f%% slope=%.0f\nThresh=%s',...
            params.extNoiseLvl(iNoise)*100, slope_allC{iccc}(iLoc_tgt, iNoise), text_thresh))
        
    end % iNoise
end % iLoc
participant.initials = participant.subjName;
sgtitle(sprintf('%s (SF=%d)', participant.initials, constant.SF))
% saveas(gcf, sprintf('%s%s_PMF.jpg', nameFolder_fig, participant.initials))
saveas(gcf, sprintf('%sSF%d_PMF.jpg', nameFolder_fig, constant.SF))

%% Fig 2. PSE as a fxn of all loc
iccc = nccc; % 1=stair, 2=constim, 3=manul, 4=all trials
if constant.expMode==1, iccc = 1; end
% iLoc_Fovea_Peri_HM_VM_LVM_UVM = input(sprintf('Current locs are %s\nwhat is your indices of fovea, peri, HM, VM, LVM, UVM (put in a cell): ', num2str(constant.iLoc_tgt_all)));

iLoc_Fovea_Peri_HM_VM_LVM_UVM = {1, 3:5, 4, [3,5], 5, 3};

figure('Position', [0 0 nNoiseLvl*400 150])
for iNoise = 1:nNoiseLvl
    subplot(1,nNoiseLvl,iNoise), hold on
    text_HVA=[];
    text_VMA=[];
    for iperf=1:nPerf
        p.perfPSE = perfPSE_all(iperf)/100;
        
        CS_perLoc = 1./PSE_allC{iccc}(:, iNoise, iperf);
        %         Fovea = CS_perLoc(iLoc_Fovea_Peri_HM_VM_LVM_UVM{1});
        %         Peri = mean(CS_perLoc(iLoc_Fovea_Peri_HM_VM_LVM_UVM{2}));
        HM = mean(CS_perLoc(iLoc_Fovea_Peri_HM_VM_LVM_UVM{3}));
        VM = mean(CS_perLoc(iLoc_Fovea_Peri_HM_VM_LVM_UVM{4}));
        LVM = mean(CS_perLoc(iLoc_Fovea_Peri_HM_VM_LVM_UVM{5}));
        UVM = mean(CS_perLoc(iLoc_Fovea_Peri_HM_VM_LVM_UVM{6}));
        %     figure
        %         x = [3.5, 4.5, 6, 7];
        %         bar(x, [Fovea, Peri, HM, VM, LVM, UVM])
        x=iperf+nPerf+.5;
        buffer=.2;
        x=[iperf-buffer, iperf+buffer, x-buffer, x+buffer];
        
        bar(x, [HM, VM, LVM, UVM])
        xticks(x), xticklabels({'HM', 'VM', 'LVM', 'UVM'})
        
        HVA = (HM-VM)/(HM+VM);
        VMA = (LVM-UVM)/(LVM+UVM);
        text_HVA=sprintf('%s//%.2f', text_HVA, HVA);
        text_VMA=sprintf('%s//%.2f', text_VMA, VMA);
        text_legends{iperf}=num2str(perfPSE_all(iperf));
    end % iperf
    
    %         xticklabels({'Fov', 'Peri', 'HM', 'VM', 'LVM', 'UVM'})
    legend(text_legends, 'NumColumns', nPerf)
    ylabel('CS')
    set(findall(gcf, '-property', 'fontsize'), 'fontsize',15)
    ylim([0, 20])
    title(sprintf('[%s] Noise=%.0f%% SF=%d\nHVA=%s VMA=%s', participant.initials, 100*params.extNoiseLvl(iNoise), constant.SF, text_HVA, text_VMA))
    
    % saveas(gcf, sprintf('%s%s_CS_compLoc.jpg', nameFolder_fig, participant.initials))
    
end% iNoise
saveas(gcf, sprintf('%sSF%d_compLoc.jpg', nameFolder_fig, constant.SF))


%% Fig 3: cross locations, whether noise=0% is diff from noise=44%
if nNoiseLvl>1
    iccc=nccc; % all trials
    yticks_log = linspace(log10(.05), log10(1), 4);
    yticks_ln = 10.^yticks_log;
    x_log = [-2, log10(params.extNoiseLvl(2:end))]; % set log10(0)=-2 because log10(0) is Inf
    
    buffer = .1;
    
    for iperf = 1:nPerf % currently is 82%
        figure('Position', [0 0 500 300]), hold on
        for iLoc_tgt = constant.iLoc_tgt_all%1:nLoc
            thresh_log = log10(PSE_allC{iccc}(iLoc_tgt, :, iperf));
            plot(x_log, thresh_log, 'o-', 'Color', colors_comb(iLoc_tgt, :), 'MarkerSize', 10, 'MarkerFaceColor', 'w')
            
            xlim(x_log + [-buffer, buffer])
            xticks(x_log)
            xticklabels([params.extNoiseLvl])
        end
        
        ylim(yticks_log([1, end]))
        yticks(yticks_log)
        yticklabels(round(yticks_ln, 2))
        ylabel('Contrast threshold')
        xlabel('External noise')
        title(sprintf('%s [SF%d] %d%%', participant.subjName, constant.SF, perfPSE_all(iperf)))
        set(findall(gcf, '-property', 'fontsize'), 'fontsize',20)
        set(findall(gcf, '-property', 'LineWidth'), 'LineWidth',2)
        saveas(gcf, sprintf('%sSF%d_compNoise_%d.jpg', nameFolder_fig, constant.SF, perfPSE_all(iperf)))
    end
end
%% Fig 2b. polar plots for PSE (70%)
% nn = 'PMF70';
% y_all = log10(squeeze(PSE_allC{3}(:, :, 1)));
% plotThreshPolar
%
% nn = 'PMF79';
% y_all = log10(squeeze(PSE_allC{3}(:, :, 3)));
% plotThreshPolar
% close all
%
% %% Fig 2c. compare PMF-estimated threshold across locations
% nn = 'PMF70';
% y_all = log10(squeeze(PSE_allC{3}(:, :, 1)));
% plotThreshAcrossLoc
%
% nn = 'PMF79';
% y_all = log10(squeeze(PSE_allC{3}(:, :, 3)));
% plotThreshAcrossLoc
%
% %% Fig 3. get TvF & Fig 3b. compare IN&E across locations
% if nNoise>3
%     PSE_all = PSE_allC{3};
%     plotTvF
% end
%
% close all

%%
function y_allComb = getComb(y_allLoc)
if length(y_allLoc) == 5
    y_allComb = nan(8, 1); % 5 single loc, HM, VM, Peri
    y_allComb(1:5) = y_allLoc;
    y_allComb(6) = mean(y_allLoc([2,4]));
    y_allComb(7) = mean(y_allLoc([5,3]));
    y_allComb(8) = mean(y_allLoc(2:5));
end
end
