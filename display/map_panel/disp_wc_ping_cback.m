function disp_wc_ping_cback(src,evt,main_figure)

current_figure=gcf;
switch current_figure.SelectionType
    case 'alt'
        map_tab_comp=getappdata(main_figure,'Map_tab');
        ax=map_tab_comp.map_axes;
        xlim=ax.XLim;
        ylim=ax.YLim;

        pt0 = ax.CurrentPoint;
        
        replace_interaction(current_figure,'interaction','WindowButtonMotionFcn','id',2,'interaction_fcn',@wbmcb,'Pointer','hand');
        replace_interaction(current_figure,'interaction','WindowButtonUpFcn','id',2,'interaction_fcn',@wbucb);
        
    case 'normal'
        
        fData_tot=getappdata(main_figure,'fData');
        
        if isempty(fData_tot)
            return;
        end
        IDs_tot=nan(1,numel(fData_tot));
        for i=1:numel(fData_tot)
            IDs_tot(i)=fData_tot{i}.ID;
        end
        switch src.Type
            case 'line'
                ID=str2double(src.Tag);
            case 'image'
                ID=str2double(src.Tag(3:end));
        end
        idx_fData=(IDs_tot==ID);
        
        fData=fData_tot{idx_fData};
        
        E=fData.X_1P_pingE;
        N=fData.X_1P_pingN;
        pt=evt.IntersectionPoint;
        [across_dist,ip]=min(sqrt((E-pt(1)).^2+(N-pt(2)).^2));
        
        %z=E(ip)*pt(1)+ N(ip)*pt(2);
        heading=fData.X_1P_pingHeading(ip)/180*pi;
        z=cross([cos(heading) sin(heading) 0], [pt(1)-E(ip) pt(2)-N(ip) 0]);
        z=z(3);
        
        disp_config=getappdata(main_figure,'disp_config');
        
        disp_config.AcrossDist=-sign(z)*across_dist;
        disp_config.Iping=ip;
        disp_config.Fdata_idx=find(idx_fData);
        
        update_wc_tab(main_figure);
        
end

    function wbmcb(~,~)
        pt = ax.CurrentPoint;
   
    end

    function wbucb(~,~)
        xlim_n=xlim-(pt(1,1)-pt0(1,1));
        ylim_n=ylim-(pt(1,2)-pt0(1,2));
        set(ax,'XLim',xlim_n,'YLim',ylim_n);
        replace_interaction(current_figure,'interaction','WindowButtonMotionFcn','id',2,'Pointer','arrow');
        replace_interaction(current_figure,'interaction','WindowButtonUpFcn','id',2);
        
    end

end