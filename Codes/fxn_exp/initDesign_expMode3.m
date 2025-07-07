function design = initDesign_expMode3(design_old, scaling)

global scr visual participant params constant

% randomize random
rand('state',sum(100*clock));
SX_analysis_setting

cst_log_lowest = log10(.03);
cst_log_highest = log10(.9);

%% estimate and plot anchoring points
% nameFile_PSE = sprintf('%s/%s_PSE_stair.mat', constant.nameFolder, participant.subjName);
nameFile_PSE = sprintf('%s/%s_PSE.mat', constant.nameFolder, participant.subjName);
load(nameFile_PSE) % nLoc x nNoiseLvL
fprintf('PSE loaded\n')
nCSTLvl = 5;
nNoiseLvL = length(params.extNoiseLvl);
nLoc = constant.nLoc_tgt;
if length(PSE_allC)==1, iccc=1;else, iccc = 4;end % make decisions based on all previous trials (1=stair, 2=constim)

nLoc_tgt = constant.nLoc_tgt;

happyWithAnchor = 1;
flag_quickPlotPMF = 1;
PSE_log_allC = PSE_allC; % clarify the name
cst_log_allC = cst_allC; % clarify the name
curveX_log = curveX;
cstLvl_all = cell(nLoc, nNoiseLvL);

%% plot raw data
if flag_quickPlotPMF, figure('Position', [0 0 nNoiseLvL * 300 nLoc*300]), end

for iLoc_tgt = constant.iLoc_tgt_all
    iiLoc = find(iLoc_tgt == constant.iLoc_tgt_all);
    for iNoise = 1:nNoiseLvL
        
        cst_log = cst_log_allC{iccc}{iLoc_tgt, iNoise};
        nData = nData_allC{iccc}{iLoc_tgt, iNoise};
        pC = pC_allC{iccc}{iLoc_tgt, iNoise};
        
        subplot(nLoc_tgt, nNoiseLvL, iNoise + nNoiseLvL*(iiLoc-1)), hold on
        
        % draw pC and PMF
        for ii=1:length(cst_log)
            plot(cst_log(ii), pC(ii),'ok','MarkerFaceColor','w','MarkerSize',1+round(nData(ii)/5),'Linewidth',1);
        end
        plot(curveX_log, yfit_all{iLoc_tgt,iNoise}, '-k', 'linewidth', 2)
        
        xlim([-2, 0.01])
        xticks(-2:.2:0)
        xticklabels(round(10.^(-2:.2:0)*100,1)), xtickangle(45)
        ylim([.4, 1])
        yticks([.5, .6, .7, perfPSE_all/100, .9, 1])
        yline(.5, 'color', ones(1,3)*.5);
        grid on
        
        title(sprintf('Loc #%d, N_{ext}=%.0f%%', ...
            iLoc_tgt, round(params.extNoiseLvl(iNoise)*100)))
    end % iNoise
end % iLoc

flag_manualEnter = input('Manually enter center and SD? (1=YES, 0=NO) ');

%% add constim
close all
if flag_quickPlotPMF, figure('Position', [0 0 nNoiseLvL * 300 nLoc*300]), end

