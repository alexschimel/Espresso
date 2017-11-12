function load_fdata_tab(main_figure,parent_tab_group)

switch parent_tab_group.Type
    case 'uitabgroup'
        fdata_tab_comp.fdata_tab=uitab(parent_tab_group,'Title','Lines','Tag','fdata_tab','BackGroundColor','w');
    case 'figure'
        fdata_tab_comp.fdata_tab=parent_tab_group;
end

fdata_tab_comp.table= uitable('Parent',fdata_tab_comp.fdata_tab,...
    'Data', [],...
    'ColumnName', {'Lines' 'Folder' 'Disp' 'ID'},...
    'ColumnFormat', {'char' 'char' 'logical' 'numeric'},...
    'ColumnEditable',[false false true false],...
    'Units','Normalized',...
    'Position',[0.01 0 0.98 1],...
    'RowName',[],...
    'CellSelectionCallback',{@cell_select_cback,main_figure},...
    'CellEditCallback',{@update_map_cback,main_figure},...
    'BusyAction','cancel');
pos_t = getpixelposition(fdata_tab_comp.table);
set(fdata_tab_comp.table,'ColumnWidth',{3*pos_t(3)/10,6*pos_t(3)/10,pos_t(3)/10, 0});

set(fdata_tab_comp.fdata_tab,'SizeChangedFcn',{@resize_table,fdata_tab_comp.table});
fdata_tab_comp.selected_idx=[];

rc_menu = uicontextmenu(ancestor(fdata_tab_comp.table,'figure'));
fdata_tab_comp.table.UIContextMenu =rc_menu;
uimenu(rc_menu,'Label','Select All','Callback',{@selection_callback,main_figure},'Tag','se');
uimenu(rc_menu,'Label','De-Select All','Callback',{@selection_callback,main_figure},'Tag','de');
uimenu(rc_menu,'Label','Inverse Selection','Callback',{@selection_callback,main_figure},'Tag','inv');
uimenu(rc_menu,'Label','Remove Selected Lines','Callback',{@remove_lines_cback,main_figure});

setappdata(main_figure,'fdata_tab',fdata_tab_comp);

update_fdata_tab(main_figure);

end

function selection_callback(src,~,main_figure)
fdata_tab_comp = getappdata(main_figure,'fdata_tab');
data=fdata_tab_comp.table.Data;
for i=1:size(data,1)
    switch src.Tag
        case 'se'
            data{i,end-1}=true;
        case 'de'
            data{i,end-1}=false;
        case 'inv'
            data{i,end-1}=~data{i,1};
    end
end
set(fdata_tab_comp.table,'Data',data);
update_map_tab(main_figure,0,0);
end


function remove_lines_cback(~,~,main_figure)
fdata_tab_comp = getappdata(main_figure,'fdata_tab');
map_tab_comp=getappdata(main_figure,'Map_tab');
ax=map_tab_comp.map_axes;

fdata=getappdata(main_figure,'fData');
idx_rem=fdata_tab_comp.selected_idx;

for i=idx_rem(:)'
    id=fdata{i}.ID;
    %     times2 = datestr(fData.X_1P_pingSDN,'HH:MM:SS.FFF');
    tag_id=num2str(id,'%.0f');
    tag_id_wc=num2str(id,'wc%.0f');
    
    obj=findobj(ax,'Tag',tag_id,'-or','Tag',tag_id_wc);
    delete(obj);
end

fdata(idx_rem)=[];

setappdata(main_figure,'fData',fdata);
if isempty(fdata)
    disp_config=getappdata(main_figure,'disp_config');
    disp_config.MET_tmproj='';
end

disp_config.Fdata_idx=numel(fdata);
disp_config.Iping=1;
disp_config.AcrossDist=0;

update_fdata_tab(main_figure);
update_file_tab(main_figure);
update_map_tab(main_figure,0,1);
update_wc_tab(main_figure);

end

function update_map_cback(src,evt,main_figure)

disp_config=getappdata(main_figure,'disp_config');
if evt.Indices(2)==3
    disp_config.Fdata_idx=evt.Indices(1);
    disp_config.Iping=1;
    disp_config.AcrossDist=0;
    update_wc_tab(main_figure);
end
update_map_tab(main_figure,0,1);
end


function cell_select_cback(~,evt,main_figure)
fdata_tab_comp = getappdata(main_figure,'fdata_tab');

if ~isempty(evt.Indices)
    selected_idx=(evt.Indices(:,1));
else
    selected_idx=[];
end

fdata_tab_comp.selected_idx=unique(selected_idx);
setappdata(main_figure,'fdata_tab',fdata_tab_comp);
update_map_tab(main_figure,1,0);
disp_config=getappdata(main_figure,'disp_config');

if ~isempty(selected_idx)
    disp_config.Fdata_idx=selected_idx(end);
else
    disp_config.Fdata_idx=1;
end

disp_config.Iping=1;
disp_config.AcrossDist=0;
update_wc_tab(main_figure);



end