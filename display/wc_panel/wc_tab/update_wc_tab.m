function update_wc_tab(main_figure,fData,across_dist,ip)
wc_tab_comp=getappdata(main_figure,'wc_tab');
map_tab_comp=getappdata(main_figure,'Map_tab');

if isfield(fData,'X_SBP_sampleAcrossDist')
    amp=fData.WC_SBP_SampleAmplitudes.Data.val(:,:,ip)./2;
else
    return;
end

s.ID=fData.ID;
s.ip=ip;
set(map_tab_comp.ping_line,'XData',fData.X_BP_bottomEasting(:,ip),'YData',fData.X_BP_bottomNorthing(:,ip),...
    'tag',sprintf('%.0f_ping_%.0f',fData.ID,ip),...
    'userdata',s);

disp_config=getappdata(main_figure,'disp_config');

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