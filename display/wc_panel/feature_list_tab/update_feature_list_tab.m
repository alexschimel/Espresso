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
function update_feature_list_tab(main_figure)

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