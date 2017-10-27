function update_map_tab(main_figure,new_res)

map_tab_comp=getappdata(main_figure,'Map_tab');
fData_tot=getappdata(main_figure,'fData');
if isempty(fData_tot)
    return;
end
fdata_tab_comp=getappdata(main_figure,'fdata_tab');
disp_config=getappdata(main_figure,'disp_config');
idx_sel=fdata_tab_comp.selected_idx;
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

    if any(i==idx_sel)
       col='r';
    else
       col='k';
    end
    
    fData=fData_tot{i};
%     times1 = datestr(fData.X_1P_pingSDN,'dd-mmm-yyyy HH:MM:SS.FFF');
%     times2 = datestr(fData.X_1P_pingSDN,'HH:MM:SS.FFF');
    tag_id=num2str(fData.ID,'%.0f');
    tag_id_wc=num2str(fData.ID,'wc%.0f');
    
    obj=findobj(ax,'Tag',tag_id);
    
    if isempty(obj)   

        plot(ax,fData.X_1P_pingE(1),fData.X_1P_pingN(1),'o','Tag',tag_id,'Visible',vis,'Color',col);
        plot(ax,fData.X_1P_pingE,fData.X_1P_pingN,...,
            'Tag',tag_id,'Visible',vis,'Color',col,...
            'ButtonDownFcn',{@disp_wc_ping_cback,main_figure});
        
        plot(ax,[fData.X_1P_pingE(1:df:end),fData.X_1P_pingE(end)],[fData.X_1P_pingN(1:df:end),fData.X_1P_pingN(end)],'.','Tag',tag_id,'Visible',vis,'Color',col);
        plot(ax,fData.X_1P_pingE(end),fData.X_1P_pingN(end),'s','Tag',tag_id,'Visible',vis,'Color',col);
%         text(ax,fData.X_1P_pingE(1),fData.X_1P_pingN(1),sprintf(' \\leftarrow %s (start)',times1(1,:)),'Tag',tag_id,'Visible',vis)
%         text(ax,fData.X_1P_pingE(end),fData.X_1P_pingN(end),sprintf(' \\leftarrow %s (end)',times1(end,:)),'Tag',tag_id,'Visible',vis)
%         
%         for ii = (df+1):df:length(fData.X_1P_pingN)-1
%             text(ax,fData.X_1P_pingE(ii),fData.X_1P_pingN(ii),sprintf(' \\leftarrow %s',times2(ii,:)),'Tag',tag_id,'Visible',vis)
%         end
    else
        set(obj,'Visible',vis);
        set(obj(arrayfun(@(x) strcmp(x.Type,'line'),obj)),'Color',col);
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
       
               
        switch disp_config.Var_disp
            case 'wc_int'
                data = nanmean(L,3);
            case 'bathy'
                data = nanmean(L,3);
            case 'bs'
                data = nanmean(L,3);
        end
                
        obj_wc=imagesc(ax,E,N,data,'Visible',vis,'Tag',tag_id_wc,...
            'ButtonDownFcn',{@disp_wc_ping_cback,main_figure});
    else
        set(obj_wc,'Visible',vis);
        data=get(obj_wc,'CData');
    end
    switch disp_config.Var_disp
        case 'wc_int'
            alphadata=data>disp_config.Cax_wc_int(1);
        case 'bathy'
            alphadata=ones(size(data));
        case 'bs'
            alphadata=ones(size(data));
    end
    set(obj_wc,'alphadata',alphadata);
    uistack(obj_wc,'bottom');
       
     if idx_zoom(i)&&isfield(fData,'X_NEH_gridLevel')
        xlim(1)=nanmin(xlim(1),nanmin(fData.X_1E_gridEasting(:)));
        xlim(2)=nanmax(xlim(2),nanmax(fData.X_1E_gridEasting(:)));
        
        ylim(1)=nanmin(ylim(1),nanmin(fData.X_N1_gridNorthing(:)));
        ylim(2)=nanmax(ylim(2),nanmax(fData.X_N1_gridNorthing(:)));
     end
end
cax=disp_config.get_cax();
caxis(ax,cax);

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

disp_config=getappdata(main_figure,'disp_config');

zone=disp_config.get_zone();

[lat,~]=utm2ll(ytick,xlim(1)*ones(size(ytick)),zone);
[~,lon]=utm2ll(ylim(1)*ones(size(xtick)),xtick,zone);
lon(lon>180)=lon(lon>180)-360;

fmt='%.4f';
y_labels=cellfun(@(x) num2str(x,fmt),num2cell(lat),'UniformOutput',0);
x_labels=cellfun(@(x) num2str(x,fmt),num2cell(lon),'UniformOutput',0);
% update strings
set(ax,'yticklabel',y_labels);
set(ax,'xticklabel',x_labels);

if ~isdeployed
    fprintf(1,'Currently %.0f active objects in Espresso\n\n',numel(findall(main_figure)));
end


end