function create_feature_list_tab(main_figure,parent_tab_group)
%CREATE_FEATURE_LIST_TAB  Creates feature_list tab in Espresso Swath panel
%
%   See also UPDATE_FEATURE_LIST_TAB, INITIALIZE_DISPLAY, ESPRESSO.

%   Copyright 2017-2024 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

% disp_config = getappdata(main_figure,'disp_config');

switch parent_tab_group.Type
    case 'uitabgroup'
        % create new Feature List tab
        feature_list_tab_comp.feature_list_tab = uitab(parent_tab_group,'Title','Feature List','Tag','feature_list_tab','BackGroundColor','w');
        tab_menu = uicontextmenu(ancestor(feature_list_tab_comp.feature_list_tab,'figure'));
        uimenu(tab_menu,'Label','Undock to External Window','Callback',{@undock_tab_callback,main_figure,'feature_list','new_fig'});
        feature_list_tab_comp.feature_list_tab.UIContextMenu = tab_menu;
    case 'figure'
        % return existing Features List tab
        feature_list_tab_comp.feature_list_tab = parent_tab_group;
end

% get list of feature classes
featureClassList = get_feature_class_list();

% create table
columnname =   {'ID',     'Class',         'Description','Type',             'Min depth','Max depth','Unique_ID'};
columnformat = {'numeric',featureClassList,'char',       {'Point','Polygon'},'numeric',  'numeric',  'char'};
feature_list_tab_comp.table = uitable('Parent', feature_list_tab_comp.feature_list_tab,...
    'Data', [],...
    'ColumnName', columnname,...
    'ColumnFormat', columnformat,...
    'ColumnEditable', [false true true false true true false],...
    'Units','Normalized',...
    'Position',[0 0 1 1],...
    'RowName',[]);

% adjust columns width
pos_t = getpixelposition(feature_list_tab_comp.table);
set(feature_list_tab_comp.table,'ColumnWidth',...
    num2cell(pos_t(3)*[0.5/10 2.5/10 2.5/10 1.5/10 1.5/10 1.5/10 0]));

% add interactions and callbacks
set(feature_list_tab_comp.table,'CellEditCallback',{@edit_features_callback,main_figure});
set(feature_list_tab_comp.table,'CellSelectionCallback',{@activate_features_callback,main_figure});
set(feature_list_tab_comp.feature_list_tab,'SizeChangedFcn',{@resize_table,feature_list_tab_comp.table});
set(feature_list_tab_comp.table,'KeyPressFcn','');

% define right-click menu
rc_menu = uicontextmenu(ancestor(parent_tab_group,'figure'));
feature_list_tab_comp.table.UIContextMenu = rc_menu;
str_importLatLong = '<HTML><center><FONT color="Black">Import Lat/Long as Point Feature(s)</Font> ';
uimenu(rc_menu,'Label',str_importLatLong,'Callback',{@import_features_callback,main_figure});
str_export = '<HTML><center><FONT color="Black">Export Selected Feature(s)</Font> ';
uimenu(rc_menu,'Label',str_export,'Callback',{@export_features_callback,main_figure,{}});
str_delete = '<HTML><center><FONT color="Red"><b>Delete Selected Feature(s)</b></Font> ';
uimenu(rc_menu,'Label',str_delete,'Callback',{@delete_features_callback,main_figure,{}});

% add all those contents to appdata
setappdata(main_figure,'feature_list_tab',feature_list_tab_comp);

% load features saved on drive from a prior Espresso session
features = getappdata(main_figure,'features');
folder = fullfile(espresso_user_folder,'feature_files');
listing = dir(folder);
for ii = 1:numel(listing)
    if ~listing(ii).isdir
        filename = fullfile(listing(ii).folder, listing(ii).name);
        [~,Unique_ID,extension] = fileparts(filename);
        if strcmp(extension,'.shp')
            % create new feature from shapefile
            new_feature = feature_cl('shapefile',filename,'Unique_ID',Unique_ID);
            % add new feature to the list of features
            if isempty(features)
                features = new_feature;
            else
                features = [features new_feature];
            end
        end
    end
