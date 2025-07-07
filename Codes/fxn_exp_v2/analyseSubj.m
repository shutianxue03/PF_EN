% function analyseSubj(cond, subj, bootStrapOn, fit, B, colList)


% for isub = 1:length(subjList)
tic
yfit=[];
pse_thres75=[];pse_thres70=[];pse_thres79=[];
pse_thres75_B=[];pse_thres70_B=[];pse_thres79_B=[];
pse_thres75_B2=[];pse_thres70_B2=[];pse_thres79_B2=[];

%     subj=subjList{isub};
if ~bootStrapOn
    filename = sprintf('%s_%s_LAM.mat',subj,cond);
elseif bootStrapOn
    filename = sprintf('%s_%s_LAM_bstrp.mat',subj,cond);
end

indPos = [13  12 8 14 18  11 3 15 23];

ccc = [];
figure('Color','white','units','normalized','Position',[0 0 .5 1]);
df=(dir((['Data/' cond '/' subj '/PF_LAM_' cond '_' subj '_b*.mat'])));
nFile = length(df);

for ifile = 1:nFile
    df =     dir((['Data/' cond '/' subj '/PF_LAM_' cond '_' subj '_b' num2str(ifile) '__*.mat']));
    
    load(['Data/' cond '/' subj '/' df.name])
    for bb=((ifile-1).*6+[1:6])
        
        ccc = [ccc;...
            real_sequence(bb).targetLoc(real_sequence(bb).trialDone==1)'...
            real_sequence(bb).extNoiseLvl(real_sequence(bb).trialDone==1)'...
            real_sequence(bb).scontrast(real_sequence(bb).trialDone==1)'...
            real_sequence(bb).iscor(real_sequence(bb).trialDone==1)'];
    end
end
save('ccc_%s', participant.identifier, 'ccc')

posInd = [1 1;2 4; 3 3; 4 2; 5 5; 6 8; 7 7; 8 6; 9 9];

for pos = 1:9
    subplot(5,5,indPos(pos))
    for exn=1:7
        ccc(ccc(:,1)==pos & ccc(:,2)==exn,3) = round(ccc(ccc(:,1)==pos & ccc(:,2)==exn,3).*100)./100;
        
        cVal2 = unique(ccc(ccc(:,1)==pos & ccc(:,2)==exn,3));
        
        pM=[];cM=[];yM=[];
        sum(ccc(:,1)==pos & ccc(:,2)==exn)
        
        for ict = 1:length(cVal2)
            indTrial = (ccc(:,1)==posInd(pos,1) | ccc(:,1)==posInd(pos,2)) & ccc(:,2)==exn & (ccc(:,3)>cVal2(ict)-0.001 & ccc(:,3)<=cVal2(ict)+0.001);
            pM(ict)  = nansum(ccc(indTrial,4));
            cM(ict)  = nansum(indTrial==1);
            yM(ict)  = pM(ict)./cM(ict);
        end
        
        
        %%% PF
        %             [paramVals, LL, exitflag] = PAL_PFML_Fit(log10(cVal2'.*100),...
        [paramVals, LL, exitflag] = PAL_PFML_Fit((cVal2'),...
            pM,...
            cM,...
            fit.searchGrid, fit.paramsFree, fit.PF,'SearchOptions',fit.options,'lapseLimits',fit.lapseLimits,'lapseLimits',fit.guessLimits);
        
        yfit{pos,exn}         = fit.PF(paramVals,fit.curveX);
        pse_thres75(pos,exn)  = fit.PF(paramVals, .75, 'Inverse')
        pse_thres70(pos,exn)  = fit.PF(paramVals, .7, 'Inverse');
        pse_thres79(pos,exn)  = fit.PF(paramVals, .79, 'Inverse');
        
        
        
        if bootStrapOn
            %                 [SD paramsSim LLSim converged] = PAL_PFML_BootstrapParametric(log10(cVal2'.*100),...
            %                     cM,paramVals,fit.paramsFreeB,B,fit.PF);
            [SD paramsSim LLSim converged] = PAL_PFML_BootstrapParametric((cVal2'),...
                cM,paramVals,fit.paramsFreeB,B,fit.PF);
            for bb=1:B
                pse_thres75_B(pos,exn,bb)  = fit.PF(paramsSim(bb,:), .75, 'Inverse');
                pse_thres70_B(pos,exn,bb)  = fit.PF(paramsSim(bb,:), .7, 'Inverse');
                pse_thres79_B(pos,exn,bb)  = fit.PF(paramsSim(bb,:), .79, 'Inverse');
                
                % limit thresholds between 0.005 and 1
                if pse_thres75_B(pos,exn,bb)>1
                    pse_thres75_B2(pos,exn,bb)=1;
                elseif pse_thres75_B(pos,exn,bb)<0.005
                    pse_thres75_B2(pos,exn,bb)=0.005;
                else
                    pse_thres75_B2(pos,exn,bb)=pse_thres75_B(pos,exn,bb);
                end
                
                if pse_thres70_B(pos,exn,bb)>1
                    pse_thres70_B2(pos,exn,bb)=1;
                elseif pse_thres70_B(pos,exn,bb)<0.005
                    pse_thres70_B2(pos,exn,bb)=0.005;
                else
                    pse_thres70_B2(pos,exn,bb)=pse_thres70_B(pos,exn,bb);
                end
                
                if pse_thres79_B(pos,exn,bb)>1
                    pse_thres79_B2(pos,exn,bb)=1;
                elseif pse_thres79_B(pos,exn,bb)<0.005
                    pse_thres79_B2(pos,exn,bb)=0.005;
                else
                    pse_thres79_B2(pos,exn,bb)=pse_thres79_B(pos,exn,bb);
                end
            end
        end
        
        hold on
        %         plot(cVal,pM./cM,'o','MarkerEdgeColor','w','MarkerFaceColor',colList{exn},'MarkerSize',12,'Linewidth',1); axis square
        for ii=1:length(cVal2)
            plot(cVal2(ii),pM(ii)./cM(ii),'o','MarkerEdgeColor',colList{exn},'MarkerFaceColor','w','MarkerSize',1+round(cM(ii)/5),'Linewidth',1); axis square
        end
        plot(fit.curveX,yfit{pos,exn},'-','color',colList{exn},'Linewidth',3);
        plot([pse_thres75(pos,exn) pse_thres75(pos,exn)], [0 .75],'--','color',colList{exn},'Linewidth',2);
        ylim([0.4 1]);xlim([0.01 1])
        set(gca,'XScale','log','Layer','top','Linewidth',3,'Box','off','PlotBoxAspectRatio',[1,1,1],'TickDir','out','TickLength',[1,1]*0.02/max(1,1));
        set(gca,'FontName','Helvetica','FontSize',18);
    end
    
end

cd(['Results/'])
if ~bootStrapOn
    save(filename,'pse_thres75','pse_thres70','pse_thres79','yfit')
elseif bootStrapOn
    save(filename,'pse_thres75','pse_thres70','pse_thres79','yfit',...
        'pse_thres75_B','pse_thres70_B','pse_thres79_B','pse_thres75_B2','pse_thres70_B2','pse_thres79_B2')
end
cd ..
% toc
% end


