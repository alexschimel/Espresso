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
    
    % First, find the indices of pings, beams, and samples we need to
    % extract from the memmapped files.
    
    % For pings, we will just extract those making up the stack
    nPings = numel(iPings);
    
    % For beams, we will extract all beams between the smallest and largest
    % index in the stack, as limited by the angles
    [indBeamKeep,~] = find(subBeamKeep);
    iBeams = nanmin(indBeamKeep):nanmax(indBeamKeep);
    nBeams = numel(iBeams);
    
    % For samples, it depends on stack mode
    stackMode = disp_config.StackAngularMode;
    switch stackMode
        case 'range'
            % for stacking in range, we extract down to the furthest bottom
            % detect sample (within the extracted pings and beams)
            bottomSamples = CFF_get_bottom_sample(fData);
            bottomSamples = bottomSamples(iBeams,iPings);
            furthestSample = nanmax(bottomSamples(:));
        case 'depth'
            % for stacking in depth, we extract down to the range of the
            % deepest depth in the widest angle (within the extracted pings
            % and beams)
            depth = fData.X_BP_bottomUpDist(iBeams,iPings);
            deepest = nanmin(depth(:));
            angleRad = fData.X_BP_beamPointingAngleRad(iBeams,iPings);
            rangeForDeepest = abs(deepest)./cos(angleRad);
            interSamplesDistance = CFF_inter_sample_distance(fData,iPings);
            furthestSample = ceil(max(rangeForDeepest./interSamplesDistance,[],'all'));
    end
    iSamples = 1:furthestSample;
    nSamples = numel(iSamples);
    
    % Initialize the stacked WC data, which is a Range (or Depth) by Pings
    % array
    switch stackMode
        case 'range'
            % for stacking in range, we will stack all samples that will be
            % extracted. The rows are thus defined by iSamples, or in m:
            stackY = iSamples.*CFF_inter_sample_distance(fData,ip);
        case 'depth'
            % for stacking in depth, we go from 0 to the deepest depth,
            % with a depth resolution defined as a factor of the
            % interSamplesDistance
            fact = 2; % hard-coded factor (for now)
            dRes = fact*min(interSamplesDistance);
            stackY = 0:dRes:abs(deepest);            
    end
    stack = nan(numel(stackY),nPings,'single');
    
    % setup GPU
    if CFF_is_parallel_computing_available()
        useGpu = 1;
        processingUnit = 'GPU';
    else
        useGpu = 0;
        processingUnit = 'CPU';
    end
    
    % number of big block variables in each mode
    switch stackMode
        case 'range'
            maxNumBlockVar = 1;
        case 'depth'
            maxNumBlockVar = 4;
    end
    
    % setup block processing
    [blocks,info] = CFF_setup_optimized_block_processing(...
        nPings,nSamples*nBeams*4,...
        processingUnit,...
        'desiredMaxMemFracToUse',0.1,...
        'maxNumBlockVar',maxNumBlockVar);
    % disp(info);
    
    % block processing
    for iB = 1:size(blocks,1)
        
        % list of pings in this block
        blockPings  = (blocks(iB,1):blocks(iB,2));
        
        % get WC data
        blockWCD = CFF_get_WC_data(fData,fieldN,'iPing',iPings(blockPings),'iBeam',iBeams,'iRange',iSamples);
        if isempty(blockWCD)
            continue;
        end
        
        % set to NaN the beams that are not part of the stack
        blockWCD(:,~subBeamKeep(iBeams,blockPings)) = NaN;
        
        if useGpu
            blockWCD = gpuArray(blockWCD);
        end
        
        switch stackMode
            
            case 'range'
                
                % average across beams in natural values, then back to dB
                blockStack = 10*log10(squeeze(mean(10.^(blockWCD/10),2,'omitnan')));
                
                % add to final array
                stack(:,blockPings) = blockStack;
                
            case 'depth'
                
                % convert a couple variables here to gpuArrays so all
                % computations downstream use the GPU and all variables
                % become gpuArrays
                if useGpu
                    iSamples = gpuArray(iSamples);
                    blockPings = gpuArray(blockPings);
                end
                
                % distance upwards from sonar for each sample
                blockStartSampleNumber = single(fData.(sprintf('%s_BP_StartRangeSampleNumber',datagramSource))(iBeams,iPings(blockPings)));
                blockSampleRange = CFF_get_samples_range(single(iSamples'),blockStartSampleNumber,single(interSamplesDistance(blockPings)));
                blockAngle = single(angleRad(:,blockPings));
                [~,blockSampleUpDist] = CFF_get_samples_dist(blockSampleRange,blockAngle);
                clear blockSampleRange % clear up memory
                
                % index of each sample in the depth (row) vector
                blockIndRow = round(-blockSampleUpDist/dRes+1);
                clear blockSampleUpDist % clear up memory
                
                % NaN those samples that fall outside of the desired array
                % (typically, samples whose depth is below deepest) 
                blockIndRow(blockIndRow<1) = NaN;
                blockIndRow(blockIndRow>numel(stackY)) = NaN;
                
                % index of each sample in the ping (column) vector
                blockIndCol = single(blockPings - blockPings(1) + 1);
                blockIndCol = shiftdim(blockIndCol,-1); % 11P
                blockIndCol = repmat(blockIndCol,nSamples,nBeams); %SBP
                
                % next: vectorize and remove any sample where we have NaNs
                blockIndNaN = isnan(blockIndRow) | isnan(blockWCD);
                blockIndRow(blockIndNaN) = [];
                blockIndCol(blockIndNaN) = [];
                blockWCD(blockIndNaN) = [];
                clear blockIndNaN % clear up memory
                
                % The following used to be the only part done on gpu, using
                % and if-then clause on: 
                % gpuAvail>0 && g.AvailableMemory/8>=numel(block_WC_data)*4
                
                % average level in each stack grid cell, in natural values
                blockStackSumVal = accumarray( [blockIndRow(:),blockIndCol(:)],...
                    10.^(blockWCD(:)/10),[],@sum,single(0));
                blockStackNumElem = accumarray( [blockIndRow(:),blockIndCol(:)],...
                    single(1),[],@sum);
                blockStackAvg = 10*log10(blockStackSumVal./blockStackNumElem);
                clear blockIndRow blockIndCol % clear up memory
                
                % save in stacked array
                stack(1:size(blockStackAvg,1),blockPings) = blockStackAvg;
                
        end
    end
        
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
        'XData',iPings,...
        'YData',stackY,...
        'ZData',zeros(size(stack)),...
        'CData',stack,...
        'AlphaData',idx_keep_al,...
        'Userdata',usrdata);
    
    % Xlim and Ylim. Cropping the nans at top and bottom
    xlim_stacked = ([iPings(1) iPings(end)]);
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
    switch stackMode
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

