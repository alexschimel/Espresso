function listenVar_disp(src,evt,main_figure)
%LISTENVAR_DISP  Callback function when Var_disp is modified
%
%   See also ESPRESSO.

%   Copyright 2017-2021 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

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