end

% if features were loaded, a few checks and actions are necessary
if ~isempty(features)

    % verify that all features have consistent UTM zone
    utmzone = unique([features.Zone]);
    if numel(utmzone)>1
        error('code here to remove features to enforce single zone');
    end
    
    % and add to disp_config
    disp_config = getappdata(main_figure,'disp_config');
    disp_config.MET_ellips = 'wgs84';
    disp_config.set_zone(utmzone);
    setappdata(main_figure,'disp_config',disp_config);
    
    % throw a warning that existing features define the session's
    % projection
    txt = sprintf('Existing features define the projection for this session (ellipsoid: %s, UTM zone: %s), so that any data file to be loaded will be using this projection. If you want to reset this session''s projection so that data files will be loaded in their natural projection, you will first need to delete the existing features (either from the "Feature List" tab, or from the folder %s) then close and restart Espresso.', disp_config.MET_ellips, disp_config.MET_tmproj, folder);
    warning(txt);
    
    % all good? save/overwrite features into main figure
    setappdata(main_figure,'features',features);
    
end

% trigger an update of the feature list tab
update_feature_list_tab(main_figure);

end


%% Callback when table is edited
function edit_features_callback(src,evt,main_figure)

% get all features
features = getappdata(main_figure,'features');
if isempty(features)
    return;
end

% get selected feature/property
if isempty(evt.Indices)
    selected_features = {};
else
    selected_features = src.Data(evt.Indices(:,1),end);
    idx_data = evt.Indices(:,2);
end
idx_feature = contains({features(:).Unique_ID},selected_features);

% get edited property value
nData = evt.NewData;

% saved edited property
switch src.ColumnName{idx_data}
    case 'Class'
        features(idx_feature).Class = nData;
    case 'Description'
        features(idx_feature).Description = nData;
    case 'Min depth'
        % save only if value acceptable
        if isnan(nData) || nData > features(idx_feature).Depth_max
            src.Data(evt.Indices(:,1),evt.Indices(:,2)) = {evt.PreviousData};
        else
            features(idx_feature).Depth_min = nData;
        end
    case 'Max depth'
        % save only if value acceptable
        if isnan(nData) || nData < features(idx_feature).Depth_min
            src.Data(evt.Indices(:,1),evt.Indices(:,2)) = {evt.PreviousData};
        else
            features(idx_feature).Depth_max = nData;
        end
end

% save edited feature to drive
features(idx_feature).feature_to_shapefile(fullfile(espresso_user_folder,'feature_files'));

% udpate list of features in app
setappdata(main_figure,'features',features);

% update display of feature
display_features(main_figure,selected_features,[]);

% trigger a select callback to display the selected feature as active on
% map
activate_features_callback(src,evt,main_figure)

end


%% Callback when elements in table are selected
function activate_features_callback(src,evt,main_figure)
% make the features active on map

if isempty(evt.Indices)
    selected_features = {};
else
    selected_features = src.Data(evt.Indices(:,1),end);
end
disp_config = getappdata(main_figure,'disp_config');
disp_config.Act_features = selected_features;

end


%% Callback for menu request to export features
function export_features_callback(~,~,main_figure,IDs)

disp_config = getappdata(main_figure,'disp_config');

features = getappdata(main_figure,'features');

if ~iscell(IDs)
    IDs = {IDs};
end

if isempty(IDs)
    IDs = disp_config.Act_features;
end

if isempty(IDs)
    return;
end

if isempty(features)
    return;
end

% select directory for export
getDirDefPath = espresso_export_folder();
folder_name = uigetdir(getDirDefPath,'Select folder where to export features');
if folder_name == 0
    return;
end

% features to export
features_id = {features(:).Unique_ID};
idx_feature_to_export = ismember(features_id,IDs);
idx_exp = find(idx_feature_to_export);

