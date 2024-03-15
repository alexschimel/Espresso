function create_mosaic_tab(main_figure,parent_tab_group)
%CREATE_MOSAIC_TAB  Creates mosaic tab in Espresso Control panel
%
%   See also UPDATE_MOSAIC_TAB, INITIALIZE_DISPLAY, ESPRESSO.

%   Copyright 2017-2024 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

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
    'CellEditCallback',{@edit_mosaic,main_figure},...
    'ColumnEditable', [true true true false],...
    'Units','Normalized','Position',[0 0.1 1 0.9],...
    'RowName',[]);

pos_t = getpixelposition(mosaic_tab_comp.table_main);
set(mosaic_tab_comp.table_main,'ColumnWidth', num2cell(pos_t(3)*[15/20 3/20 2/20 0/20]));
set(mosaic_tab_comp.mosaic_tab,'SizeChangedFcn',{@resize_table,mosaic_tab_comp.table_main});

uicontrol(mosaic_tab_comp.mosaic_tab,'Style','pushbutton','units','normalized',...
    'pos',[0 0.01 0.2 0.08],...
    'String','New 2D Mosaic',...
    'callback',{@create_new_mosaic_cback,main_figure,'2D'});

uicontrol(mosaic_tab_comp.mosaic_tab,'Style','pushbutton','units','normalized',...
    'pos',[0.2 0.01 0.2 0.08],...
    'String','New 3D Mosaic',...
    'callback',{@create_new_mosaic_cback,main_figure,'3D'});

uicontrol(mosaic_tab_comp.mosaic_tab,'Style','pushbutton','units','normalized',...
    'pos',[0.4 0.01 0.2 0.08],...
    'String','Re-compute',...
    'callback',{@re_mosaic_cback,main_figure});

uicontrol(mosaic_tab_comp.mosaic_tab,'Style','pushbutton','units','normalized',...
    'pos',[0.6 0.01 0.2 0.08],...
    'String','Delete',...
    'callback',{@delete_mosaic_cback,main_figure});

