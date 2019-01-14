%% initialize_display.m
%
% Initialize display of Espresso main figure
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |input_variable_1|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% * |output_variable_1|: TODO: write description and info on variable
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-10-25: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help Espresso.m| for copyright information.

%% Function
function initialize_display(main_figure)

%% CONTROL PANEL

% create panel
control_panel = uitabgroup(main_figure,'Position',[0 0.525 0.3 .475]);
setappdata(main_figure,'control_panel',control_panel);

% create tabs in panel
load_files_tab(main_figure,control_panel);
load_fdata_tab(main_figure,control_panel);
load_wc_proc_tab(main_figure,control_panel);
load_mosaic_tab(main_figure,control_panel);


%% SWATHE PANEL

% create panel
swath_panel = uitabgroup(main_figure,'Position',[0 0.05  0.3 .475]);
setappdata(main_figure,'swath_panel',swath_panel);

% create tabs in panel
load_wc_tab(main_figure,swath_panel);
load_stacked_wc_tab(main_figure,swath_panel);
load_feature_list_tab(main_figure,swath_panel);


%% MAP PANEL

% create panel
map_panel = uitabgroup(main_figure,'Position',[0.3 0.05 0.7 0.95]);
setappdata(main_figure,'map_panel',map_panel);

% create tabs in panel
load_map_tab(main_figure,map_panel);


%% INFO PANEL (bottom panel)

% create panel
load_info_panel(main_figure);


%% obsolete: top menu
% create_menu(main_figure);
% obj_enable = findobj(main_figure,'Enable','on','-not','Type','uimenu');
% set(obj_enable,'Enable','off');

%% FINISHING UP
% center main window on screen and make visible

centerfig(main_figure);
set(main_figure,'Visible','on');
drawnow;

end