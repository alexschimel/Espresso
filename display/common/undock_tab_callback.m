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
function undock_tab_callback(~,~,main_figure,tab,dest)

switch tab
    case 'wc'
        
        wc_tab_comp = getappdata(main_figure,'wc_tab');
        tab_h = wc_tab_comp.wc_tab;
        tt = 'Water Column';
        
    case 'stacked_wc'
        
        stacked_wc_tab_comp = getappdata(main_figure,'stacked_wc_tab');
        tab_h = stacked_wc_tab_comp.wc_tab;
        tt = 'Stacked Water Column';
        
    case 'feature_list'
        
        feature_list_tab_comp = getappdata(main_figure,'feature_list_tab');
        tab_h = feature_list_tab_comp.feature_list_tab;
        tt = 'Feature list';
        
end

if~isvalid(tab_h)
    return;
end

delete(tab_h);

switch dest
    case {'wc_tab','stacked_wc_tab','feature_list_tab'}
        
        dest_fig = getappdata(main_figure,'wc_panel');
        
    case 'new_fig'
        
        size_max  =  get(0, 'MonitorPositions');
        pos_fig = [size_max(1,1)+size_max(1,3)*0.2 size_max(1,2)+size_max(1,4)*0.2 size_max(1,3)*0.6 size_max(1,4)*0.6];
        dest_fig = figure(...
            'Units','pixels',...
            'Position',pos_fig,...
            'Name',tt,...
            'Resize','on',...
            'Color','White',...
            'MenuBar','none',...
            'Toolbar','none',...
            'CloseRequestFcn',{@close_tab,main_figure},...
            'Tag',tab);
        set_icon_espresso(dest_fig)
        ext_figs = getappdata(main_figure,'ext_figs');
        ext_figs = [ext_figs dest_fig];
        setappdata(main_figure,'ext_figs',ext_figs);
        centerfig(dest_fig);
        
end

switch tab
    case 'wc'
        load_wc_tab(main_figure,dest_fig);
        display_features(main_figure,{},{'wc_tab'})
    case 'stacked_wc'
        load_stacked_wc_tab(main_figure,dest_fig);
        display_features(main_figure,{},{'stacked_wc_tab'})
    case 'feature_list'
        load_feature_list_tab(main_figure,dest_fig);
end

end

function close_tab(src,~,main_figure)

tag = src.Tag;
delete(src);
dest_fig = getappdata(main_figure,'swath_panel');

switch tag
    case 'wc'
        load_wc_tab(main_figure,dest_fig);
        display_features(main_figure,{},{'wc_tab'})
    case 'stacked_wc'
        load_stacked_wc_tab(main_figure,dest_fig);
        display_features(main_figure,{},{'stacked_wc_tab'})
    case 'feature_list'
        load_feature_list_tab(main_figure,dest_fig);
end

end