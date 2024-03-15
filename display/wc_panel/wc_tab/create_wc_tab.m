function create_wc_tab(main_figure,parent_tab_group)
%CREATE_WC_TAB  Creates wc tab in Espresso Swath panel
%
%   See also UPDATE_WC_TAB, INITIALIZE_DISPLAY, ESPRESSO.

%   Copyright 2017-2021 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

disp_config = getappdata(main_figure,'disp_config');

switch parent_tab_group.Type
    case 'uitabgroup'
        wc_tab_comp.wc_tab = uitab(parent_tab_group,'Title','WC','Tag','wc_tab','BackGroundColor','w');
        tab_menu = uicontextmenu(ancestor(wc_tab_comp.wc_tab,'figure'));
        uimenu(tab_menu,'Label','Undock to External Window','Callback',{@undock_tab_callback,main_figure,'wc','new_fig'});
        wc_tab_comp.wc_tab.UIContextMenu = tab_menu;
    case 'figure'
        wc_tab_comp.wc_tab = parent_tab_group;
end


%
%% create the tab components
%
% axes and contents
wc_tab_comp.wc_axes = axes(wc_tab_comp.wc_tab,...
    'Units','normalized',...
    'outerposition',[0 0 1 0.95],...
    'nextplot','add',...
    'YDir','normal',...
    'Tag','wc');

axis(wc_tab_comp.wc_axes,'equal');
[cmap,~,~,~,~,~] = init_cmap('ek60');
colorbar(wc_tab_comp.wc_axes,'southoutside');
colormap(wc_tab_comp.wc_axes,cmap);
caxis(wc_tab_comp.wc_axes,disp_config.Cax_wc);
wc_tab_comp.wc_axes.XAxisLocation='top';
wc_tab_comp.wc_axes.XAxis.TickLabelFormat='%.0fm';
wc_tab_comp.wc_axes.YAxis.TickLabelFormat='%.0fm';
wc_tab_comp.wc_axes.YAxis.FontSize=8;
wc_tab_comp.wc_axes.XAxis.FontSize=8;

grid(wc_tab_comp.wc_axes,'on');
box(wc_tab_comp.wc_axes,'on')
wc_tab_comp.wc_gh = pcolor(wc_tab_comp.wc_axes,[],[],[]);
set(wc_tab_comp.wc_gh,'facealpha','flat','LineStyle','none','AlphaData',[]);
wc_tab_comp.ac_gh = plot(wc_tab_comp.wc_axes,nan,nan,'--k','Tag','ac','linewidth',2);
wc_tab_comp.bot_gh = plot(wc_tab_comp.wc_axes,nan,nan,'.k','Tag','ac','markersize',4);
% axis(wc_tab_comp.wc_axes,'equal');

wc_tab_comp.wc_axes_tt = uicontrol(wc_tab_comp.wc_tab,...
    'Units','normalized',...
    'Style','Text',...
    'position',[0 0.95 1 0.05],'BackgroundColor',[1 1 1]);

% save the tab to appdata
setappdata(main_figure,'wc_tab',wc_tab_comp);

% update tab if data is loaded
fData = getappdata(main_figure,'fData');
if isempty(fData)
    return;
end
update_wc_tab(main_figure);

end
