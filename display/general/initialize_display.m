function initialize_display(main_figure)
%INITIALIZE_DISPLAY  Create the contents of Espresso main figure
%
%   See also ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 11-11-2021


%% FIGURE DIMENSIONS AND POSITION

% primary monitor's dimensions
monitorPositions = get(0, 'MonitorPositions');
if size(monitorPositions,1)>1
    iPrimaryDisplay = (monitorPositions(:,1)==1) & (monitorPositions(:,2)==1);
    monitorPositions = monitorPositions(iPrimaryDisplay,:);
end

% Espresso's window size
Espresso_window_position = [monitorPositions(1,1), ... % bottom-left corner X
    monitorPositions(1,2), ...     % bottom-left corner Y
    round(monitorPositions(1,3).*(3/4)), ... % width
    round(monitorPositions(1,4).*(3/4))];    % height
set(main_figure,'Position',Espresso_window_position);
centerfig(main_figure);

%% CONTROL PANEL (left-top)

% create panel
control_panel = uitabgroup(main_figure,'Position',[0 0.525 0.3 .475]);
setappdata(main_figure,'control_panel',control_panel);

% create tabs in panel
create_datafiles_tab(main_figure,control_panel);
create_loadedlines_tab(main_figure,control_panel);
create_wc_proc_tab(main_figure,control_panel);
create_display_tab(main_figure,control_panel);
create_mosaic_tab(main_figure,control_panel);


%% SWATHE PANEL (left-bottom)

% create panel
swath_panel = uitabgroup(main_figure,'Position',[0 0.05  0.3 .475]);
setappdata(main_figure,'swath_panel',swath_panel);

% create tabs in panel
create_wc_tab(main_figure,swath_panel);
create_stacked_wc_tab(main_figure,swath_panel);
create_feature_list_tab(main_figure,swath_panel);


%% MAP PANEL (right)

% create panel
map_panel = uitabgroup(main_figure,'Position',[0.3 0.05 0.7 0.95]);
setappdata(main_figure,'map_panel',map_panel);

% create tabs in panel
create_map_tab(main_figure,map_panel);


%% INFO PANEL (bottom panel)

% create panel
create_info_panel(main_figure);


%% TOP MENU -- OBSOLETE
% create_menu(main_figure);
% obj_enable = findobj(main_figure,'Enable','on','-not','Type','uimenu');
% set(obj_enable,'Enable','off');


%% FINISHING UP

% make visible
set(main_figure,'Visible','on');
drawnow;

end