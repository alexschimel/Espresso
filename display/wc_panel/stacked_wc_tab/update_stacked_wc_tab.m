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
IDs=[fData_tot(:).ID];

if ~ismember(disp_config.fData_ID , IDs)
    disp_config.Fdata_ID = IDs(1);
    disp_config.Iping = 1;
    return;
end

fData = fData_tot{strcmpi(disp_config.Fdata_ID ,IDs)};
ip          = disp_config.Iping;

% get indices of pings and angles from main mab
map_tab_comp = getappdata(main_figure,'Map_tab');
usrdata = get(map_tab_comp.ping_window,'UserData');
idx_pings = usrdata.idx_pings;
idx_angles = usrdata.idx_angles;

% the index of the current ping in the stack
ip_sub = ip - idx_pings(1) + 1;

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
        ~strcmpi(str_disp,stacked_wc_tab_comp.wc_gh.UserData.str_disp);
end

% get colour extents
wc_proc_tab_comp = getappdata(main_figure,'wc_proc_tab');
cax_min = str2double(wc_proc_tab_comp.clim_min_wc.String);
cax_max = str2double(wc_proc_tab_comp.clim_max_wc.String);
cax = [cax_min cax_max];

[iangles,~] = find(idx_angles==0);
idx_angle_keep = nanmin(iangles):nanmax(iangles);


%% get data for stacked view
datagramSource = fData.MET_datagramSource;
%% Stacked view display
if up_stacked_wc_bool
    % stacked data is "amp_al". Its columns are idx_pings and its rows
    % are all samples in the usual WC data. But we need to turn these
    % samples # into range (m) for the display. Problem is it is not
    % constant over subsequent pings! For each sample #, calculate mean
    % range of all beams within stack view for the main ping.
    soundSpeed          = fData.(sprintf('%s_1P_SoundSpeed',datagramSource)).*0.1; %m/s
    samplingFrequencyHz = fData.(sprintf('%s_1P_SamplingFrequencyHz',datagramSource)); %Hz
    %profile on;
    dr_samples = soundSpeed./(samplingFrequencyHz.*2);
    dr_res=4*dr_samples;
    disp_type=disp_config.StackAngularMode;

    
    switch disp_type
        case 'depth'
            bot=fData.X_BP_bottomUpDist(idx_angle_keep,idx_pings);
            idx_r=1:nanmax(ceil(-bot(:)./dr_samples(ip)));
        case'range'
            bot=fData.X_BP_bottomSample(idx_angle_keep,idx_pings);
            idx_r=1:nanmax(bot(:));
    end

    sampleRange = CFF_get_samples_range(idx_r',fData.(sprintf('%s_BP_StartRangeSampleNumber',datagramSource))(idx_angle_keep,ip),dr_samples(ip));
    angleData=fData.(sprintf('%s_BP_BeamPointingAngle',datagramSource))(idx_angle_keep,idx_pings)/100/180*pi;
    
  
    
    switch str_disp        
        case 'Original'            
            dtg_to_load=sprintf('%s_SBP_SampleAmplitudes',datagramSource);        
        case 'Processed'            
            dtg_to_load='X_SBP_WaterColumnProcessed';            
        case 'Phase'    
            dtg_to_load=sprintf('%s_SBP_SamplePhase',datagramSource);  
            
    end
    
    wc_data = CFF_get_WC_data(fData,dtg_to_load,'iPing',idx_pings,'iBeam',idx_angle_keep,'iRange',idx_r);
    wc_data(:,idx_angles(idx_angle_keep,:)) = nan;
    [gpu_comp,g]=get_gpu_comp_stat();
    switch disp_type
        case 'depth'
            [~,sampleUpDist] = CFF_get_samples_dist(sampleRange,angleData);
            idx_accum=ceil(-sampleUpDist/(dr_res(ip)));
            idx_accum(idx_accum>size(sampleUpDist,1))=size(sampleUpDist,1);
            idx_pings_mat=shiftdim(idx_pings,-1);
            idx_pings_mat=repmat(idx_pings_mat-idx_pings(1)+1,size(idx_accum,1),size(idx_accum,2));
            idx_nan=isnan(wc_data);
            wc_data(idx_nan)=[];
            idx_accum(idx_nan)=[];
            idx_pings_mat(idx_nan)=[];
            
            if gpu_comp>0
                amp_al=accumarray([idx_accum(:) idx_pings_mat(:)],gpuArray(wc_data(:)),[],@sum,single(-999))./...
                    accumarray([idx_accum(:) idx_pings_mat(:)],gpuArray(ones(numel(wc_data(:),1))),[],@sum);
                amp_al=gather(amp_al);
            else
                amp_al=accumarray([idx_accum(:) idx_pings_mat(:)],wc_data(:),[],@mean,single(-999));
            end
            sampleUpDistAl=(0:(size(amp_al,1)-1))*dr_res(ip);
        case 'range'
            
            
            amp_al = squeeze(nanmean(wc_data,2));
            sampleUpDist = sampleRange;
            sampleUpDistAl = nanmean(sampleUpDist(:,~idx_angles(idx_angle_keep,ip_sub)),2);
    end
    
%     profile off;
%     profile viewer;
    switch str_disp
        
        case {'Original';'Processed'}
            
            idx_keep_al = amp_al >= cax(1);
            
        case 'Phase'
            
            idx_keep_al = amp_al ~= 0;
            
    end
    

    
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
    idx_al_s = find(~isnan(nanmean(amp_al,2)),1,'first');
    idx_al_e = find(~isnan(nanmean(amp_al,2)),1,'last');
    ylim_stacked = [sampleUpDistAl(idx_al_s)*0.9 sampleUpDistAl(idx_al_e)*1.1];
    set(stacked_wc_tab_comp.wc_axes,...
        'XLim',xlim_stacked,...
        'Ylim',ylim_stacked,...
        'Layer','top',...
        'UserData',usrdata);
    
end

% Current ping vertical line
set(stacked_wc_tab_comp.ping_gh,...
    'XData',ones(1,2)*idx_pings(ip_sub),...
    'YData',get(stacked_wc_tab_comp.wc_axes,'Ylim'));



%% set title
fname = fData.ALLfilename{1};
[~,fnamet,~] = fileparts(fname);
tt = sprintf('File: %s. Ping: %.0f/%.0f. Time: %s.',fnamet,ip,numel(fData.(sprintf('%s_1P_PingCounter',datagramSource))),datestr(fData.X_1P_pingSDN(ip),'HH:MM:SS'));
stacked_wc_tab_comp.wc_axes.Title.String = tt;

% ensure that the line now displayed in WC is selected in the list of
% files loaded

IDs=[fData_tot(:).ID];

if ~ismember(disp_config.fData_ID , IDs)
    disp_config.Fdata_ID = IDs(1);
    disp_config.Iping = 1;
    return;
end

line_idx = findstrcmpi(disp_config.Fdata_ID ,IDs);


fdata_tab_comp = getappdata(main_figure,'fdata_tab');
if ~ismember(line_idx,fdata_tab_comp.selected_idx)
    
    % select the cell in the table. Unfortunately, findjobj takes a while
    % but seems the only solution to select a cell programmatically
    jUIScrollPane = findjobj(fdata_tab_comp.table);
    jUITable = jUIScrollPane.getViewport.getView;
    jUITable.changeSelection(line_idx-1,0, false, false);
    
    % and update selected_idx
    fdata_tab_comp.selected_idx = unique([fdata_tab_comp.selected_idx;line_idx]);
    
    % and save back
    setappdata(main_figure,'fdata_tab',fdata_tab_comp);
end


end

