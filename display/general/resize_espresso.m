function resize_espresso(main_figure,~)
%FUNCTION_NAME  resize Espresso main figure
%
%   Callback function of the main figure
%
%   See also ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 21-07-2021

% get current axes info
map_tab_comp = getappdata(main_figure,'Map_tab');

if ~isempty(map_tab_comp)
    
    ax = map_tab_comp.map_axes;
    
    % get info needed
    xlim = ax.XLim;
    ylim = ax.YLim;
    pos = getpixelposition(ax);
    
    % calculate new window height/width ratio
    ratio = pos(4)/pos(3);
    
    % ensure xlim and ylim maintain that ratio for equal units
    dx = diff(xlim);
    dy = dx*ratio;
    
    % calculate new xlim and ylim
    xlim = mean(xlim)+[-dx/2 dx/2];
    ylim = mean(ylim)+[-dy/2 dy/2];
    
    % set
    set(ax,'YLim',ylim,'XLim',xlim);
    
end

end