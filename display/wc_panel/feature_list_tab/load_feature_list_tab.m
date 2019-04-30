%% this_function_name.m
%
% _This section contains a very short description of the function, for the
% user to know this function is part of the software and what it does for
% it. Example below to replace. Delete these lines XXX._
%
% Template of ESP3 function header. XXX
%
%% Help
%
% *USE*
%
% _This section contains a more detailed description of what the function
% does and how to use it, for the interested user to have an overall
% understanding of its function. Example below to replace. Delete these
% lines XXX._
%
% This is a text file containing the basic comment template to add at the
% start of any new ESP3 function to serve as function help. XXX
%
% *INPUT VARIABLES*
%
% _This section contains bullet points of input variables with description
% and information. Put input variable and other valid entries or defaults
% between | symbols so it shows as monospace. Information section to
% contain, in order: requirement (i.e. Required/Optional/Paramter), valid
% type (e.g. Num, Positive num, char, 1xN cell array, etc.) and default
% value if there is one (e.g. Default: '10'). Example below to replace.
% Delete these lines XXX._
%
% * |input_variable_1|: Description (Information). XXX
% * |input_variable_2|: Description (Information). XXX
% * |input_variable_3|: Description (Information). XXX
%
% *OUTPUT VARIABLES*
%
% _This section contains bullet points of output variables with description
% and information. See input variables for template. Example below to
% replace. Delete these lines XXX._
%
% * |output_variable_1|: Description (Information). XXX
% * |output_variable_2|: Description (Information). XXX
%
% *DEVELOPMENT NOTES*
%
% _This section describes what features are temporary, needed future
% developments and paper references. Example below to replace. Delete these
% lines XXX._
%
% * research point 1. XXX
% * research point 2. XXX
%
% *NEW FEATURES*
%
% _This section contains dates and descriptions of major updates. Example
% below to replace. Delete these lines XXX._
%
% * YYYY-MM-DD: second version. Describes the update. XXX
% * YYYY-MM-DD: first version. XXX
%
% *EXAMPLE*
%
% _This section contains examples of valid function calls. Note that
% example lines start with 3 white spaces so that the publish function
% shows them correctly as matlab code. Example below to replace. Delete
% these lines XXX._
%
%   example_use_1; % comment on what this does. XXX
%   example_use_2: % comment on what this line does. XXX
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% _This last section contains at least author name and affiliation. Delete
% these lines XXX._
%
% Yoann Ladroit, Alexandre Schimel, NIWA. XXX

%% Function
function load_feature_list_tab(main_figure,parent_tab_group)

% disp_config = getappdata(main_figure,'disp_config');

switch parent_tab_group.Type
    case 'uitabgroup'
        feature_list_tab_comp.feature_list_tab = uitab(parent_tab_group,'Title','Feature List','Tag','feature_list_tab','BackGroundColor','w');
        tab_menu = uicontextmenu(ancestor(feature_list_tab_comp.feature_list_tab,'figure'));
        uimenu(tab_menu,'Label','Undock to External Window','Callback',{@undock_tab_callback,main_figure,'feature_list','new_fig'});
        feature_list_tab_comp.feature_list_tab.UIContextMenu = tab_menu;
    case 'figure'
        feature_list_tab_comp.feature_list_tab = parent_tab_group;
end

% pos = getpixelposition(feature_list_tab_comp.wc_tab);

columnname =   {'ID',     'Class',          'Description','Type',             'Min depth','Max depth','Unique_ID'};
columnformat = {'numeric',init_feature_class,'char',       {'Point','Polygon'},'numeric',  'numeric',  'char'};

feature_list_tab_comp.table = uitable('Parent', feature_list_tab_comp.feature_list_tab,...
    'Data', [],...
    'ColumnName', columnname,...
    'ColumnFormat', columnformat,...
    'ColumnEditable', [false true true false true true false],...
    'Units','Normalized',...
    'Position',[0 0 1 1],...
    'RowName',[]);

pos_t = getpixelposition(feature_list_tab_comp.table);

set(feature_list_tab_comp.table,'ColumnWidth',...
    num2cell(pos_t(3)*[0.5/10 2.5/10 2.5/10 1.5/10 1.5/10 1.5/10 0]));

set(feature_list_tab_comp.table,'CellEditCallback',{@edit_features_callback,main_figure});
set(feature_list_tab_comp.table,'CellSelectionCallback',{@activate_features_callback,main_figure});
set(feature_list_tab_comp.feature_list_tab,'SizeChangedFcn',{@resize_table,feature_list_tab_comp.table});
set(feature_list_tab_comp.table,'KeyPressFcn','');

%% Define right-click menu
rc_menu = uicontextmenu(ancestor(parent_tab_group,'figure'));

