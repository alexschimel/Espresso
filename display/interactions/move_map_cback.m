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
function move_map_cback(~,~,main_figure)

current_figure = gcf;
if ~strcmpi(current_figure.Tag,'Espresso')
    return;
end

switch current_figure.SelectionType
    
    case 'normal'
        
        map_tab_comp = getappdata(main_figure,'Map_tab');
        
        % get axes, its boundaries, and current point
        ax = map_tab_comp.map_axes;
        pt0 = ax.CurrentPoint;
        
        % exit if cursor outside of window
        if pt0(1,1)<ax.XLim(1) || pt0(1,1)>ax.XLim(2) || pt0(1,2)<ax.YLim(1) || pt0(1,2)>ax.YLim(2)
            return;
        end
        
        % setptr(main_figure,'hand');
        replace_interaction(current_figure,'interaction','WindowButtonMotionFcn','id',2,'Pointer','hand','interaction_fcn',@wbmfcb);
        replace_interaction(current_figure,'interaction','WindowButtonUpFcn','id',2,'interaction_fcn',@wbucb);
        
    otherwise
        
        return;
        
end

    function wbmfcb(~,~)
        xlim = ax.XLim;
        ylim = ax.YLim;
        pt = ax.CurrentPoint;
        xlim_n = xlim-(pt(1,1)-pt0(1,1));
        ylim_n = ylim-(pt(1,2)-pt0(1,2));
        set(ax,'XLim',xlim_n,'YLim',ylim_n);
        
    end


    function wbucb(~,~)
        
        replace_interaction(current_figure,'interaction','WindowButtonMotionFcn','id',2,'Pointer','arrow');
        replace_interaction(current_figure,'interaction','WindowButtonUpFcn','id',2);
        
        % setptr(main_figure,'arrow');
        
    end

end