fData_tot = getappdata(main_figure,'fData');
table_out=[];
for ii = 1:numel(idx_exp)
    
    output_file = [sprintf('%s_%i_%s',features(idx_exp(ii)).Class,features(idx_exp(ii)).ID,features(idx_exp(ii)).Description) '.shp'];
    
    geostruct=features(idx_exp(ii)).feature_to_geostruct();
    
    geostruct.Files={};
    geostruct.PingStart=[];
    geostruct.PingEnd=[];
    geostruct.BottomDepth=[];
    geostruct.DateTimeStart={};
    geostruct.DateTimeEnd={};
    
    [idx_pings,bot_depth]=cellfun(@(x) interesect_feature_with_lines(features(idx_exp(ii)),x),fData_tot,'un',0);
    
    idx_lines=find(~cellfun(@isempty,idx_pings));
    if ~isempty(idx_lines)
        for i=idx_lines
            geostruct.Files=[geostruct.Files fData_tot{i}.ALLfilename{1}];
            geostruct.PingStart=[geostruct.PingStart idx_pings{i}(1)];
            geostruct.PingEnd=[geostruct.PingEnd idx_pings{i}(2)];
            geostruct.BottomDepth=[geostruct.BottomDepth abs(bot_depth{i})];
            geostruct.DateTimeStart=[geostruct.DateTimeStart,datestr(fData_tot{i}.X_1P_pingSDN(idx_pings{i}(1)),'yyyy/mm/dd HH:MM:SS')];
            geostruct.DateTimeEnd=[geostruct.DateTimeEnd,datestr(fData_tot{i}.X_1P_pingSDN(idx_pings{i}(2)),'yyyy/mm/dd HH:MM:SS')];
        end
    end
    geostruct.Files=strjoin(geostruct.Files,';');
    
    if ~isempty( geostruct.PingStart)
        geostruct.PingStart=sprintf('%.0f;',geostruct.PingStart);
        geostruct.PingStart(end)='';
    else
        geostruct.PingStart='';
    end
    
    if ~isempty( geostruct.PingEnd)
        geostruct.PingEnd=sprintf('%.0f;',geostruct.PingEnd);
        geostruct.PingEnd(end)='';
    else
        geostruct.PingEnd='';
    end
    
    if ~isempty( geostruct.BottomDepth)
        geostruct.BottomDepth=sprintf('%.0f;',geostruct.BottomDepth);
        geostruct.BottomDepth(end)='';
    else
        geostruct.BottomDepth='';
    end
    
    geostruct.DateTimeStart=strjoin(geostruct.DateTimeStart,';');
    geostruct.DateTimeEnd=strjoin(geostruct.DateTimeEnd,';');
    
    output_file=generate_valid_filename(output_file);
    output_file=fullfile(folder_name,output_file);
    %output_file='D:\test.shp';
    shapewrite(geostruct,output_file);
    
    geostruct=rmfield(geostruct,'BoundingBox');
    switch geostruct.Geometry
        case 'Polygon'
            geostruct.Lat=nanmean(geostruct.Lat(:));
            geostruct.Lon=nanmean(geostruct.Lon(:));
    end
    if isempty(table_out)
        table_out=struct2table(geostruct,'AsArray',1);
    else
        table_tmp=struct2table(geostruct,'AsArray',1);
        table_out=[table_out;table_tmp];
    end
    
end

if ~isempty(table_out)
    output_file_csv = fullfile(folder_name,[sprintf('%s_saved_features_%s',datestr(now,'yyyymmddHHMMSS')) '.csv']);
    writetable(table_out,output_file_csv);
end
fprintf('Export to %s finished\n',folder_name);
end


%%
function [idx_pings,bot_depth] = interesect_feature_with_lines(feature,fData)

idx_pings=[];
bot_depth=0;
[vert_poly,~,~] = poly_vertices_from_fData(fData,[],[]);
[intersection,features_intersecting] = feature_intersect_polygon(feature,polyshape(vert_poly));

if isempty(features_intersecting)
    % escape if no intersection. No polygon to draw on
    % stacked view
    return;
end

% get coordinates of sliding polygon vertices
easting = fData.X_1P_pingE;
northing = fData.X_1P_pingN;

