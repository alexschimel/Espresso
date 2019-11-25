%% this_function_name.m
%
% _This section contains a very short description of the function, for the
% user to know this function is part of the software and what it does for
% it. Example below to replace. Delete these lines XXX._
%
% Template of ESP3 function header. XXX
%
%% Help
%
% *USE*
%
% _This section contains a more detailed description of what the function
% does and how to use it, for the interested user to have an overall
% understanding of its function. Example below to replace. Delete these
% lines XXX._
%
% This is a text file containing the basic comment template to add at the
% start of any new ESP3 function to serve as function help. XXX
%
% *INPUT VARIABLES*
%
% _This section contains bullet points of input variables with description
% and information. Put input variable and other valid entries or defaults
% between | symbols so it shows as monospace. Information section to
% contain, in order: requirement (i.e. Required/Optional/Paramter), valid
% type (e.g. Num, Positive num, char, 1xN cell array, etc.) and default
% value if there is one (e.g. Default: '10'). Example below to replace.
% Delete these lines XXX._
%
% * |input_variable_1|: Description (Information). XXX
% * |input_variable_2|: Description (Information). XXX
% * |input_variable_3|: Description (Information). XXX
%
% *OUTPUT VARIABLES*
%
% _This section contains bullet points of output variables with description
% and information. See input variables for template. Example below to
% replace. Delete these lines XXX._
%
% * |output_variable_1|: Description (Information). XXX
% * |output_variable_2|: Description (Information). XXX
%
% *DEVELOPMENT NOTES*
%
% _This section describes what features are temporary, needed future
% developments and paper references. Example below to replace. Delete these
% lines XXX._
%
% * research point 1. XXX
% * research point 2. XXX
%
% *NEW FEATURES*
%
% _This section contains dates and descriptions of major updates. Example
% below to replace. Delete these lines XXX._
%
% * YYYY-MM-DD: second version. Describes the update. XXX
% * YYYY-MM-DD: first version. XXX
%
% *EXAMPLE*
%
% _This section contains examples of valid function calls. Note that
% example lines start with 3 white spaces so that the publish function
% shows them correctly as matlab code. Example below to replace. Delete
% these lines XXX._
%
%   example_use_1; % comment on what this does. XXX
%   example_use_2: % comment on what this line does. XXX
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% _This last section contains at least author name and affiliation. Delete
% these lines XXX._
%
% Yoann Ladroit, Alexandre Schimel, NIWA. XXX

%% Function
function update_stacked_wc_tab(main_figure,varargin)

%% INTRO

% input parser
p = inputParser;
addOptional(p,'force_update_flag',0);
parse(p,varargin{:});
force_update_flag = p.Results.force_update_flag;
clear p
if ~isdeployed()
    disp('Update Stacked WC Tab');
end


%% check if there are data to display
fData_tot = getappdata(main_figure,'fData');
if isempty(fData_tot)
    no_data_clear_all_displays(main_figure);
    return;
end

%% clean-up disp_config
disp_config = getappdata(main_figure,'disp_config');
disp_config.cleanup(main_figure);


%% get fdata, current ping and pings to be displayed
IDs=cellfun(@(c) c.ID,fData_tot);

if ~ismember(disp_config.Fdata_ID , IDs)
    disp_config.Fdata_ID = IDs(1);
    disp_config.Iping = 1;
    return;
end

fData = fData_tot{disp_config.Fdata_ID ==IDs};
ip          = disp_config.Iping;

% get indices of pings and angles from main mab
map_tab_comp = getappdata(main_figure,'Map_tab');
usrdata = get(map_tab_comp.ping_window,'UserData');
idx_pings = usrdata.idx_pings;
idx_angles = usrdata.idx_angles;
usrdata.StackAngularMode=disp_config.StackAngularMode;

% the index of the current ping in the stack
ip_sub = ip - idx_pings(1) + 1;
ip_sub=nanmax(ip_sub,1);

% get data type to be grabbed
wc_tab_comp  = getappdata(main_figure,'wc_tab');
wc_str = wc_tab_comp.data_disp.String;
str_disp = wc_str{wc_tab_comp.data_disp.Value};

% if "Processed" was selected but there is no Processed data, or if "Phase"
% was selected and there is no Phase data, switch back to original
if strcmp(str_disp,'Processed') && ~isfield(fData,'X_SBP_WaterColumnProcessed') || ...
        strcmp(str_disp,'Phase') && ~isfield(fData,'AP_SBP_SamplePhase')
    set(wc_tab_comp.data_disp,'Value',find(contains(wc_str,'Original')));
    str_disp = 'Original';
end
%% check if stacked view needs to be changed (true) or not (false)
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

datagramSource = CFF_get_datagramSource(fData);

