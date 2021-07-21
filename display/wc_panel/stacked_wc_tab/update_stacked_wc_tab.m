function update_stacked_wc_tab(main_figure,varargin)
%UPDATE_STACKED_WC_TAB  Updates stacked_wc tab in Espresso Swath panel
%
%   See also CREATE_STACKED_WC_TAB, INITIALIZE_DISPLAY, ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 21-07-2021

% input parser
p = inputParser;
addOptional(p,'force_update_flag',0);
parse(p,varargin{:});
force_update_flag = p.Results.force_update_flag;
clear p

% disp
if ~isdeployed()
    tic;
    disp('Update Stacked WC Tab');
end

% check if there are data to display
fData_tot = getappdata(main_figure,'fData');
if isempty(fData_tot)
    no_data_clear_all_displays(main_figure);
    return;
end

% clean-up disp_config
disp_config = getappdata(main_figure,'disp_config');
disp_config.cleanup(main_figure);

% get fdata to be displayed
fData_tot_IDs = cellfun(@(c) c.ID,fData_tot);
fData = fData_tot{fData_tot_IDs==disp_config.Fdata_ID};
datagramSource = CFF_get_datagramSource(fData);

% get ping to be displayed
ip = disp_config.Iping;

% get indices of pings and angles from main map's UserData
map_tab_comp = getappdata(main_figure,'Map_tab');
usrdata = get(map_tab_comp.ping_window,'UserData');
idx_pings = usrdata.idx_pings;
idx_angles = usrdata.idx_angles;
usrdata.StackAngularMode = disp_config.StackAngularMode; % add StackAngularMode

% index of the current ping in the stack
ip_sub = nanmax(ip-idx_pings(1)+1,1);

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
stacked_wc_tab_comp  = getappdata(main_figure,'stacked_wc_tab');

[iangles,~] = find(idx_angles==0);
idx_angle_keep = nanmin(iangles):nanmax(iangles);

if ~isfield(stacked_wc_tab_comp.wc_gh.UserData,'idx_pings')
    % fist time setting a stacked view
    up_stacked_wc_bool = true;
elseif force_update_flag
    % forcing the update, typically after reprocessing
    up_stacked_wc_bool = true;
else
    up_stacked_wc_bool = ~isempty(setdiff(idx_pings,stacked_wc_tab_comp.wc_gh.UserData.idx_pings)) || ...
        ~(fData.ID==stacked_wc_tab_comp.wc_gh.UserData.ID) || ...
        ~isempty(setxor(find(idx_angles),find(stacked_wc_tab_comp.wc_gh.UserData.idx_angles))) || ...
        ~strcmpi(str_disp,stacked_wc_tab_comp.wc_gh.UserData.str_disp)||...
        ~strcmpi(disp_config.StackAngularMode,stacked_wc_tab_comp.wc_gh.UserData.StackAngularMode);
end

% get colour extents
display_tab_comp = getappdata(main_figure,'display_tab');
cax_min = str2double(display_tab_comp.clim_min_wc.String);
cax_max = str2double(display_tab_comp.clim_max_wc.String);
cax = [cax_min cax_max];

% PingCounter=fData.(sprintf('%s_1P_PingCounter',datagramSource));

