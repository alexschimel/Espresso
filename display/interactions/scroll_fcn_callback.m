function scroll_fcn_callback(src,callbackdata,main_figure)

map_tab_comp=getappdata(main_figure,'Map_tab');

ah=map_tab_comp.map_axes;

x_lim=get(ah,'XLim');
y_lim=get(ah,'YLim');

if src==main_figure
    set(ah,'units','pixels');
    pos=ah.CurrentPoint(1,1:2);
    set(ah,'units','normalized');
else
    pos=[nanmean(x_lim) nanmean(y_lim)];
end

if (pos(1)<x_lim(1)||pos(1)>x_lim(2))||pos(2)<y_lim(1)||pos(2)>y_lim(2)
    return;
end

dx=diff(x_lim);
dy=diff(y_lim);

if callbackdata.VerticalScrollCount<0
    x_lim_new=[pos(1) pos(1)]+[-3*dx/8 3*dx/8];
    y_lim_new=[pos(2) pos(2)]+[-3*dy/8 3*dy/8];   
else  
    x_lim_new=[pos(1) pos(1)]+[-5*dx/8 5*dx/8];
    y_lim_new=[pos(2) pos(2)]+[-5*dy/8 5*dy/8]; 
end


if diff(x_lim_new)<=0||diff(y_lim_new)<=0
    return;
end
set(ah,'XLim',x_lim_new,'YLim',y_lim_new);


end