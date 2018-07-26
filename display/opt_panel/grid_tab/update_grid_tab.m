function update_grid_tab(main_figure)


grid_tab_comp=getappdata(main_figure,'grid_tab');
grids=getappdata(main_figure,'grids');

nb_grids = numel(grids);

if nb_grids>=1
    new_entry = cell(nb_grids,4);
    new_entry(:,1)={grids(:).name};
    new_entry(:,2)=num2cell([grids(:).res]);
    new_entry(:,3)=num2cell(ones(1,nb_grids)==1);
    new_entry(:,4)=num2cell([grids(:).ID]);
    grid_tab_comp.table_main.Data=new_entry;
    
else
    grid_tab_comp.table_main.Data={};
end

end