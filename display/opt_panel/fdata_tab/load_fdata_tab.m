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
setappdata(main_figure,'fdata_tab',fdata_tab_comp);

update_fdata_tab(main_figure);

end

function update_map_cback(src,~,main_figure)
update_map_tab(main_figure,0);
end


function cell_select_cback(~,evt,main_figure)
fdata_tab_comp = getappdata(main_figure,'fdata_tab');

if ~isempty(evt.Indices)
    selected_idx=(evt.Indices(:,1));
else
    selected_idx=[];
end

fdata_tab_comp.selected_idx=selected_idx;
setappdata(main_figure,'fdata_tab',fdata_tab_comp);
update_map_tab(main_figure,1);

end