%% Stacked view display
if up_stacked_wc_bool
    % stacked data is "amp_al". Its columns are idx_pings and its rows
    % are all samples in the usual WC data. But we need to turn these
    % samples # into range (m) for the display. Problem is it is not
    % constant over subsequent pings! For each sample #, calculate mean
    % range of all beams within stack view for the main ping.
    dr_samples = CFF_inter_sample_distance(fData);
    
    %profile on;
    
    disp_type = disp_config.StackAngularMode;
    
    switch str_disp
        case 'Original'
            dtg_to_load=sprintf('%s_SBP_SampleAmplitudes',datagramSource);
        case 'Processed'
            dtg_to_load='X_SBP_WaterColumnProcessed';
        case 'Phase'
            dtg_to_load=sprintf('%s_SBP_SamplePhase',datagramSource);
            
    end
    
    idx_pings(idx_pings>numel(fData.(sprintf('%s_1P_Date',datagramSource))))=[];
    idx_angle_keep(idx_angle_keep>size(fData.(sprintf('%s_BP_NumberOfSamples',datagramSource)),1))=[];
    
    switch disp_type
        case 'depth'
            bot=fData.X_BP_bottomUpDist(idx_angle_keep,idx_pings);
            idx_r=1:nanmax(ceil(-bot(:)./dr_samples(ip)));
            n_res=2;
        case'range'
            bot=fData.X_BP_bottomSample(idx_angle_keep,idx_pings);
            idx_r=1:nanmax(bot(:));
            n_res=1;
    end
    dr_res=n_res*dr_samples;
    
    sampleRange = CFF_get_samples_range(idx_r',fData.(sprintf('%s_BP_StartRangeSampleNumber',datagramSource))(idx_angle_keep,ip),dr_samples(ip));
    
    [gpu_comp,g] = get_gpu_comp_stat();
    
    nSamples = numel(idx_r);
    nBeams = numel(idx_angle_keep);
    
    if gpu_comp == 0
        mem_struct = memory;
        blockLength = ceil(mem_struct.MemAvailableAllArrays/(nSamples/n_res*nBeams*8)/10);
    else
        blockLength = ceil(g.AvailableMemory/(nSamples*nBeams*8)/4);
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
        angleData=fData.(sprintf('%s_BP_BeamPointingAngle',datagramSource))(idx_angle_keep,idx_pings(blockPings))/180*pi;
        wc_data = CFF_get_WC_data(fData,dtg_to_load,'iPing',idx_pings(blockPings),'iBeam',idx_angle_keep,'iRange',idx_r);
        if isempty(wc_data)
            continue;
        end
        wc_data(:,idx_angles(idx_angle_keep,blockPings)) = nan;
        
        switch disp_type
            case 'depth'
                [~,sampleUpDist] = CFF_get_samples_dist(sampleRange,angleData);
                idx_accum=ceil(-sampleUpDist/(dr_res(ip)));
                idx_accum(idx_accum>size(sampleUpDist,1))=size(sampleUpDist,1);
                idx_pings_mat=shiftdim(blockPings,-1);
                idx_pings_mat=repmat(idx_pings_mat-blockPings(1)+1,size(idx_accum,1),size(idx_accum,2));
                
                
                if gpu_comp>0
                    idx_nan=isnan(wc_data);
                    wc_data(idx_nan)=[];
                    idx_accum(idx_nan)=[];
                    idx_pings_mat(idx_nan)=[];
                    if g.AvailableMemory/8/4<=numel(wc_data)
                        gpuDevice(1);
                    end
                    tmp=accumarray(gpuArray([idx_accum(:) idx_pings_mat(:)]),gpuArray(wc_data(:)),[],@sum,single(-999))./...
                        accumarray(gpuArray([idx_accum(:) idx_pings_mat(:)]),gpuArray(1),[],@sum);
                    amp_al(1:size(tmp,1),blockPings)=gather(tmp);
                else
                    tmp=accumarray([idx_accum(:) idx_pings_mat(:)],wc_data(:),[],@nanmean,single(-999));
                    amp_al(1:size(tmp,1),blockPings)=tmp;
                end
                
            case 'range'
                idx_r_tmp=intersect(idx_r,1:size(wc_data,1));
                amp_al(idx_r_tmp,blockPings) = squeeze(nanmean(wc_data,2));
        end
    end
    
    
    switch disp_type
        case 'depth'
            sampleUpDistAl=(0:(size(amp_al,1)-1))*dr_res(ip);
        case 'range'
            sampleUpDist = sampleRange;
            sampleUpDistAl = nanmean(sampleUpDist(:,~idx_angles(idx_angle_keep,ceil(nanmean(blockPings)))),2);
    end
    %     profile off;
    %     profile viewer;
    switch str_disp
        
        case {'Original';'Processed'}
            
            idx_keep_al = amp_al >= cax(1);
            
        case 'Phase'
            
            idx_keep_al = amp_al ~= 0;
            
    end
    
    usrdata.str_disp=str_disp;
    
    % display stacked view itself
    set(stacked_wc_tab_comp.wc_gh,...
        'XData',idx_pings,...
        'YData',sampleUpDistAl,...
        'ZData',zeros(size(amp_al)),...
        'CData',amp_al,...
        'AlphaData',idx_keep_al,...
        'Userdata',usrdata);
    
    % Xlim and Ylim. Cropping the nans at top and bottom
    xlim_stacked = [idx_pings(1) idx_pings(end)];
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
    'XData',ones(1,2)*idx_pings(ip_sub),...
    'YData',get(stacked_wc_tab_comp.wc_axes,'Ylim'));



%% set Fdata_ID


IDs=cellfun(@(c) c.ID,fData_tot);


if ~ismember(disp_config.Fdata_ID , IDs)
    disp_config.Fdata_ID = IDs(1);
    disp_config.Iping = 1;
    return;
end
% Commen to avoid issued with double update.
% line_idx = find(disp_config.Fdata_ID ==IDs);
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

