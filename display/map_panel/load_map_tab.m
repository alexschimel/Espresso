function load_map_tab(main_figure,map_tab_group)

if isappdata(main_figure,'Map_tab')
    map_tab_comp=getappdata(main_figure,'Map_tab');
    delete(map_tab_comp.map_tab);
    rmappdata(main_figure,'Map_tab');
end

map_tab=uitab(map_tab_group,'BackgroundColor',[1 1 1],'tag','axes_panel','Title','Map');

map_tab_comp.map_tab=map_tab;

map_tab_comp.map_axes=axes('Parent',map_tab,'FontSize',10,'Units','normalized',...
    'OuterPosition',[0 0 1 1],...
    'XAxisLocation','bottom',...
    'XLimMode','auto',...
    'YLimMode','auto',...
    'TickDir','in',...
    'box','on',...
    'SortMethod','childorder',...
    'NextPlot','add',...
    'visible','on',...
    'Tag','main');


axis(map_tab_comp.map_axes,'equal');
grid(map_tab_comp.map_axes,'on');
xlabel(map_tab_comp.map_axes,'Easting (m)')
ylabel(map_tab_comp.map_axes,'Northing (m)')

setappdata(main_figure,'Map_tab',map_tab_comp);


end