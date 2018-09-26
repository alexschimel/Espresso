function move_map_cback(src,evt,main_figure)

current_figure = gcf;

switch current_figure.SelectionType
    case 'alt'
        map_tab_comp = getappdata(main_figure,'Map_tab');
        ax = map_tab_comp.map_axes;
        xlim = ax.XLim;
        ylim = ax.YLim;
        
        pt0 = ax.CurrentPoint;
        
        replace_interaction(current_figure,'interaction','WindowButtonMotionFcn','id',2,'Pointer','hand');
        replace_interaction(current_figure,'interaction','WindowButtonUpFcn','id',2,'interaction_fcn',@wbucb);
        
    otherwise
        return;
end

    function wbucb(~,~)
        pt = ax.CurrentPoint;
        xlim_n = xlim-(pt(1,1)-pt0(1,1));
        ylim_n = ylim-(pt(1,2)-pt0(1,2));
        set(ax,'XLim',xlim_n,'YLim',ylim_n);
        replace_interaction(current_figure,'interaction','WindowButtonMotionFcn','id',2,'Pointer','arrow');
        replace_interaction(current_figure,'interaction','WindowButtonUpFcn','id',2);
        
    end

end