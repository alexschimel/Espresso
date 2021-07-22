function move_map_cback(~,~,main_figure)
%MOVE_MAP_CBACK  Call when left-clicking the map
%
%   See also ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 21-07-2021

current_figure = gcf;
if ~strcmpi(current_figure.Tag,'Espresso')
    return;
end

switch current_figure.SelectionType
    
    case 'normal' % left-click
        
        map_tab_comp = getappdata(main_figure,'Map_tab');
        
        % location of click in the main figure
        ax = map_tab_comp.map_axes;
        pt0 = ax.CurrentPoint;
        
        % check if cursor is in map
        pt0_outside_map = pt0(1,1)<ax.XLim(1) || pt0(1,1)>ax.XLim(2) || pt0(1,2)<ax.YLim(1) || pt0(1,2)>ax.YLim(2);
        if pt0_outside_map
            return;
        end
        
        % replace interactions for panning on the map
        replace_interaction(current_figure,'interaction','WindowButtonMotionFcn','id',2,'Pointer','hand','interaction_fcn',@wbmfcb);
        replace_interaction(current_figure,'interaction','WindowButtonUpFcn','id',2,'interaction_fcn',@wbucb);
        
    otherwise
        
        return;
        
end

    function wbmfcb(~,~)
        %WBMFCB Called when panning on the map
        
        % reset map's XLim and YLim so that pointer remains on initially
        % clicked position remain, effectively panning
        xlim = ax.XLim;
        ylim = ax.YLim;
        pt = ax.CurrentPoint;
        xlim_n = xlim-(pt(1,1)-pt0(1,1));
        ylim_n = ylim-(pt(1,2)-pt0(1,2));
        set(ax,'XLim',xlim_n,'YLim',ylim_n);
    end

    function wbucb(~,~)
        %WBUCB Called when releasing left button after panning
        
        % reset normal interactions
        replace_interaction(current_figure,'interaction','WindowButtonMotionFcn','id',2,'Pointer','arrow');
        replace_interaction(current_figure,'interaction','WindowButtonUpFcn','id',2);
    end

end