function listenVar_disp(src,evt,main_figure)
%LISTENVAR_DISP  Callback function when Var_disp is modified
%
%   See also ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 21-07-2021

disp_config = getappdata(main_figure,'disp_config');
update_map_tab(main_figure,1,0,0);

switch disp_config.Var_disp
    case 'wc_int'
        disp_config.Cmap = 'ek60';
    case 'bathy'
        disp_config.Cmap = 'parula';
    case 'bs'
        disp_config.Cmap = 'gray';
end

end