function shortcuts_func(src,callbackdata,main_figure)

% get data
disp_config = getappdata(main_figure,'disp_config');
fData_tot = getappdata(main_figure,'fData');

if isempty(fData_tot)
    return;
end

% get relevant fData
IDs=cellfun(@(c) c.ID,fData_tot);


if ~ismember(disp_config.Fdata_ID , IDs)
    disp_config.Fdata_ID = IDs(1);
    disp_config.Iping = 1;
    return;
end

fData = fData_tot{disp_config.Fdata_ID ==IDs};

% total number of pings
nb_pings = numel(fData.X_1P_pingCounter);

% ?
replace_interaction(src,'interaction','KeyPressFcn','id',1);

try
    switch callbackdata.Key
        
        case {'1' 'numpad0'}
            % Normal interaction with map
            disp_config.Mode = 'Normal';
            
        case {'2' 'numpad1'}
            % Mode to draw features on map
            disp_config.Mode = 'DrawNewFeature';
            
        case {'3' 'numpad3'}
            
        case {'4' 'numpad4'}
            
        case {'5' 'numpad6'}
            
        case {'6' 'numpad5'}
            
        case {'uparrow'}
            % Use Up/Down arrow to move pings by a set offset
            disp_config.Iping = nanmin(disp_config.Iping+1,nb_pings);
            
        case {'downarrow'}
            % Use Up/Down arrow to move pings by a set offset
            disp_config.Iping = nanmax(disp_config.Iping-1,1);
            
    end
    
catch
    if ~isdeployed
        disp('Error in Keyboard_func');
    end
end

% ?
replace_interaction(src,'interaction','KeyPressFcn','id',1,'interaction_fcn',{@shortcuts_func,main_figure});

end