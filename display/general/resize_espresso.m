%% resize_espresso.m
%
% Callback function when Espresso's main figure is resized
%
function resize_espresso(main_figure,~)

% get current axes info
map_tab_comp = getappdata(main_figure,'Map_tab');

if ~isempty(map_tab_comp)
    
    ax = map_tab_comp.map_axes;
    
    % get info needed
    xlim = ax.XLim;
    ylim = ax.YLim;
    pos = getpixelposition(ax);
    
    % calculate ration
    ratio = pos(4)/pos(3);
    dx = nanmax([diff(xlim) diff(ylim)]);
    dy = dx*ratio;
    
    xlim = mean(xlim)+[-11*dx/20 +11*dx/20];
    ylim = mean(ylim)+[-11*dy/20 +11*dy/20];
    
    set(ax,'YLim',ylim,'XLim',xlim);
    
end

end