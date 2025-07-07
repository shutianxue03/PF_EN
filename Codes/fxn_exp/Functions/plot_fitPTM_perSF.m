function plot_fitPTM_perSF(whichSFcond,modelName,paramsfit1_all,paramsfit2_all,paramsfit3_all)
% close all;
figure('Name',modelName,'Color','white','units','normalized','outerposition',[0 0 1 1])% plots all three groups fit by PTM3.m

fontSize = 22;


% colorCond  = [0   .3  .6; .95 .6 .65; .9 0 0; .75 0 .1];
% colorPatch = [.7 .75 .9;  1 .75 .75; .9 .65 .65; .9 .5 .6];
% colorCond  = [0   0  .5;  .9 .6 .75; .8 .2 .6; .8  0 0];
% colorPatch = [.6 .7  1;  1 .7 .9; .9  .5 .8;  .9 .5 .5];
colorCond  = [0  .3 .6; .925  .6 .75; .8  0 .1];

if whichSFcond==1
    SFs            = {'05' '1' };
    figLabel = 'lowSF';
elseif whichSFcond==2
    SFs            = {'9' '16'};
    figLabel = 'highSF';
    % elseif whichSFcond==3
    %     SFs            = {'9'};
    % elseif whichSFcond==4
    %     SFs            = {'3'};
end

startwith      = 0.001;
startwith_axis = startwith - 0.0001;
startwith_axis = 0.0005;
X_interest     = [startwith    0.0210    0.0410    0.0830    0.1240    0.1650    0.2480    0.3300];
% X_plot         = exp(linspace(log(startwith),log(X_interest(end)),100));
X_plot         = exp(linspace(log(startwith),log(1),1e4));

d              = [1.089 1.634];
axismat        = [startwith_axis 0.4 1 100];

for whichSF = 1:length(SFs)
    
    load(['data_WB' (SFs{whichSF})]);
    
    paramsfit1 = paramsfit1_all(whichSF,:);
    paramsfit2 = paramsfit2_all(whichSF,:);
    paramsfit3 = paramsfit3_all(whichSF,:);
    
    [stats_TC70, errors_TC70] = get_plotstats(TC_70);
    [stats_TC79, errors_TC79] = get_plotstats(TC_79);
    
    [stats_KC70, errors_KC70] = get_plotstats([KC_sev_70; KC_mod_70]);
    [stats_KC79, errors_KC79] = get_plotstats([KC_sev_79; KC_mod_79]);
    
    [stats_KCsev70, errors_KCsev70] = get_plotstats(KC_sev_70);
    [stats_KCsev79, errors_KCsev79] = get_plotstats(KC_sev_79);
    
    [stats_KCmod70, errors_KCmod70] = get_plotstats(KC_mod_70);
    [stats_KCmod79, errors_KCmod79] = get_plotstats(KC_mod_79);
    
    
    nRow = 2;
    nCol = 6;
    
    subplot(nRow,nCol,whichSF);
    h1=ploterr_wp(X_interest,10.^(stats_KCmod70.avg),[],{10.^errors_KCmod70.low,10.^errors_KCmod70.up},'^','logxy'); hold on;
    set(h1,'MarkerSize',8,'MarkerEdgeColor',colorCond(2,:),'color',colorCond(2,:),'Linewidth',1.5)
    h1=loglog(X_plot,exp(predictedcontrast(paramsfit2,X_plot,d(1))).*100,'-');
    set(h1,'color',colorCond(2,:),'Linewidth',3)
    h1=ploterr_wp(X_interest,10.^(stats_KCsev70.avg),[],{10.^errors_KCsev70.low,10.^errors_KCsev70.up},'^','logxy');
    set(h1,'MarkerSize',8,'MarkerEdgeColor',colorCond(3,:),'color',colorCond(3,:),'Linewidth',1.5)
    h1=loglog(X_plot,exp(predictedcontrast(paramsfit3,X_plot,d(1))).*100,'-');
    set(h1,'color',colorCond(3,:),'Linewidth',3)
    h1=ploterr_wp(X_interest,10.^(stats_TC70.avg),[],{10.^errors_TC70.low,10.^errors_TC70.up},'o','logxy');
    set(h1,'MarkerSize',8,'MarkerEdgeColor',colorCond(1,:),'color',colorCond(1,:),'Linewidth',1.5)
    h1=loglog(X_plot,exp(predictedcontrast(paramsfit1,X_plot,d(1))).*100,'-');
    set(h1,'color',colorCond(1,:),'Linewidth',3)
    
    axis(axismat);
    set(gca,'Layer','top','Linewidth',3,'Box','off','PlotBoxAspectRatio',[.66,1,1],'TickDir','out','TickLength',[1,1]*0.02/max(1,1));
    set(gca,'FontName','Helvetica','FontSize',fontSize);
    %     set(gcf,'color','w','Position',[5 5 600 600])
    set(gca,'Ytick',([1 10 100]),'YtickLabel',{'1','10','100'})
    set(gca,'Xtick',([.001 .01 .1]),'XtickLabel',{'0','1','10'})
    
    
    subplot(nRow,nCol,whichSF+nCol);
    h1=ploterr_wp(X_interest,10.^(stats_KCmod79.avg),[],{10.^errors_KCmod79.low,10.^errors_KCmod79.up},'^','logxy'); hold on;
    set(h1,'MarkerSize',8,'MarkerEdgeColor',colorCond(2,:),'color',colorCond(2,:),'Linewidth',1.5)
    h1=loglog(X_plot,exp(predictedcontrast(paramsfit2,X_plot,d(2))).*100,'-');
    set(h1,'color',colorCond(2,:),'Linewidth',3)
    
    h1=ploterr_wp(X_interest,10.^(stats_KCsev79.avg),[],{10.^errors_KCsev79.low,10.^errors_KCsev79.up},'^','logxy'); hold on;
    set(h1,'MarkerSize',8,'MarkerEdgeColor',colorCond(3,:),'color',colorCond(3,:),'Linewidth',1.5)
    h1=loglog(X_plot,exp(predictedcontrast(paramsfit3,X_plot,d(2))).*100,'-');
    set(h1,'color',colorCond(3,:),'Linewidth',3)
    h1=ploterr_wp(X_interest,10.^(stats_TC79.avg),[],{10.^errors_TC79.low,10.^errors_TC79.up},'o','logxy'); hold on;
    set(h1,'MarkerSize',8,'MarkerEdgeColor',colorCond(1,:),'color',colorCond(1,:),'Linewidth',1.5)
    h1=loglog(X_plot,exp(predictedcontrast(paramsfit1,X_plot,d(2))).*100,'-');
    set(h1,'color',colorCond(1,:),'Linewidth',3)
    
    axis(axismat);
    set(gca,'Layer','top','Linewidth',3,'Box','off','PlotBoxAspectRatio',[.66,1,1],'TickDir','out','TickLength',[1,1]*0.02/max(1,1));
    set(gca,'FontName','Helvetica','FontSize',fontSize);
    %     set(gcf,'color','w','Position',[5 5 600 600])
    set(gca,'Ytick',([1 10 100]),'YtickLabel',{'1','10','100'})
    set(gca,'Xtick',([.001 .01 .1]),'XtickLabel',{'0','1','10'})
end
set(gcf, 'renderer', 'painters')
set(gcf,'PaperPositionMode','auto')
fig = gcf;
fig_pos = fig.PaperPosition;
set(gcf,'PaperSize',[fig_pos(3) fig_pos(4)]) 
saveas(gcf,[pwd '/FIGURES/PTM_' figLabel '_' modelName '.pdf']);

