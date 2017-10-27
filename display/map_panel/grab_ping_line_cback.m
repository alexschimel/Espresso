function grab_ping_line_cback(src,evt,main_figure)

fData_tot=getappdata(main_figure,'fData');
if isempty(fData_tot);
    return;
end

map_tab_comp=getappdata(main_figure,'Map_tab');

ip=map_tab_comp.ping_line.UserData.ip;
ID=map_tab_comp.ping_line.UserData.ID;

IDs_tot=nan(1,numel(fData_tot));
for i=1:numel(fData_tot)
    IDs_tot(i)=fData_tot{i}.ID;
end

idx_fData=(IDs_tot==ID);
fData=fData_tot{idx_fData};
ah=map_tab_comp.map_axes;


current_fig=gcf;

if strcmp(current_fig.SelectionType,'normal')
        
    replace_interaction(current_fig,'interaction','WindowButtonMotionFcn','id',2,'interaction_fcn',@wbmcb,'Pointer','fleur');
    replace_interaction(current_fig,'interaction','WindowButtonUpFcn','id',2,'interaction_fcn',@wbucb);
    
    
end
    function wbmcb(~,~)
        pt = ah.CurrentPoint;
        
        E=fData.X_1P_pingE;
        N=fData.X_1P_pingN;

        [across_dist,ip]=min(sqrt((E-pt(1,1)).^2+(N-pt(1,2)).^2));
        
        z=cross([E(ip) N(ip) 0],[pt(1,1) pt(1,2) 0]);
        across_dist=sign(z(3))*across_dist;
        
        update_wc_tab(main_figure,fData,across_dist,ip);
        
    end

    function wbucb(~,~)
       
        replace_interaction(current_fig,'interaction','WindowButtonMotionFcn','id',2);
        replace_interaction(current_fig,'interaction','WindowButtonUpFcn','id',2);

    end
end