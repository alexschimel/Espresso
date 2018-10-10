function grid = get_default_res(grid,fData_tot)

E_lim = grid.E_lim ;
N_lim = grid.N_lim;

for iF = 1:numel(fData_tot)
    fData = fData_tot{iF};
    grid.fData_ID(iF) = fData.ID;
    
    if ~isfield(fData,'X_1E_gridEasting')
        continue;
    end
    
    E = fData.X_1E_gridEasting;
    N = fData.X_N1_gridNorthing;
    L = fData.X_NEH_gridLevel;
    
    if size(L,3)>1
        data = pow2db_perso(nanmean(10.^(L/10),3));
    else
        data = L;
    end
    
    idx_keep_E = E>E_lim(1)&E<E_lim(2);
    idx_keep_N = N>N_lim(1)&N<N_lim(2);
    
    data(~idx_keep_N,:) = [];
    data(:,~idx_keep_E) = [];
    
    idx_nan = isnan(data);
    data(idx_nan) = [];
    if isempty(data)
        continue;
    end
    grid.res = nanmax(fData.X_1_gridHorizontalResolution,grid.res);
end

numElemGridE = ceil((E_lim(2)-E_lim(1))./grid.res)+1;
numElemGridN = ceil((N_lim(2)-N_lim(1))./grid.res)+1;

grid.name = 'New Grid';
if grid.res>0
    grid.grid_level = zeros(numElemGridN,numElemGridE,'single');
else
    grid.grid_level = single([]);
end


end

function db = pow2db_perso(pow)

pow(pow<0) = nan;
db = 10*log10(pow);

end