% Stacked view display
if up_stacked_wc_bool
    % stacked data is "amp_al". Its columns are idx_pings and its rows
    % are all samples in the usual WC data. But we need to turn these
    % samples # into range (m) for the display. Problem is it is not
    % constant over subsequent pings! For each sample #, calculate mean
    % range of all beams within stack view for the main ping.
    dr_samples = CFF_inter_sample_distance(fData);
    
    % profile on;
    
    disp_type = disp_config.StackAngularMode;
    switch str_disp
        case 'Original'
            dtg_to_load=sprintf('%s_SBP_SampleAmplitudes',datagramSource);
        case 'Processed'
            dtg_to_load='X_SBP_WaterColumnProcessed';
        case 'Phase'
            dtg_to_load=sprintf('%s_SBP_SamplePhase',datagramSource);
            
    end
    
    idx_pings(idx_pings>numel(fData.(sprintf('%s_1P_Date',datagramSource)))) = [];
    idx_angle_keep(idx_angle_keep>size(fData.(sprintf('%s_BP_NumberOfSamples',datagramSource)),1)) = [];
    
    switch disp_type
        case 'depth'
            bot = fData.X_BP_bottomUpDist(idx_angle_keep,idx_pings);
            idx_r = 1:nanmax(ceil(-bot(:)./dr_samples(ip)));
            n_res = 2;
        case'range'
            bot = CFF_get_bottom_sample(fData);
            bot = bot(idx_angle_keep,idx_pings);
            idx_r = 1:nanmax(bot(:));
            n_res = 1;
    end
    dr_res = n_res*dr_samples;
    
    sampleRange = CFF_get_samples_range(idx_r',fData.(sprintf('%s_BP_StartRangeSampleNumber',datagramSource))(idx_angle_keep,ip),dr_samples(ip));
    
    [gpu_comp,g] = get_gpu_comp_stat();
    
    nSamples = numel(idx_r);
    nBeams = numel(idx_angle_keep);
    
    if gpu_comp == 0
        mem = CFF_memory_available;
        blockLength = ceil(mem/(nSamples/n_res*nBeams*8)/10);
    else
        blockLength = ceil(g.AvailableMemory/(nSamples*nBeams*8*4*8));
    end
    
    % block processing setup
    %blockLength = 200;
    nPings = numel(idx_pings);
    nBlocks = ceil(nPings/(blockLength));
    blocks = [ 1+(0:nBlocks-1)'.*blockLength , (1:nBlocks)'.*blockLength ];
    blocks(end,2) = nPings;
    
    amp_al = nan(ceil(nSamples/n_res),nPings);
    
    for iB = 1:nBlocks
        
        % list of pings in this block
        blockPings  = (blocks(iB,1):blocks(iB,2));
        angleData = fData.(sprintf('%s_BP_BeamPointingAngle',datagramSource))(idx_angle_keep,idx_pings(blockPings))/180*pi;
        wc_data = CFF_get_WC_data(fData,dtg_to_load,'iPing',idx_pings(blockPings),'iBeam',idx_angle_keep,'iRange',idx_r);
        
        if isempty(wc_data)
            continue;
        end
        wc_data(:,idx_angles(idx_angle_keep,blockPings)) = nan;
        
        switch disp_type
            case 'depth'
                [~,sampleUpDist] = CFF_get_samples_dist(sampleRange,angleData);
                idx_accum = ceil(-sampleUpDist/(dr_res(ip)));
                idx_accum(idx_accum>size(sampleUpDist,1)) = size(sampleUpDist,1);
                idx_pings_mat = shiftdim(blockPings,-1);
                idx_pings_mat = repmat(idx_pings_mat-blockPings(1)+1,size(idx_accum,1),size(idx_accum,2));
                
                if gpu_comp>0 && g.AvailableMemory/8<=numel(wc_data)*4
                    g = gpuDevice(1);
                end
                
                if gpu_comp>0 && g.AvailableMemory/8>=numel(wc_data)*4
                    idx_nan = isnan(wc_data);
                    wc_data(idx_nan) = [];
                    idx_accum(idx_nan) = [];
                    idx_pings_mat(idx_nan) = [];
                    
                    tmp = accumarray(gpuArray([idx_accum(:) idx_pings_mat(:)]),gpuArray(10.^(wc_data(:)/10)),[],@sum,single(0))./...
                        accumarray(gpuArray([idx_accum(:) idx_pings_mat(:)]),gpuArray(1),[],@sum);
                    amp_al(1:size(tmp,1),blockPings) = gather(10*log10(tmp));
                    
                else
                    tmp = accumarray([idx_accum(:) idx_pings_mat(:)],10.^(wc_data(:)/10),[],@nanmean,single(0));
                    amp_al(1:size(tmp,1),blockPings) = 10*log10(tmp);
                end
                
            case 'range'
                idx_r_tmp = intersect(idx_r,1:size(wc_data,1));
                amp_al(idx_r_tmp,blockPings) = 10*log10(squeeze(nanmean(10.^(wc_data/10),2)));
        end
    end
    
    
    switch disp_type
        case 'depth'
            sampleUpDistAl = (0:(size(amp_al,1)-1))*dr_res(ip);
        case 'range'
            sampleUpDist = sampleRange;
            sampleUpDistAl = nanmean(sampleUpDist(:,~idx_angles(idx_angle_keep,ceil(nanmean(blockPings)))),2);
    end
    
    % profile off;
    % profile viewer;
    
    switch str_disp
        case {'Original';'Processed'}
            idx_keep_al = amp_al >= cax(1);
        case 'Phase'
            idx_keep_al = amp_al ~= 0;
    end
    
    usrdata.str_disp = str_disp;
    
    % display stacked view itself
    set(stacked_wc_tab_comp.wc_gh,...
        'XData',idx_pings,...
        'YData',sampleUpDistAl,...
        'ZData',zeros(size(amp_al)),...
        'CData',amp_al,...
        'AlphaData',idx_keep_al,...
        'Userdata',usrdata);
    
    % Xlim and Ylim. Cropping the nans at top and bottom
    xlim_stacked = ([idx_pings(1) idx_pings(end)]);
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
    fname = fData.ALLfilename{1};
    [~,fnamet,~] = fileparts(fname);
    tt = sprintf('File: %s.',fnamet);
    stacked_wc_tab_comp.wc_axes.Title.String = tt;
    
end

% Current ping vertical line
set(stacked_wc_tab_comp.ping_gh,...
    'XData',ones(1,2)*(idx_pings(ip_sub)),...
    'YData',get(stacked_wc_tab_comp.wc_axes,'Ylim'));

if ~isdeployed()
    toc;
    disp('Done...');
end


% set Fdata_ID
fData_tot_IDs = cellfun(@(c) c.ID,fData_tot);
if ~ismember(disp_config.Fdata_ID , fData_tot_IDs)
    disp_config.Fdata_ID = fData_tot_IDs(1);
    disp_config.Iping = 1;
    return;
end

% Commen to avoid issued with double update.
% line_idx = find(disp_config.Fdata_ID ==fData_tot_IDs);
%
%
% fdata_tab_comp = getappdata(main_figure,'fdata_tab');
% if ~ismember(line_idx,fdata_tab_comp.selected_idx)
%
%     % select the cell in the table. Unfortunately, findjobj takes a while
%     % but seems the only solution to select a cell programmatically
%     jUIScrollPane = findjobj(fdata_tab_comp.table);
%     jUITable = jUIScrollPane.getViewport.getView;
%     jUITable.changeSelection(line_idx-1,0, false, false);
%
%     % and update selected_idx
%     fdata_tab_comp.selected_idx = unique([fdata_tab_comp.selected_idx;line_idx]);
%
%     % and save back
%     setappdata(main_figure,'fdata_tab',fdata_tab_comp);
% end


end

