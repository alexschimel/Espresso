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
function update_wc_tab(main_figure)

wc_tab_comp  = getappdata(main_figure,'wc_tab');
stacked_wc_tab_comp  = getappdata(main_figure,'stacked_wc_tab');
map_tab_comp = getappdata(main_figure,'Map_tab');
fData_tot    = getappdata(main_figure,'fData');

if isempty(fData_tot)
    set(map_tab_comp.ping_swathe,'XData',nan,'YData',nan);
    set(wc_tab_comp.wc_gh,'XData',[], 'YData',[],'ZData',[], 'CData',[],'AlphaData',[]);
    set(wc_tab_comp.ac_gh,'XData',[],'YData',[]);
    set(wc_tab_comp.bot_gh,'XData',[],'YData',[]);
    title(wc_tab_comp.wc_axes,'');
    return;
end


%% get file, ping and across-dist to be displayed
disp_config = getappdata(main_figure,'disp_config');
if disp_config.Fdata_idx > numel(fData_tot)
    disp_config.Fdata_idx = numel(fData_tot);
end
ip = disp_config.Iping;
across_dist = disp_config.AcrossDist;
fData = fData_tot{disp_config.Fdata_idx};


%% the rest only applies if data is water column
datagramSource = fData.MET_datagramSource;
if ismember(datagramSource,{'WC' 'AP'})
    
    if isempty(ip)
        ip = 1;
        disp_config.Iping = 1;
    end
    
    if ip > numel(fData.(sprintf('%s_1P_PingCounter',datagramSource)))
        ip = 1;
        disp_config.Iping = 1;
    end
    
    wc_str = wc_tab_comp.data_disp.String;
    str_disp = wc_str{wc_tab_comp.data_disp.Value};
    
    % if "Processed" was selected but there is no Processed data, switch back
    % to original
    if ~isfield(fData,'X_SBP_WaterColumnProcessed') && strcmp(str_disp,'Processed')
        set(wc_tab_comp.data_disp,'Value',find(contains(wc_str,'Original')));
        str_disp = 'Original';
    end
    
    wc_proc_tab_comp = getappdata(main_figure,'wc_proc_tab');
    
    % colour extents
    cax_min = str2double(wc_proc_tab_comp.clim_min_wc.String);
    cax_max = str2double(wc_proc_tab_comp.clim_max_wc.String);
    cax = [cax_min cax_max];
    
    % pings composing the window for stack view
    nb_pings = size(fData.X_BP_bottomEasting,2);
    idx_pings = ip-disp_config.StackPingWidth:ip+disp_config.StackPingWidth-1;    
    id_min = nansum(idx_pings<1);
    idx_pings = idx_pings+id_min;
    id_max = nansum(idx_pings>nb_pings);
    idx_pings = idx_pings-id_max;
    idx_pings(idx_pings<1|idx_pings>nb_pings) = [];
    ip_sub = ip-idx_pings(1)+1;
    
    % indices of beams to keep for computation of stack view
    idx_a = ~( disp_config.StackAngularWidth(1)/180*pi<=fData.X_PB_beamPointingAngleRad(:,idx_pings) & disp_config.StackAngularWidth(2)/180*pi>=fData.X_PB_beamPointingAngleRad(:,idx_pings) );
    
    % start writing usrdata for stacked view
    usrdata.idx_angles = idx_a;
    usrdata.idx_pings  = idx_pings;
    usrdata.ID         = fData.ID;
    usrdata.str_disp   = str_disp;
    
    %% check if stacked view needs to be changed (true) or not (false)
    if isfield(stacked_wc_tab_comp.wc_gh.UserData,'idx_pings')
        up_stacked_wc_bool = ~isempty(setdiff(idx_pings,stacked_wc_tab_comp.wc_gh.UserData.idx_pings)) || ...
                             ~(fData.ID==stacked_wc_tab_comp.wc_gh.UserData.ID) || ...
                             ~isempty(setdiff(idx_a,stacked_wc_tab_comp.wc_gh.UserData.idx_angles)) || ...
                             ~strcmpi(str_disp,stacked_wc_tab_comp.wc_gh.UserData.str_disp);
    else
        % fist time setting a stacked view
        up_stacked_wc_bool = true;
    end
    
    
    %% ping sliding window polygon definition
    if  ~up_stacked_wc_bool
        % not changing stacked view, so ???
        idx_pings = ip;
        ip_sub = 1;
    else
        % need to change stacked view
        if isfield(fData,'X_BP_bottomEasting')
            
            ping_decimate_factor = 10;
            dp_sub = ceil(numel(idx_pings)./ping_decimate_factor);
            poly_pings = unique([1:dp_sub:numel(idx_pings),numel(idx_pings)]);
            
            % get easting coordinates of sliding window polygon
            e_p = fData.X_BP_bottomEasting(:,idx_pings);
            e_p_s = arrayfun(@(col) e_p(find(~isnan(e_p(:, col)),1,'first'),col), poly_pings, 'UniformOutput', 1);
            e_p_e = arrayfun(@(col) e_p(find(~isnan(e_p(:, col)),1,'last'),col), poly_pings, 'UniformOutput', 1);
            
            % get northing coordinates of sliding window polygon
            n_p = fData.X_BP_bottomNorthing(:,idx_pings);
            n_p_s = arrayfun(@(col) n_p(find(~isnan(n_p(:, col)),1,'first'),col), poly_pings, 'UniformOutput', 1);
            n_p_e = arrayfun(@(col) n_p(find(~isnan(n_p(:, col)),1,'last'),col), poly_pings, 'UniformOutput', 1);
            
            % compiling vertices for polygon
            new_vert = [[e_p_s fliplr(e_p_e)];[n_p_s fliplr(n_p_e)]]';
            
            % update vertices and tag in sliding window polygon
            map_tab_comp.ping_window.Shape.Vertices = new_vert;
            map_tab_comp.ping_window.Tag = sprintf('%.0f0_pingwindow',fData.ID);
            
        end
        
    end
    
    
    %% profile swathe line
    set(map_tab_comp.ping_swathe,'XData',fData.X_BP_bottomEasting(:,ip),'YData',fData.X_BP_bottomNorthing(:,ip));
    
    
    
    %% ??
    switch str_disp
        
        case 'Original'
            
            % get data
            wc_data = CFF_get_WC_data(fData,sprintf('%s_SBP_SampleAmplitudes',datagramSource),idx_pings,1,1);
            
            % ping to display in WC tab
            amp = wc_data(:,:,ip_sub);
            idx_keep = amp >= cax(1);
            
            % computing data for stacked view
            wc_data(:,idx_a) = nan;
            amp_al = squeeze(nanmean(wc_data,2));
            idx_keep_al = amp_al >= cax(1);
            
        case 'Phase'
            
            if isfield(fData,'AP_SBP_SamplePhase')
                wc_data = CFF_get_WC_data(fData,sprintf('%s_SBP_SamplePhase',datagramSource),idx_pings,1,1);
                cax = [-180 180];
                amp = wc_data(:,:,ip_sub);
                wc_data(:,idx_a) = nan;
                amp_al = squeeze(nanmean(wc_data,2));
                idx_keep = amp ~= 0;
                idx_keep_al = amp_al ~= 0;
            else
                wc_data = CFF_get_WC_data(fData,sprintf('%s_SBP_SampleAmplitudes',datagramSource),idx_pings,1,1);
                amp = wc_data(:,:,ip_sub);
                wc_data(:,idx_a) = nan;
                amp_al = squeeze(nanmean(wc_data,2));
                set(wc_tab_comp.data_disp,'Value',find(contains(wc_str,'Original')));
                idx_keep = amp >= cax(1);
                idx_keep_al = amp_al >= cax(1);
            end
            
        case 'Processed'
            
            % get data
            wc_data = CFF_get_WC_data(fData,'X_SBP_WaterColumnProcessed',idx_pings,1,1);
            
            % ping to display in WC tab
            amp = wc_data(:,:,ip_sub);
            idx_keep = amp >= cax(1);
            
            % computing stacked view
            wc_data(:,idx_a) = nan;
            amp_al = squeeze(nanmean(wc_data,2));
            idx_keep_al = amp_al >= cax(1);
            
    end
        
    % not sure what is this for?
    if isfield(fData,'X_BP_bottomEasting')
        %set(map_tab_comp.ping_swathe,'XData',fData.X_BP_bottomEasting(:,ip),'YData',fData.X_BP_bottomNorthing(:,ip),'userdata',s);
    else
        return;
    end


    %% Water-column swath display
    
    % get distances across and upwards for all samples
    soundSpeed          = fData.(sprintf('%s_1P_SoundSpeed',datagramSource)).*0.1; %m/s
    samplingFrequencyHz = fData.(sprintf('%s_1P_SamplingFrequencyHz',datagramSource)); %Hz
    dr_samples = soundSpeed./(samplingFrequencyHz.*2);
    [nsamples,~] = size(amp);
    sampleRange = CFF_get_samples_range((1:nsamples)',fData.(sprintf('%s_BP_StartRangeSampleNumber',datagramSource))(:,ip),dr_samples(ip));
    [sampleAcrossDist,sampleUpDist] = CFF_get_samples_dist(sampleRange,fData.(sprintf('%s_BP_BeamPointingAngle',datagramSource))(:,ip)/100/180*pi);
    
    % display WC data itself
    set(wc_tab_comp.wc_gh,...
        'XData',sampleAcrossDist,...
        'YData',sampleUpDist,...
        'ZData',zeros(size(amp)),...
        'CData',amp,...
        'AlphaData',idx_keep);
    
    % display Bottom
    set(wc_tab_comp.bot_gh,...
        'XData',fData.X_BP_bottomAcrossDist(:,ip),...
        'YData',fData.X_BP_bottomUpDist(:,ip));
    
    % display Pointer location across
    set(wc_tab_comp.ac_gh,...
        'XData',[across_dist across_dist],...
        'YData',get(wc_tab_comp.wc_axes,'YLim'));
    
    % Xlim and Ylim
    xlim = [-max(abs(sampleAcrossDist(idx_keep))) max(abs(sampleAcrossDist(idx_keep)))];
    ylim = [min(nanmin(fData.X_BP_bottomUpDist(:,ip)),nanmin(sampleUpDist(idx_keep))) 0];
    set(wc_tab_comp.wc_axes,...
        'XLim',xlim,...
        'Ylim',ylim,...
        'Layer','top');
    
    %% Stacked view display
    if up_stacked_wc_bool
        
        % stacked data is "amp_al". Its columns are idx_pings and its rows
        % are all samples in the usual WC data. But we need to turn these
        % samples # into range (m) for the display. Problem is it is not
        % constant over subsequent pings! For each sample #, calculate mean
        % range of all beams within stack view for the main ping. 
        sampleRangeAl = nanmean(sampleRange(:,~idx_a(:,ip_sub)),2);
        
        % display stacked view itself
        set(stacked_wc_tab_comp.wc_gh,...
            'XData',idx_pings,...
            'YData',sampleRangeAl,...
            'ZData',zeros(size(amp_al)),...
            'CData',amp_al,...
            'AlphaData',idx_keep_al,...
            'Userdata',usrdata);
        
        % Xlim and Ylim. Cropping the nans at top and bottom
        xlim_stacked = [idx_pings(1) idx_pings(end)];
        idx_al_s = find(~isnan(nanmean(amp_al,2)),1,'first');
        idx_al_e = find(~isnan(nanmean(amp_al,2)),1,'last');
        ylim_stacked = [sampleRangeAl(idx_al_s) sampleRangeAl(idx_al_e)];
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
    
    

    %% set title on both WC and stack view
    fname = fData.ALLfilename{1};
    [~,fnamet,~] = fileparts(fname);
    tt = sprintf('File: %s. Ping: %.0f/%.0f. Time: %s.',fnamet,ip,numel(fData.(sprintf('%s_1P_PingCounter',datagramSource))),datestr(fData.X_1P_pingSDN(ip),'HH:MM:SS'));
    wc_tab_comp.wc_axes.Title.String = tt;
    stacked_wc_tab_comp.wc_axes.Title.String = tt;
    
    %% ?
    if any(disp_config.Cax_wc~=cax)
        disp_config.Cax_wc = cax;
    end
    
end

% ensure that the line now displayed in WC is selected in the list of
% files loaded
line_idx = disp_config.Fdata_idx;
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