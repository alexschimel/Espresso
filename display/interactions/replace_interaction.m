
%replace_interaction(curr_fig,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',{@zoom_in_callback,curr_fig},'pointer','glassplus');
function replace_interaction(curr_fig,varargin)

interact_fields={'WindowButtonDownFcn',...
    'WindowButtonMotionFcn',...
    'WindowButtonUpFcn',...
    'WindowKeyPressFcn',...
    'KeyPressFcn',...
    'WindowKeyReleaseFcn',...
    'WindowScrollWheelFcn'};

p = inputParser;

addRequired(p,'curr_fig',@ishandle);
addParameter(p,'interaction','WindowButtonDownFcn',@(x) ismember(x,interact_fields));
addParameter(p,'id',1,@(x) ismember(x,[1 2 3]));
addParameter(p,'interaction_fcn',[],@(x) isempty(x)||isa(x,'function_handle')||iscell(x));
addParameter(p,'pointer',[],@(x) ischar(x)||isempty(x))

parse(p,curr_fig,varargin{:});

interactions_id=getappdata(curr_fig,'interactions_id');

if isempty(interactions_id)
    return;
end

iptremovecallback(curr_fig,p.Results.interaction,interactions_id.(p.Results.interaction)(p.Results.id));

if isempty(p.Results.interaction_fcn)
    fcn=' ';
else
    fcn=p.Results.interaction_fcn;
end
interactions_id.(p.Results.interaction)(p.Results.id)=iptaddcallback(curr_fig,(p.Results.interaction),fcn);

if isappdata(curr_fig,'Curr_disp')&&isempty(p.Results.pointer)
    curr_disp=getappdata(curr_fig,'Curr_disp');
    setptr(curr_fig,curr_disp.get_pointer());
elseif ~isempty(p.Results.pointer)
    setptr(curr_fig,p.Results.pointer);
end

setappdata(curr_fig,'interactions_id',interactions_id);

end