%% this_function_name.m
%
% Callback function when using the mouse wheel on the figure
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
function scroll_fcn_callback(src,callbackdata,main_figure)

map_tab_comp = getappdata(main_figure,'Map_tab');

ah = map_tab_comp.map_axes;

% current boundaries
x_lim = get(ah,'XLim');
y_lim = get(ah,'YLim');

% cursor position
if src == main_figure
    set(ah,'units','pixels');
    pos = ah.CurrentPoint(1,1:2);
    set(ah,'units','normalized');
else
    pos = [nanmean(x_lim) nanmean(y_lim)];
end

% exit if cursor outside of window
if (pos(1)<x_lim(1)||pos(1)>x_lim(2))||pos(2)<y_lim(1)||pos(2)>y_lim(2)
    return;
end

% range of current boundaries
dx = diff(x_lim);
dy = diff(y_lim);

% current center
center_x = x_lim(1) + dx./2;
center_y = y_lim(1) + dy./2;

% zoom ratio (the closer to zero the smaller the zoom step, the closer to 1
% the bigger the step)
zoom_ratio = 0.2;

if callbackdata.VerticalScrollCount<0
    % zoom in
    
    % shrinked range
    dx_new = dx*(1-zoom_ratio);
    dy_new = dy*(1-zoom_ratio);
    
    % new center
    center_x_new = center_x + (pos(1)-center_x).*zoom_ratio;
    center_y_new = center_y + (pos(2)-center_y).*zoom_ratio;
    
    % new limits
    x_lim_new = center_x_new + [-dx_new/2,dx_new/2]; 
    y_lim_new = center_y_new + [-dy_new/2,dy_new/2]; 
    
    % old zoom:
    % x_lim_new = [pos(1) pos(1)]+[-2*dx/8 2*dx/8];
    % y_lim_new = [pos(2) pos(2)]+[-2*dy/8 2*dy/8];
    
else
    % zoom out
    
    % expanded range
    dx_new = dx*(1+zoom_ratio);
    dy_new = dy*(1+zoom_ratio);
    
    % new center
    center_x_new = center_x - (pos(1)-center_x).*zoom_ratio;
    center_y_new = center_y - (pos(2)-center_y).*zoom_ratio;
    
    % new limits
    x_lim_new = center_x_new + [-dx_new/2,dx_new/2]; 
    y_lim_new = center_y_new + [-dy_new/2,dy_new/2]; 
    
    % old zoom
    % x_lim_new = [pos(1) pos(1)]+[-5*dx/8 5*dx/8];
    % y_lim_new = [pos(2) pos(2)]+[-5*dy/8 5*dy/8];
    
end

if diff(x_lim_new)<=0 || diff(y_lim_new)<=0
    return;
end

set(ah,'XLim',x_lim_new,'YLim',y_lim_new);

end