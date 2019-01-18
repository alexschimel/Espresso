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
function listenAct_features(~,~,main_figure)

% get disp_config for active features
disp_config = getappdata(main_figure,'disp_config');

% get both map and stacked view axes
stacked_wc_tab_comp  = getappdata(main_figure,'stacked_wc_tab');
map_tab_comp = getappdata(main_figure,'Map_tab');
ah_tot = [map_tab_comp.map_axes stacked_wc_tab_comp.wc_axes];

for iax = 1:numel(ah_tot)
    
    ax = ah_tot(iax);
    
    % get features on axes and their labels
    features_h      = findobj(ax,{'tag','feature'});
    features_text_h = findobj(ax,{'tag','feature_text'});
    
    if isempty(features_h)
        return;
    end
    
    % colours: first for inactive, second for active
    col = {[0.1 0.1 0.1],'r'};
    
    for ii = 1:numel(features_h)
        
        % feature
        isAct = ismember(features_h(ii).UserData,disp_config.Act_features);
        switch features_h(ii).Type
            case 'line'
                features_h(ii).Color = col{isAct+1};
                features_h(ii).MarkerFaceColor = col{isAct+1};
            case 'polygon'
                features_h(ii).EdgeColor = col{isAct+1};
                features_h(ii).FaceColor = col{isAct+1};
        end
        
        % text
        isAct = ismember(features_text_h(ii).UserData,disp_config.Act_features);
        features_text_h(ii).Color = col{isAct+1};
        
    end
end

end