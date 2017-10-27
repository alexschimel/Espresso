function disp_wc_ping_cback(src,evt,main_figure)

fData_tot=getappdata(main_figure,'fData');

if isempty(fData_tot)
    return;
end
IDs_tot=nan(1,numel(fData_tot));
for i=1:numel(fData_tot)
    IDs_tot(i)=fData_tot{i}.ID;
end
switch src.Type
    case 'line'
        ID=str2double(src.Tag);
    case 'image'
        ID=str2double(src.Tag(3:end));
end
idx_fData=(IDs_tot==ID);

fData=fData_tot{idx_fData};

E=fData.X_1P_pingE;
N=fData.X_1P_pingN;
pt=evt.IntersectionPoint;
[across_dist,ip]=min(sqrt((E-pt(1)).^2+(N-pt(2)).^2));

z=cross([E(ip) N(ip) 0],[pt(1) pt(2) 0]);
across_dist=sign(z(3))*across_dist;

update_wc_tab(main_figure,fData,across_dist,ip);

disp_config=getappdata(main_figure,'disp_config');

zone=disp_config.get_zone();


[lat,lon]=utm2ll(N,E,double(zone));


end