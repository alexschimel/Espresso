function init_listeners(main_figure)
%INIT_LISTENERS  Add listeners to disp_config properties.
%
%   See also ESPRESSO.

%   Copyright 2017-2021 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

% get config data
disp_config = getappdata(main_figure,'disp_config');

% get current listeners
if isappdata(main_figure,'ListenersH')
    ls = getappdata(main_figure,'ListenersH');
else
    ls = [];
end

% add listeners
ls = [ls addlistener(disp_config,'Act_features',     'PostSet',@(src,envdata) listenAct_features(src,envdata,main_figure) )];
ls = [ls addlistener(disp_config,'Cax_bathy',        'PostSet',@(src,envdata) listenCax(src,envdata,main_figure)          )];
ls = [ls addlistener(disp_config,'Cax_bs',           'PostSet',@(src,envdata) listenCax(src,envdata,main_figure)          )];
ls = [ls addlistener(disp_config,'Cax_wc',           'PostSet',@(src,envdata) listenCax(src,envdata,main_figure)          )];
ls = [ls addlistener(disp_config,'Cax_wc_int',       'PostSet',@(src,envdata) listenCax(src,envdata,main_figure)          )];
ls = [ls addlistener(disp_config,'Cmap',             'PostSet',@(src,envdata) listenCmap(src,envdata,main_figure)         )];
ls = [ls addlistener(disp_config,'Iping',            'PostSet',@(src,envdata) listenIping(src,envdata,main_figure)        )];
ls = [ls addlistener(disp_config,'Mode',             'PostSet',@(src,envdata) listenMode(src,envdata,main_figure)         )];
ls = [ls addlistener(disp_config,'StackAngularMode', 'PostSet',@(src,envdata) listenIping(src,envdata,main_figure)        )];
ls = [ls addlistener(disp_config,'StackAngularWidth','PostSet',@(src,envdata) listenIping(src,envdata,main_figure)        )];
ls = [ls addlistener(disp_config,'StackPingWidth',   'PostSet',@(src,envdata) listenIping(src,envdata,main_figure)        )];
ls = [ls addlistener(disp_config,'Var_disp',         'PostSet',@(src,envdata) listenVar_disp(src,envdata,main_figure)     )];

% save back into main figure
setappdata(main_figure,'ListenersH',ls);

end