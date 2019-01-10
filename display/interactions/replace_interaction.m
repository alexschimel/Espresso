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
function replace_interaction(curr_fig,varargin)

% replace_interaction(curr_fig,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',{@zoom_in_callback,curr_fig},'pointer','glassplus');

%% parsing inputs

% list of valid interaction types
interact_fields = {'WindowButtonDownFcn',... % End user presses a mouse button while the pointer is in the figure window.
    'WindowButtonMotionFcn',... % End user moves the pointer within the figure window.
    'WindowButtonUpFcn',... % End user releases a mouse button.
    'WindowKeyPressFcn',... % End user presses a key while the pointer is on the figure or any of its child objects.
    'KeyPressFcn',... % End user presses a keyboard key while the pointer is on the object.
    'WindowKeyReleaseFcn',... % End user releases a key while the pointer is on the figure or any of its child objects.
    'WindowScrollWheelFcn'}; % End user turns the mouse wheel while the pointer is on the figure.

p = inputParser;
addRequired(p,'curr_fig',@ishandle);
addParameter(p,'interaction','WindowButtonDownFcn',@(x) ismember(x,interact_fields));
addParameter(p,'id',1,@(x) ismember(x,[1 2 3]));
addParameter(p,'interaction_fcn',[],@(x) isempty(x)||isa(x,'function_handle')||iscell(x));
addParameter(p,'pointer',[],@(x) ischar(x)||isempty(x))
parse(p,curr_fig,varargin{:});

% get list of current interaction callbacks in main figure
interactions_id = getappdata(curr_fig,'interactions_id');

if isempty(interactions_id)
    return;
end

% remove from the figure the callback we want to replace
iptremovecallback(curr_fig,p.Results.interaction,interactions_id.(p.Results.interaction)(p.Results.id));

if isempty(p.Results.interaction_fcn)
    fcn = ' ';
else
    fcn = p.Results.interaction_fcn;
end

% and add the new callback in its place, saving handle to interactions_id
interactions_id.(p.Results.interaction)(p.Results.id) = iptaddcallback(curr_fig,(p.Results.interaction),fcn);

% modify the pointer
if ~isempty(p.Results.pointer)
    setptr(curr_fig,p.Results.pointer);
end

% and save interactions_id back into figure
setappdata(curr_fig,'interactions_id',interactions_id);

end