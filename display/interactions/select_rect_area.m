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
function select_rect_area(main_figure,func)

map_tab_comp = getappdata(main_figure,'Map_tab');

ah = map_tab_comp.map_axes;

x_lim = get(ah,'xlim');
y_lim = get(ah,'ylim');

cp = ah.CurrentPoint;
xinit = cp(1,1);
yinit = cp(1,2);

if xinit<x_lim(1) || xinit>x_lim(end) || yinit<y_lim(1) || yinit>y_lim(end)
    return;
end

u = 1;

x_box = xinit;
y_box = yinit;

hp = line(ah,x_box,y_box,'color','r','linewidth',1,'Tag','reg_temp');

% replacing mouse interactions when moving the pointer, and releasing the
% button
replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2,'interaction_fcn',@wbmcb);
replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',2,'interaction_fcn',@wbucb);

    function wbmcb(~,~)
        
        % callback when mouse moves -> update the red box
        
        u = u+1;
                
        cp = ah.CurrentPoint;
        X = [xinit,cp(1,1)];
        Y = [yinit,cp(1,2)];
        
        x_min = nanmin(X);
        x_max = nanmax(X);
        y_min = nanmin(Y);
        y_max = nanmax(Y);
        
        x_box = ([x_min x_max  x_max x_min x_min]);
        y_box = ([y_max y_max y_min y_min y_max]);
        
        if isvalid(hp)
            set(hp,'XData',x_box,'YData',y_box,'Tag','reg_temp');
        else
            hp = plot(ah,x_box,x_box,'color','k','linewidth',1);
        end
        
    end

    function wbucb(main_figure,~)
        
        % replace interactions back to nothing
        replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2);
        replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',2);
        
        if isempty(y_box) || isempty(x_box)
            delete(txt);
            delete(hp);
            return;
        end
        
        y_min = nanmin(y_box);
        y_max = nanmax(y_box);
        x_min = nanmin(x_box);
        x_max = nanmax(x_box);
        
        delete(hp);
        
        feval(func,main_figure,[x_min x_max],[y_min y_max]);
        
    end



end