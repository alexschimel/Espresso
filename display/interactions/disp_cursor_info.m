function disp_cursor_info(~,~,main_figure)
fData_tot=getappdata(main_figure,'fData');
if isempty(fData_tot)
    return;
end
info_panel_comp=getappdata(main_figure,'info_panel');
map_tab_comp=getappdata(main_figure,'Map_tab');

ax=map_tab_comp.map_axes;
cp = ax.CurrentPoint;
x=cp(1,1);
y=cp(1,2);


disp_config=getappdata(main_figure,'disp_config');

zone=disp_config.get_zone();

[lat,lon]=utm2ll(x,y,zone);


[lat_str,lon_str]=latlon2str(lat,lon,'%.3f');

pos_string=sprintf('%s\n%s\n',lat_str,lon_str);

set(info_panel_comp.pos_disp,'string',pos_string);



end