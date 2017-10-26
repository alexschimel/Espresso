function update_map_tab(main_figure,new_res)

map_tab_comp=getappdata(main_figure,'Map_tab');
fData_tot=getappdata(main_figure,'fData');
if isempty(fData_tot)
    return;
end
fdata_tab_comp=getappdata(main_figure,'fdata_tab');

idx_zoom=(cell2mat(fdata_tab_comp.table.Data(:,end-1)));

ax=map_tab_comp.map_axes;


df = 100;
xlim=[nan nan];
ylim=[nan nan];

for i=1:length(fData_tot)
    if idx_zoom(i)
        vis='on';
    else
        vis='off';
    end
    fData=fData_tot{i};
    times1 = datestr(fData.X_1P_pingSDN,'dd-mmm-yyyy HH:MM:SS.FFF');
    times2 = datestr(fData.X_1P_pingSDN,'HH:MM:SS.FFF');
    tag_id=num2str(fData.ID,'%.0f');
    tag_id_wc=num2str(fData.ID,'wc%.0f');
    
    obj=findobj(ax,'Tag',tag_id);
    
    if isempty(obj)   

        plot(ax,fData.X_1P_pingE(1),fData.X_1P_pingN(1),'go','Tag',tag_id,'Visible',vis);
        plot(ax,[fData.X_1P_pingE(1:df:end),fData.X_1P_pingE(end)],[fData.X_1P_pingN(1:df:end),fData.X_1P_pingN(end)],'k.-','Tag',tag_id,'Visible',vis);
        plot(ax,fData.X_1P_pingE(end),fData.X_1P_pingN(end),'rs','Tag',tag_id,'Visible',vis);
        text(ax,fData.X_1P_pingE(1),fData.X_1P_pingN(1),sprintf(' \\leftarrow %s (start)',times1(1,:)),'Tag',tag_id,'Visible',vis)
        text(ax,fData.X_1P_pingE(end),fData.X_1P_pingN(end),sprintf(' \\leftarrow %s (end)',times1(end,:)),'Tag',tag_id,'Visible',vis)
        for ii = (df+1):df:length(fData.X_1P_pingN)-1
            text(ax,fData.X_1P_pingE(ii),fData.X_1P_pingN(ii),sprintf(' \\leftarrow %s',times2(ii,:)),'Tag',tag_id,'Visible',vis)
        end
    else
        set(obj,'Visible',vis);
    end
     if idx_zoom(i)
        xlim(1)=nanmin(xlim(1),nanmin(fData.X_1P_pingE));
        xlim(2)=nanmax(xlim(2),nanmax(fData.X_1P_pingE));
        
        ylim(1)=nanmin(ylim(1),nanmin(fData.X_1P_pingN));
        ylim(2)=nanmax(ylim(2),nanmax(fData.X_1P_pingN));
    end
    
    obj_wc=findobj(ax,'Tag',tag_id_wc);
    
    if new_res
        delete(obj_wc);
        obj_wc=[];
    end
    
    
    
    if isempty(obj_wc)&&isfield(fData,'X_NEH_gridLevel')
        % grab data
        E = fData.X_1E_gridEasting;
        N = fData.X_N1_gridNorthing;
        %H = fData.X_11H_gridHeight;
        L = fData.X_NEH_gridLevel;        
        % get mean
        meanL = nanmean(L,3);
        obj_wc=imagesc(ax,E,N,meanL,'Visible',vis,'alphadata',~isnan(meanL),'Tag',tag_id_wc);
    else
        set(obj_wc,'Visible',vis);
    end
    
    uistack(obj_wc,'bottom');
       
     if idx_zoom(i)&&isfield(fData,'X_NEH_gridLevel')
        xlim(1)=nanmin(xlim(1),nanmin(fData.X_1E_gridEasting(:)));
        xlim(2)=nanmax(xlim(2),nanmax(fData.X_1E_gridEasting(:)));
        
        ylim(1)=nanmin(ylim(1),nanmin(fData.X_N1_gridNorthing(:)));
        ylim(2)=nanmax(ylim(2),nanmax(fData.X_N1_gridNorthing(:)));
    end
   
end

if~any(idx_zoom)
    return;
end

xlim=xlim+[-diff(xlim)/20 +diff(xlim)/20];
set(ax,'XLim',xlim);
ylim=ylim+[-diff(ylim)/20 +diff(ylim)/20];
set(ax,'YLim',ylim);


% get current ticks position
ytick=get(ax,'ytick');
xtick=get(ax,'xtick');

% turn to strings
ytickstr=num2str(ytick',10);
xtickstr=num2str(xtick',10);

% update strings
set(ax,'yticklabel',ytickstr);
set(ax,'xticklabel',xtickstr);

if ~isdeployed
    fprintf(1,'Currently %.0f active objects in Espresso\n\n',numel(findall(main_figure)));
end


end