%% load_mosaic_tab.m
%
% Creates "Mosaicking" tab (#4) in Espresso's Control Panel. Also has
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
function load_mosaic_tab(main_figure,parent_tab_group)

%% create tab variable
switch parent_tab_group.Type
    case 'uitabgroup'
        mosaic_tab_comp.mosaic_tab = uitab(parent_tab_group,'Title','Mosaicking','Tag','mosaic_tab','BackGroundColor','w');
    case 'figure'
        mosaic_tab_comp.mosaic_tab = parent_tab_group;
end


%% design

% disp_config = getappdata(main_figure,'disp_config');

survDataSummary = {};

% Column names and column format
columnname = {'Name' 'Res.' 'Disp' 'ID'};
columnformat = {'char','numeric','logical','numeric'};

% Create the uitable
mosaic_tab_comp.table_main = uitable('Parent',mosaic_tab_comp.mosaic_tab,...
    'Data', survDataSummary,...
    'ColumnName', columnname,...
    'ColumnFormat', columnformat,...
    'CellSelectionCallback',{@cell_select_cback,main_figure},...
    'CellEditCallback',{@update_mosaic_map,main_figure},...
    'ColumnEditable', [true true true false],...
    'Units','Normalized','Position',[0 0.1 1 0.9],...
    'RowName',[]);

pos_t = getpixelposition(mosaic_tab_comp.table_main);
set(mosaic_tab_comp.table_main,'ColumnWidth', num2cell(pos_t(3)*[15/20 3/20 2/20 0/20]));
set(mosaic_tab_comp.mosaic_tab,'SizeChangedFcn',{@resize_table,mosaic_tab_comp.table_main});

uicontrol(mosaic_tab_comp.mosaic_tab,'Style','pushbutton','units','normalized',...
    'pos',[0.1 0.01 0.2 0.08],...
    'String','New Mosaic',...
    'callback',{@mosaic_tot_cback,main_figure});

uicontrol(mosaic_tab_comp.mosaic_tab,'Style','pushbutton','units','normalized',...
    'pos',[0.3 0.01 0.2 0.08],...
    'String','Re-compute',...
    'callback',{@re_mosaic_cback,main_figure});

uicontrol(mosaic_tab_comp.mosaic_tab,'Style','pushbutton','units','normalized',...
    'pos',[0.5 0.01 0.2 0.08],...
    'String','Delete',...
    'callback',{@delete_mosaic_cback,main_figure});

uicontrol(mosaic_tab_comp.mosaic_tab,'Style','pushbutton','units','normalized',...
    'pos',[0.7 0.01 0.2 0.08],...
    'String','Export',...
    'callback',{@export_mosaic_cback,main_figure});

mosaic_tab_comp.selected_idx = [];
setappdata(main_figure,'mosaic_tab',mosaic_tab_comp);

end



%% CALLBACKS


%%
% Callback when ...
%
function export_mosaic_cback(~,~,main_figure)

mosaics = getappdata(main_figure,'mosaics');
map_tab_comp = getappdata(main_figure,'Map_tab');
mosaic_tab_comp = getappdata(main_figure,'mosaic_tab');
ax = map_tab_comp.map_axes;
file_tab_comp = getappdata(main_figure,'file_tab');
path_tmp = file_tab_comp.path_box.String;
disp_config = getappdata(main_figure,'disp_config');

zone = disp_config.get_zone();

for i = mosaic_tab_comp.selected_idx(:)'
    
    % tag_id_mosaic = num2str(mosaics(i).ID,'mosaic%.0f');
    % tag_id_box = num2str(mosaics(i).ID,'box%.0f');
    % mosaic_obj = findobj(ax,'Tag',tag_id_mosaic);
    
    [fileN, pathname] = uiputfile({'*.tif'},...
        'Export to GeoTiff',...
        fullfile(path_tmp,sprintf('%s_mosaic_%d.tif',mosaics(i).name,mosaics(i).res)));
    if isequal(pathname,0)||isequal(fileN,0)
        return;
    end
    
    if zone>0
        z = 32600+zone;
    else
        z = 32700-zone;
    end
    
    % [latlim,lonlim] = utm2ll(mosaics(i).E_lim,mosaics(i).N_lim,zone);
    % lonlim(lonlim>180) = lonlim(lonlim>180)-360;
    %
    R = makerefmat(mosaics(i).E_lim(1),mosaics(i).N_lim(1),mosaics(i).res,mosaics(i).res);
    % R = [[mosaics(i).E_lim(1) mosaics(i).N_lim(1)];[mosaics(i).res mosaics(i).res];[size(mosaics(i).mosaic_level)]];
    % levels = mosaics(i).mosaic_level;
    % levels(isnan(levels)) = -999;
    geotiffwrite(fullfile(pathname,fileN),mosaics(i).mosaic_level,R,'CoordRefSysCode',sprintf('EPSG:%d',z));
    fprintf('...Done.\n');
    
end

end


%%
% Callback when pressing the Delete button
%
function delete_mosaic_cback(~,~,main_figure)

mosaics = getappdata(main_figure,'mosaics');
map_tab_comp = getappdata(main_figure,'Map_tab');
mosaic_tab_comp = getappdata(main_figure,'mosaic_tab');
ax = map_tab_comp.map_axes;
idx_rem = [];

for i = mosaic_tab_comp.selected_idx(:)'
    if i <= numel(mosaics)
        tag_id_mosaic = num2str(mosaics(i).ID,'mosaic%.0f');
        tag_id_box = num2str(mosaics(i).ID,'box%.0f');
        obj = findobj(ax,'Tag',tag_id_mosaic,'-or','Tag',tag_id_box);
        delete(obj);
        idx_rem = union(i,idx_rem);
    end
end

mosaics(idx_rem) = [];
setappdata(main_figure,'mosaics',mosaics);

update_mosaic_tab(main_figure);

end


%%
% Callback when clicking the Recompute button
%
function re_mosaic_cback(~,~,main_figure)

mosaics         = getappdata(main_figure,'mosaics');
mosaic_tab_comp = getappdata(main_figure,'mosaic_tab');
fData_tot       = getappdata(main_figure,'fData');

if isempty(mosaic_tab_comp.selected_idx)
    % no mosaic to recompute
    return;
end

idx_mosaic = find(cell2mat(mosaic_tab_comp.table_main.Data(mosaic_tab_comp.selected_idx(:),4)) == [mosaics(:).ID]);

for i = idx_mosaic(:)'
    mosaics(idx_mosaic) = compute_mosaic(mosaics(idx_mosaic),fData_tot);
end

setappdata(main_figure,'mosaics',mosaics);

update_map_tab(main_figure,1,0,[]);

end

%%
% Callback when ...
%
function update_mosaic_map(src,evt,main_figure)

mosaics = getappdata(main_figure,'mosaics');
fData_tot = getappdata(main_figure,'fData');
idx_mosaic = cell2mat(src.Data(evt.Indices(1),4)) == [mosaics(:).ID];

switch evt.Indices(2)
    case 1
        mosaics(idx_mosaic).name = evt.NewData;
    case 2
        if ~isnan(evt.NewData)&&evt.NewData>0
            mosaics(idx_mosaic).res = evt.NewData;
            mosaics(idx_mosaic) = get_default_res(mosaics(idx_mosaic),fData_tot);
            
            mosaics(idx_mosaic) = compute_mosaic(mosaics(idx_mosaic),fData_tot);
        else
            src.Data{evt.Indices(1),evt.Indices(2)} = evt.PreviousData;
        end
end

setappdata(main_figure,'mosaics',mosaics);

update_map_tab(main_figure,1,0,[]);

end

%%
% Callback when clicking the Create/New button for a new mosaic
%
function mosaic_tot_cback(~,~,main_figure)

% replace pointer with cross, and callback when clicking down on the map
replace_interaction(main_figure,'interaction','WindowButtonDownFcn',  'id',1,'interaction_fcn',{@create_mosaic,main_figure},'pointer','cross');
replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',1,'interaction_fcn',{@disp_cursor_info,main_figure},'pointer','cross');

end


%%
% Callback when ...
%
function cell_select_cback(~,evt,main_figure)

mosaic_tab_comp = getappdata(main_figure,'mosaic_tab');

if ~isempty(evt.Indices)
    selected_idx = (evt.Indices(:,1));
else
    selected_idx = [];
end

% selected_idx'
mosaic_tab_comp.selected_idx = unique(selected_idx);
setappdata(main_figure,'mosaic_tab',mosaic_tab_comp);

end