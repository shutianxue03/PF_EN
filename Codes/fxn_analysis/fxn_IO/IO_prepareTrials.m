

function [sequenceMatrix, UD] = IO_prepareTrials(nRepet, nLoc, nNoise, nStairs, nTrialsPerStair, nTrialsCatch, params)

sequenceMatrixALL = [];
for iRepet = 1:nRepet
    % stair
    sequenceMatrix = [];
    for iLoc = 1:nLoc
        for iNoise = 1:nNoise
            for iStair = 1:nStairs
                if iStair<=nStairs/2, ORI=1; else, ORI=2; end
                for nTrials = 1:nTrialsPerStair
                    sequenceMatrix = [sequenceMatrix; iLoc, iNoise, iStair, ORI];
                end
            end
        end
    end
    
    % catch trials
    for iLoc = 1:nLoc
        for iNoise = 1:nNoise
            for iStair = nStairs + (1:2)
                for i_nTrials = 1:nTrialsCatch(iStair-nStairs)
                    if i_nTrials<=nTrialsCatch(iStair-nStairs)/2, ORI=1; else, ORI=2; end
                    sequenceMatrix = [sequenceMatrix; iLoc, iNoise, iStair, ORI];
                end
            end
        end
    end
    
    % randomize twice
    sequenceMatrix = sequenceMatrix(randperm(length(sequenceMatrix)),:);
    sequenceMatrix = sequenceMatrix(randperm(length(sequenceMatrix)),:);
    sequenceMatrixALL = [sequenceMatrixALL; sequenceMatrix];
end % iRep

sequenceMatrix = sequenceMatrixALL; % [iLoc, iNoise, iStair, ORI]

%% setting up staircases
UD = cell(nLoc, nNoise, nStairs+2);

for iLoc = 1:nLoc
    for iNoise = 1:nNoise
        for iStair = 1:nStairs
            UD{iLoc,iNoise,iStair} = PAL_AMUD_setupUD('up',1,'down',params.stairRule(iStair),...
                'stepSizeUp',params.stairStep(1),'stepSizeDown',params.stairStep(1),...
                'stopCriterion','trials','stopRule',params.stairStopRule,'startValue',params.startLvl(iStair),...
                'xMax',params.maxVal,'xMin',params.minVal,'truncate','yes');
        end
    end
end

% catch trials
for iLoc = 1:nLoc
    for iNoise = 1:nNoise
        for iStair = nStairs + (1:2)
            UD{iLoc,iNoise,iStair} = PAL_AMUD_setupUD('up',100,'down',100,...
                'stepSizeUp',0,'stepSizeDown',0,...
                'stopCriterion','trials','stopRule',params.stairStopRule,'startValue',params.catchLvl(iStair-nStairs),...
                'xMax',params.maxVal,'xMin',params.minVal,'truncate','yes');
        end
    end
end
