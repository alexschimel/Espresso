function update_display(main_figure)

update_fdata_tab(main_figure);
update_map_tab(main_figure,0,1,[]);
update_wc_tab(main_figure);
enabled_obj = findobj(main_figure,'Enable','off');
set(enabled_obj,'Enable','on');

end