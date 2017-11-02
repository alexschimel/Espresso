function load_grid_tab(main_figure,parent_tab_group)

switch parent_tab_group.Type
    case 'uitabgroup'
        grid_tab_comp.grid_tab=uitab(parent_tab_group,'Title','Grid Proc.','Tag','grid_tab','BackGroundColor','w');
    case 'figure'
        grid_tab_comp.grid_tab=parent_tab_group;
end
%disp_config=getappdata(main_figure,'disp_config');


uicontrol(grid_tab_comp.grid_tab,'Style','pushbutton','units','normalized',...
    'pos',[0.2 0.26 0.25 0.08],...
    'String','Grid',...
    'callback',{@grid_tot_cback,main_figure});

setappdata(main_figure,'grid_tab',grid_tab_comp);

end



function grid_tot_cback(~,~,main_figure)
%disp_config=getappdata(main_figure,'disp_config');
grids=getappdata(main_figure,'grids');
map_tab_comp=getappdata(main_figure,'Map_tab');
fData_tot=getappdata(main_figure,'fData');

res=0.5;

ax=map_tab_comp.map_axes;
E_lim=ax.XLim;
N_lim=ax.YLim;

numElemGridE = ceil((E_lim(2)-E_lim(1))./res)+1;
numElemGridN = ceil((N_lim(2)-N_lim(1))./res)+1;

gridSum   = zeros(numElemGridN,numElemGridE,'single');
gridCount = zeros(numElemGridN,numElemGridE,'single');

grid.fData_ID=nan(1,numel(fData_tot));
for iF=1:numel(fData_tot)
    fData=fData_tot{iF};
    grid.fData_ID(iF)=fData.ID;
    
    if ~isfield(fData,'X_1E_gridEasting')
        continue;
    end
    
    E = fData.X_1E_gridEasting;
    N = fData.X_N1_gridNorthing;
    L = fData.X_NEH_gridLevel;
    
    if size(L,3)>1
        data = pow2db_perso(nanmean(db2pow(L),3));
    else
        data=L;
    end
    
    
      
    idx_keep_E=E>E_lim(1)&E<E_lim(2);
    idx_keep_N=N>N_lim(1)&N<N_lim(2);
    
    E(~idx_keep_E)=[];
    N(~idx_keep_N)=[];
    data(~idx_keep_N,:)=[];
    data(:,~idx_keep_E)=[];   
    idx_nan=isnan(data);

    E_mat=repmat(E,numel(N),1);
    N_mat=repmat(N,1,numel(E));
    
    data(idx_nan)=[];
    N_mat(idx_nan)=[];
    E_mat(idx_nan)=[];
    data = (10.^(data./10));
     
    E_idx = round((E_mat-E_lim(1))/res+1);
    N_idx = round((N_mat-N_lim(1))/res+1);
       
    idx_E_start = min(E_idx);
    idx_N_start = min(N_idx);
    
    E_idx = E_idx - min(E_idx) + 1;
    N_idx = N_idx - min(N_idx) + 1;
     
    N_E = max(E_idx);
    N_N = max(N_idx);
    
    subs = single([N_idx(:) E_idx(:)]);
    
    gridCountTemp = accumarray(subs,ones(size(data(:)'),'single'),single([N_N N_E]),@sum,single(0));
    
    gridSumTemp = accumarray(subs,data(:)',single([N_N N_E]),@sum,single(0));
    
    gridCount(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1) = ...
        gridCount(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1)+gridCountTemp;
    
    
    gridSum(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1) = ...
        gridSum(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1)+gridSumTemp;
    
end

grid.grid_level=single(10.*log10(gridSum./gridCount));
grid.minGridE  = E_lim(1);
grid.minGridN = N_lim(1);
grid.res=res;

%grid.ID=str2double(datestr(now,'yyyymmddHHMMSSFFF'));
grid.ID=1;

if numel(grids)>1
    id_g=nan(1,numel(grids));
    for ig=1:numel(grids)
        id_g(ig)=grids{ig}.ID;
    end
    idx_grid=find(id_g==grid.ID);
    if isempty(idx_grid)
        idx_grid=numel(grids)+1;
    end
else
    idx_grid=1;
end

grids{idx_grid}=grid;
setappdata(main_figure,'grids',grids);
update_map_tab(main_figure,0,0);
end