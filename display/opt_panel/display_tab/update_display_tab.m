function update_display_tab(main_figure)

fData_tot = getappdata(main_figure,'fData');

if isempty(fData_tot)
    return;
end

disp_config = getappdata(main_figure,'disp_config');

IDs=cellfun(@(c) c.ID,fData_tot);

if ~ismember(disp_config.Fdata_ID , IDs)
    return;
end

display_tab_comp=getappdata(main_figure,'display_tab');

d_max=0;
d_min=nan;

for ui=1:numel(fData_tot)    
    d_min=nanmin(nanmin(fData_tot{ui}.X_BP_bottomHeight(:),d_min));
end

display_tab_comp.d_line_max.Value=1;

display_tab_comp.d_line_max.Label=sprintf('%.1fm',d_max);

display_tab_comp.d_line_min.Value=0;

display_tab_comp.d_line_min.Label=sprintf('%.1fm',d_min);

display_tab_comp.d_line_mean.Value=0.5;

display_tab_comp.d_lim_patch.YData=[0 1 1 0];

end