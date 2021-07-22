function disp_cursor_info(~,~,main_figure)
%DISP_CURSOR_INFO  One-line description
%
%   See also ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 21-07-2021

fData_tot = getappdata(main_figure,'fData');

if isempty(fData_tot)
    return;
end

info_panel_comp = getappdata(main_figure,'info_panel');
map_tab_comp = getappdata(main_figure,'Map_tab');

ax = map_tab_comp.map_axes;
cp = ax.CurrentPoint;
x = cp(1,1);
y = cp(1,2);

disp_config = getappdata(main_figure,'disp_config');

IDs=cellfun(@(c) c.ID,fData_tot);


if ~ismember(disp_config.Fdata_ID , IDs)
    disp_config.Fdata_ID = IDs(1);
    disp_config.Iping = 1; % calls listenIping
    return;
end

fData = fData_tot{disp_config.Fdata_ID ==IDs};

E = fData.X_1P_pingE;
N = fData.X_1P_pingN;

[~,ip] = min(sqrt((E-cp(1,1)).^2+(N-cp(1,2)).^2));
[~,file,~] = fileparts(fData.ALLfilename{1});

info_str = sprintf('File: %s \n Proj: %s Time: %s',file,fData.MET_tmproj,datestr(fData.X_1P_pingSDN(ip)));

zone = disp_config.get_zone();

[lat,lon] = utm2ll(x,y,zone);

[lat_str,lon_str] = latlon2str(lat,lon);

pos_string = sprintf('%s\n%s\n',lat_str,lon_str);

set(info_panel_comp.pos_disp,'string',pos_string);

set(info_panel_comp.info_disp,'string',info_str,'Interpreter','none');

end