%% load_info_panel.m
%
% Creates info panel (bottom panel) in Espresso
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
function load_info_panel(main_figure)

if isappdata(main_figure,'info_panel')
    % if info panel already exist, grab it and clean it
    info_panel_comp = getappdata(main_figure,'info_panel');
    delete(get(info_panel_comp.info_panel,'children'));
else
    % if info panel does not exist yet (initialization), create it
    info_panel_comp.info_panel = uipanel(main_figure,'Position',[0 0 1 0.05],'BackgroundColor',[1 1 1],'tag','info_panel');
end

ax = axes(info_panel_comp.info_panel,'units','normalized','position',[0 0 1 1],'visible','off','Xlim',[0 1],'YLim',[0 1]);

info_panel_comp.pos_disp = text(ax,'Position',[0.2 0.4]);
info_panel_comp.info_disp = text(ax,'Position',[0.6 0.4]);

% save into main figure app data
setappdata(main_figure,'info_panel',info_panel_comp);

end