feature_list_tab_comp.table.UIContextMenu = rc_menu;

str_export = '<HTML><center><FONT color="Black">Export Selected Feature(s)</Font> ';
uimenu(rc_menu,'Label',str_export,'Callback',{@export_features_callback,main_figure,{}});

str_delete = '<HTML><center><FONT color="Red"><b>Delete Selected Feature(s)</b></Font> ';
uimenu(rc_menu,'Label',str_delete,'Callback',{@delete_features_callback,main_figure,{}});

% add all those contents to appdata
setappdata(main_figure,'feature_list_tab',feature_list_tab_comp);

% Load existing features
features = getappdata(main_figure,'features');

folder = fullfile(whereisroot,'feature_files');
listing = dir(folder);

for ii = 1:numel(listing)
    if ~listing(ii).isdir
        
        filename = fullfile(listing(ii).folder, listing(ii).name);
        [~,Unique_ID,extension] = fileparts(filename);
        
        if strcmp(extension,'.shp')
            
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
    txt = sprintf('Existing features define the projection for this session (ellipsoid: %s, UTM zone: %s), which will be used for files to be loaded. If you want to use the files'' natural projection, delete the features first.', disp_config.MET_ellips, disp_config.MET_tmproj);
    warning(txt);

    % all good? save/overwrite features into main figure
    setappdata(main_figure,'features',features);

end
                
% trigger an update of the feature list tab
update_feature_list_tab(main_figure);

end

%%
% Callback when table is edited
%
function edit_features_callback(src,evt,main_figure)

features = getappdata(main_figure,'features');

if isempty(features)
    return;
end

if isempty(evt.Indices)
    selected_features = {};
else
    selected_features = src.Data(evt.Indices(:,1),end);
    idx_data = evt.Indices(:,2);
end

nData = evt.NewData;

idx_feature = contains({features(:).Unique_ID},selected_features);

switch src.ColumnName{idx_data}
    case 'Class'
        features(idx_feature).Class = nData;
    case 'Description'
        features(idx_feature).Description = nData;
    case 'Min depth'
        if isnan(nData) || nData > features(idx_feature).Depth_max
            src.Data(evt.Indices(:,1),evt.Indices(:,2)) = {evt.PreviousData};
        else
            features(idx_feature).Depth_min = nData;
        end
    case 'Max depth'
        if isnan(nData) || nData < features(idx_feature).Depth_min
            src.Data(evt.Indices(:,1),evt.Indices(:,2)) = {evt.PreviousData};
        else
            features(idx_feature).Depth_max = nData;
        end
end

features(idx_feature).feature_to_shapefile(fullfile(whereisroot,'feature_files'));

setappdata(main_figure,'features',features);

display_features(main_figure,selected_features,[]);

% trigger a callback to display the selected feature as active
activate_features_callback(src,evt,main_figure)

end

%%
% Callback when element in table is selected
%
function activate_features_callback(src,evt,main_figure)

if isempty(evt.Indices)
    selected_features = {};
else
    selected_features = src.Data(evt.Indices(:,1),end);
end

disp_config = getappdata(main_figure,'disp_config');

disp_config.Act_features = selected_features;

end


%%
% Callback when calling for exporting selected features
%
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
file_tab_comp = getappdata(main_figure,'file_tab');
path_ori = get(file_tab_comp.path_box,'string');
folder_name = uigetdir(path_ori,'Select folder for features to export');

% features to export
features_id = {features(:).Unique_ID};
idx_feature_to_export = ismember(features_id,IDs);
idx_exp = find(idx_feature_to_export);

fData_tot = getappdata(main_figure,'fData');
table_out=[];
for ii = 1:numel(idx_exp)
    
    output_file = fullfile(folder_name,[sprintf('%s_%i_%s',features(idx_exp(ii)).Class,features(idx_exp(ii)).ID,features(idx_exp(ii)).Description) '.shp']);

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

function [idx_pings,bot_depth]=interesect_feature_with_lines(feature,fData)
idx_pings=[];
bot_depth=0;
[vert_poly,~,~]=poly_vertices_from_fData(fData,[],[]);
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

function delete_features_callback(~,~,main_figure,IDs)

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

features_id = {features(:).Unique_ID};

idx_rem = ismember(features_id,IDs);

shp_files = dir(fullfile(whereisroot,'feature_files'));

idx_f_to_rem = contains({shp_files(:).name},features_id(idx_rem));

files_to_rem = cellfun(@(x) fullfile(whereisroot,'feature_files',x),{shp_files(idx_f_to_rem).name},'un',0);

cellfun(@delete,files_to_rem);

features(idx_rem) = [];

setappdata(main_figure,'features',features);

update_feature_list_tab(main_figure);

display_features(main_figure,{},[]);

disp_config.Act_features = {};

end
