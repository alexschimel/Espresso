function update_feature_list_tab(main_figure)
%UPDATE_FEATURE_LIST_TAB  Updates feature_list tab in Espresso Swath panel
%
%   See also CREATE_FEATURE_LIST_TAB, INITIALIZE_DISPLAY, ESPRESSO.

%   Copyright 2017-2021 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

features = getappdata(main_figure,'features');

feature_list_tab_comp = getappdata(main_figure,'feature_list_tab');

if isempty(features)
    ID_features = {};
else
    ID_features = {features(:).Unique_ID};
end

idx_uid = strcmpi(feature_list_tab_comp.table.ColumnName,'Unique_ID');

if ~isempty(feature_list_tab_comp.table.Data)
    ID_features_table = feature_list_tab_comp.table.Data(:,idx_uid);
    idx_rem = ~ismember(ID_features_table,ID_features);
    feature_list_tab_comp.table.Data(idx_rem,:) = [];
else
    ID_features_table = {};
end

idx_add = find(~ismember(ID_features,ID_features_table));

if isempty(idx_add)
    return;
end

new_data = cell(numel(idx_add),numel(feature_list_tab_comp.table.ColumnName));

new_data(:,strcmpi(feature_list_tab_comp.table.ColumnName,'ID')) = num2cell([features(idx_add).ID]);
new_data(:,strcmpi(feature_list_tab_comp.table.ColumnName,'Description')) = {features(idx_add).Description};
new_data(:,strcmpi(feature_list_tab_comp.table.ColumnName,'Class')) = {features(idx_add).Class};

idx_polygon = false(1,numel(idx_add));

for ii = 1:numel(idx_add)
    idx_polygon(ii) = ~isempty(features(idx_add(ii)).Polygon);
end

idx_point=~idx_polygon;

new_data(idx_polygon,strcmpi(feature_list_tab_comp.table.ColumnName,'Type')) = {'Polygon'};
new_data(idx_point,strcmpi(feature_list_tab_comp.table.ColumnName,'Type')) = {'Point'};
new_data(:,strcmpi(feature_list_tab_comp.table.ColumnName,'Min depth')) = num2cell([features(idx_add).Depth_min]);
new_data(:,strcmpi(feature_list_tab_comp.table.ColumnName,'Max depth')) = num2cell([features(idx_add).Depth_max]);
new_data(:,strcmpi(feature_list_tab_comp.table.ColumnName,'Unique_ID')) = {features(idx_add).Unique_ID};

feature_list_tab_comp.table.Data = [feature_list_tab_comp.table.Data;new_data];

end