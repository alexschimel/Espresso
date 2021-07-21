function update_mosaic_tab(main_figure)
%UPDATE_MOSAIC_TAB  Updates mosaic tab in Espresso Control panel
%
%   See also CREATE_MOSAIC_TAB, INITIALIZE_DISPLAY, ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 21-07-2021

mosaic_tab_comp = getappdata(main_figure,'mosaic_tab');
mosaics = getappdata(main_figure,'mosaics');

nb_mosaics = numel(mosaics);

if nb_mosaics >= 1
    
    new_entry = cell(nb_mosaics,4);
    new_entry(:,1) = {mosaics(:).name};
    new_entry(:,2) = num2cell([mosaics(:).res]);
    new_entry(:,3) = num2cell(ones(1,nb_mosaics) == 1);
    new_entry(:,4) = num2cell([mosaics(:).ID]);
    mosaic_tab_comp.table_main.Data = new_entry;
    
else
    mosaic_tab_comp.table_main.Data = {};
end

end