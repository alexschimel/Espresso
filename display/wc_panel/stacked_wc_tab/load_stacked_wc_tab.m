
function load_stacked_wc_tab(main_figure,parent_tab_group)

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

stacked_wc_tab_comp.wc_axes = axes(stacked_wc_tab_comp.wc_tab,'Units','normalized','outerposition',[0 0 1 1],'nextplot','add','YDir','normal');

[cmap,col_ax,col_lab,col_grid,col_bot,col_txt] = init_cmap(disp_config.Cmap);

colorbar(stacked_wc_tab_comp.wc_axes,'southoutside');
colormap(stacked_wc_tab_comp.wc_axes,cmap);
title(stacked_wc_tab_comp.wc_axes,'','Interpreter','none');
caxis(stacked_wc_tab_comp.wc_axes,disp_config.Cax_wc);
xlabel(stacked_wc_tab_comp.wc_axes,'Ping Number');
ylabel(stacked_wc_tab_comp.wc_axes,'Range');
grid(stacked_wc_tab_comp.wc_axes,'on');
box(stacked_wc_tab_comp.wc_axes,'on')
axis(stacked_wc_tab_comp.wc_axes,'ij');
stacked_wc_tab_comp.wc_gh = pcolor(stacked_wc_tab_comp.wc_axes,[],[],[]);
stacked_wc_tab_comp.wc_gh.ButtonDownFcn={@goToPing_cback,main_figure};
set(stacked_wc_tab_comp.wc_gh,'facealpha','flat','LineStyle','none','AlphaData',[]);
stacked_wc_tab_comp.ping_gh = plot(stacked_wc_tab_comp.wc_axes,nan,nan,'--k','Tag','ac','linewidth',2);
% stacked_wc_tab_comp.bot_gh = plot(stacked_wc_tab_comp.wc_axes,nan,nan,'.k','Tag','ac','markersize',4);


setappdata(main_figure,'stacked_wc_tab',stacked_wc_tab_comp);
fData = getappdata(main_figure,'fData');

if isempty(fData)
    return;
end

update_wc_tab(main_figure);

end

function goToPing_cback(src,evt,main_figure)
disp_config = getappdata(main_figure,'disp_config');
disp_config.Iping=round(evt.IntersectionPoint(1));

end



