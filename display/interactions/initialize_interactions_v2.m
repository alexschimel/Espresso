%% this_function_name.m
%
% _This section contains a very short description of the function, for the
% user to know this function is part of the software and what it does for
% it. Example below to replace. Delete these lines XXX._
%
% Template of ESP3 function header. XXX
%
%% Help
%
% *USE*
%
% _This section contains a more detailed description of what the function
% does and how to use it, for the interested user to have an overall
% understanding of its function. Example below to replace. Delete these
% lines XXX._
%
% This is a text file containing the basic comment template to add at the
% start of any new ESP3 function to serve as function help. XXX
%
% *INPUT VARIABLES*
%
% _This section contains bullet points of input variables with description
% and information. Put input variable and other valid entries or defaults
% between | symbols so it shows as monospace. Information section to
% contain, in order: requirement (i.e. Required/Optional/Paramter), valid
% type (e.g. Num, Positive num, char, 1xN cell array, etc.) and default
% value if there is one (e.g. Default: '10'). Example below to replace.
% Delete these lines XXX._
%
% * |input_variable_1|: Description (Information). XXX
% * |input_variable_2|: Description (Information). XXX
% * |input_variable_3|: Description (Information). XXX
%
% *OUTPUT VARIABLES*
%
% _This section contains bullet points of output variables with description
% and information. See input variables for template. Example below to
% replace. Delete these lines XXX._
%
% * |output_variable_1|: Description (Information). XXX
% * |output_variable_2|: Description (Information). XXX
%
% *DEVELOPMENT NOTES*
%
% _This section describes what features are temporary, needed future
% developments and paper references. Example below to replace. Delete these
% lines XXX._
%
% * research point 1. XXX
% * research point 2. XXX
%
% *NEW FEATURES*
%
% _This section contains dates and descriptions of major updates. Example
% below to replace. Delete these lines XXX._
%
% * YYYY-MM-DD: second version. Describes the update. XXX
% * YYYY-MM-DD: first version. XXX
%
% *EXAMPLE*
%
% _This section contains examples of valid function calls. Note that
% example lines start with 3 white spaces so that the publish function
% shows them correctly as matlab code. Example below to replace. Delete
% these lines XXX._
%
%   example_use_1; % comment on what this does. XXX
%   example_use_2: % comment on what this line does. XXX
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% _This last section contains at least author name and affiliation. Delete
% these lines XXX._
%
% Yoann Ladroit, Alexandre Schimel, NIWA. XXX

%% Function
function initialize_interactions_v2(main_figure)

interactions = getappdata(main_figure,'interactions_id');

% if this is the first time, initialize list of callback identifiers
if isempty(interactions)
    interactions.WindowButtonDownFcn   = nan(1,2); % End user presses a mouse button while the pointer is in the figure window.
    interactions.WindowButtonMotionFcn = nan(1,3); % End user moves the pointer within the figure window.
    interactions.WindowButtonUpFcn     = nan(1,2); % End user releases a mouse button.
    interactions.WindowKeyPressFcn     = nan(1,2); % End user presses a key while the pointer is on the figure or any of its child objects.
    interactions.KeyPressFcn           = nan(1,2); % End user presses a keyboard key while the pointer is on the object.
    interactions.WindowKeyReleaseFcn   = nan(1,2); % End user releases a key while the pointer is on the figure or any of its child objects.
    interactions.KeyReleaseFcn         = nan(1,2);
    interactions.WindowScrollWheelFcn  = nan(1,2); % End user turns the mouse wheel while the pointer is on the figure.
end

% list of interaction types
field_interaction = fieldnames(interactions);

% remove all callbacks and nan all callback identifiers
for i = 1:numel(field_interaction)
    for ir = 1:numel(interactions.(field_interaction{i}))
        iptremovecallback(main_figure,field_interaction{i}, interactions.(field_interaction{i})(ir));
        interactions.(field_interaction{i})(ir) = nan;
    end
end

%% now set initial interactions

% Set pointer to arrow
setptr(main_figure,'arrow');

% Set normal interactions in the figure
interactions.WindowButtonDownFcn(1)   = iptaddcallback(main_figure,'WindowButtonDownFcn',{@move_map_cback,main_figure});
interactions.KeyPressFcn(1)           = iptaddcallback(main_figure,'KeyPressFcn',{@shortcuts_func,main_figure});
interactions.WindowScrollWheelFcn(1)  = iptaddcallback(main_figure,'WindowScrollWheelFcn',{@scroll_fcn_callback,main_figure});
interactions.WindowButtonMotionFcn(1) = iptaddcallback(main_figure,'WindowButtonMotionFcn',{@disp_cursor_info,main_figure});

% add interactions to appdata
setappdata(main_figure,'interactions_id',interactions);

end