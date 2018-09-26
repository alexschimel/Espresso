%% load_map_tab.m
%
% Creates "Map" tab in Espresso's Map Panel
%
function load_map_tab(main_figure,map_tab_group)

if isappdata(main_figure,'Map_tab')
    map_tab_comp = getappdata(main_figure,'Map_tab');
    delete(map_tab_comp.map_tab);
    rmappdata(main_figure,'Map_tab');
end

disp_config = getappdata(main_figure,'disp_config');
map_tab = uitab(map_tab_group,'BackgroundColor',[1 1 1],'tag','axes_panel','Title','Map');

map_tab_comp.map_tab = map_tab;

map_tab_comp.map_axes = axes('Parent',map_tab,...
                              'FontSize',10,'Units','normalized',...
                              'Position',[0 0 1 1],...
                              'XAxisLocation','bottom',...
                              'XLimMode','manual',...
                              'YLimMode','manual',...
                              'TickDir','in',...
                              'box','on',...
                              'SortMethod','childorder',...
                              'NextPlot','add',...
                              'visible','on',...
                              'Tag','main');
                          
map_tab_comp.map_axes.XTickLabelRotation = 90;

[cmap,col_ax,col_lab,col_grid,col_bot,col_txt] = init_cmap(disp_config.Cmap);

map_tab_comp.cbar = colorbar(map_tab_comp.map_axes,'east');
colormap(map_tab_comp.map_axes,cmap);

%axis(map_tab_comp.map_axes,'equal');
grid(map_tab_comp.map_axes,'on');
xlabel(map_tab_comp.map_axes,'Longitude (^\circ)')
ylabel(map_tab_comp.map_axes,'Latitude (^\circ)')

map_tab_comp.ping_line = plot(map_tab_comp.map_axes,nan,nan,'k','linewidth',2,'ButtonDownFcn',{@grab_ping_line_cback,main_figure});

pointerBehavior.enterFcn = @(figHandle, currentPoint) set(figHandle, 'Pointer', 'fleur');
pointerBehavior.exitFcn  = @(figHandle, currentPoint) set(figHandle, 'Pointer', 'fleur');
pointerBehavior.traverseFcn = @(figHandle, currentPoint) set(figHandle, 'Pointer', 'fleur');

iptSetPointerBehavior(map_tab_comp.ping_line,pointerBehavior);

setappdata(main_figure,'Map_tab',map_tab_comp);

end