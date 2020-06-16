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
function grab_ping_line_cback(src,evt,main_figure)

% profile on;

fData_tot   = getappdata(main_figure,'fData');
map_tab_comp = getappdata(main_figure,'Map_tab');
disp_config = getappdata(main_figure,'disp_config');

% If no data to grab, and not in Normal mode, exit
if isempty(fData_tot)||~strcmpi(disp_config.Mode,'normal')
    return;
end

IDs = cellfun(@(c) c.ID,fData_tot);
if ~ismember(disp_config.Fdata_ID, IDs)
    disp_config.Fdata_ID = IDs(1);
    disp_config.Iping = 1;
    return;
end

% current data
fData = fData_tot{disp_config.Fdata_ID==IDs};

ah = map_tab_comp.map_axes;
current_fig = gcf;
across_dist = 0;
ip = 1;

% modify interaction
if strcmp(current_fig.SelectionType,'normal')
    
    replace_interaction(current_fig,'interaction','WindowButtonMotionFcn','id',2,'interaction_fcn',@wbmcb,'Pointer','fleur');
    replace_interaction(current_fig,'interaction','WindowButtonUpFcn','id',2,'interaction_fcn',@wbucb);
    
end

    function wbmcb(~,~)
        pt = ah.CurrentPoint;
        E = fData.X_1P_pingE;
        N = fData.X_1P_pingN;
        [across_dist,ip] = min(sqrt((E-pt(1,1)).^2+(N-pt(1,2)).^2));
        heading = fData.X_1P_pingHeading(ip)/180*pi;
        % z = E(ip)*pt(1,1)+ N(ip)*pt(1,2);
        heading = -heading+pi/2;
        % heading/pi*180
        z = cross([cos(heading) sin(heading) 0], [pt(1,1)-E(ip) pt(1,2)-N(ip) 0]);
        z = -z(3);
        across_dist = sign(z)*across_dist;
        set(map_tab_comp.ping_swathe,'XData',fData.X_BP_bottomEasting(:,ip),'YData',fData.X_BP_bottomNorthing(:,ip));
    end

    function wbucb(~,~)
        % profile off;
        %  profile viewer;
        disp_config.AcrossDist = across_dist;
        disp_config.Iping = ip;
        replace_interaction(current_fig,'interaction','WindowButtonMotionFcn','id',2);
        replace_interaction(current_fig,'interaction','WindowButtonUpFcn','id',2);
    end

end