function update_wc_tab(main_figure)
wc_tab_comp=getappdata(main_figure,'wc_tab');
map_tab_comp=getappdata(main_figure,'Map_tab');
fData_tot=getappdata(main_figure,'fData');

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

disp_config=getappdata(main_figure,'disp_config');

ip=disp_config.Iping;
across_dist=disp_config.AcrossDist;


if disp_config.Fdata_idx>numel(fData_tot)
    disp_config.Fdata_idx=numel(fData_tot);
end

fData=fData_tot{disp_config.Fdata_idx};

if ip>numel(fData.WC_1P_PingCounter)
    ip=1;
    disp_config.Iping=1;
end

str_disp=wc_tab_comp.data_disp.String{wc_tab_comp.data_disp.Value};

if ~isfield(fData,'X_SBP_Masked')
    str_disp='Original';
end

switch str_disp
    case 'Original'
        amp = single(fData.WC_SBP_SampleAmplitudes.Data.val(:,:,ip))./2;
    case 'Processed'
        amp=single(fData.X_SBP_Masked.Data.val(:,:,ip));
end

amp(amp==-64)=nan;
s.ID=fData.ID;
s.ip=ip;

soundSpeed          = fData.WC_1P_SoundSpeed.*0.1; %m/s
samplingFrequencyHz = fData.WC_1P_SamplingFrequencyHz; %Hz
dr_samples = soundSpeed./(samplingFrequencyHz.*2);

[nsamples,~]=size(amp);
[~,ac_dist,up_dist]=get_samples_range_dist((1:nsamples)',...
    fData.WC_BP_StartRangeSampleNumber(:,ip)...
    ,dr_samples(ip),...
    fData.WC_BP_BeamPointingAngle(:,ip)/100/180*pi);


if isfield(fData,'X_BP_bottomEasting')
    set(map_tab_comp.ping_line,'XData',fData.X_BP_bottomEasting(:,ip),'YData',fData.X_BP_bottomNorthing(:,ip),...
        'userdata',s);
else
    return;
end

tt=sprintf('Ping # %.0f/%.0f Time: %s',ip,numel(fData.WC_1P_PingCounter),datestr(fData.X_1P_pingSDN(ip),'HH:MM:SS'));

cax=disp_config.Cax_wc;

idx_keep=amp>=cax(1);

xlim=[-max(abs(ac_dist(idx_keep))) max(abs(ac_dist(idx_keep)))];
ylim=[min(nanmin(fData.X_BP_bottomUpDist(:,ip)),nanmin(up_dist(~isnan(amp)))) 0];

set(wc_tab_comp.wc_gh,'XData',ac_dist,...
    'YData',up_dist,'ZData',zeros(size(amp)),...
    'CData',amp,'AlphaData',idx_keep);

set(wc_tab_comp.ac_gh,'XData',[across_dist across_dist],...
    'YData',get(wc_tab_comp.wc_axes,'YLim'));

set(wc_tab_comp.bot_gh,'XData',fData.X_BP_bottomAcrossDist(:,ip),...
    'YData',fData.X_BP_bottomUpDist(:,ip));


set(wc_tab_comp.wc_axes,'XLim',xlim,'Ylim',ylim,'Layer','top');
title(wc_tab_comp.wc_axes,tt);

uistack(map_tab_comp.ping_line,'top');


end