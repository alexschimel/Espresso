function compute_and_add_grid(main_figure,E_lim,N_lim)

fData_tot=getappdata(main_figure,'fData');

if isempty(fData_tot)
    return;
end

grid=init_grid(E_lim,N_lim,0);
grid=get_default_res(grid,fData_tot);

if grid.res==0
   replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1);
   disp('Nothing to grid in there');
   return;
end

grid=compute_grid(grid,fData_tot);

grids=getappdata(main_figure,'grids');
if numel(grids)>=1
    id_g=grids(:).ID;
    idx_grid=find(id_g==grid.ID);
    if isempty(idx_grid)
        idx_grid=numel(grids)+1;
    end
    grids(idx_grid)=grid;
else
    grids=grid;
end

setappdata(main_figure,'grids',grids);
replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1);

update_grid_tab(main_figure);

update_map_tab(main_figure,0,0,[]);
