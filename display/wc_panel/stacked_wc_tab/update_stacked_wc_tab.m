function update_stacked_wc_tab(main_figure,varargin)
%UPDATE_STACKED_WC_TAB  Updates stacked_wc tab in Espresso Swath panel
%
%   See also CREATE_STACKED_WC_TAB, INITIALIZE_DISPLAY, ESPRESSO.

%   Copyright 2017-2021 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/


%% input parser
p = inputParser;
addOptional(p,'force_update_flag',0);
parse(p,varargin{:});
force_update_flag = p.Results.force_update_flag;
clear p


%% prep

% check if there are data to display
fData_tot = getappdata(main_figure,'fData');
if isempty(fData_tot)
    no_data_clear_all_displays(main_figure);
    return;
end

% get disp_config
disp_config = getappdata(main_figure,'disp_config');
disp_config.cleanup(main_figure);

% exit if not showing water column data
if ~ismember(disp_config.MET_datagramSource, {'WC','AP'})
    return
end

% get fdata to be displayed
fData_tot_IDs = cellfun(@(c) c.ID,fData_tot);
fData = fData_tot{fData_tot_IDs==disp_config.Fdata_ID};

% get ping to be displayed
ip = disp_config.Iping;

% get indices of pings and beams making up the stack window
map_tab_comp = getappdata(main_figure,'Map_tab');
usrdata = get(map_tab_comp.ping_window,'UserData');
iPings = usrdata.idx_pings;
subBeamKeep = usrdata.idx_angles;
usrdata.StackAngularMode = disp_config.StackAngularMode; % add StackAngularMode

% index of the current ping in the stack
ip_sub = nanmax(ip-iPings(1)+1,1);

% get data type to be grabbed
display_tab_comp = getappdata(main_figure,'display_tab');
wc_str = display_tab_comp.data_disp.String;
str_disp = wc_str{display_tab_comp.data_disp.Value};

% if "Processed" was selected but there is no Processed data, or if "Phase"
% was selected and there is no Phase data, switch back to original
if strcmp(str_disp,'Processed') && ~isfield(fData,'X_SBP_WaterColumnProcessed') || ...
        strcmp(str_disp,'Phase') && ~isfield(fData,'AP_SBP_SamplePhase')
    set(display_tab_comp.data_disp,'Value',find(contains(wc_str,'Original')));
    str_disp = 'Original';
end

% check if stacked view needs to be changed (true) or not (false)
stacked_wc_tab_comp = getappdata(main_figure,'stacked_wc_tab');
if ~isfield(stacked_wc_tab_comp.wc_gh.UserData,'idx_pings')
    % fist time setting a stacked view, so yes
    up_stacked_wc_bool = true;
elseif force_update_flag
    % forcing the update, typically after reprocessing, so yes
    up_stacked_wc_bool = true;
else
    % otherwise, update only if we request anything different
    flag_diff_pings = ~isempty(setdiff(iPings,stacked_wc_tab_comp.wc_gh.UserData.idx_pings));
    flag_diff_line = ~(fData.ID==stacked_wc_tab_comp.wc_gh.UserData.ID);
    flag_diff_beams = ~isempty(setxor(find(subBeamKeep),find(stacked_wc_tab_comp.wc_gh.UserData.idx_angles)));
    flag_diff_datatype = ~strcmpi(str_disp,stacked_wc_tab_comp.wc_gh.UserData.str_disp);
    flag_diff_mode = ~strcmpi(disp_config.StackAngularMode,stacked_wc_tab_comp.wc_gh.UserData.StackAngularMode);
    
    up_stacked_wc_bool = flag_diff_pings || flag_diff_line ||  ...
        flag_diff_beams || flag_diff_datatype || flag_diff_mode;
end


if up_stacked_wc_bool
    
    % data type to grab
    datagramSource = CFF_get_datagramSource(fData);
    switch str_disp
        case 'Original'
            fieldN = sprintf('%s_SBP_SampleAmplitudes',datagramSource);
        case 'Processed'
            fieldN = 'X_SBP_WaterColumnProcessed';
        case 'Phase'
            fieldN = sprintf('%s_SBP_SamplePhase',datagramSource);
    end
    
    % create parameters structure for CFF_stack_WCD
    params = struct(); 
    params.dataField = fieldN;
    params.stackMode = disp_config.StackAngularMode;
    params.angleDegLims = disp_config.StackAngularWidth;
    % params.minStackY = 0; % should be default value
    % params.maxStackY = 0; % should be default value
    % params.resDepthStackY = 0; % should be default value
    params.iPingLims = [iPings(1),iPings(end)];
    % params.iBeamLims = [1,inf]; % should be default value
    % params.iSampleLims = [1,inf]; % should be default value
    
    % stack it baby
    [stack,stackX,stackY] = CFF_stack_WCD(fData,params);
    
    % get colour extents
    cax_min = str2double(display_tab_comp.clim_min_wc.String);
    cax_max = str2double(display_tab_comp.clim_max_wc.String);
    cax = [cax_min cax_max];
    
    % alphadata
    switch str_disp
        case {'Original';'Processed'}
            idx_keep_al = stack >= cax(1);
        case 'Phase'
            idx_keep_al = stack ~= 0;
    end
    
    usrdata.str_disp = str_disp;
    
    % update stacked WC data
    set(stacked_wc_tab_comp.wc_gh,...
        'XData',stackX,...
        'YData',stackY,...
        'ZData',zeros(size(stack)),...
        'CData',stack,...
        'AlphaData',idx_keep_al,...
        'Userdata',usrdata);
    
    % Xlim and Ylim. Cropping the nans at top and bottom
    xlim_stacked = ([stackX(1) stackX(end)]);
    if xlim_stacked(1) == xlim_stacked(2)
        % in case only one ping in this view (file with 1 ping)
        xlim_stacked(2) = xlim_stacked(1)+1;
    end
    idx_al_s = find(~isnan(nanmean(stack,2)),1,'first');
    idx_al_e = find(~isnan(nanmean(stack,2)),1,'last');
    if ~isempty(idx_al_s)&&~isempty(idx_al_s)
        ylim_stacked = [stackY(idx_al_s)*0.9 stackY(idx_al_e)*1.1];
        set(stacked_wc_tab_comp.wc_axes,...
            'XLim',xlim_stacked,...
            'Ylim',ylim_stacked,...
            'Layer','top',...
            'UserData',usrdata);
    end
    
    % title
    fname = fData.ALLfilename{1};
    [~,fnamet,~] = fileparts(fname);
    tt = sprintf('File: %s.',fnamet);
    stacked_wc_tab_comp.wc_axes.Title.String = tt;
    
    % Y Label
    switch disp_config.StackAngularMode
        case 'range'
            stacked_wc_tab_comp.wc_axes.YLabel.String = 'Range (m)';
        case 'depth'
            stacked_wc_tab_comp.wc_axes.YLabel.String = 'Depth (m)';
    end
    
    
end

% Current ping display as vertical line
set(stacked_wc_tab_comp.ping_gh,...
    'XData',ones(1,2)*(iPings(ip_sub)),...
    'YData',get(stacked_wc_tab_comp.wc_axes,'Ylim'));


end

