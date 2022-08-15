function listenCmap(src,evt,main_figure)
%LISTENCMAP  Callback function when Cmap is modified
%
%   See also ESPRESSO.

%   Authors: Yoann Ladroit (NIWA, yoann.ladroit@niwa.co.nz) and Alex
%   Schimel (NIWA, alexandre.schimel@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

disp_config = getappdata(main_figure,'disp_config');
[cmap,col_ax,col_lab,col_grid,col_bot,col_txt] = init_cmap(disp_config.Cmap);

map_tab_comp = getappdata(main_figure,'Map_tab');
wc_tab_comp = getappdata(main_figure,'wc_tab');
stacked_wc_tab_comp  = getappdata(main_figure,'stacked_wc_tab');

switch disp_config.Var_disp
    case 'wc_int'
        colormap(map_tab_comp.map_axes,cmap);
        colormap(wc_tab_comp.wc_axes,cmap);
        colormap(stacked_wc_tab_comp.wc_axes,cmap);
    otherwise
        colormap(map_tab_comp.map_axes,cmap);
end

end