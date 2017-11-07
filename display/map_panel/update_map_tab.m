function update_map_tab(main_figure,new_res,new_zoom)

map_tab_comp=getappdata(main_figure,'Map_tab');
fData_tot=getappdata(main_figure,'fData');
grids=getappdata(main_figure,'grids');
if isempty(fData_tot)
    return;
end
fdata_tab_comp=getappdata(main_figure,'fdata_tab');
grid_tab_comp=getappdata(main_figure,'grid_tab');
disp_config=getappdata(main_figure,'disp_config');
idx_sel=fdata_tab_comp.selected_idx;
idx_zoom=(cell2mat(fdata_tab_comp.table.Data(:,end-1)));

if ~isempty(grid_tab_comp.table_main.Data)
    idx_zoom_grid=(cell2mat(grid_tab_comp.table_main.Data(:,end-1)));
else
    idx_zoom_grid=[];
end

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
    tag_id_line=num2str(fData.ID,'%.0f_line');
    obj_line=findobj(ax,'Tag',tag_id_line);
    set(obj_line,'Visible',vis);
    obj=findobj(ax,'Tag',tag_id);
    
    if isempty(obj)
        
        plot(ax,fData.X_1P_pingE(1),fData.X_1P_pingN(1),'o','Tag',tag_id,'Visible','on','Color',col);
        plot(ax,fData.X_1P_pingE,fData.X_1P_pingN,...,
            'Tag',tag_id,'Visible',vis,'Color',col,...
            'ButtonDownFcn',{@disp_wc_ping_cback,main_figure});
        
        plot(ax,[fData.X_1P_pingE(1:df:end),fData.X_1P_pingE(end)],[fData.X_1P_pingN(1:df:end),fData.X_1P_pingN(end)],'.','Tag',tag_id,'Visible','on','Color',col);
        plot(ax,fData.X_1P_pingE(end),fData.X_1P_pingN(end),'s','Tag',tag_id,'Visible','on','Color',col);
        %         text(ax,fData.X_1P_pingE(1),fData.X_1P_pingN(1),sprintf(' \\leftarrow %s (start)',times1(1,:)),'Tag',tag_id,'Visible',vis)
        %         text(ax,fData.X_1P_pingE(end),fData.X_1P_pingN(end),sprintf(' \\leftarrow %s (end)',times1(end,:)),'Tag',tag_id,'Visible',vis)
        %
        %         for ii = (df+1):df:length(fData.X_1P_pingN)-1
        %             text(ax,fData.X_1P_pingE(ii),fData.X_1P_pingN(ii),sprintf(' \\leftarrow %s',times2(ii,:)),'Tag',tag_id,'Visible',vis)
        %         end
    else
        set(obj,'Visible','on');
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
        L = fData.X_NEH_gridLevel;
        % get mean
        
        
        switch disp_config.Var_disp
            case 'wc_int'
                if size(L,3)>1
                    data = pow2db_perso(nanmean(db2pow(L),3));
                else
                    data=L;
                end
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

if nansum(idx_zoom)==0
    set(map_tab_comp.ping_line,'XData',nan,'YData',nan);
end


for igrid=1:numel(grids)
    
    if idx_zoom_grid(igrid)
        vis='on';
    else
        vis='off';
    end
    
    grid=grids(igrid);
    tag_id_grid=num2str(grid.ID,'grid%.0f');
    tag_id_box=num2str(grid.ID,'box%.0f');
    [numElemGridN,numElemGridE]=size(grid.grid_level);
    gridEasting  = (0:numElemGridE-1) .*grid.res + grid.E_lim(1);
    gridNorthing = (0:numElemGridN-1)'.*grid.res +grid.N_lim(1);
    alphadata=grid.grid_level>disp_config.Cax_wc_int(1);
    obj_grid=findobj(ax,'Tag',tag_id_grid);
    obj_box=findobj(ax,'Tag',tag_id_box);
    
    if isempty(obj_box)
        rectangle(ax,'Position',[grid.E_lim(1),grid.N_lim(1),diff(grid.E_lim),diff(grid.N_lim)],'Tag',tag_id_box,'EdgeColor','b');
    else
        set(obj_box,'Position',[grid.E_lim(1),grid.N_lim(1),diff(grid.E_lim),diff(grid.N_lim)]);
    end
    
    
    if new_res
        delete(obj_grid);
        obj_grid=[];
    end
    
    if isempty(obj_grid)
        obj_grid=imagesc(ax,gridEasting,gridNorthing,grid.grid_level,'Tag',tag_id_grid,'alphadata',alphadata);
    else
        set(obj_grid,'XData',gridEasting,'YData',gridNorthing,'CData',grid.grid_level,'alphadata',alphadata);
    end
    set(obj_grid,'Visible',vis);
    uistack(obj_grid,'bottom');
end

cax=disp_config.get_cax();
caxis(ax,cax);

if~any(idx_zoom)
    return;
end

if new_zoom>0
    dx=nanmax([diff(xlim) diff(ylim)]);
    xlim=xlim+[-dx/20 +dx/20];
    set(ax,'XLim',xlim);
    ylim=ylim+[-dx/20 +dx/20];
    set(ax,'YLim',ylim);
end

% get current ticks position
ytick=get(ax,'ytick');
xtick=get(ax,'xtick');

disp_config=getappdata(main_figure,'disp_config');

zone=disp_config.get_zone();

[lat,~]=utm2ll(xtick,ylim(1)*ones(size(xtick)),zone);
[~,lon]=utm2ll(xlim(1)*ones(size(ytick)),ytick,zone);
lon(lon>180)=lon(lon>180)-360;

fmt='%.2f';
[~,x_labels]=cellfun(@(x,y) latlon2str(x,y,fmt),num2cell(lon),num2cell(lon),'un',0);
[y_labels,~]=cellfun(@(x,y) latlon2str(x,y,fmt),num2cell(lat),num2cell(lat),'un',0);

% update strings
set(ax,'yticklabel',y_labels);
set(ax,'xticklabel',x_labels);

if ~isdeployed
    fprintf(1,'Currently %.0f active objects in Espresso\n\n',numel(findall(main_figure)));
end


end