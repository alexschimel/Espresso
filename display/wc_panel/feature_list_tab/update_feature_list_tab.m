function update_feature_list_tab(main_figure)

features=getappdata(main_figure,'features');
feature_list_tab_comp=getappdata(main_figure,'feature_list_tab');

if isempty(features)
    ID_features={};
else
    ID_features={features(:).Unique_ID};
end
idx_uid=strcmpi(feature_list_tab_comp.table.ColumnName,'Unique_ID');

 

if ~isempty(feature_list_tab_comp.table.Data)
    ID_features_table=feature_list_tab_comp.table.Data(:,idx_uid);
    idx_rem=~ismember(ID_features_table,ID_features);
    feature_list_tab_comp.table.Data(idx_rem,:)=[];
else
    ID_features_table={};
end

idx_add=find(~ismember(ID_features,ID_features_table));
if isempty(idx_add)
    return;
end
new_data=cell(numel(idx_add),numel(feature_list_tab_comp.table.ColumnName));

new_data(:,strcmpi(feature_list_tab_comp.table.ColumnName,'ID'))=num2cell([features(idx_add).ID]);
new_data(:,strcmpi(feature_list_tab_comp.table.ColumnName,'Tag'))={features(idx_add).Tag};
new_data(:,strcmpi(feature_list_tab_comp.table.ColumnName,'Type'))={features(idx_add).Type};
idx_polygon=false(1,numel(idx_add));
for i1=1:numel(idx_add)
    idx_polygon(i1)=~isempty(features(idx_add(i1)).Polygon);
end
idx_point=~idx_polygon;
new_data(idx_polygon,strcmpi(feature_list_tab_comp.table.ColumnName,'Shape'))={'Polygon'};
new_data(idx_point,strcmpi(feature_list_tab_comp.table.ColumnName,'Shape'))={'Point'};
new_data(:,strcmpi(feature_list_tab_comp.table.ColumnName,'Depth Min'))=num2cell([features(idx_add).Depth_min]);
new_data(:,strcmpi(feature_list_tab_comp.table.ColumnName,'Depth Max'))=num2cell([features(idx_add).Depth_max]);
new_data(:,strcmpi(feature_list_tab_comp.table.ColumnName,'Unique_ID'))={features(idx_add).Unique_ID};

feature_list_tab_comp.table.Data=[feature_list_tab_comp.table.Data;new_data];





end