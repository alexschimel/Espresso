
%% Function
function shortcuts_func(src,callbackdata,main_figure)

disp_config=getappdata(main_figure,'disp_config');

replace_interaction(src,'interaction','KeyPressFcn','id',1);

try
    switch callbackdata.Key        
        case {'0' 'numpad0'}
            disp_config.Mode='Normal';
        case {'1' 'numpad1'}
            disp_config.Mode='DrawPolyFeature';
        case {'2' 'numpad2'}
           
        case {'3' 'numpad3'}
        
        case {'4' 'numpad4'}
          
        case {'6' 'numpad6'}
          
        case {'5' 'numpad5'}
         
    end
catch
    if~isdeployed
        disp('Error in Keyboard_func');
    end
end
replace_interaction(src,'interaction','KeyPressFcn','id',1,'interaction_fcn',{@shortcuts_func,main_figure});


end