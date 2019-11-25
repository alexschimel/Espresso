
%% Function
function grab_vert_lim_cback(src,evt,main_figure)

fData_tot = getappdata(main_figure,'fData');

if isempty(fData_tot)
    return;
end

disp_config = getappdata(main_figure,'disp_config');
display_tab_comp = getappdata(main_figure,'display_tab');

IDs=cellfun(@(c) c.ID,fData_tot);

if ~ismember(disp_config.Fdata_ID , IDs)
    return;
end

fData = fData_tot{disp_config.Fdata_ID==IDs};

ah=display_tab_comp.d_lim_ax;

d_line_max_val=display_tab_comp.d_line_max.Value;
d_line_min_val=display_tab_comp.d_line_min.Value;
current_fig = gcf;
y_patch=display_tab_comp.d_lim_patch.YData;

d_max=nanmax(fData.X_BP_bottomHeight(:));
d_min=nanmin(fData.X_BP_bottomHeight(:));

if strcmp(current_fig.SelectionType,'normal')
    
    replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2,'interaction_fcn',@wbmcb,'Pointer','fleur');
    replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',2,'interaction_fcn',@wbucb);
    
end

    function wbmcb(~,~)
        
        pt = ah.CurrentPoint;
        ip=pt(1,2);
        
        switch src.Tag
            case 'd_line_max'
                if ip<=1&&ip>d_line_min_val
                    display_tab_comp.d_line_max.Value=ip;
                    y_patch(2:3)=ip;
                    display_tab_comp.d_line_max.Label=sprintf('%.1fm',d_min+(d_max-d_min)*ip);
                end
            case 'd_line_min'
                if ip>=0&&ip<d_line_max_val
                    display_tab_comp.d_line_min.Value=ip;
                    y_patch([1 4])=ip;
                    display_tab_comp.d_line_min.Label=sprintf('%.1fm',d_min+(d_max-d_min)*ip);
                end
        end
        display_tab_comp.d_lim_patch.YData=y_patch;
    end

    function wbucb(~,~)
        
        replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2);
        replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',2);
        
        update_map_tab(main_figure,1);
    end
end