uicontrol(mosaic_tab_comp.mosaic_tab,'Style','pushbutton','units','normalized',...
    'pos',[0.8 0.01 0.2 0.08],...
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
disp_config = getappdata(main_figure,'disp_config');

zone = disp_config.get_zone();

defaultExportFolder = espresso_export_folder();

for i = mosaic_tab_comp.selected_idx(:)'
    
    % tag_id_mosaic = num2str(mosaics(i).ID,'%.0f_mosaic');
    % tag_id_box = num2str(mosaics(i).ID,'%.0f_box');
    % mosaic_obj = findobj(ax,'Tag',tag_id_mosaic);
    
    mosaicName = mosaics(i).name;
    mosaicRes = mosaics(i).res;
    mosaicResString = sprintf('%gm',mosaicRes);
    defaultExportFile = sprintf('mosaic_%s_res_%s.tif',mosaicName,mosaicResString);
    defaultExportFullFile = fullfile(defaultExportFolder,defaultExportFile);
    
    [fileN, pathname] = uiputfile({'*.tif'}, 'Export mosaic to GeoTiff',defaultExportFullFile);
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
    R = makerefmat(mosaics(i).E_lim(1),mosaics(i).N_lim(1),mosaicRes,mosaicRes);
    % R = [[mosaics(i).E_lim(1) mosaics(i).N_lim(1)];[mosaics(i).res mosaics(i).res];[size(mosaics(i).mosaic_level)]];
    % levels = mosaics(i).mosaic_level;
    % levels(isnan(levels)) = -999;
    exportFile = fullfile(pathname,fileN);
    geotiffwrite(exportFile,mosaics(i).mosaic_level,R,'CoordRefSysCode',sprintf('EPSG:%d',z));
    fprintf('Mosaic %s exported as %s.\n',mosaicName,exportFile);
    
end

end


%%
% Callback when pressing the Delete button
%
function delete_mosaic_cback(~,~,main_figure)

mosaics         = getappdata(main_figure,'mosaics');
map_tab_comp    = getappdata(main_figure,'Map_tab');
mosaic_tab_comp = getappdata(main_figure,'mosaic_tab');

ax = map_tab_comp.map_axes;
idx_rem = [];

for i = mosaic_tab_comp.selected_idx(:)'
    if i <= numel(mosaics)
        tag_id_mosaic = num2str(mosaics(i).ID,'%.0f_mosaic');
        tag_id_box = num2str(mosaics(i).ID,'%.0f_box');
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
display_tab_comp = getappdata(main_figure,'display_tab');

% get current 3D grids display value
d_lim_sonar_ref  = [sscanf(display_tab_comp.d_line_min.Label,'%fm') sscanf(display_tab_comp.d_line_max.Label,'%fm')];
d_lim_bottom_ref = [sscanf(display_tab_comp.d_line_bot_min.Label,'%fm') sscanf(display_tab_comp.d_line_bot_max.Label,'%fm')];

if isempty(mosaic_tab_comp.selected_idx)
    % no mosaic to recompute
    return;
end

idx_mosaic = find(cell2mat(mosaic_tab_comp.table_main.Data(mosaic_tab_comp.selected_idx(:),4)) == [mosaics(:).ID]);

% recompute mosaics
for i = idx_mosaic(:)'
    mosaics(idx_mosaic) = compute_mosaic(mosaics(idx_mosaic), fData_tot, d_lim_sonar_ref, d_lim_bottom_ref);
end

setappdata(main_figure,'mosaics',mosaics);

% update map with new mosaic, no zoom adjustement
update_map_tab(main_figure,0,1,0,[]);

end


%%
% Callback when editing mosaic (name or resolution)
%
function edit_mosaic(src,evt,main_figure)

mosaics = getappdata(main_figure,'mosaics');
fData_tot = getappdata(main_figure,'fData');
display_tab_comp = getappdata(main_figure,'display_tab');

% get current 3D grids display value
d_lim_sonar_ref = [sscanf(display_tab_comp.d_line_min.Label,'%fm') sscanf(display_tab_comp.d_line_max.Label,'%fm')];
d_lim_bottom_ref = [sscanf(display_tab_comp.d_line_bot_min.Label,'%fm') sscanf(display_tab_comp.d_line_bot_max.Label,'%fm')];

idx_mosaic = cell2mat(src.Data(evt.Indices(1),4)) == [mosaics(:).ID];

switch evt.Indices(2)
    case 1
        % name update
        mosaics(idx_mosaic).name = evt.NewData;
    case 2
        % resolution update
        newRes = evt.NewData;
        if ~isnan(newRes) && newRes>=mosaics(idx_mosaic).res
            
            % initialize a new mosaic with bounds of old mosaic but new
            % resolution
            tmp_mosaic = CFF_init_mosaic(mosaics(idx_mosaic).E_lim,mosaics(idx_mosaic).N_lim,newRes);
            
            % new resolution and blank mosaic grid
            mosaics(idx_mosaic).res = newRes;
            mosaics(idx_mosaic).mosaic_level = tmp_mosaic.mosaic_level;
            
            % recompute mosaic with new resolution, but only with original fData
            fData_tot_IDs = cellfun(@(x) x.ID, fData_tot);
            ind_fData_tot_in_mosaic = ismember( fData_tot_IDs, mosaics(idx_mosaic).Fdata_ID );
            mosaics(idx_mosaic) = compute_mosaic(mosaics(idx_mosaic), fData_tot(ind_fData_tot_in_mosaic), d_lim_sonar_ref, d_lim_bottom_ref);
            
        elseif ~isnan(newRes) && newRes>0
            % valid new resolution but not possible
            warning('Cannot mosaic data at higher resolution than coarsest constituent grid. Best resolution possible is %.2g m.', mosaics(idx_mosaic).res);
            src.Data{evt.Indices(1),evt.Indices(2)} = evt.PreviousData;
        else
            % not a valid new resolution
            src.Data{evt.Indices(1),evt.Indices(2)} = evt.PreviousData;
        end
end

setappdata(main_figure,'mosaics',mosaics);

% update map with new mosaic, no zoom adjustement
update_map_tab(main_figure,0,1,0,[]);

end


function create_new_mosaic_cback(~,~,main_figure,mosaic_type)
%CREATE_NEW_MOSAIC_CBACK 
%   Callback when clicking the Create/New button for a new mosaic
%
%   Pass into interactive "box dawing", requesting to create a mosaic of
%   appropriate type (2D or 3D) when the bx has finished drawing

pointerStyle = 'cross';
endFunction = @compute_and_add_mosaic;
endFunctionInputVar = mosaic_type;
init_box_drawing_mode(main_figure,endFunction,endFunctionInputVar,pointerStyle);

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