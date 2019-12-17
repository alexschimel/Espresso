

%% Function
function fData = CFF_grid_2D_fields_data(fData,varargin)

%% input parsing

% init
p = inputParser;

addParameter(p,'grid_horz_res',1,@(x) isnumeric(x)&&x>0);
addParameter(p,'grid_vert_res',1,@(x) isnumeric(x)&&x>0);


% parse
parse(p,varargin{:})

% get results
grid_horz_res = p.Results.grid_horz_res;

[gridN,gridE,gridNan]=CFF_compute_grid(fData,'grid_horz_res',grid_horz_res);
[N,E] = ndgrid(gridN,gridE);

idx_val = ~isnan(fData.X_BP_bottomHeight) & ~isinf(fData.X_BP_bottomHeight);

if isfield(fData,'X8_BP_ReflectivityBS')
    BSinterpolant = scatteredInterpolant(fData.X_BP_bottomNorthing(idx_val),fData.X_BP_bottomEasting(idx_val),fData.X8_BP_ReflectivityBS(idx_val),'natural','none');
    fData.X_NE_bs = BSinterpolant(N,E);
else
    fData.X_NE_bs=nan(size(E),'single');
end

HeightInterpolant = scatteredInterpolant(fData.X_BP_bottomNorthing(idx_val),fData.X_BP_bottomEasting(idx_val),fData.X_BP_bottomHeight(idx_val),'natural','none');
fData.X_NE_bathy = HeightInterpolant(N,E);

fData.X_NE_bs(gridNan)=nan;
fData.X_NE_bathy(gridNan)=nan;
fData.X_2Dgrid_reference=grdlim_var;

fData.X_1E_2DgridEasting  = gridEasting;
fData.X_N1_2DgridNorthing = gridNorthing;

fData.X_1_2DgridHorizontalResolution = grid_horz_res;