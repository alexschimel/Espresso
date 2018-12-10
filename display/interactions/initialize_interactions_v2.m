function initialize_interactions_v2(main_figure)

interactions = getappdata(main_figure,'interactions_id');

if isempty(interactions)
    interactions.WindowButtonDownFcn = nan(1,2);
    interactions.WindowButtonMotionFcn = nan(1,3);
    interactions.WindowButtonUpFcn = nan(1,2);
    interactions.WindowKeyPressFcn = nan(1,2);
    interactions.KeyPressFcn = nan(1,2);
    interactions.WindowKeyReleaseFcn = nan(1,2);
    interactions.KeyReleaseFcn = nan(1,2);
    interactions.WindowScrollWheelFcn = nan(1,2);
end

field_interaction = fieldnames(interactions);

for i = 1:numel(field_interaction)
    for ir = 1:numel(interactions.(field_interaction{i}))
        iptremovecallback(main_figure,field_interaction{i}, interactions.(field_interaction{i})(ir));
        interactions.(field_interaction{i})(ir) = nan;
    end
end

%%% Set Interactions

% Pointer to Arrow
setptr(main_figure,'arrow');

% Initialize Mouse interactions in the figure
interactions.WindowButtonDownFcn(1) = iptaddcallback(main_figure,'WindowButtonDownFcn',' ');

% Initialize Keyboard interactions in the figure
interactions.KeyPressFcn(1) = iptaddcallback(main_figure,'KeyPressFcn',{@shortcuts_func,main_figure});

% Set wheel mouse scroll cback
interactions.WindowScrollWheelFcn(1) = iptaddcallback(main_figure,'WindowScrollWheelFcn',{@scroll_fcn_callback,main_figure});

% Set pointer motion cback
interactions.WindowButtonMotionFcn(1) = iptaddcallback(main_figure,'WindowButtonMotionFcn',{@disp_cursor_info,main_figure});

setappdata(main_figure,'interactions_id',interactions);

end