function [gridN,gridE,gridNan]=CFF_compute_2D_grid(fData,varargin)

% init
p = inputParser;

addParameter(p,'grid_horz_res',1,@(x) isnumeric(x)&&x>0);

addParameter(p,'grdlim_east',[],@isnumeric);
addParameter(p,'grdlim_north',[],@isnumeric);

% parse
parse(p,varargin{:})
E=fData.X_BP_bottomEasting;
N=fData.X_BP_bottomNorthing;
idx_keep=~isnan(E(:))&~isnan(N(:));

gridE=min(E(idx_keep)):p.Results.grid_horz_res:max(E(idx_keep));
gridN=min(N(idx_keep)):p.Results.grid_horz_res:max(N(idx_keep));

E_idx=floor((E(idx_keep)-gridE(1))/p.Results.grid_horz_res)+1;
N_idx=floor((N(idx_keep)-gridN(1))/p.Results.grid_horz_res)+1;


subs    = single([N_idx E_idx]); 
sz      = single([numel(gridN) numel(gridE)]);      

gridNan = accumarray(subs,ones(numel(E(idx_keep)),1),sz,@(x) sum(x),0);
gridNan=gridNan==0;



