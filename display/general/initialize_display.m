%% initialize_display.m
%
% Initialize display
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

% create the four main panels in main window
map_panel     = uitabgroup(main_figure,'Position',[0.3  .05  0.7 .95]);
options_panel = uitabgroup(main_figure,'Position',[0    .525 0.3 .475]);
wc_panel      = uitabgroup(main_figure,'Position',[0    .05  0.3 .475]);
infos_panel   = uitabgroup(main_figure,'Position',[0   0     1   .05]);

% add panels to appdata
setappdata(main_figure,'map_panel',map_panel);
setappdata(main_figure,'options_panel',options_panel);
setappdata(main_figure,'wc_panel',wc_panel);
setappdata(main_figure,'infos_panel',infos_panel);

load_files_tab(main_figure,options_panel);
load_fdata_tab(main_figure,options_panel);
load_wc_proc_tab(main_figure,options_panel);
load_wc_tab(main_figure,wc_panel);

load_map_tab(main_figure,map_panel);

% create menu in main window
%create_menu(main_figure);

% obj_enable = findobj(main_figure,'Enable','on','-not','Type','uimenu');
% set(obj_enable,'Enable','off');

% center main window and make visible
centerfig(main_figure);
set(main_figure,'Visible','on');
drawnow;

end