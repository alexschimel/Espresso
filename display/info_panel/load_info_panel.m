function load_info_panel(main_figure)

if isappdata(main_figure,'info_panel')
    info_panel_comp=getappdata(main_figure,'info_panel');
    delete(get(info_panel_comp.info_panel,'children'));
else
   info_panel_comp.info_panel   = uipanel(main_figure,'Position',[0 0 1 .05],'BackgroundColor',[1 1 1],'tag','info_panel');
end

ax=axes(info_panel_comp.info_panel,'units','normalized','position',[0 0 1 1],'visible','off','Xlim',[0 1],'YLim',[0 1]);

info_panel_comp.pos_disp=text(ax,'Position',[0.2 0.4]);
info_panel_comp.info_disp=text(ax,'Position',[0.6 0.4]);

setappdata(main_figure,'info_panel',info_panel_comp);


end