if isempty(feature.Polygon)
    % feature is a point
    % find closest ping nav to point
    [~,idx_pings] = min(sqrt((intersection(1)-easting).^2+(intersection(2)-northing).^2),[],2);
    idx_pings=[idx_pings idx_pings];
    bot_depth=nanmean(nanmean(fData.X_BP_bottomUpDist(:,idx_pings)));
else
    % get vertices in stack display
    [~,ip] = min(sqrt((intersection.Vertices(:,1)-easting).^2+(intersection.Vertices(:,2)-northing).^2),[],2);
    
    idx_pings = [nanmin(ip) nanmax(ip)];
    bot_depth =  nanmean(nanmean(fData.X_BP_bottomUpDist(:,idx_pings(1):idx_pings(end))));
    
end
end


%% Callback for menu request to delete features
function delete_features_callback(~,~,main_figure,IDs)

% if feature ID in input, ensure it's cell
if ~iscell(IDs)
    IDs = {IDs};
end

% get active feature
disp_config = getappdata(main_figure,'disp_config');
if isempty(IDs)
    IDs = disp_config.Act_features;
end

if isempty(IDs)
    return;
end

% get all features
features = getappdata(main_figure,'features');
if isempty(features)
    return;
end

features_id = {features(:).Unique_ID};

idx_rem = ismember(features_id,IDs);

shp_files = dir(fullfile(espresso_user_folder,'feature_files'));

idx_f_to_rem = contains({shp_files(:).name},features_id(idx_rem));

files_to_rem = cellfun(@(x) fullfile(espresso_user_folder,'feature_files',x),{shp_files(idx_f_to_rem).name},'un',0);

cellfun(@delete,files_to_rem);

features(idx_rem) = [];

setappdata(main_figure,'features',features);

update_feature_list_tab(main_figure);

display_features(main_figure,{},[]);

disp_config.Act_features = {};

end


%% Callback for menu request to import features
function import_features_callback(~,~,main_figure)

% get display config and features
disp_config = getappdata(main_figure,'disp_config');
features = getappdata(main_figure,'features');

% prompt user for .csv file to import
getFileDefPath = fullfile(espresso_user_folder,'*.csv');
getFileTitle = 'Select .csv files with "Lat" and "Lon" headers to import as point features';
[file, path] = uigetfile(getFileDefPath,getFileTitle);
if isequal(file,0)
    return
end

% read .csv file
filename = fullfile(path, file);
T = readtable(filename,'delimiter',',');
varnames = T.Properties.VariableNames;

% get lat/long for each feature and project
idxLat = find(startsWith(varnames,'lat','IgnoreCase',true));
idxLon = find(startsWith(varnames,'lon','IgnoreCase',true));
lat = table2array(T(:,idxLat));
lon = table2array(T(:,idxLon));
[E, N] = CFF_ll2tm(lon, lat, disp_config.MET_ellips, disp_config.MET_tmproj);

% get description
idxDesc = find(startsWith(varnames,'desc','IgnoreCase',true));
if ~isempty(idxDesc)
    desc = table2cell(T(:,idxDesc));
    for ii = 1:numel(desc)
        % description must be cell array of char
        if isnumeric(desc{ii})
            if isnan(desc{ii})
                desc{ii} = '';
            else
                desc{ii} = num2str(desc{ii});
            end
        end
    end
else
    desc = repmat({''},numel(lat),1);
end

% get max ID of current features
if ~isempty(features)
    ID = nanmax([features(:).ID]);
else
    ID = 0;
end

% save features
zone = disp_config.get_zone();
nPoints = numel(E);
for ii = 1:nPoints
    ID = ID+1;
    new_feature = feature_cl('Point',[E(ii) N(ii)],'Zone',zone,'ID',ID,'Description',desc{ii});
    new_feature.feature_to_shapefile(fullfile(espresso_user_folder,'feature_files'));
    features = [features new_feature];
end

% save/overwrite features into main figure
setappdata(main_figure,'features',features);

% trigger an update of displaying features on map and stacked view
display_features(main_figure,{},[]);

% trigger an update of the feature list tab
update_feature_list_tab(main_figure);

end