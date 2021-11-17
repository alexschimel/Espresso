function update_stacked_wc_tab(main_figure,varargin)
%UPDATE_STACKED_WC_TAB  Updates stacked_wc tab in Espresso Swath panel
%
%   See also CREATE_STACKED_WC_TAB, INITIALIZE_DISPLAY, ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 11-11-2021


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
idx_angles = usrdata.idx_angles;
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
    flag_diff_beams = ~isempty(setxor(find(idx_angles),find(stacked_wc_tab_comp.wc_gh.UserData.idx_angles)));
    flag_diff_datatype = ~strcmpi(str_disp,stacked_wc_tab_comp.wc_gh.UserData.str_disp);
    flag_diff_mode = ~strcmpi(disp_config.StackAngularMode,stacked_wc_tab_comp.wc_gh.UserData.StackAngularMode);
    
    up_stacked_wc_bool = flag_diff_pings || flag_diff_line ||  ...
        flag_diff_beams || flag_diff_datatype || flag_diff_mode;
end


if up_stacked_wc_bool
    
    % profile on;
    
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
    
    % First, find the indices of pings, beams, and samples we need to
    % extract from the memmapped files.
    
    % For pings, we'll just extract the indices of pings making up the
    % stack.
    nPings = numel(iPings);
    
    % For beams, we'll extract the set of beams between the smallest index
    % in the stack to the largest.
    [iangles,~] = find(idx_angles);
    iBeams = nanmin(iangles):nanmax(iangles);
    nBeams = numel(iBeams);
    
    % For samples, it depends on stack mode
    dr_samples = CFF_inter_sample_distance(fData);
    stack_mode = disp_config.StackAngularMode;
    switch stack_mode
        case 'depth'
            % for stacking in depth, we will extract down to the index of
            % the sample corresponding to the deepest bottom detect in
            % actual depth in meters.
            depth = fData.X_BP_bottomUpDist(iBeams,iPings); % in m
            deepest = nanmin(depth(:)); % in m
            idx_samples = 1:ceil(-deepest./dr_samples(ip));
            n_res = 2;
            dr_res = n_res*dr_samples; % intersample distance per ping times. what is n_res for??
        case'range'
            % for stacking in range, we extract down to the index of the
            % sample of the deepest bottom detect
            botsamp = CFF_get_bottom_sample(fData);
            botsamp = botsamp(iBeams,iPings);
            idx_samples = 1:nanmax(botsamp(:));
            n_res = 1;
    end
    nSamples = numel(idx_samples);
    
    % init stack WC data
    amp_al = nan(ceil(nSamples/n_res),nPings);
    
    % range for each sample in this ping
    startSampleNumber = fData.(sprintf('%s_BP_StartRangeSampleNumber',datagramSource))(iBeams,ip);
    sampleRange = CFF_get_samples_range(idx_samples',startSampleNumber,dr_samples(ip));
    
    % block processing setup
    [gpu_comp,g] = get_gpu_comp_stat();
    if gpu_comp
        blockLength = ceil(g.AvailableMemory/(nSamples*nBeams*8*4*8));
    else
        mem = CFF_memory_available;
        blockLength = ceil(mem/(nSamples/n_res*nBeams*8)/10);
    end
    nBlocks = ceil(nPings/(blockLength));
    blocks = [ 1+(0:nBlocks-1)'.*blockLength , (1:nBlocks)'.*blockLength ];
    
    try
        blocks(end,2) = nPings;
    catch
        XXX
    end
    
    % block processing
    for iB = 1:nBlocks
        
        % list of pings in this block
        blockPings  = (blocks(iB,1):blocks(iB,2));
        
        % get WC data
        WC_data = CFF_get_WC_data(fData,fieldN,'iPing',iPings(blockPings),'iBeam',iBeams,'iRange',idx_samples);
        if isempty(WC_data)
            continue;
        end
        
        % set to nan the beams that are not part of the stack
        WC_data(:,~idx_angles(iBeams,blockPings)) = NaN;
        
        switch stack_mode
            case 'depth'
                % BP array of pointing angles in rad
                angleData = fData.(sprintf('%s_BP_BeamPointingAngle',datagramSource))(iBeams,iPings(blockPings))/180*pi;
                
                [~,sampleUpDist] = CFF_get_samples_dist(sampleRange,angleData);
                idx_accum = ceil(-sampleUpDist/(dr_res(ip)));
                idx_accum(idx_accum>size(sampleUpDist,1)) = size(sampleUpDist,1);
                idx_pings_mat = shiftdim(blockPings,-1);
                idx_pings_mat = repmat(idx_pings_mat-blockPings(1)+1,size(idx_accum,1),size(idx_accum,2));
                
                if gpu_comp>0 && g.AvailableMemory/8<=numel(WC_data)*4
                    g = gpuDevice(1);
                end
                
                if gpu_comp>0 && g.AvailableMemory/8>=numel(WC_data)*4
                    idx_nan = isnan(WC_data);
                    WC_data(idx_nan) = [];
                    idx_accum(idx_nan) = [];
                    idx_pings_mat(idx_nan) = [];
                    
                    tmp = accumarray(gpuArray([idx_accum(:) idx_pings_mat(:)]),gpuArray(10.^(WC_data(:)/10)),[],@sum,single(0))./...
                        accumarray(gpuArray([idx_accum(:) idx_pings_mat(:)]),gpuArray(1),[],@sum);
                    amp_al(1:size(tmp,1),blockPings) = gather(10*log10(tmp));
                    
                else
                    tmp = accumarray([idx_accum(:) idx_pings_mat(:)],10.^(WC_data(:)/10),[],@nanmean,single(0));
                    amp_al(1:size(tmp,1),blockPings) = 10*log10(tmp);
                end
                
            case 'range'
                % average across range in natural and bring back to dB
                block_stack = 10*log10(squeeze(nanmean(10.^(WC_data/10),2)));
                
                % add to final array
                amp_al(:,blockPings) = block_stack;
        end
    end
    
    % distance down (in m)
    switch stack_mode
        case 'depth'
            sampleUpDistAl = (0:(size(amp_al,1)-1))*dr_res(ip);
        case 'range'
            sampleUpDistAl = nanmean(sampleRange(:,idx_angles(iBeams,ceil(nanmean(blockPings)))),2);
    end
    
    % profile off;
    % profile viewer;
    
    % get colour extents
    cax_min = str2double(display_tab_comp.clim_min_wc.String);
    cax_max = str2double(display_tab_comp.clim_max_wc.String);
    cax = [cax_min cax_max];
    
    % alphadata
    switch str_disp
        case {'Original';'Processed'}
            idx_keep_al = amp_al >= cax(1);
        case 'Phase'
            idx_keep_al = amp_al ~= 0;
    end
    
    usrdata.str_disp = str_disp;
    
    % update stacked WC data
    set(stacked_wc_tab_comp.wc_gh,...
        'XData',iPings,...
        'YData',sampleUpDistAl,...
        'ZData',zeros(size(amp_al)),...
        'CData',amp_al,...
        'AlphaData',idx_keep_al,...
        'Userdata',usrdata);
    
    % Xlim and Ylim. Cropping the nans at top and bottom
    xlim_stacked = ([iPings(1) iPings(end)]);
    if xlim_stacked(1) == xlim_stacked(2)
        % in case only one ping in this view (file with 1 ping)
        xlim_stacked(2) = xlim_stacked(1)+1;
    end
    idx_al_s = find(~isnan(nanmean(amp_al,2)),1,'first');
    idx_al_e = find(~isnan(nanmean(amp_al,2)),1,'last');
    if ~isempty(idx_al_s)&&~isempty(idx_al_s)
        ylim_stacked = [sampleUpDistAl(idx_al_s)*0.9 sampleUpDistAl(idx_al_e)*1.1];
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
    
end

% Current ping display as vertical line
set(stacked_wc_tab_comp.ping_gh,...
    'XData',ones(1,2)*(iPings(ip_sub)),...
    'YData',get(stacked_wc_tab_comp.wc_axes,'Ylim'));


end

