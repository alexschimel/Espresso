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

 %z=E(ip)*pt(1)+ N(ip)*pt(2);
 
 z=cross([E(ip) N(ip) 0], [pt(1) pt(2) 0]);
 z=z(3);

disp_config=getappdata(main_figure,'disp_config');

disp_config.AcrossDist=sign(z)*across_dist;
disp_config.Iping=ip;
disp_config.Fdata_idx=find(idx_fData);

update_wc_tab(main_figure);


end