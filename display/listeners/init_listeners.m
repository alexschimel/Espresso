function init_listeners(main_figure)

disp_config_obj = getappdata(main_figure,'disp_config');

if isappdata(main_figure,'ListenersH')
    ls = getappdata(main_figure,'ListenersH');
else
    ls = [];
end

ls = [ls addlistener(disp_config_obj,'Cax_wc_int','PostSet',@(src,envdata)listenCax(src,envdata,main_figure))];
ls = [ls addlistener(disp_config_obj,'Cax_wc','PostSet',@(src,envdata)listenCax(src,envdata,main_figure))];
ls = [ls addlistener(disp_config_obj,'Cax_bs','PostSet',@(src,envdata)listenCax(src,envdata,main_figure))];
ls = [ls addlistener(disp_config_obj,'Cax_bathy','PostSet',@(src,envdata)listenCax(src,envdata,main_figure))];
ls = [ls addlistener(disp_config_obj,'Var_disp','PostSet',@(src,envdata)listenVar_disp(src,envdata,main_figure))];
ls = [ls addlistener(disp_config_obj,'Cmap','PostSet',@(src,envdata)listenCmap(src,envdata,main_figure))];
ls = [ls addlistener(disp_config_obj,'Mode','PostSet',@(src,envdata)listenMode(src,envdata,main_figure))];

setappdata(main_figure,'ListenersH',ls);

end