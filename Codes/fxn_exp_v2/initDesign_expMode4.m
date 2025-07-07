function design = initDesign_expMode4(design_old, scaling)

% scaling is NOT in use right now
global scr visual participant params constant

% rand('state',sum(100*clock)); % randomize the seed generator

params.extNoiseLvl = [0, .055, .11, .165, .22, .33, .44, .66, .88];

%% load and setting
cst_ln_manual = input('\n\n       >>> Manually add constim stim (linear): ');
nLoc_tgt = constant.nLoc_tgt;
nNoiseLvL = constant.nNoiseSD;
nConstim = 0; for iLoc=1:nLoc_tgt, for iN=1:nNoiseLvL; if ~isnan(cst_ln_manual{iLoc, iN}), nConstim=nConstim+length(cst_ln_manual{iLoc, iN}); cst_ln_manual{iLoc, iN} = cst_ln_manual{iLoc, iN}/100; end, end, end
SX_analysis_setting
curveX_log = log10(fit.curveX);

%% number of trials
design = design_old;
design_old.nNoiseLvL = constant.nNoiseSD;
design.ntrialsPerConstim = constant.ntrialsPerConstim4; fprintf('\nNumber of trials per point is %d!!\n', design.ntrialsPerConstim)% increase from 20 to 30
design.nConstim = nConstim;

design.nTrialsTotal = nConstim * design.ntrialsPerConstim;

fprintf('\n================================================\n*%d trials*\n%d tested locations\n%d noise levels\n%d anchor points\n%d trials per anchor point\n\n', ...
    design.nTrialsTotal, design_old.nLoc_tgt, design_old.nNoiseLvL, design.nConstim, design.ntrialsPerConstim)

%% block & session design
constant.expMode = 4;
constant.nTrialsPerBlock_exp4 = input('         >>> Specify no. of trials/block: ');
design.nTrialsPerBlock = constant.nTrialsPerBlock_exp4; % [manual] number of trials per block, SX
design.nBlockTotal = round(design.nTrialsTotal/design.nTrialsPerBlock); % [manual] number of blocks to finish all trials per rep (<=100 trials per block), SX
design.nBlocksPerSession = design.nBlockTotal;

% if design.nTrialsPerBlock>150, error('WARNING: number of trials per block is too high (=%d)!!', design.nTrialsPerBlock), end
design.nSess = design.nBlockTotal/design.nBlocksPerSession; if design.nSess ~= round(design.nSess), error('WARNING: nSess is NOT an integer!'), end% SX

fprintf('Number of total trials: %d = %d x %d blocks x %d sessions\n================================================\n\n',  ...)
    design.nTrialsTotal, design.nTrialsPerBlock, design.nBlocksPerSession, design.nSess)

%% create trial matrix
design_old.nNoiseLvL = 9;
sequenceMatrix = [];
for iLoc_tgt = constant.iLoc_tgt_all
    iiLoc = find(iLoc_tgt == constant.iLoc_tgt_all);
    for iNoise = 1:design_old.nNoiseLvL
        if ~isnan(cst_ln_manual{iiLoc, iNoise})
            for iConstim = 1:length(cst_ln_manual{iiLoc, iNoise})
                sequenceMatrix = [sequenceMatrix; repmat([constant.CUE, iLoc_tgt, params.extNoiseLvl(iNoise), cst_ln_manual{iiLoc, iNoise}(iConstim)], ...
                    design.ntrialsPerConstim, 1)];
            end
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
        trial(itrial).iNoise=nan;
        trial(itrial).scue  = sequenceBlock(itrial,1);
        trial(itrial).targetLoc = sequenceBlock(itrial,2);
        trial(itrial).extNoiseLvl = sequenceBlock(itrial,3);
        trial(itrial).stair = 99;
        trial(itrial).dataMode = 99;
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

design.nConstim = nConstim;
design.nNoiseLvL = nNoiseLvL;
design.nLoc_tgt = nLoc_tgt;

end