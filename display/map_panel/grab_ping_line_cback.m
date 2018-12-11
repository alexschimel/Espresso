function grab_ping_line_cback(src,evt,main_figure)

fData_tot = getappdata(main_figure,'fData');

if isempty(fData_tot)
    return;
end

disp_config = getappdata(main_figure,'disp_config');
map_tab_comp = getappdata(main_figure,'Map_tab');

fData = fData_tot{disp_config.Fdata_idx};

ah = map_tab_comp.map_axes;

current_fig = gcf;

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
        disp_config.AcrossDist = across_dist;
        disp_config.Iping = ip;

    end

    function wbucb(~,~)
        
        replace_interaction(current_fig,'interaction','WindowButtonMotionFcn','id',2);
        replace_interaction(current_fig,'interaction','WindowButtonUpFcn','id',2);
        
    end
end