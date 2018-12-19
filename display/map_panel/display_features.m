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
function display_features(main_figure,IDs)

if ~iscell(IDs)
    IDs = {};
end

disp_config = getappdata(main_figure,'disp_config');

map_tab_comp = getappdata(main_figure,'Map_tab');
features = getappdata(main_figure,'features');

if ~isempty(features)
    id_features = {features(:).Unique_ID};
else
    id_features = {};
end

ah = map_tab_comp.map_axes;

features_h = findobj(ah,{'tag','feature_tmp'});

delete(features_h);

features_h = findobj(ah,{'tag','feature','-or','tag','feature_text'});

if~isempty(features_h)
    id_disp = get(features_h,'UserData');
    id_rem = ~ismember(id_disp,id_features)|ismember(id_disp,IDs);
    delete(features_h(id_rem));
    features_h(id_rem) = [];
end

if~isempty(features_h)
    id_disp = get(features_h,'UserData');
else
    id_disp = {};
end

%id_features(ismember(id_features,id_disp)) = [];
idx_add = id_features(~contains(id_features,id_disp));
idx_act = ismember(id_features,disp_config.Act_features);

col = cell(1,numel(idx_act));
col(idx_act) = {'r'};
col(~idx_act) = {[0.1 0.1 0.1]};

for id = 1:numel(idx_add)
    if ~ismember(idx_add{id},id_disp)
        idf = find(strcmp(id_features,idx_add{id}));
        [h_p,h_t] = features(idf).draw_feature(ah,col{id});
    end
end

end