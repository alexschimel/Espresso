function listenCax(src,~,main_figure)
%LISTENCAX  Callback function when a Cax is modified
%
%   See also ESPRESSO.

%   Copyright 2017-2021 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

% get data
fData_tot = getappdata(main_figure,'fData');

if isempty(fData_tot)
    return;
end

disp_config = getappdata(main_figure,'disp_config');

IDs = cellfun(@(c) c.ID,fData_tot);

if ~ismember(disp_config.Fdata_ID , IDs)
    disp_config.Fdata_ID = IDs(1);
    disp_config.Iping = 1;
    return;
end

cax = disp_config.get_cax();

switch src.Name
    
    case {'Cax_wc_int' 'Cax_bathy' 'Cax_bs'}
        % colour axis for map (whether variable shown is integrated water
        % column, bathymtry, or backscatter).
        
        % working per file...
        for ui = 1:numel(fData_tot)
            
            fData_tot_tmp = fData_tot{ui};
            map_tab_comp = getappdata(main_figure,'Map_tab');
            ax = map_tab_comp.map_axes;
            
            tag_id_wc = num2str(fData_tot_tmp.ID,'%.0f_wc');
            obj_wc = findobj(ax,'Tag',tag_id_wc);
            
            data = get(obj_wc,'CData');
            
            switch disp_config.Var_disp
                case 'wc_int'
                    if iscell(data)
                        for ic = 1:numel(data)
                            set(obj_wc,'alphadata',data{ic} > cax(1));
                        end
                    else
                        set(obj_wc,'alphadata',data > cax(1));
                    end
                case {'bathy' 'bs'}
                    if iscell(data)
                        for ic = 1:numel(data)
                            set(obj_wc,'alphadata',~isnan(data{ic}));
                        end
                    else
                        set(obj_wc,'alphadata',~isnan(data));
                    end
            end
        end
        
        caxis(ax,cax);
        
    case 'Cax_wc'
        % colour axis for WC view and stacked view
        
        wc_tab_comp = getappdata(main_figure,'wc_tab');
        display_tab_comp = getappdata(main_figure,'display_tab');
        wc_str = display_tab_comp.data_disp.String;
        str_disp = wc_str{display_tab_comp.data_disp.Value};
        
        switch str_disp
            
            case 'Phase'
                
                % update caxis on WC view
                caxis(wc_tab_comp.wc_axes,[-180 180]);
                alphadata = abs(get(wc_tab_comp.wc_gh,'CData'))>0;
                set(wc_tab_comp.wc_gh,'AlphaData',alphadata);
                
                % update caxis on stacked view
                stacked_wc_tab_comp = getappdata(main_figure,'stacked_wc_tab');
                caxis(stacked_wc_tab_comp.wc_axes,[-180 180]);
                stacked_alphadata = abs(get(stacked_wc_tab_comp.wc_gh,'CData'))>0;
                set(stacked_wc_tab_comp.wc_gh,'AlphaData',stacked_alphadata);
                
            otherwise
                % Original or Processed
                
                % update caxis on WC view
                caxis(wc_tab_comp.wc_axes,disp_config.Cax_wc);
                alphadata = get(wc_tab_comp.wc_gh,'CData') >= disp_config.Cax_wc(1);
                set(wc_tab_comp.wc_gh,'AlphaData',alphadata);
                
                % update caxis on stacked view
                stacked_wc_tab_comp = getappdata(main_figure,'stacked_wc_tab');
                caxis(stacked_wc_tab_comp.wc_axes,disp_config.Cax_wc);
                alphadata = get(stacked_wc_tab_comp.wc_gh,'CData') >= disp_config.Cax_wc(1);
                set(stacked_wc_tab_comp.wc_gh,'AlphaData',alphadata);
                
        end
        
end

end