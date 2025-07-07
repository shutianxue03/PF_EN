function design = initDesign_expMode3(design_old)

global scr visual participant params constant

% randomize random
rand('state',sum(100*clock));

%% get anchoring points (5)
% nameFile_PSE = sprintf('%s/%s_PSE_stair.mat', constant.nameFolder, participant.subjName);
nameFile_PSE = sprintf('%s/%s_PSE.mat', constant.nameFolder, participant.subjName);
load(nameFile_PSE) % nLoc x nNoise
fprintf('PSE (stair) loaded\n')
nAnchor = 5;
nNoise = length(params.extNoiseLvl);
nLoc = 3;%design_old.nLoc;
iccc=1;
iperf=1;
nLoc_tgt = constant.nLoc_tgt;

%%
happyWithAnchor = 0;
scaling=1;
while ~happyWithAnchor
    flag_quickPlotPMF = 1;
    cst_anchor = cell(nLoc, nNoise);
    close all
    if flag_quickPlotPMF
        figure('Position', [0 0 nNoise * 300 nLoc*300])
    end
    for iLoc_tgt = constant.iLoc_tgt_all
        iiLoc = find(iLoc_tgt == constant.iLoc_tgt_all);
        for iNoise = 1:nNoise
            anchor_center = log10(PSE_allC{iccc}(iLoc_tgt, iNoise, iperf)); % cst threshold measured by staircase, 70% acc, on log scale
            cst_std = std(log10(cst_allC{iccc}{iLoc_tgt, iNoise}))/scaling;% 1.5 is an arbtrary value set for each observer
            cst_anchor{iLoc_tgt, iNoise} = 10.^[anchor_center - cst_std, anchor_center - cst_std/2, anchor_center, anchor_center + cst_std/2, anchor_center + cst_std];
            
            fprintf('Loc#%d-NoiseLvl#%d: %d, %d, %d, %d, %d\n', iLoc_tgt, iNoise, round(cst_anchor{iLoc_tgt, iNoise}*100))
            %         anchor_sides = anchor_center + cst_std;
            %                 cst_anchor{iLoc, iNoise} = getAnchor(10^mean(thresh(iLoc, iNoise, :)), curveX, yfit{iLoc, iNoise}, nAnchor);
            %         cst_anchor{iLoc, iNoise} = 10.^quantile(log10(cst_all{iLoc, iNoise}), [.3, .4, .5, .75, .9]);
            
            if flag_quickPlotPMF
                cst = cst_allC{iccc}{iLoc_tgt, iNoise};
                nData = nData_allC{iccc}{iLoc_tgt, iNoise};
                pC = pC_allC{iccc}{iLoc_tgt, iNoise};
                
                subplot(nLoc_tgt, nNoise, iNoise + nNoise*(iiLoc-1)), hold on
                
                % draw pC and PMF
                for ii=1:length(cst)
                    plot(log10(cst(ii)), pC(ii),'ok','MarkerFaceColor','w','MarkerSize',1+round(nData(ii)/5),'Linewidth',1);
                end
                plot(log10(curveX), yfit_all{iLoc_tgt,iNoise}, '-k', 'linewidth', 2)
                
                % mark PSE
                xline(log10(PSE_allC{iccc}(iLoc_tgt, iNoise, iperf)), 'r-', 'linewidth', 2);
                
                % draw potential anchor points
                for ianchor = 1:nAnchor
                    xline(log10(cst_anchor{iLoc_tgt, iNoise}(ianchor)), 'm-');
                end
                
                xlim([-2, 0])
                xticks(-2:.5:0)
                xticklabels(round(10.^(-2:.5:0)*100))
                ylim([0, 1])
                yline(.5, 'color', ones(1,3)*.5);
                %             yline(.9, 'color', ones(1,3)*.5);
                %             yline(.6, 'color', ones(1,3)*.5);
                title(sprintf('Loc #%d, N_{ext}=%d%%', iLoc_tgt, round(params.extNoiseLvl(iNoise)*100)))
            end % if flag_quickPlotPMF
        end % iNoise
    end % iLoc
    
    
    happyWithAnchor = input(sprintf('Curent scaling factor is %.1f\nHappy with the anchor points? (1=YES, 0=NO): ', scaling));
    
    if ~happyWithAnchor
        scaling=input('Enter the new scaling value: ');
    end
end % while

%% number of trials
design.nAnchor = nAnchor;
design.ntrialsPerAnchor = constant.ntrialsPerAnchor;
design.nTrialsTotal = nAnchor * design.ntrialsPerAnchor * design_old.nLoc_tgt * design_old.nNoiseLvL; % SX

fprintf('\n================================================\n*%d trials*\n%d tested locations\n%d noise levels\n%d anchor points\n%d trials per anchor point\n\n', ...
    design.nTrialsTotal, design_old.nLoc_tgt, design_old.nNoiseLvL, design.nAnchor, design.ntrialsPerAnchor)

%% block & session design
design.nTrialsPerBlock = constant.nTrialsPerBlock; % [manual] number of trials per block, SX
design.nBlockTotal = round(design.nTrialsTotal/design.nTrialsPerBlock); % [manual] number of blocks to finish all trials per rep (<=100 trials per block), SX
design.nBlocksPerSession = design.nBlockTotal;

