%% load_map_tab.m
%
% Creates "Map" tab in Espresso's Map Panel
%
%% Help
%
% *USE*
%
% _This section contains a more detailed description of what the function
% does and how to use it, for the interested user to have an overall
% understanding of its function. Example below to replace. Delete these
% lines XXX._
%
% This is a text file containing the basic comment template to add at the
% start of any new ESP3 function to serve as function help. XXX
%
% *INPUT VARIABLES*
%
% _This section contains bullet points of input variables with description
% and information. Put input variable and other valid entries or defaults
% between | symbols so it shows as monospace. Information section to
% contain, in order: requirement (i.e. Required/Optional/Paramter), valid
% type (e.g. Num, Positive num, char, 1xN cell array, etc.) and default
% value if there is one (e.g. Default: '10'). Example below to replace.
% Delete these lines XXX._
%
% * |input_variable_1|: Description (Information). XXX
% * |input_variable_2|: Description (Information). XXX
% * |input_variable_3|: Description (Information). XXX
%
% *OUTPUT VARIABLES*
%
% _This section contains bullet points of output variables with description
% and information. See input variables for template. Example below to
% replace. Delete these lines XXX._
%
% * |output_variable_1|: Description (Information). XXX
% * |output_variable_2|: Description (Information). XXX
%
% *DEVELOPMENT NOTES*
%
% _This section describes what features are temporary, needed future
% developments and paper references. Example below to replace. Delete these
% lines XXX._
%
% * research point 1. XXX
% * research point 2. XXX
%
% *NEW FEATURES*
%
% _This section contains dates and descriptions of major updates. Example
% below to replace. Delete these lines XXX._
%
% * YYYY-MM-DD: second version. Describes the update. XXX
% * YYYY-MM-DD: first version. XXX
%
% *EXAMPLE*
%
% _This section contains examples of valid function calls. Note that
% example lines start with 3 white spaces so that the publish function
% shows them correctly as matlab code. Example below to replace. Delete
% these lines XXX._
%
%   example_use_1; % comment on what this does. XXX
%   example_use_2: % comment on what this line does. XXX
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% _This last section contains at least author name and affiliation. Delete
% these lines XXX._
%
% Yoann Ladroit, Alexandre Schimel, NIWA. XXX

%% Function
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

map_tab_comp.ping_poly = plot(polyshape(nan(1,3),nan(1,3)),...
    'FaceColor','g',...
    'parent',map_tab_comp.map_axes,'FaceAlpha',0.2,...
    'EdgeColor','g',...
    'LineWidth',1);

pointerBehavior.enterFcn = @(figHandle, currentPoint) set(figHandle, 'Pointer', 'fleur');
pointerBehavior.exitFcn  = @(figHandle, currentPoint) set(figHandle, 'Pointer', 'fleur');
pointerBehavior.traverseFcn = @(figHandle, currentPoint) set(figHandle, 'Pointer', 'fleur');

iptSetPointerBehavior(map_tab_comp.ping_line,pointerBehavior);

setappdata(main_figure,'Map_tab',map_tab_comp);

end