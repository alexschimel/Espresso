function callback_press_process_button(~,~,main_figure)
%CALLBACK_PRESS_PROCESS_BUTTON  Called when pressing the process button
%
%   See also ESPRESSO.

%   Authors: Yoann Ladroit (NIWA, yoann.ladroit@niwa.co.nz) and Alex
%   Schimel (NIWA, alexandre.schimel@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021


% get data from main figure
fData_tot = getappdata(main_figure,'fData');
if isempty(fData_tot)
    return;
end

% get needed info from loaded lines tab
fdata_tab_comp = getappdata(main_figure,'fdata_tab');
idx_fData = find(cell2mat(fdata_tab_comp.table.Data(:,end-1)));
if isempty(idx_fData)
    fprintf('No lines are selected. Process aborted.\n');
    return;
end

% get needed info from data processing tab

wc_proc_tab_comp = getappdata(main_figure,'wc_proc_tab');

% main procession flag
procpar.processing_flag     = wc_proc_tab_comp.proc_bool.Value;

% bottom filter
procpar.bottomfilter_flag   = wc_proc_tab_comp.bot_filtering.Value;

% grid bathy/BS
procpar.gridbathyBS_flag    = wc_proc_tab_comp.bs_grid_bool.Value;
procpar.gridbathyBS_res     = str2double(get(wc_proc_tab_comp.bs_grid_res,'String'));

% masking parameters
procpar.masking_flag       = wc_proc_tab_comp.masking.Value;
procpar.mask_angle         = str2double(get(wc_proc_tab_comp.angle_mask,'String'));
procpar.mask_closerange    = str2double(get(wc_proc_tab_comp.r_min,'String'));
procpar.mask_bottomrange   = -str2double(get(wc_proc_tab_comp.r_bot,'String')); % NOTE inverting sign here.
procpar.mask_ping          = str2double(get(wc_proc_tab_comp.mask_badpings,'String'));
procpar.mask_minslantrange = wc_proc_tab_comp.mask_minslantrange.Value;

% radiometric correction parameters
procpar.radiomcorr_flag     = wc_proc_tab_comp.radiomcorr.Value;
procpar.radiomcorr_output   = wc_proc_tab_comp.radiomcorr_output.String{wc_proc_tab_comp.radiomcorr_output.Value};

% sidelobe filtering parameters
procpar.sidelobefilter_flag = wc_proc_tab_comp.sidelobe.Value;
procpar.badpings_flag       = str2double(wc_proc_tab_comp.mask_badpings.String)<100;

% main water-column gridding flag
procpar.WCgridding_flag     = wc_proc_tab_comp.grid_bool.Value;

% gridding parameters
procpar.grid_horz_res = str2double(get(wc_proc_tab_comp.grid_val,'String'));
procpar.grid_vert_res = str2double(get(wc_proc_tab_comp.vert_grid_val,'String'));
procpar.data_type     = wc_proc_tab_comp.data_type.String{wc_proc_tab_comp.data_type.Value};
procpar.grdlim_mode   = wc_proc_tab_comp.grdlim_mode.String{wc_proc_tab_comp.grdlim_mode.Value};
procpar.grdlim_var    = wc_proc_tab_comp.grdlim_var.String{wc_proc_tab_comp.grdlim_var.Value};
if wc_proc_tab_comp.grid_2d.Value>0
    procpar.grid_type = '2D';
else
    procpar.grid_type = '3D';
end
procpar.grdlim_mindist = str2double(get(wc_proc_tab_comp.grdlim_mindist,'String'));
procpar.grdlim_maxdist = str2double(get(wc_proc_tab_comp.grdlim_maxdist,'String'));
procpar.dr_sub = str2double(wc_proc_tab_comp.dr.String);
procpar.db_sub = str2double(wc_proc_tab_comp.db.String);


% initialize flag to update stacked view
update_stackview_flag = 0;

% part 1 - processing
if procpar.processing_flag
    
    % bottom filtering
    if procpar.bottomfilter_flag
        fData_tot = filter_bottomdetect(fData_tot, idx_fData);
    end
    
    % data processing
    if procpar.masking_flag || procpar.sidelobefilter_flag || procpar.badpings_flag || procpar.radiomcorr_flag
        
        % this includes saving fDatas on the drive
        fData_tot = process_watercolumn(fData_tot, idx_fData, procpar);
        update_stackview_flag = 1;
        
    end
    
    % bathy/BS gridding
    if procpar.gridbathyBS_flag
        fData_tot = gridbathyBS(fData_tot, idx_fData, procpar);
    end
    
    % update the WC view to "Processed"
    display_tab_comp = getappdata(main_figure,'display_tab');
    wc_tab_strings = display_tab_comp.data_disp.String;
    [~,idx] = ismember('Processed',wc_tab_strings);
    display_tab_comp.data_disp.Value = idx;
    
    % update stacked view
    disp_config = getappdata(main_figure,'disp_config');
    switch disp_config.StackAngularMode
        case 'range'
            ylab = 'Range(m)';
        case 'depth'
            ylab = 'Depth (m)';
    end
    stacked_wc_tab_comp = getappdata(main_figure,'stacked_wc_tab');
    if ~strcmpi(ylab,stacked_wc_tab_comp.wc_axes.YLabel.String)
        stacked_wc_tab_comp.wc_axes.YLabel.String = ylab;
    end
    
end

% part 2 - gridding
if procpar.WCgridding_flag
    % this includes saving fDatas on the drive
    fData_tot = grid_watercolumn(fData_tot, idx_fData, procpar);
end

% save fData_tot in figure
setappdata(main_figure,'fData',fData_tot);
disp_config.Fdata_ID = fData_tot{idx_fData(end)}.ID;

% update map with new grid, zoom on changed lines
update_swathview_flag = update_map_tab(main_figure,1,0,1,idx_fData);

% update WC view and stacked view
if update_swathview_flag || update_stackview_flag
    update_wc_tab(main_figure);
    update_stacked_wc_tab(main_figure,update_stackview_flag);
end

end
