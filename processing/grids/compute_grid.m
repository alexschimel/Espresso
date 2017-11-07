function grid=compute_grid(grid,fData_tot)

[numElemGridN,numElemGridE]=size(grid.grid_level);

gridSum   = zeros(numElemGridN,numElemGridE,'single');
gridCount = zeros(numElemGridN,numElemGridE,'single');

E_lim=grid.E_lim ;
N_lim=grid.N_lim;
res=grid.res;

if res==0
    
end

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
    data(idx_nan)=[];
    if isempty(data)
        continue;
    end
    E_mat=repmat(E,numel(N),1);
    N_mat=repmat(N,1,numel(E));
    
    
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
    grid.fData_ID=[grid.fData_ID fData.ID];
end

grid.grid_level=single(10.*log10(gridSum./gridCount));


