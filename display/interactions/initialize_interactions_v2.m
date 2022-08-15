function initialize_interactions_v2(main_figure)
%INITIALIZE_INTERACTIONS_V2  Initialize button interactions in Espresso
%
%   See also ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 21-07-2021

interactions = getappdata(main_figure,'interactions_id');

if isempty(interactions)
    % initialize
    
    interactions.WindowButtonDownFcn   = nan(1,2); % End user presses a mouse button while the pointer is in the figure window.
    interactions.WindowButtonMotionFcn = nan(1,3); % End user moves the pointer within the figure window.
    interactions.WindowButtonUpFcn     = nan(1,2); % End user releases a mouse button.
    interactions.WindowKeyPressFcn     = nan(1,2); % End user presses a key while the pointer is on the figure or any of its child objects.
    interactions.KeyPressFcn           = nan(1,2); % End user presses a keyboard key while the pointer is on the object.
    interactions.WindowKeyReleaseFcn   = nan(1,2); % End user releases a key while the pointer is on the figure or any of its child objects.
    interactions.KeyReleaseFcn         = nan(1,2);
    interactions.WindowScrollWheelFcn  = nan(1,2); % End user turns the mouse wheel while the pointer is on the figure.
    
else
    % re-initialize
    
    % list of interaction types
    field_interaction = fieldnames(interactions);
    
    % remove all callbacks and nan all callback identifiers
    for i = 1:numel(field_interaction)
        for ir = 1:numel(interactions.(field_interaction{i}))
            iptremovecallback(main_figure,field_interaction{i}, interactions.(field_interaction{i})(ir));
            interactions.(field_interaction{i})(ir) = nan;
        end
    end
    
end

%% now set initial interactions

% Set pointer to arrow
setptr(main_figure,'arrow');

% Set normal interactions in the figure
interactions.WindowButtonDownFcn(1)   = iptaddcallback(main_figure,'WindowButtonDownFcn',{@move_map_cback,main_figure});       % left-click on map, for panning
interactions.KeyPressFcn(1)           = iptaddcallback(main_figure,'KeyPressFcn',{@shortcuts_func,main_figure});               % press keyboard key, for shortcuts
interactions.WindowScrollWheelFcn(1)  = iptaddcallback(main_figure,'WindowScrollWheelFcn',{@scroll_fcn_callback,main_figure}); % mouse scroll, for zoom
interactions.WindowButtonMotionFcn(1) = iptaddcallback(main_figure,'WindowButtonMotionFcn',{@disp_cursor_info,main_figure});   % move cursor, for navigation display

% add interactions to appdata
setappdata(main_figure,'interactions_id',interactions);

end