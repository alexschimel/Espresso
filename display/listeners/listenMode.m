function listenMode(~,listdata,main_figure)
%LISTENMODE  Callback function when Mode is modified
%
%   See also ESPRESSO.

%   Copyright 2017-2021 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

if ~isdeployed
    disp('ListenMode')
end

switch listdata.AffectedObject.Mode
    
    case 'Normal'
        
        % set normal interaction (select, and pan)
        replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',{@move_map_cback,main_figure},'pointer','arrow');
        
        map_tab_comp = getappdata(main_figure,'Map_tab');
        set(map_tab_comp.tgbt1,'Value',1);
        set(map_tab_comp.tgbt2,'Value',0);
        setappdata(main_figure,'Map_tab',map_tab_comp);

    case 'DrawNewFeature'
        
        % set feature drawing interaction
        replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',{@draw_new_feature,main_figure},'pointer','crosshair');
        
        map_tab_comp = getappdata(main_figure,'Map_tab');
        set(map_tab_comp.tgbt1,'Value',0);
        set(map_tab_comp.tgbt2,'Value',1);
        setappdata(main_figure,'Map_tab',map_tab_comp);
        
end

end