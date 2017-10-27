function listenCax(src,evt,main_figure)

disp_config=getappdata(main_figure,'disp_config');

switch src.Name
    case {'Cax_wc_int' 'Cax_bathy' 'Cax_bs'}
        update_map_tab(main_figure,0);
    case 'Cax_wc'        
        wc_tab_comp=getappdata(main_figure,'wc_tab');
        caxis(wc_tab_comp.wc_axes,disp_config.Cax_wc);        
        alphadata=get(wc_tab_comp.wc_gh,'CData')>=disp_config.Cax_wc(1);
        set(wc_tab_comp.wc_gh,'AlphaData',alphadata);
end

end