if design.nTrialsPerBlock>100, error('WARNING: number of trials per block is too high (=%d)!!', design.nTrialsPerBlock), end
design.nSess = design.nBlockTotal/design.nBlocksPerSession; if design.nSess ~= round(design.nSess), error('WARNING: nSess is NOT an integer!'), end% SX

fprintf('Number of total trials: %d = %d x %d blocks x %d sessions\n================================================\n\n',  ...)
    design.nTrialsTotal, design.nTrialsPerBlock, design.nBlocksPerSession, design.nSess)

%% create trial matrix
sequenceMatrix = [];
for iLoc_tgt = constant.iLoc_tgt_all
    for iNoise = 1:design_old.nNoiseLvL
        for iAnchor = 1:nAnchor
            sequenceMatrix = [sequenceMatrix; repmat([constant.CUE, iLoc_tgt, iNoise, cst_anchor{iLoc_tgt, iNoise}(iAnchor)], design.ntrialsPerAnchor, 1)];
            % specify the tilt in my experiment!!
        end
    end
end

% add iblock index
indBlock = repmat(1:design.nBlockTotal, 1, design.nTrialsPerBlock);
sequenceMatrix = [sequenceMatrix, indBlock'];

% randomize
sequenceMatrix = sequenceMatrix(randperm(size(sequenceMatrix, 1)),:);
design.sequenceMatrix = sequenceMatrix;

%% group trials based on iblock (the 5th col of sequenceMatrix)
design.allBlocks = [];
for iblock = 1:design.nBlockTotal
    itrial_currentBlk = sequenceMatrix(:,end)==iblock;
    sequenceBlock = sequenceMatrix(itrial_currentBlk,:);
    assert(design.nTrialsPerBlock == size(sequenceBlock, 1))
    for itrial = 1:design.nTrialsPerBlock
        fixX  = design_old.fixX;
        fixY  = design_old.fixY;
        trial(itrial).scue  = sequenceBlock(itrial,1);
        trial(itrial).targetLoc = sequenceBlock(itrial,2);
        trial(itrial).extNoiseLvl = sequenceBlock(itrial,3);
        if constant.expMode == 1, trial(itrial).stair = sequenceBlock(itrial,4);
        else, trial(itrial).stair = 99;
        end
        trial(itrial).fixLoc = visual.scrCenter+ (visual.ppd*[design_old.fixX, design_old.fixY, design_old.fixX, design_old.fixY]);
        trial(itrial).fixCol = visual.fixColor;
        trial(itrial).marCol = visual.black;
        trial(itrial).fixDur  = round(design_old.fixDur/scr.fd)*scr.fd;
        trial(itrial).fixNoise  = round(design_old.fixNoise/scr.fd)*scr.fd;
        trial(itrial).preCueDur1 = round(design_old.preCueDur1/scr.fd)*scr.fd;
        trial(itrial).preCueDur2 = round(design_old.preCueDur2/scr.fd)*scr.fd;
        trial(itrial).preISIDur = round(design_old.preISIDur/scr.fd)*scr.fd;
        trial(itrial).stimDur = round(design_old.stimDur/scr.fd)*scr.fd;
        trial(itrial).postISIDur  = round(design_old.postISIDur/scr.fd)*scr.fd;
        trial(itrial).ITIDur  = round((design_old.ITIDur.*rand)/scr.fd)*scr.fd;
        trial(itrial).afterKeyDur = design_old.afterKeyDur;
        trial(itrial).itrial = [];
        trial(itrial).iblock_local = [];
        trial(itrial).iblock = [];
        if constant.expMode == 1, trial(itrial).stimContrast = [];
        else, trial(itrial).stimContrast = sequenceBlock(itrial,4);
        end
        trial(itrial).stimOri = [];
        trial(itrial).fixBreak = [];
        trial(itrial).rt = [];
        %         trial(itrial).resp = [];
        trial(itrial).oriResp = [];
        trial(itrial).confidence = [];
        trial(itrial).cor = [];
        
        design.allBlocks(iblock).allTrials(itrial) = trial(itrial);
    end % for itrial
    
    design.nTrialsPB  = itrial; % number of trials per Block
end % for iblock

design.nAnchor = nAnchor;
design.nNoise = nNoise;
design.nLoc_tgt = nLoc_tgt;

%%
% function cst_anchor = getAnchor(PSE, cst_full, PMF_pred, nAnchor)
% % all cst are on linear scale
% cst_anchor = nan(1, nAnchor);
% nfull = length(PMF_pred); assert(nfull == length(cst_full));
%
% elbow_low_ln = cst_full(nfull - sum(PMF_pred>.6));
% elbow_high_ln = cst_full(sum(PMF_pred<=.85));
%
% if PSE <=elbow_low_ln, cst_anchor(1) = 10^(log10(elbow_low_ln)*2);
% else, cst_anchor(1) = elbow_low_ln;
% end
%
% if PSE >= elbow_high_ln, cst_anchor(nAnchor) = 10^(log10(elbow_high_ln)*2);
% else, cst_anchor(nAnchor) = elbow_high_ln;
% end
%
% cst_anchor(2) = 10^mean([log10(elbow_low_ln), log10(PSE)]);
% cst_anchor(3) = PSE;
% cst_anchor(4) = 10^mean([log10(elbow_high_ln), log10(PSE)]);
% % cst_anchor(1) = .01;
% % cst_anchor(5) = .5;
% end

end