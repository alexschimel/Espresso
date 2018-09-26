function listenCmap(src,evt,main_figure)

disp_config = getappdata(main_figure,'disp_config');
[cmap,col_ax,col_lab,col_grid,col_bot,col_txt] = init_cmap(disp_config.Cmap);

map_tab_comp = getappdata(main_figure,'Map_tab');
wc_tab_comp = getappdata(main_figure,'wc_tab');

colormap(map_tab_comp.map_axes,cmap);
colormap(wc_tab_comp.wc_axes,cmap);

end