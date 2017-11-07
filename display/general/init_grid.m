function grid=init_grid(E_lim,N_lim,res)

numElemGridE = ceil((E_lim(2)-E_lim(1))./res)+1;
numElemGridN = ceil((N_lim(2)-N_lim(1))./res)+1;
grid.name='New Grid';
if res>0
grid.grid_level=zeros(numElemGridN,numElemGridE,'single');
else
    grid.grid_level=single([]);
end
grid.E_lim  = E_lim;
grid.N_lim = N_lim;
grid.res=res;
grid.ID=str2double(datestr(now,'yyyymmddHHMMSSFFF'));
grid.fData_ID=[];

