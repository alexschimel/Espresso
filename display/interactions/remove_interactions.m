%% remove_interactions.m
%
% Initialize user interactions with ESP3 main figure, new version, in
% developpement
%
%% Help
%
% *USE*
%
% TODO
%
% *INPUT VARIABLES*
%
% * |main_figure|: Handle to main ESP3 window (Required).
%
% *OUTPUT VARIABLES*
%
% NA
%
% *RESEARCH NOTES*
%
% TODO
%
% *NEW FEATURES*
%
% * 2017-06-29: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function remove_interactions(main_figure)

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