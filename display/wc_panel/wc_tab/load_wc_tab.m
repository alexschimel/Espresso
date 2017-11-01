function load_wc_tab(main_figure,parent_tab_group)

disp_config=getappdata(main_figure,'disp_config');

switch parent_tab_group.Type
    case 'uitabgroup'
        wc_tab_comp.wc_tab=uitab(parent_tab_group,'Title','WC','Tag','wc_tab','BackGroundColor','w');
        tab_menu = uicontextmenu(ancestor(wc_tab_comp.wc_tab,'figure'));
        uimenu(tab_menu,'Label','Undock to External Window','Callback',{@undock_tab_callback,main_figure,'wc','new_fig'});
        wc_tab_comp.wc_tab.UIContextMenu=tab_menu;
    case 'figure'
        wc_tab_comp.wc_tab=parent_tab_group;
end

%pos = getpixelposition(wc_tab_comp.wc_tab);
wc_tab_comp.data_disp=uicontrol(wc_tab_comp.wc_tab,'style','popup','Units','pixels','position',[20 20 120 20],...
    'String',{'Original' 'Masked Original' 'Without Sidelobes' 'Masked without Sidelobes'},'Value',3,'Callback',{@change_wc_disp_cback,main_figure});

wc_tab_comp.wc_axes=axes(wc_tab_comp.wc_tab,...
    'Units','normalized','outerposition',[0 0 1 1],'nextplot','add','YDir','normal');


[cmap,col_ax,col_lab,col_grid,col_bot,col_txt]=init_cmap(disp_config.Cmap);
colorbar(wc_tab_comp.wc_axes,'southoutside');
colormap(wc_tab_comp.wc_axes,cmap);
caxis(wc_tab_comp.wc_axes,disp_config.Cax_wc);
xlabel(wc_tab_comp.wc_axes,'Across Distance (m)');
ylabel(wc_tab_comp.wc_axes,'Depth (m)');
grid(wc_tab_comp.wc_axes,'on');
box(wc_tab_comp.wc_axes,'on')
wc_tab_comp.wc_gh=pcolor(wc_tab_comp.wc_axes,[],[],[]);
set(wc_tab_comp.wc_gh,'facealpha','flat','LineStyle','none','AlphaData',[]);
wc_tab_comp.ac_gh=plot(wc_tab_comp.wc_axes,nan,nan,'--k','Tag','ac','linewidth',2);
wc_tab_comp.bot_gh=plot(wc_tab_comp.wc_axes,nan,nan,'.k','Tag','ac','markersize',4);

axis(wc_tab_comp.wc_axes,'equal');

setappdata(main_figure,'wc_tab',wc_tab_comp);
fData=getappdata(main_figure,'fData');

if isempty(fData)
    return;
end

update_wc_tab(main_figure);
end

function change_wc_disp_cback(~,~,main_figure)
update_wc_tab(main_figure);
end

