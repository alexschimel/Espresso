function update_mosaic_tab(main_figure)
%UPDATE_MOSAIC_TAB  Updates mosaic tab in Espresso Control panel
%
%   See also CREATE_MOSAIC_TAB, INITIALIZE_DISPLAY, ESPRESSO.

%   Copyright 2017-2021 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

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