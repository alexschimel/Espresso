function initialize_display(main_figure)

map_panel=uitabgroup(main_figure,'Position',[0.3 .05 0.7 .95]);
options_panel=uitabgroup(main_figure,'Position',[0 .525 0.3 .475]);
wc_panel=uitabgroup(main_figure,'Position',[0 .05 0.3 .475]);
infos_panel=uitabgroup(main_figure,'Position',[0 0 1 .05]);

setappdata(main_figure,'map_panel',map_panel);
setappdata(main_figure,'options_panel',options_panel);
setappdata(main_figure,'wc_panel',wc_panel);
setappdata(main_figure,'infos_panel',infos_panel);

create_menu(main_figure);

obj_enable=findobj(main_figure,'Enable','on','-not','Type','uimenu');
set(obj_enable,'Enable','off');
centerfig(main_figure);
set(main_figure,'Visible','on');
drawnow;