for iLoc_tgt = constant.iLoc_tgt_all
    iiLoc = find(iLoc_tgt == constant.iLoc_tgt_all);
    for iNoise = 1:nNoiseLvL
        
        cst_log = cst_log_allC{iccc}{iLoc_tgt, iNoise};
        nData = nData_allC{iccc}{iLoc_tgt, iNoise};
        pC = pC_allC{iccc}{iLoc_tgt, iNoise};
        
        subplot(nLoc_tgt, nNoiseLvL, iNoise + nNoiseLvL*(iiLoc-1)), hold on
        
        % draw pC and PMF
        for ii=1:length(cst_log)
            plot(cst_log(ii), pC(ii),'ok','MarkerFaceColor','w','MarkerSize',1+round(nData(ii)/5),'Linewidth',1);
        end
        plot(curveX_log, yfit_all{iLoc_tgt,iNoise}, '-k', 'linewidth', 2)
        
        xlim([-2, 0.01])
        xticks(-2:.2:0)
        xticklabels(round(10.^(-2:.2:0)*100,1)), xtickangle(45)
        ylim([.4, 1])
        yticks([.5, .6, .7, perfPSE_all/100, .9, 1])
        yline(.5, 'color', ones(1,3)*.5);
        grid on
        
        % mark estimated PSE and print in the title
        assert(nPerf==size(PSE_log_allC{iccc}, 3));
        for iperf=1:nPerf
            perfPSE = perfPSE_all(iperf)/100;
            PSE_log=PSE_log_allC{iccc}(iLoc_tgt, iNoise, iperf);
            plot([PSE_log, PSE_log], [0, perfPSE], 'k-' , 'linewidth', 1);%SX
            plot([log10(.001), PSE_log], [perfPSE, perfPSE], 'k-', 'linewidth', 1);
        end
        
        title(sprintf('Loc #%d, N_{ext}=%.0f%%\nthresh=%.0f%%', ...
            iLoc_tgt, round(params.extNoiseLvl(iNoise)*100), 10.^PSE_log*100))
        
        %% map constim
        flag_shiftCenter=1; count=1;
        while flag_shiftCenter
            cst_log_center = PSE_log_allC{iccc}(iLoc_tgt, iNoise, nPerf)-.01*count; % cst threshold measured by staircase, 70% acc, on log scale
            cst_log_std = std(cst_log_allC{iccc}{iLoc_tgt, iNoise})/scaling;% 1.5 is an arbtrary value set for each observer
            
            %             if sum(flag_manualEnter(:, 1) == iLoc_tgt) && sum(flag_manualEnter(:, 2) == iNoise)
            if flag_manualEnter
                %----------------------------------------------------------------------%
                cst_log_center = log10(input(sprintf('L%dN%d, enter the center (est: %.1f; %%): ', ...
                    iLoc_tgt, iNoise, 10^cst_log_center*100))/100);
                cst_log_std = input(sprintf('L%dN%d, enter the SD (est: %.2f; 0.4 is good): ', iLoc_tgt, iNoise, cst_log_std));
                %----------------------------------------------------------------------%                
            end
            
            cstLvl_all{iLoc_tgt, iNoise} = 10.^[cst_log_lowest, cst_log_center - cst_log_std/2, cst_log_center, cst_log_center + cst_log_std/2, cst_log_highest];
            if log10(cstLvl_all{iLoc_tgt, iNoise}(end-1))>= cst_log_highest-cst_log_std/3
                count = count+1;
            else, flag_shiftCenter = 0;
            end
        end
        assert(length(cstLvl_all{iLoc_tgt, iNoise})==nCSTLvl)
        text=[];
        for icst=1:nCSTLvl, text=sprintf('%s %.0f', text, cstLvl_all{iLoc_tgt, iNoise}(icst)*100); end
        fprintf('Loc#%d & NoiseLvl#%.0f: %s; count=%d\n', iLoc_tgt, iNoise,text, count)
        % draw potential anchor points
        for icst = 1:nCSTLvl, xline(log10(cstLvl_all{iLoc_tgt, iNoise}(icst)), 'm-', 'linewidth', 1); end
        xline(log10(cstLvl_all{iLoc_tgt, iNoise}(1)), 'm-', 'linewidth', 2);
        xline(log10(cstLvl_all{iLoc_tgt, iNoise}(end)), 'm-', 'linewidth', 2);
        
        
    end % iNoise
end % iLoc

if ~happyWithAnchor
    scaling=input(sprintf('     Curent scaling factor is %.1f. Enter the new scaling value (higher=finer sampling): ', scaling));
end

%% number of trials
design = design_old;
design.nAnchor = nCSTLvl;
design.ntrialsPerAnchor = constant.ntrialsPerAnchor;
design.nTrialsTotal = nCSTLvl * design.ntrialsPerAnchor * design_old.nLoc_tgt * design_old.nNoiseLvL; % SX

fprintf('\n================================================\n*%d trials*\n%d tested locations\n%d noise levels\n%d anchor points\n%d trials per anchor point\n\n', ...
    design.nTrialsTotal, design_old.nLoc_tgt, design_old.nNoiseLvL, design.nAnchor, design.ntrialsPerAnchor)

%% block & session design
design.nTrialsPerBlock = constant.nTrialsPerBlock_exp3; % [manual] number of trials per block, SX
design.nBlockTotal = round(design.nTrialsTotal/design.nTrialsPerBlock); % [manual] number of blocks to finish all trials per rep (<=100 trials per block), SX
design.nBlocksPerSession = design.nBlockTotal;

