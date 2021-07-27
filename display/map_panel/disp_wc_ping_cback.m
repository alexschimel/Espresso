function disp_wc_ping_cback(src,evt,main_figure)
%DISP_WC_PING_CBACK  Called when clicking on a navigation line on the map
%
%   See also UPDATE_MAP_TAB, ESPRESSO

%   Authors: Yoann Ladroit (NIWA, yoann.ladroit@niwa.co.nz) and Alex
%   Schimel (NIWA, alexandre.schimel@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

current_figure = gcf;

switch current_figure.SelectionType
    
    case 'normal' % left-click
        
        % get ID of all lines
        fData_tot = getappdata(main_figure,'fData');
        if isempty(fData_tot)
            return;
        end
        IDs_tot = cellfun(@(c) c.ID,fData_tot);
        
        % get ID of selection
        switch src.Type
            case 'line'
                % clicking on nav line
                ID = str2double(src.Tag(1:end-4));
            case 'image'
                % clicking on grid
                ID = str2double(src.Tag(1:end-3));
        end
        
        % check if line is active
        idx_fData = find(IDs_tot==ID);
        fdata_tab_comp = getappdata(main_figure,'fdata_tab');
        idx_active_lines = cell2mat(fdata_tab_comp.table.Data(:,3));
        if ~idx_active_lines(idx_fData)
            return
        end
        
        % get fdata of selected line
        fData = fData_tot{idx_fData};
        
        % find nearest ping, and calculate horizontal distance from
        % selection to line
        E = fData.X_1P_pingE;
        N = fData.X_1P_pingN;
        pt = evt.IntersectionPoint;
        [across_dist,ip] = min(sqrt((E-pt(1)).^2+(N-pt(2)).^2));
        
        % correct sign of across_dist
        heading = fData.X_1P_pingHeading(ip)/180*pi;
        heading = -heading+pi/2;
        z = cross([cos(heading) sin(heading) 0], [pt(1)-E(ip) pt(2)-N(ip) 0]);
        z = -z(3);
        across_dist = sign(z)*across_dist;
        
        % get and update disp_config
        disp_config = getappdata(main_figure,'disp_config');
        disp_config.AcrossDist = across_dist;
        disp_config.Fdata_ID = ID;
        disp_config.Iping = ip; % calls listenIping
        
end
