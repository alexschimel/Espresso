function grab_ping_line_cback(src,evt,main_figure)

fData_tot = getappdata(main_figure,'fData');

if isempty(fData_tot)
    return;
end

disp_config = getappdata(main_figure,'disp_config');
map_tab_comp = getappdata(main_figure,'Map_tab');

fData = fData_tot{disp_config.Fdata_idx};

ip = map_tab_comp.ping_line.UserData.ip;
ID = map_tab_comp.ping_line.UserData.ID;

IDs_tot = nan(1,numel(fData_tot));

for i = 1:numel(fData_tot)
    IDs_tot(i) = fData_tot{i}.ID;
end

idx_fData = (IDs_tot==ID);
fData = fData_tot{idx_fData};
ah = map_tab_comp.map_axes;
disp_config.Fdata_idx = find(idx_fData);

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
        
        s.ID = fData.ID;
        s.ip = ip;
        
        
         if isfield(fData,'X_BP_bottomEasting')
             idx_pings=nanmax(1,ip-disp_config.StackPingWidth):nanmin(ip+disp_config.StackPingWidth-1,size(fData.X_BP_bottomEasting,2));
             e_p=fData.X_BP_bottomEasting(:,idx_pings);
             e_p_s = arrayfun(@(col) e_p(find(~isnan(e_p(:, col)),1,'first'),col), ...
               1:size(e_p, 2), 'UniformOutput', 1);
             e_p_e = arrayfun(@(col) e_p(find(~isnan(e_p(:, col)),1,'last'),col), ...
               1:size(e_p, 2), 'UniformOutput', 1);
           
             n_p=fData.X_BP_bottomNorthing(:,idx_pings);
             n_p_s = arrayfun(@(col) n_p(find(~isnan(n_p(:, col)),1,'first'),col), ...
               1:size(e_p, 2), 'UniformOutput', 1);
             n_p_e = arrayfun(@(col) n_p(find(~isnan(n_p(:, col)),1,'last'),col), ...
               1:size(e_p, 2), 'UniformOutput', 1);
           new_vert=[[e_p_s fliplr(e_p_e)];[n_p_s fliplr(n_p_e)]]';
           
             set(map_tab_comp.ping_line,'XData',fData.X_BP_bottomEasting(:,ip),'YData',fData.X_BP_bottomNorthing(:,ip),'userdata',s);
             map_tab_comp.ping_poly.Shape.Vertices=new_vert;
                
         else
             return;
         end
        
        update_wc_tab(main_figure)
        
    end

    function wbucb(~,~)
        
        replace_interaction(current_fig,'interaction','WindowButtonMotionFcn','id',2);
        replace_interaction(current_fig,'interaction','WindowButtonUpFcn','id',2);
        
    end
end