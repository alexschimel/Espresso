function resize_espresso(main_figure,~)
map_tab_comp=getappdata(main_figure,'Map_tab');
ax=map_tab_comp.map_axes;
xlim=ax.XLim;
ylim=ax.YLim;
pos=getpixelposition(ax);
ratio=pos(4)/pos(3);
dx=nanmax([diff(xlim) diff(ylim)]);
dy=dx*ratio;
xlim=mean(xlim)+[-11*dx/20 +11*dx/20];
ylim=mean(ylim)+[-11*dy/20 +11*dy/20];

set(ax,'YLim',ylim,'XLim',xlim);
end