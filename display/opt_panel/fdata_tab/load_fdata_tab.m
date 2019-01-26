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

% create the table of lines loaded
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

% set its location
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

% indices of selected line
if ~isempty(evt.Indices)
    selected_idx = (evt.Indices(:,1));
    selected_row =(evt.Indices(:,2));
else
    selected_idx = [];
    selected_row= [];
end

% update the selected lines in fdata_tab
fdata_tab_comp = getappdata(main_figure,'fdata_tab');
fdata_tab_comp.selected_idx = unique(selected_idx);
setappdata(main_figure,'fdata_tab',fdata_tab_comp);

% update the displays if the new selection does not include the line
% currently displayed
disp_config = getappdata(main_figure,'disp_config');
IDs=[fData_tot(:).ID];

if ~isempty(selected_idx)

    % update only if selected lines do not include the one currently
    % displayed
    
    % udpate in disp_config
     disp_config.Fdata_ID = IDs(selected_idx(1));
%     disp_config.AcrossDist = 0;
%     disp_config.Iping = 1; % this updates the WC view with listenIping
%     
%     
    % update map with zoom adjusted to selected lines
    update_map_tab(main_figure,0,0,1,fdata_tab_comp.selected_idx);
    
end

end


%%
% Callback when editing the table, aka checking/unchecking the "Disp" check
% box
%
function update_map_cback(~,evt,main_figure)

% do only when it's the disp checkbox that was activated

if evt.Indices(2) == 3
    
    disp_config = getappdata(main_figure,'disp_config');
    fData_tot = getappdata(main_figure,'fData');
    IDs=[fData_tot(:).ID];
    disp_config.Fdata_ID = IDs(evt.Indices(1)); % line that was switched
    %     disp_config.AcrossDist = 0;
    %     disp_config.Iping = 1;
    update_map_tab(main_figure,0,0,0,evt.Indices(1));
end



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

% update map with zoom back on all lines
update_map_tab(main_figure,0,0,1,[]);

end

%%
% Callback when choosing "remove selected lines" in the right click menu
%
function remove_lines_cback(~,~,main_figure)

fdata = getappdata(main_figure,'fData');
fdata_tab_comp = getappdata(main_figure,'fdata_tab');
map_tab_comp = getappdata(main_figure,'Map_tab');

ax = map_tab_comp.map_axes;
idx_rem = find([fdata_tab_comp.table.Data{:,end-1}]);

% for each line, remove navigation and grid from map
for i = idx_rem(:)'
    
    id = fdata{i}.ID;
    tag_id_nav = num2str(id,'%.0f_nav');
    tag_id_wc = num2str(id,'%.0f_wc');
    obj = findobj(ax,'Tag',tag_id_nav,'-or','Tag',tag_id_wc);
    delete(obj);
    
end

% if all lines are gone, reinitialize (hide) ping swathe and ping window
if numel(idx_rem) == numel(fdata)
    
    set(map_tab_comp.ping_swathe,'XData',nan,'YData',nan);
    map_tab_comp.ping_window.Shape.Vertices = [0,0,1,1;1,0,0,1]'-999;
    
end

% then remove the fData itself
fdata(idx_rem) = [];

setappdata(main_figure,'fData',fdata);

if isempty(fdata)
    disp_config = getappdata(main_figure,'disp_config');
    disp_config.MET_tmproj = '';
end


update_fdata_tab(main_figure);
update_file_tab(main_figure);

% update map with zoom back on all remaining lines

disp_config.Fdata_ID =fdata{end}.ID;
disp_config.AcrossDist = 0;
disp_config.Iping = 1;
update_map_tab(main_figure,0,0,1,[]);


end
