function listenCax(src,~,main_figure)

disp_config = getappdata(main_figure,'disp_config');

switch src.Name
    
    case {'Cax_wc_int' 'Cax_bathy' 'Cax_bs'}
        
        update_map_tab(main_figure,0,0,[]);
        
    case 'Cax_wc'
        
        wc_tab_comp = getappdata(main_figure,'wc_tab');
        stacked_wc_tab_comp = getappdata(main_figure,'stacked_wc_tab');
        wc_str = wc_tab_comp.data_disp.String;
        str_disp = wc_str{wc_tab_comp.data_disp.Value};
        
        switch str_disp
            
            case 'Phase'
                
                caxis(wc_tab_comp.wc_axes,[-180 180]);
                alphadata = abs(get(wc_tab_comp.wc_gh,'CData'))>0;
                set(wc_tab_comp.wc_gh,'AlphaData',alphadata);
                caxis(stacked_wc_tab_comp.wc_axes,[-180 180]);
                 stacked_alphadata = abs(get(stacked_wc_tab_comp.wc_gh,'CData'))>0;
                set(stacked_wc_tab_comp.wc_gh,'AlphaData',stacked_alphadata);
                
            otherwise
                
                caxis(wc_tab_comp.wc_axes,disp_config.Cax_wc);
                alphadata = get(wc_tab_comp.wc_gh,'CData') >= disp_config.Cax_wc(1);
                set(wc_tab_comp.wc_gh,'AlphaData',alphadata);
                caxis(stacked_wc_tab_comp.wc_axes,disp_config.Cax_wc);
                                alphadata = get(stacked_wc_tab_comp.wc_gh,'CData') >= disp_config.Cax_wc(1);
                set(stacked_wc_tab_comp.wc_gh,'AlphaData',alphadata);
                
        end
        
end

end