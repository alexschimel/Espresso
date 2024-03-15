function grab_ping_line_cback(src,evt,main_figure)
%GRAB_PING_LINE_CBACK  One-line description
%
%   See also ESPRESSO.

%   Copyright 2017-2021 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/


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