if design.nTrialsPerBlock>150, error('WARNING: number of trials per block is too high (=%d)!!', design.nTrialsPerBlock), end
design.nSess = design.nBlockTotal/design.nBlocksPerSession; if design.nSess ~= round(design.nSess), error('WARNING: nSess is NOT an integer!'), end% SX

fprintf('Number of total trials: %d = %d x %d blocks x %d sessions\n================================================\n\n',  ...)
    design.nTrialsTotal, design.nTrialsPerBlock, design.nBlocksPerSession, design.nSess)

%% create trial matrix
sequenceMatrix = [];
for iLoc_tgt = constant.iLoc_tgt_all
    for iNoise = 1:design_old.nNoiseLvL
        for iAnchor = 1:nCSTLvl
            sequenceMatrix = [sequenceMatrix; repmat([constant.CUE, iLoc_tgt, iNoise, cstLvl_all{iLoc_tgt, iNoise}(iAnchor)], design.ntrialsPerAnchor, 1)];
        end
    end
end

% add iblock index

indBlock = repmat(1:design.nBlockTotal, 1, design.nTrialsPerBlock);
indOri = repmat([1,2], 1, size(sequenceMatrix, 1)/2); indOri = indOri(randperm(length(indOri)));
sequenceMatrix = [sequenceMatrix, indOri', indBlock'];

% randomize
sequenceMatrix = sequenceMatrix(randperm(size(sequenceMatrix, 1)),:);
sequenceMatrix = sequenceMatrix(randperm(size(sequenceMatrix, 1)),:);
design.sequenceMatrix = sequenceMatrix;

%% group trials based on iblock (the 5th col of sequenceMatrix)
design.allBlocks = [];
for iblock = 1:design.nBlockTotal
    itrial_currentBlk = sequenceMatrix(:,end)==iblock;
    sequenceBlock = sequenceMatrix(itrial_currentBlk,:);
    assert(design.nTrialsPerBlock == size(sequenceBlock, 1))
    
    for itrial = 1:design.nTrialsPerBlock
        % design
        trial(itrial).scue  = sequenceBlock(itrial,1);
        trial(itrial).targetLoc = sequenceBlock(itrial,2);
        trial(itrial).extNoiseLvl = sequenceBlock(itrial,3);
        trial(itrial).stair = 99;
        trial(itrial).stimContrast = sequenceBlock(itrial,4);
        trial(itrial).stimOri = sequenceBlock(itrial,5);
        
        % params
        fixX  = design_old.fixX;
        fixY  = design_old.fixY;
        trial(itrial).fixLoc = visual.scrCenter+ (visual.ppd*[design_old.fixX, design_old.fixY, design_old.fixX, design_old.fixY]);
        trial(itrial).fixCol = visual.fixColor;
        trial(itrial).marCol = visual.black;
        trial(itrial).fixDur  = round(design_old.fixDur/scr.fd)*scr.fd;
        trial(itrial).fixNoise  = round(design_old.fixNoise/scr.fd)*scr.fd;
        trial(itrial).preCueDur1 = round(design_old.preCueDur1/scr.fd)*scr.fd;
        trial(itrial).preCueDur2 = round(design_old.preCueDur2/scr.fd)*scr.fd;
        trial(itrial).preISIDur = round(design_old.preISIDur/scr.fd)*scr.fd;
        trial(itrial).stimDur = round(design_old.stimDur/scr.fd)*scr.fd;
        trial(itrial).bufferDur = round(design.bufferDur/scr.fd)*scr.fd;
        trial(itrial).postISIDur  = round(design_old.postISIDur/scr.fd)*scr.fd;
        trial(itrial).ITIDur  = round((design_old.ITIDur.*rand)/scr.fd)*scr.fd;
        trial(itrial).afterKeyDur = design_old.afterKeyDur;
        
        % empty containers for recording response
        trial(itrial).itrial = [];
        trial(itrial).iblock_local = [];
        trial(itrial).iblock = [];
        trial(itrial).fixBreak = [];
        trial(itrial).rt = [];
        trial(itrial).oriResp = [];
        trial(itrial).confidence = [];
        trial(itrial).cor = [];
        
        design.allBlocks(iblock).allTrials(itrial) = trial(itrial);
        
    end % for itrial
    
    design.nTrialsPB  = itrial; % number of trials per Block
end % for iblock

design.nAnchor = nCSTLvl;
design.nNoiseLvL = nNoiseLvL;
design.nLoc_tgt = nLoc_tgt;


end