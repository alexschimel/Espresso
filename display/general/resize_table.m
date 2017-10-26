
function resize_table(~,~,main_figure)
fdata_tab_comp=getappdata(main_figure,'fdata_tab');
if isempty(fdata_tab_comp)
    return;
end
table=fdata_tab_comp.table;

if~isempty(table)&&isvalid(table)
    column_width=table.ColumnWidth;
    pos_f=getpixelposition(fdata_tab_comp.fdata_tab);
    width_t_old=nansum([column_width{:}]);
    width_t_new=pos_f(3);
    new_width=cellfun(@(x) x/width_t_old*width_t_new,column_width,'un',0);
    set(table,'ColumnWidth',new_width);
end
end