function update_wc_tab(main_figure)

wc_tab_comp  = getappdata(main_figure,'wc_tab');
stacked_wc_tab_comp  = getappdata(main_figure,'stacked_wc_tab');
map_tab_comp = getappdata(main_figure,'Map_tab');
fData_tot    = getappdata(main_figure,'fData');

if isempty(fData_tot)
    set(map_tab_comp.ping_line,'XData',nan,'YData',nan);
    set(wc_tab_comp.wc_gh,'XData',[], 'YData',[],'ZData',[], 'CData',[],'AlphaData',[]);
    set(wc_tab_comp.ac_gh,'XData',[],'YData',[]);
    set(wc_tab_comp.bot_gh,'XData',[],'YData',[]);
    title(wc_tab_comp.wc_axes,'');
    return;
end

disp_config = getappdata(main_figure,'disp_config');

ip = disp_config.Iping;
across_dist = disp_config.AcrossDist;

if disp_config.Fdata_idx > numel(fData_tot)
    disp_config.Fdata_idx = numel(fData_tot);
end

fData = fData_tot{disp_config.Fdata_idx};

datagramSource = fData.MET_datagramSource;

% the rest only applies if data is water column
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
    
    cax_min = str2double(wc_proc_tab_comp.clim_min_wc.String);
    cax_max = str2double(wc_proc_tab_comp.clim_max_wc.String);
    cax = [cax_min cax_max];
    
    nb_pings=size(fData.X_BP_bottomEasting,2);
    idx_pings=ip-disp_config.StackPingWidth:ip+disp_config.StackPingWidth-1;
    
    id_min=nansum(idx_pings<1);
    idx_pings=idx_pings+id_min;
    
    id_max=nansum(idx_pings>nb_pings);
    idx_pings=idx_pings-id_max;
    
    idx_pings(idx_pings<1|idx_pings>nb_pings)=[];
    
    idx_a=~(disp_config.StackAngularWidth(1)/180*pi<=fData.X_PB_beamPointingAngleRad(:,idx_pings)&disp_config.StackAngularWidth(2)/180*pi>=fData.X_PB_beamPointingAngleRad(:,idx_pings));
   
    ip_sub=ip-idx_pings(1)+1;
    
    usrdata.idx_angles=idx_a;
    usrdata.idx_pings=idx_pings;
    usrdata.ID=fData.ID;
    usrdata.str_disp=str_disp;
    
    if isfield(stacked_wc_tab_comp.wc_gh.UserData,'idx_pings')
        up_stacked_wc_bool=~isempty(setdiff(idx_pings,stacked_wc_tab_comp.wc_gh.UserData.idx_pings))||...
            ~(fData.ID==stacked_wc_tab_comp.wc_gh.UserData.ID)||...
            ~isempty(setdiff(idx_a,stacked_wc_tab_comp.wc_gh.UserData.idx_angles))||...
             ~strcmpi(str_disp,stacked_wc_tab_comp.wc_gh.UserData.str_disp);
    else
        up_stacked_wc_bool=true;
    end
    
    if  ~up_stacked_wc_bool
        idx_pings=ip;
        ip_sub=1;
    else
        if isfield(fData,'X_BP_bottomEasting')
            
            e_p=fData.X_BP_bottomEasting(:,idx_pings);
            e_p_s = arrayfun(@(col) e_p(find(~isnan(e_p(:, col)),1,'first'),col), ...
                1:size(e_p, 2), 'UniformOutput', 1);
            e_p_e = arrayfun(@(col) e_p(find(~isnan(e_p(:, col)),1,'last'),col), ...
                1:size(e_p, 2), 'UniformOutput', 1);
            
            n_p=fData.X_BP_bottomNorthing(:,idx_pings);
            n_p_s = arrayfun(@(col) n_p(find(~isnan(n_p(:, col)),1,'first'),col), ...
                1:size(e_p, 2), 'UniformOutput', 1);
            n_p_e = arrayfun(@(col) n_p(find(~isnan(n_p(:, col)),1,'last'),col), ...
                1:size(e_p, 2), 'UniformOutput', 1);
            new_vert=[[e_p_s fliplr(e_p_e)];[n_p_s fliplr(n_p_e)]]';
            
            
            map_tab_comp.ping_poly.Shape.Vertices=new_vert;
            map_tab_comp.ping_poly.Tag=sprintf('poly_%.0f0',fData.ID);
            
        end
        
    end
    set(map_tab_comp.ping_line,'XData',fData.X_BP_bottomEasting(:,ip),'YData',fData.X_BP_bottomNorthing(:,ip));
    
    
    switch str_disp
        case 'Original'
            wc_data=CFF_get_WC_data(fData,sprintf('%s_SBP_SampleAmplitudes',datagramSource),idx_pings,1,1);
            amp = wc_data(:,:,ip_sub);
            wc_data(:,idx_a)=nan;
            amp_al=squeeze(nanmean(wc_data,2));
            idx_keep = amp >= cax(1);
            idx_keep_al = amp_al >= cax(1);
        case 'Phase'
            if isfield(fData,'AP_SBP_SamplePhase')
                wc_data = CFF_get_WC_data(fData,sprintf('%s_SBP_SamplePhase',datagramSource),idx_pings,1,1);
                cax = [-180 180];
                amp = wc_data(:,:,ip_sub);
                wc_data(:,idx_a)=nan;
                amp_al=squeeze(nanmean(wc_data,2));
                
                idx_keep = amp ~= 0;
                idx_keep_al = amp_al ~= 0;
            else
                wc_data = CFF_get_WC_data(fData,sprintf('%s_SBP_SampleAmplitudes',datagramSource),idx_pings,1,1);
                amp = wc_data(:,:,ip_sub);
                wc_data(:,idx_a)=nan;
                amp_al=squeeze(nanmean(wc_data,2));
                set(wc_tab_comp.data_disp,'Value',find(contains(wc_str,'Original')));
                idx_keep = amp >= cax(1);
                idx_keep_al = amp_al >= cax(1);
            end
            
        case 'Processed'
            wc_data = CFF_get_WC_data(fData,'X_SBP_WaterColumnProcessed',idx_pings,1,1);
            amp = wc_data(:,:,ip_sub);
            wc_data(:,idx_a)=nan;
            amp_al=squeeze(nanmean(wc_data,2));
            idx_keep = amp >= cax(1);
            idx_keep_al = amp_al >= cax(1);
    end
    
    
    soundSpeed          = fData.(sprintf('%s_1P_SoundSpeed',datagramSource)).*0.1; %m/s
    samplingFrequencyHz = fData.(sprintf('%s_1P_SamplingFrequencyHz',datagramSource)); %Hz
    dr_samples = soundSpeed./(samplingFrequencyHz.*2);
    
    [nsamples,~] = size(amp);
    
    % get distances across and upwards for XXX?
    sampleRange = CFF_get_samples_range((1:nsamples)',fData.(sprintf('%s_BP_StartRangeSampleNumber',datagramSource))(:,ip),dr_samples(ip));
    [sampleAcrossDist,sampleUpDist] = CFF_get_samples_dist(sampleRange,fData.(sprintf('%s_BP_BeamPointingAngle',datagramSource))(:,ip)/100/180*pi);
    
    sampleRangeAl=nanmean(sampleRange(:,nansum(~idx_a,2)>0),2);
    
    if isfield(fData,'X_BP_bottomEasting')
        %set(map_tab_comp.ping_line,'XData',fData.X_BP_bottomEasting(:,ip),'YData',fData.X_BP_bottomNorthing(:,ip),'userdata',s);
    else
        return;
    end
    
    fname = fData.ALLfilename{1};
    [~,fnamet,~] = fileparts(fname);
    tt = sprintf('File: %s Ping # %.0f/%.0f Time: %s',fnamet,ip,numel(fData.(sprintf('%s_1P_PingCounter',datagramSource))),datestr(fData.X_1P_pingSDN(ip),'HH:MM:SS'));
    
    xlim = [-max(abs(sampleAcrossDist(idx_keep))) max(abs(sampleAcrossDist(idx_keep)))];
    ylim = [min(nanmin(fData.X_BP_bottomUpDist(:,ip)),nanmin(sampleUpDist(idx_keep))) 0];
    amp_mean=nanmean(amp_al,2);
    idx_al=nansum(~isnan(amp_mean));
    xlim_stacked = [idx_pings(1) idx_pings(end)];
    ylim_stacked = [sampleRangeAl(1) sampleRangeAl(idx_al)];
    
    set(wc_tab_comp.wc_gh,'XData',sampleAcrossDist,...
        'YData',sampleUpDist,'ZData',zeros(size(amp)),...
        'CData',(amp),'AlphaData',(idx_keep));
    
    if up_stacked_wc_bool
        set(stacked_wc_tab_comp.wc_gh,'XData',idx_pings,...
            'YData',sampleRangeAl,'ZData',zeros(size(amp_al)),...
            'CData',(amp_al),'AlphaData',(idx_keep_al),'Userdata',usrdata);
        set(stacked_wc_tab_comp.wc_axes,'XLim',xlim_stacked,'Ylim',ylim_stacked,'Layer','top','UserData',usrdata);
    end
    set(stacked_wc_tab_comp.ping_gh,'XData',ones(1,2)*idx_pings(ip_sub),'YData',ylim_stacked);
    
    set(wc_tab_comp.ac_gh,'XData',[across_dist across_dist],...
        'YData',get(wc_tab_comp.wc_axes,'YLim'));
    
    set(wc_tab_comp.bot_gh,'XData',fData.X_BP_bottomAcrossDist(:,ip),...
        'YData',fData.X_BP_bottomUpDist(:,ip));
    
    set(wc_tab_comp.wc_axes,'XLim',xlim,'Ylim',ylim,'Layer','top');
    
    
    wc_tab_comp.wc_axes.Title.String=tt;
    stacked_wc_tab_comp.wc_axes.Title.String=tt;
    uistack(map_tab_comp.ping_line,'top');
    if any(disp_config.Cax_wc~=cax)
        disp_config.Cax_wc = cax;
    end
    
end


end