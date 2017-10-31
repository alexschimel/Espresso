function update_wc_tab(main_figure)
wc_tab_comp=getappdata(main_figure,'wc_tab');
map_tab_comp=getappdata(main_figure,'Map_tab');
fData_tot=getappdata(main_figure,'fData');

disp_config=getappdata(main_figure,'disp_config');

ip=disp_config.Iping;
across_dist=disp_config.AcrossDist;
fData=fData_tot{disp_config.Fdata_idx};

if ip>numel(fData.WC_1P_PingCounter)
    ip=1;
    disp_config.Iping=1;
end


switch wc_tab_comp.data_disp.String{wc_tab_comp.data_disp.Value}
    case 'Original'
        amp = double(fData.WC_SBP_SampleAmplitudes.Data.val(:,:,ip))./2;
    case 'Masked Original'
        amp = double(fData.WC_SBP_SampleAmplitudes.Data.val(:,:,ip))./2;
        amp(fData.X_SBP_Mask.Data.val(:,:,ip)==0)=nan;
    case 'Without Sidelobes'
        amp = double(fData.X_SBP_L1.Data.val(:,:,ip));
    case 'Masked without Sidelobes'
        amp = double(fData.X_SBP_L1.Data.val(:,:,ip));
        amp(fData.X_SBP_Mask.Data.val(:,:,ip)==0)=nan;
end

s.ID=fData.ID;
s.ip=ip;

if isfield(fData,'X_BP_bottomEasting')
    set(map_tab_comp.ping_line,'XData',fData.X_BP_bottomEasting(:,ip),'YData',fData.X_BP_bottomNorthing(:,ip),...
        'tag',sprintf('%.0f_line',fData.ID),...
        'userdata',s);
else
    return;
end

tt=sprintf('Ping # %.0f',ip);

cax=disp_config.Cax_wc;

idx_keep=amp>=cax(1);

ac_dist=fData.X_SBP_sampleAcrossDist.Data.val(:,:,ip);
up_dist=fData.X_SBP_sampleUpDist.Data.val(:,:,ip);
xlim=[nanmin(ac_dist(idx_keep)) nanmax(ac_dist(idx_keep))];
ylim=[nanmin(up_dist(~isnan(amp))) 0];

set(wc_tab_comp.wc_gh,'XData',ac_dist,...
    'YData',up_dist,'ZData',zeros(size(amp)),...
    'CData',amp,'AlphaData',idx_keep);
set(wc_tab_comp.ac_gh,'XData',[across_dist across_dist],...
    'YData',get(wc_tab_comp.wc_axes,'YLim'));
set(wc_tab_comp.wc_axes,'XLim',xlim,'Ylim',ylim,'Layer','top');
title(wc_tab_comp.wc_axes,tt);

uistack(map_tab_comp.ping_line,'top');


end