function resize_table(src,~,table)
%RESIZE_TABLE  Resize width of columns in a table
%
%   Typically after user resizes a window
%
%   See also ESPRESSO.

%   Authors: Yoann Ladroit (NIWA, yoann.ladroit@niwa.co.nz) and Alex
%   Schimel (NIWA, alexandre.schimel@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

if ~isempty(table) && isvalid(table)
    
    column_width = table.ColumnWidth;
    pos_f = getpixelposition(src);
    width_t_old = nansum([column_width{:}]);
    width_t_new = pos_f(3);
    new_width = cellfun(@(x) x/width_t_old*width_t_new,column_width,'uniformoutput',0);
    set(table,'ColumnWidth',new_width);
    
end

end