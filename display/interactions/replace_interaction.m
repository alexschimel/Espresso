function replace_interaction(curr_fig,varargin)
%REPLACE_INTERACTION  One-line description
%
%   See also ESPRESSO.

%   Authors: Yoann Ladroit (NIWA, yoann.ladroit@niwa.co.nz) and Alex
%   Schimel (NIWA, alexandre.schimel@niwa.co.nz)
%   2017-2021; Last revision: 10-12-2018

% replace_interaction(curr_fig,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',{@zoom_in_callback,curr_fig},'pointer','glassplus');

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