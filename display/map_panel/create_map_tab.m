function create_map_tab(main_figure,map_tab_group)
%CREATE_MAP_TAB  Creates map tab in Espresso Map panel
%
%   See also UPDATE_MAP_TAB, INITIALIZE_DISPLAY, ESPRESSO.

%   Authors: Yoann Ladroit (NIWA, yoann.ladroit@niwa.co.nz) and Alex
%   Schimel (NIWA, alexandre.schimel@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

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



%% toggle buttons on map for modes

% get icons
icon = get_icons_cdata(fullfile(whereisroot(),'icons'));

map_tab_comp.tgbt1 = uicontrol(map_tab_comp.map_tab ,'Style','togglebutton','String','1',...
    'units','normalized',...
    'pos',[0.01 0.95 0.025 0.035],...
    'String','',...
    'Cdata',icon.pointer,...
    'Callback',{@test1,main_figure});

map_tab_comp.tgbt2 = uicontrol(map_tab_comp.map_tab ,'Style','togglebutton','String','2',...
    'units','normalized',...
    'pos',[0.01 0.91 0.025 0.035],...
    'String','',...
    'Cdata',icon.edit_bot,...
    'Callback',{@test2,main_figure});

%% initialize ping_swathe and ping_window

map_tab_comp.ping_swathe = plot(map_tab_comp.map_axes,nan,nan,'k','linewidth',2,'ButtonDownFcn',{@grab_ping_line_cback,main_figure});

map_tab_comp.ping_window = plot(polyshape([0 0 1 1]-999,[1 0 0 1]-999),...
    'FaceColor','g',...
    'parent',map_tab_comp.map_axes,...
    'FaceAlpha',0.2,...
    'EdgeColor','g',...
    'LineWidth',1);

pointerBehavior.enterFcn = @(figHandle, currentPoint) set(figHandle, 'Pointer', 'fleur');
pointerBehavior.exitFcn  = @(figHandle, currentPoint) set(figHandle, 'Pointer', 'arrow');
pointerBehavior.traverseFcn = @(figHandle, currentPoint) set(figHandle, 'Pointer', 'fleur');

iptSetPointerBehavior(map_tab_comp.ping_swathe,pointerBehavior);

setappdata(main_figure,'Map_tab',map_tab_comp);

% display existing features
display_features(main_figure,{},[])


end

%% callbacks for toggle buttons

function test1(~,~,main_figure)

disp_config =  getappdata(main_figure,'disp_config');
disp_config.Mode = 'Normal';

end

function test2(~,~,main_figure)

disp_config = getappdata(main_figure,'disp_config');
disp_config.Mode = 'DrawNewFeature';

end