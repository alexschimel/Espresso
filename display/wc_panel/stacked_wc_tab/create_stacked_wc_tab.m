function create_stacked_wc_tab(main_figure,parent_tab_group)
%CREATE_STACKED_WC_TAB  Creates stacked_wc tab in Espresso Swath panel
%
%   See also UPDATE_STACKED_WC_TAB, INITIALIZE_DISPLAY, ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 21-07-2021
s
disp_config = getappdata(main_figure,'disp_config');

switch parent_tab_group.Type
    case 'uitabgroup'
        stacked_wc_tab_comp.wc_tab = uitab(parent_tab_group,'Title','Stacked WC','Tag','stacked_wc_tab','BackGroundColor','w');
        tab_menu = uicontextmenu(ancestor(stacked_wc_tab_comp.wc_tab,'figure'));
        uimenu(tab_menu,'Label','Undock to External Window','Callback',{@undock_tab_callback,main_figure,'stacked_wc','new_fig'});
        stacked_wc_tab_comp.wc_tab.UIContextMenu = tab_menu;
    case 'figure'
        stacked_wc_tab_comp.wc_tab = parent_tab_group;
end
% pos = getpixelposition(stacked_wc_tab_comp.wc_tab);

stacked_wc_tab_comp.wc_axes = axes(stacked_wc_tab_comp.wc_tab,...
    'Units','normalized',...
    'outerposition',[0 0 0.98 1],...
    'nextplot','add',...
    'YDir','normal',...
    'Tag','stacked_wc');

[cmap,col_ax,col_lab,col_grid,col_bot,col_txt] = init_cmap(disp_config.Cmap);

colorbar(stacked_wc_tab_comp.wc_axes,'southoutside');
colormap(stacked_wc_tab_comp.wc_axes,cmap);
title(stacked_wc_tab_comp.wc_axes,'N/A','Interpreter','none','FontSize',10,'FontWeight','normal');
caxis(stacked_wc_tab_comp.wc_axes,disp_config.Cax_wc);
ylabel(stacked_wc_tab_comp.wc_axes,'Range (m)','FontSize',10);
grid(stacked_wc_tab_comp.wc_axes,'on');
box(stacked_wc_tab_comp.wc_axes,'on')
axis(stacked_wc_tab_comp.wc_axes,'ij');
stacked_wc_tab_comp.wc_axes.XAxisLocation='top';
stacked_wc_tab_comp.wc_axes.YAxis.TickLabelFormat='%.0fm';
stacked_wc_tab_comp.wc_axes.YAxis.FontSize=8;
stacked_wc_tab_comp.wc_axes.XAxis.FontSize=8;
stacked_wc_tab_comp.wc_gh = pcolor(stacked_wc_tab_comp.wc_axes,[],[],[]);
%stacked_wc_tab_comp.wc_gh.ButtonDownFcn = {@goToPing_cback,main_figure};
set(stacked_wc_tab_comp.wc_gh,'facealpha','flat','LineStyle','none','AlphaData',[]);
stacked_wc_tab_comp.ping_gh = plot(stacked_wc_tab_comp.wc_axes,nan,nan,'--k','Tag','ac','linewidth',2,'ButtonDownFcn',{@grab_vert_ping_line_cback,main_figure});
% stacked_wc_tab_comp.bot_gh = plot(stacked_wc_tab_comp.wc_axes,nan,nan,'.k','Tag','ac','markersize',4);
pointerBehavior.enterFcn = @(figHandle, currentPoint) set(figHandle, 'Pointer', 'fleur');
pointerBehavior.exitFcn  = @(figHandle, currentPoint) set(figHandle, 'Pointer', 'arrow');
pointerBehavior.traverseFcn = @(figHandle, currentPoint) set(figHandle, 'Pointer', 'fleur');
iptSetPointerBehavior(stacked_wc_tab_comp.ping_gh,pointerBehavior);

setappdata(main_figure,'stacked_wc_tab',stacked_wc_tab_comp);
fData = getappdata(main_figure,'fData');

if isempty(fData)
    return;
end

update_wc_tab(main_figure);
update_stacked_wc_tab(main_figure);

end

function goToPing_cback(~,evt,main_figure)

disp_config = getappdata(main_figure,'disp_config');
disp_config.Iping = round(evt.IntersectionPoint(1));

end



