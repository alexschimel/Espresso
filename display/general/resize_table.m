% resize_table.m
%  
% Resize the width of columns in a table, typically after user resizes a
% window
%
function resize_table(src,~,table)

if ~isempty(table) && isvalid(table)
    
    column_width = table.ColumnWidth;
    pos_f = getpixelposition(src);
    width_t_old = nansum([column_width{:}]);
    width_t_new = pos_f(3);
    new_width = cellfun(@(x) x/width_t_old*width_t_new,column_width,'uniformoutput',0);
    set(table,'ColumnWidth',new_width);
    
end

end