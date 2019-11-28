
%% Function
function grab_vert_lim_cback(src,~,main_figure,ref)

fData_tot = getappdata(main_figure,'fData');

if isempty(fData_tot)
    return;
end

% disp_config = getappdata(main_figure,'disp_config');
display_tab_comp = getappdata(main_figure,'display_tab');

depth_min=nan;
for ui=1:numel(fData_tot)
    depth_min =  nanmin(depth_min,nanmin(fData_tot{ui}.X_BP_bottomHeight(:)));
end

current_fig = gcf;

switch ref
    case'bot'
        ah=display_tab_comp.d_lim_bot_ax;
        d_min=0;
        d_max=abs(depth_min);
        d_line_max_h=display_tab_comp.d_line_bot_max;
        d_line_min_h=display_tab_comp.d_line_bot_min;
        d_patch_h=display_tab_comp.d_lim_bot_patch;
        d_line_mean_h=display_tab_comp.d_line_bot_mean;
    case 'sonar'
        ah=display_tab_comp.d_lim_ax;
        d_max=0;
        d_min=depth_min;
        d_line_max_h=display_tab_comp.d_line_max;
        d_line_min_h=display_tab_comp.d_line_min;
        d_patch_h=display_tab_comp.d_lim_patch;
        d_line_mean_h=display_tab_comp.d_line_mean;
end

d_line_max_val=d_line_max_h.Value;
d_line_min_val=d_line_min_h.Value;

if strcmp(current_fig.SelectionType,'normal')
    
    replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2,'interaction_fcn',@wbmcb,'Pointer','fleur');
    replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',2,'interaction_fcn',@wbucb);
    
end

    function wbmcb(~,~)
        
        pt = ah.CurrentPoint;
        ip=pt(1,2);
        d_line_max_val=d_line_max_h.Value;
        d_line_min_val=d_line_min_h.Value;
        
        switch src.Tag
            case 'd_line_max'
                if ip<=1&&ip>d_line_min_val
                    d_line_max_h.Value=ip;
                    d_line_max_h.Label=sprintf('%.1fm',d_min+(d_max-d_min)*ip);
                end
            case 'd_line_min'
                if ip>=0&&ip<d_line_max_val
                    d_line_min_h.Value=ip;
                    d_line_min_h.Label=sprintf('%.1fm',d_min+(d_max-d_min)*ip);
                end
            case 'd_line_mean'
                dr=d_line_max_val-d_line_min_val;
                if ip+dr/2<=1&&ip-dr/2>0
                    d_line_max_h.Value=ip+dr/2;
                    d_line_min_h.Value=ip-dr/2;
                end
        end
        
        y_patch=[d_line_min_h.Value d_line_max_h.Value d_line_max_h.Value d_line_min_h.Value];
        d_patch_h.YData=y_patch;
        d_line_max_h.Label=sprintf('%.1fm',d_min+(d_max-d_min)*d_line_max_h.Value);
        d_line_min_h.Label=sprintf('%.1fm',d_min+(d_max-d_min)*d_line_min_h.Value);
        d_line_mean_h.Value=(d_line_min_h.Value+d_line_max_h.Value)/2;
    end

    function wbucb(~,~)
        
        replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2,'Pointer','arrow');
        replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',2);
        
        fdata_tab_comp = getappdata(main_figure,'fdata_tab');
        
        selected_idx = find([fdata_tab_comp.table.Data{:,end-1}]);
        if ~isempty(selected_idx)
            update_map_tab(main_figure,1,0,0,selected_idx);
        end
    end
end