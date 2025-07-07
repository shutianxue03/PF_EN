function varargout = StaircaseGUI(varargin)

hgui = figure;
set(hgui,'Visible','off', ...
    'MenuBar','none','Name','Contrast selection','NumberTitle','off', ...
    'Position',[0 0 600 400],'Units','pixels','Resize','off','Toolbar','none');

movegui(hgui,'center');

htextthr = uicontrol(hgui,'Style','text', ...
    'String','Threshold estimation','Position',[60 360 140 20],'FontSize',9);
hmenuthr = uicontrol(hgui,'Style','popupmenu', ...
    'String',{'Mean (overall)','Mean (reversals)'},'Value',1,'Position',[60 340 140 20]);

htextfst = uicontrol(hgui,'Style','text', ...
    'String','First','Position',[230 360 40 20],'FontSize',9);
heditfst = uicontrol(hgui,'Style','edit', ...
    'String','13','Position',[230 340 40 20]);

hbuttupd = uicontrol(hgui,'Style','pushbutton','Callback',@UpdateButtonCallback, ...
    'String','Update','Position',[300 340 80 40],'FontSize',9);

hbuttupd = uicontrol(hgui,'Style','pushbutton','Callback',@ApplyButtonCallback, ...
    'String','Apply','Position',[460 340 80 40],'FontSize',9);

haxes = axes('Parent',hgui, ...
    'Position',[.100 .130 .792 .600]);

s = varargin{1};
r = [];

UpdateEstimation;
set(hgui,'Visible','on');
uiwait(hgui);

varargout{1} = r;

    function UpdateButtonCallback(h,eventdata)
    UpdateEstimation;
    end

    function ApplyButtonCallback(h,eventdata)
    delete(hgui);
    end

    function UpdateEstimation
    estimations = {'overall','reversals'};
    iestimation = get(hmenuthr,'Value');
    ifirst = str2num(get(heditfst,'String'));
    r = GetStaircaseResults(s,estimations{iestimation},ifirst);
    cla(haxes);
    hold(haxes,'on');
    xlim(haxes,[0,r.nstp]+0.5);
    ylim(haxes,[0,50]);
    if ~isnan(r.ithr)
        [b,i] = ismember(r.ithr,r.istp);
        patch([min(xlim),i(1)-0.5,i(1)-0.5,min(xlim)],[min(ylim),min(ylim),max(ylim),max(ylim)],[0.8,0.8,0.8],'EdgeColor','none');
    end
    plot(haxes,100*r.x(r.istp),'b.-');
    [b,i] = ismember(r.irev,r.istp);
    plot(haxes,i,100*r.x(r.irev),'bo');
    for i = (0:3:40)+0.5
        plot(i*[1,1],ylim,'k:');
    end
    if ~isnan(r.ithr)
        [b,i] = ismember(r.ithr,r.istp);
        plot(haxes,i,100*r.x(r.ithr),'r.');
        switch estimations{iestimation}
            case 'reversals'
                plot(haxes,i,100*r.x(r.ithr),'ro');
        end
        plot(haxes,[i(1)-0.5,max(xlim)],100*r.xthr*[1,1],'r-');
        plot(haxes,(i(1)-0.5)*[1,1],ylim,'k-');
        text(0.95,0.92,sprintf('Contrast: %04.1f %%\nAccuracy: %04.1f %%',100*r.xthr,100*r.pthr), ...
            'HorizontalAlignment','right','VerticalAlignment','top','Units','normalized','BackgroundColor',[1,1,1]);
    end
    hold(haxes,'off');
    set(haxes,'FontSize',8,'Layer','top','Box','on','PlotBoxAspectRatio',[2,1,1],'TickDir','out','TickLength',[0.01,0.01]);
    set(haxes,'XTick',(0:3:40)+0.5,'YTick',0:10:100,'XTickLabel',{});
    ylabel(haxes,'Contrast (%)');
    
    end

end