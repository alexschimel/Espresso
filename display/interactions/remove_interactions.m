function remove_interactions(main_figure)
%REMOVE_INTERACTIONS  Initialize user interactions with Espresso
%
%   New version, in development
%
%   See also ESPRESSO.

%   Authors: Yoann Ladroit (NIWA, yoann.ladroit@niwa.co.nz) and Alex
%   Schimel (NIWA, alexandre.schimel@niwa.co.nz)
%   2017-2021; Last revision: 29-06-2017

interactions = getappdata(main_figure,'interactions_id');

if isempty(interactions)
    interactions.WindowButtonDownFcn = nan(1,2);
    interactions.WindowButtonMotionFcn = nan(1,2);
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

end