function grab_vert_ping_line_cback(src,evt,main_figure)
%GRAB_VERT_PING_LINE_CBACK  One-line description
%
%   See also ESPRESSO.

%   Authors: Yoann Ladroit (NIWA, yoann.ladroit@niwa.co.nz) and Alex
%   Schimel (NIWA, alexandre.schimel@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

% profile on;
fData_tot = getappdata(main_figure,'fData');

if isempty(fData_tot)
    return;
end

disp_config = getappdata(main_figure,'disp_config');
stacked_wc_tab_comp = getappdata(main_figure,'stacked_wc_tab');

IDs=cellfun(@(c) c.ID,fData_tot);


if ~ismember(disp_config.Fdata_ID , IDs)
    disp_config.Fdata_ID = IDs(1);
    disp_config.Iping = 1;
    return;
end

fData = fData_tot{disp_config.Fdata_ID==IDs};
nb_pings=numel(fData.X_1P_pingCounter);
ah=stacked_wc_tab_comp.wc_axes;

current_fig = gcf;

ip=1;

if strcmp(current_fig.SelectionType,'normal')
    
    replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2,'interaction_fcn',@wbmcb,'Pointer','fleur');
    replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',2,'interaction_fcn',@wbucb);
    
end

    function wbmcb(~,~)
        
        pt = ah.CurrentPoint;
        ip=round(pt(1,1));
        ip=nanmin(ip,nb_pings);
        ip=nanmax(ip,1);
        set(stacked_wc_tab_comp.ping_gh,'XData',ones(1,2)*ip);
        
        
    end

    function wbucb(~,~)
        
        
        replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2);
        replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',2);
        disp_config.Iping = ip;
    end
end