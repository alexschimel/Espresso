
%% Function
function shortcuts_func(src,callbackdata,main_figure)

disp_config=getappdata(main_figure,'disp_config');
fData_tot=getappdata(main_figure,'fData');
if isempty(fData_tot)
    return;
end
fData=fData_tot{disp_config.Fdata_idx};
nb_pings=numel(fData.WC_1P_Date);
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
            
        case {'uparrow'}
            disp_config.Iping=nanmin(disp_config.Iping+ceil(disp_config.StackPingWidth/5),nb_pings);
        case {'downarrow'}
            disp_config.Iping=nanmax(disp_config.Iping-ceil(disp_config.StackPingWidth/5),1);        
    end
catch
    if~isdeployed
        disp('Error in Keyboard_func');
    end
end
replace_interaction(src,'interaction','KeyPressFcn','id',1,'interaction_fcn',{@shortcuts_func,main_figure});


end