function update_wc_tab(main_figure)

wc_tab_comp = getappdata(main_figure,'wc_tab');
map_tab_comp = getappdata(main_figure,'Map_tab');
fData_tot = getappdata(main_figure,'fData');

if isempty(fData_tot)
    set(map_tab_comp.ping_line,'XData',nan,'YData',nan);
    set(wc_tab_comp.wc_gh,'XData',[],...
        'YData',[],'ZData',[],...
        'CData',[],'AlphaData',[]);
    set(wc_tab_comp.ac_gh,'XData',[],...
        'YData',[]);
    set(wc_tab_comp.bot_gh,'XData',[],...
        'YData',[]);
    title(wc_tab_comp.wc_axes,'');
    return;
end

disp_config = getappdata(main_figure,'disp_config');

ip = disp_config.Iping;
across_dist = disp_config.AcrossDist;

if disp_config.Fdata_idx>numel(fData_tot)
    disp_config.Fdata_idx = numel(fData_tot);
end

fData = fData_tot{disp_config.Fdata_idx};

if isfield(fData,'WC_SBP_SampleAmplitudes')
    start_fmt = 'WC_';
elseif isfield(fData,'WCAP_SBP_SampleAmplitudes')
    start_fmt = 'WCAP_';
end

if ip > numel(fData.(sprintf('%s1P_PingCounter',start_fmt)))
    ip = 1;
    disp_config.Iping = 1;
end

wc_str = wc_tab_comp.data_disp.String;
str_disp = wc_str{wc_tab_comp.data_disp.Value};

if ~isfield(fData,'X_SBP_Masked')&&strcmp(str_disp,'Processed')
    set(wc_tab_comp.data_disp,'Value',find(contains(wc_str,'Original')));
    str_disp = 'Original';
end

wc_proc_tab_comp = getappdata(main_figure,'wc_proc_tab');
cax_min = str2double(wc_proc_tab_comp.clim_min_wc.String);
cax_max = str2double(wc_proc_tab_comp.clim_max_wc.String);
cax = [cax_min cax_max];

switch str_disp
    
    case 'Original'
        amp = get_wc_data(fData,sprintf('%sSBP_SampleAmplitudes',start_fmt),ip,1,1);
        idx_keep = amp >= cax(1);
        
    case 'Phase'
        if isfield(fData,'WCAP_SBP_SamplePhase')
            amp = get_wc_data(fData,sprintf('%sSBP_SamplePhase',start_fmt),ip,1,1);
            cax = [-180 180];
            idx_keep = amp ~= 0;
        else
            amp = get_wc_data(fData,sprintf('%sSBP_SampleAmplitudes',start_fmt),ip,1,1);
            set(wc_tab_comp.data_disp,'Value',find(contains(wc_str,'Original')));
            idx_keep = amp >= cax(1);
        end
        
    case 'Processed'
        amp = single(fData.X_SBP_Masked.Data.val(:,:,ip));
        idx_keep = amp >= cax(1);
        
end

s.ID = fData.ID;
s.ip = ip;

soundSpeed          = fData.(sprintf('%s1P_SoundSpeed',start_fmt)).*0.1; %m/s
samplingFrequencyHz = fData.(sprintf('%s1P_SamplingFrequencyHz',start_fmt)); %Hz
dr_samples = soundSpeed./(samplingFrequencyHz.*2);

[nsamples,~] = size(amp);
[~,ac_dist,up_dist] = get_samples_range_dist((1:nsamples)',...
    fData.(sprintf('%sBP_StartRangeSampleNumber',start_fmt))(:,ip)...
    ,dr_samples(ip),...
    fData.(sprintf('%sBP_BeamPointingAngle',start_fmt))(:,ip)/100/180*pi);

if isfield(fData,'X_BP_bottomEasting')
    set(map_tab_comp.ping_line,'XData',fData.X_BP_bottomEasting(:,ip),'YData',fData.X_BP_bottomNorthing(:,ip),'userdata',s);
else
    return;
end

fname = fData.ALLfilename{1};
[~,fnamet,~] = fileparts(fname);
tt = sprintf('File: %s Ping # %.0f/%.0f Time: %s',fnamet,ip,numel(fData.(sprintf('%s1P_PingCounter',start_fmt))),datestr(fData.X_1P_pingSDN(ip),'HH:MM:SS'));

xlim = [-max(abs(ac_dist(idx_keep))) max(abs(ac_dist(idx_keep)))];
ylim = [min(nanmin(fData.X_BP_bottomUpDist(:,ip)),nanmin(up_dist(idx_keep))) 0];

set(wc_tab_comp.wc_gh,'XData',ac_dist,...
    'YData',up_dist,'ZData',zeros(size(amp)),...
    'CData',amp,'AlphaData',idx_keep);

set(wc_tab_comp.ac_gh,'XData',[across_dist across_dist],...
    'YData',get(wc_tab_comp.wc_axes,'YLim'));

set(wc_tab_comp.bot_gh,'XData',fData.X_BP_bottomAcrossDist(:,ip),...
    'YData',fData.X_BP_bottomUpDist(:,ip));

set(wc_tab_comp.wc_axes,'XLim',xlim,'Ylim',ylim,'Layer','top');
title(wc_tab_comp.wc_axes,tt,'Interpreter','none');

uistack(map_tab_comp.ping_line,'top');
if any(disp_config.Cax_wc~=cax)
    disp_config.Cax_wc = cax;
end

end