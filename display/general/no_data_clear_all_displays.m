function no_data_clear_all_displays(main_figure)
%NO_DATA_CLEAR_ALL_DISPLAYS  Clear all displays in Espresso
%
%   See also ESPRESSO.

%   Copyright 2017-2021 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

% clear ping swathe line on map
map_tab_comp = getappdata(main_figure,'Map_tab');
set(map_tab_comp.ping_swathe,'XData',nan,'YData',nan);

% clear swath view
wc_tab_comp  = getappdata(main_figure,'wc_tab');
set(wc_tab_comp.wc_gh,'XData',[], 'YData',[],'ZData',[], 'CData',[],'AlphaData',[]);
set(wc_tab_comp.ac_gh,'XData',[],'YData',[]);
set(wc_tab_comp.bot_gh,'XData',[],'YData',[]);
title(wc_tab_comp.wc_axes,'');

% clear stacked view
stacked_wc_tab_comp  = getappdata(main_figure,'stacked_wc_tab');
set(stacked_wc_tab_comp.wc_gh,'XData',[], 'YData',[],'ZData',[], 'CData',[],'AlphaData',[]);
set(stacked_wc_tab_comp.ping_gh,'XData',[],'YData',[]);
title(stacked_wc_tab_comp.wc_axes,'');



