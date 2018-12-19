%% load_fdata_tab.m
%
% Creates "Loaded lines" tab (#2) in Espresso's Control Panel. Also has
% callback functions for when interacting with the tab's contents.
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |input_variable_1|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% * |output_variable_1|: TODO: write description and info on variable
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2018-10-05: general editing and commenting (Alex Schimel)
% * 2017-10-25: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, Alexandre Schimel NIWA. Type |help Espresso.m| for
% copyright information.

%% Function
function load_fdata_tab(main_figure,parent_tab_group)

switch parent_tab_group.Type
    case 'uitabgroup'
        fdata_tab_comp.fdata_tab = uitab(parent_tab_group,'Title','Loaded lines','Tag','fdata_tab','BackGroundColor','w');
    case 'figure'
        fdata_tab_comp.fdata_tab = parent_tab_group;
end

% create the table of lines
fdata_tab_comp.table = uitable( 'Parent',fdata_tab_comp.fdata_tab,...
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

% initially, blank selection
fdata_tab_comp.selected_idx = [];

% right click menu
rc_menu = uicontextmenu(ancestor(fdata_tab_comp.table,'figure'));
fdata_tab_comp.table.UIContextMenu = rc_menu;
uimenu(rc_menu,'Label','Select All','Callback',{@selection_callback,main_figure},'Tag','se');
uimenu(rc_menu,'Label','De-Select All','Callback',{@selection_callback,main_figure},'Tag','de');
uimenu(rc_menu,'Label','Inverse Selection','Callback',{@selection_callback,main_figure},'Tag','inv');
uimenu(rc_menu,'Label','Remove Selected Lines','Callback',{@remove_lines_cback,main_figure});

% save and update the figure
setappdata(main_figure,'fdata_tab',fdata_tab_comp);
update_fdata_tab(main_figure);

end

%% CALLBACKS



%%
% Callback when selecting a line in the table
%
function cell_select_cback(~,evt,main_figure)

% selected line
if ~isempty(evt.Indices)
    selected_idx = (evt.Indices(:,1));
else
    selected_idx = [];
end

% update fdata_tab in main_figure's appdata
fdata_tab_comp = getappdata(main_figure,'fdata_tab');
fdata_tab_comp.selected_idx = unique(selected_idx);
setappdata(main_figure,'fdata_tab',fdata_tab_comp);

% update disp_config
disp_config = getappdata(main_figure,'disp_config');
if ~isempty(selected_idx)
    disp_config.Fdata_idx = selected_idx(end);
else
    disp_config.Fdata_idx = 1;
end
disp_config.Iping = 1;
disp_config.AcrossDist = 0;

% update ? XXX
update_wc_tab(main_figure);

end


%%
% Callback when editing the table, aka checking/unchecking the "Disp" check
% box
%
function update_map_cback(~,evt,main_figure)

fdata_tab_comp = getappdata(main_figure,'fdata_tab');
disp_config = getappdata(main_figure,'disp_config');

% checking that it's the disp checkbok that was activated
if evt.Indices(2) == 3
    disp_config.Fdata_idx = evt.Indices(1); % line that was switched
    disp_config.Iping = 1;
    disp_config.AcrossDist = 0;
    update_wc_tab(main_figure);
end

% update the map to put line on top
update_map_tab(main_figure,0,1,evt.Indices(1));

end


%%
% Callback when choosing either "Select all", "Deselect all", or "invert selection" in the right-click menu
%
function selection_callback(src,~,main_figure)

fdata_tab_comp = getappdata(main_figure,'fdata_tab');
data = fdata_tab_comp.table.Data;

for i = 1:size(data,1)
    switch src.Tag
        case 'se'
            data{i,end-1} = true;
        case 'de'
            data{i,end-1} = false;
        case 'inv'
            data{i,end-1} = ~data{i,end-1};
    end
end

fdata_tab_comp.table.Data = data;
fdata_tab_comp.selected_idx = find([data{:,end-1}]);
setappdata(main_figure,'fdata_tab',fdata_tab_comp);
update_map_tab(main_figure,0,0,[]);

end

%%
% Callback when choosing "remove selected lines" in the right click menu
%
function remove_lines_cback(~,~,main_figure)

fdata_tab_comp = getappdata(main_figure,'fdata_tab');
map_tab_comp = getappdata(main_figure,'Map_tab');
ax = map_tab_comp.map_axes;

fdata = getappdata(main_figure,'fData');
idx_rem = find([fdata_tab_comp.table.Data{:,end-1}]);

for i = idx_rem(:)'
    id = fdata{i}.ID;
    % times2 = datestr(fData.X_1P_pingSDN,'HH:MM:SS.FFF');
    tag_id = num2str(id,'%.0f');
    tag_id_wc = num2str(id,'wc%.0f');
    tag_id_poly = sprintf('poly_%.0f0',id);
    
    obj = findobj(ax,'Tag',tag_id,'-or','Tag',tag_id_wc);
    delete(obj);
    obj_poly = findobj(ax,'Tag',tag_id_poly);
    obj_poly.Shape.Vertices=[];
end

fdata(idx_rem) = [];

setappdata(main_figure,'fData',fdata);

if isempty(fdata)
    disp_config = getappdata(main_figure,'disp_config');
    disp_config.MET_tmproj = '';
end
update_fdata_tab(main_figure);
update_file_tab(main_figure);
update_map_tab(main_figure,0,1,[]);
disp_config.Fdata_idx = numel(fdata);
disp_config.AcrossDist = 0;
disp_config.Iping = 1;


end
