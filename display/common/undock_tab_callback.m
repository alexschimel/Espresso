function undock_tab_callback(~,~,main_figure,tab,dest)

switch tab
    case 'wc'
        wc_tab_comp = getappdata(main_figure,'wc_tab');
        tab_h = wc_tab_comp.wc_tab;
        tt = 'Water Column';
        
    case 'stacked_wc'
        stacked_wc_tab_comp = getappdata(main_figure,'stacked_wc_tab');
        tab_h = stacked_wc_tab_comp.wc_tab;
        tt = 'Stacked Water Column';
    case 'feature_list'
        feature_list_tab_comp = getappdata(main_figure,'feature_list_tab');
        tab_h = feature_list_tab_comp.feature_list_tab;
        tt = 'Feature list';
end

if~isvalid(tab_h)
    return;
end

delete(tab_h);

switch dest
    case {'wc_tab','stacked_wc_tab','feature_list_tab'}
        dest_fig = getappdata(main_figure,'wc_panel');
    case 'new_fig'
        size_max  =  get(0, 'MonitorPositions');
        pos_fig = [size_max(1,1)+size_max(1,3)*0.2 size_max(1,2)+size_max(1,4)*0.2 size_max(1,3)*0.6 size_max(1,4)*0.6];
        dest_fig = figure(...
            'Units','pixels',...
            'Position',pos_fig,...
            'Name',tt,...
            'Resize','on',...
            'Color','White',...
            'MenuBar','none',...
            'Toolbar','none',...
            'CloseRequestFcn',{@close_tab,main_figure},...
            'Tag',tab);
        set_icon_espresso(dest_fig)
        ext_figs = getappdata(main_figure,'ext_figs');
        ext_figs = [ext_figs dest_fig];
        setappdata(main_figure,'ext_figs',ext_figs);
        centerfig(dest_fig);
end

switch tab
    case 'wc'
        load_wc_tab(main_figure,dest_fig);
    case 'stacked_wc'
        load_stacked_wc_tab(main_figure,dest_fig);
    case 'feature_list'
        load_feature_list_tab(main_figure,dest_fig);
end

end

function close_tab(src,~,main_figure)

tag = src.Tag;
delete(src);
dest_fig = getappdata(main_figure,'swath_panel');

switch tag
    case 'wc'
        load_wc_tab(main_figure,dest_fig);
    case 'stacked_wc'
        load_stacked_wc_tab(main_figure,dest_fig);
    case 'feature_list'
        load_feature_list_tab(main_figure,dest_fig);
end

end