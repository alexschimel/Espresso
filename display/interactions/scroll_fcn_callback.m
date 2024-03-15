function scroll_fcn_callback(src,callbackdata,main_figure)
%SCROLL_FCN_CALLBACK  One-line description
%
%   See also ESPRESSO.

%   Copyright 2017-2021 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

map_tab_comp = getappdata(main_figure,'Map_tab');

ah = map_tab_comp.map_axes;

% current boundaries
x_lim = get(ah,'XLim');
y_lim = get(ah,'YLim');

% cursor position
if src == main_figure
    set(ah,'units','pixels');
    pos = ah.CurrentPoint(1,1:2);
    set(ah,'units','normalized');
else
    pos = [nanmean(x_lim) nanmean(y_lim)];
end

% exit if cursor outside of window
if (pos(1)<x_lim(1)||pos(1)>x_lim(2))||pos(2)<y_lim(1)||pos(2)>y_lim(2)
    return;
end

% range of current boundaries
dx = diff(x_lim);
dy = diff(y_lim);

% current center
center_x = x_lim(1) + dx./2;
center_y = y_lim(1) + dy./2;

% zoom ratio (the closer to zero the smaller the zoom step, the closer to 1
% the bigger the step)
zoom_ratio = 0.2;

pos_p=getpixelposition(ah);

r=pos_p(3)/pos_p(4);

dz=nanmax(dx,dy);

dy=1/r*dz;
dx=dz;

if callbackdata.VerticalScrollCount<0
    % zoom in
    
    % shrinked range
    dx_new = dx*(1-zoom_ratio);
    dy_new = dy*(1-zoom_ratio);
    
    % new center
    center_x_new = center_x + (pos(1)-center_x).*zoom_ratio;
    center_y_new = center_y + (pos(2)-center_y).*zoom_ratio;
    
    % new limits
    x_lim_new = center_x_new + [-dx_new/2,dx_new/2]; 
    y_lim_new = center_y_new + [-dy_new/2,dy_new/2]; 
    
    % old zoom:
    % x_lim_new = [pos(1) pos(1)]+[-2*dx/8 2*dx/8];
    % y_lim_new = [pos(2) pos(2)]+[-2*dy/8 2*dy/8];
    
else
    % zoom out
    
    % expanded range
    
    dx_new = dx*(1+zoom_ratio);
    dy_new = dy*(1+zoom_ratio);
    
    % new center
    center_x_new = center_x - (pos(1)-center_x).*zoom_ratio;
    center_y_new = center_y - (pos(2)-center_y).*zoom_ratio;
    
    % new limits
    x_lim_new = center_x_new + [-dx_new/2,dx_new/2]; 
    y_lim_new = center_y_new + [-dy_new/2,dy_new/2]; 
    
    % old zoom
    % x_lim_new = [pos(1) pos(1)]+[-5*dx/8 5*dx/8];
    % y_lim_new = [pos(2) pos(2)]+[-5*dy/8 5*dy/8];
    
end

if diff(x_lim_new)<=0 || diff(y_lim_new)<=0
    return;
end

set(ah,'XLim',x_lim_new,'YLim',y_lim_new);

end