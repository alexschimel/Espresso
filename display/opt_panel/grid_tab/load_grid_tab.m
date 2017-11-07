function load_grid_tab(main_figure,parent_tab_group)

switch parent_tab_group.Type
    case 'uitabgroup'
        grid_tab_comp.grid_tab=uitab(parent_tab_group,'Title','Grid Proc.','Tag','grid_tab','BackGroundColor','w');
    case 'figure'
        grid_tab_comp.grid_tab=parent_tab_group;
end
%disp_config=getappdata(main_figure,'disp_config');


survDataSummary = {};

% Column names and column format
columnname = {'Name' 'Res.' 'Disp' 'ID'};
columnformat = {'char','numeric','logical','numeric'};

% Create the uitable
grid_tab_comp.table_main = uitable('Parent',grid_tab_comp.grid_tab,...
    'Data', survDataSummary,...
    'ColumnName', columnname,...
    'ColumnFormat', columnformat,...
    'CellSelectionCallback',{@cell_select_cback,main_figure},...
    'CellEditCallback',{@update_grid_map,main_figure},...
    'ColumnEditable', [true true true false],...
    'Units','Normalized','Position',[0 0.1 1 0.9],...
    'RowName',[]);
pos_t = getpixelposition(grid_tab_comp.table_main);
set(grid_tab_comp.table_main,'ColumnWidth',...
    num2cell(pos_t(3)*[15/20 3/20 2/20 0/20]));
set(grid_tab_comp.grid_tab,'SizeChangedFcn',{@resize_table,grid_tab_comp.table_main});


uicontrol(grid_tab_comp.grid_tab,'Style','pushbutton','units','normalized',...
    'pos',[0.1 0.01 0.25 0.08],...
    'String','Create',...
    'callback',{@grid_tot_cback,main_figure});


uicontrol(grid_tab_comp.grid_tab,'Style','pushbutton','units','normalized',...
    'pos',[0.35 0.01 0.25 0.08],...
    'String','Re-compute',...
    'callback',{@re_grid_cback,main_figure});

uicontrol(grid_tab_comp.grid_tab,'Style','pushbutton','units','normalized',...
    'pos',[0.6 0.01 0.25 0.08],...
    'String','Delete',...
    'callback',{@delete_grid_cback,main_figure});

grid_tab_comp.selected_idx=[];
setappdata(main_figure,'grid_tab',grid_tab_comp);

end

function delete_grid_cback(src,~,main_figure)
grids=getappdata(main_figure,'grids');
map_tab_comp= getappdata(main_figure,'Map_tab');
grid_tab_comp = getappdata(main_figure,'grid_tab');
ax=map_tab_comp.map_axes;
idx_rem=[];
for i=grid_tab_comp.selected_idx(:)'
    if i<=numel(grids)
        tag_id_grid=num2str(grids(i).ID,'grid%.0f'); 
        tag_id_box=num2str(grids(i).ID,'box%.0f'); 
        obj=findobj(ax,'Tag',tag_id_grid,'-or','Tag',tag_id_box);
        delete(obj);
        idx_rem=union(i,idx_rem);
    end
end
grids(idx_rem)=[];
setappdata(main_figure,'grids',grids);

update_grid_tab(main_figure);

end

function re_grid_cback(src,~,main_figure)
grids=getappdata(main_figure,'grids');
grid_tab_comp = getappdata(main_figure,'grid_tab');
fData_tot=getappdata(main_figure,'fData');
idx_grid=find(cell2mat(grid_tab_comp.table_main.Data(grid_tab_comp.selected_idx(:),4))==[grids(:).ID]);
for i=idx_grid(:)'
    grids(idx_grid)=compute_grid(grids(idx_grid),fData_tot);
end
setappdata(main_figure,'grids',grids);

update_map_tab(main_figure,1,0);

end

function update_grid_map(src,evt,main_figure)
grids=getappdata(main_figure,'grids');
fData_tot=getappdata(main_figure,'fData');
idx_grid=cell2mat(src.Data(evt.Indices(1),4))==[grids(:).ID];
    switch evt.Indices(2)
        case 1  
            grids(idx_grid).name=evt.NewData;
        case 2
            if ~isnan(evt.NewData)
                grids(idx_grid).res=evt.NewData;
                grids(idx_grid)=compute_grid(grids(idx_grid),fData_tot);
            end
    end
    setappdata(main_figure,'grids',grids);
    
    update_map_tab(main_figure,1,0);

end

function grid_tot_cback(~,~,main_figure)
    
replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',{@create_grid,main_figure});

end



function cell_select_cback(~,evt,main_figure)
grid_tab_comp = getappdata(main_figure,'grid_tab');

if ~isempty(evt.Indices)
    selected_idx=(evt.Indices(:,1));
else
    selected_idx=[];
end
%selected_idx'
grid_tab_comp.selected_idx=selected_idx;
setappdata(main_figure,'grid_tab',grid_tab_comp);

end