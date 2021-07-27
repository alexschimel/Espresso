function fData = CFF_grid_2D_fields_data(fData,varargin)
%CFF_GRID_2D_FIELDS_DATA  Grid bathy and backscatter data
%
%   See also CFF_COMPUTE_2D_GRID, ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

% input parser
p = inputParser;
addParameter(p,'grid_horz_res',1,@(x) isnumeric(x)&&x>0);
parse(p,varargin{:})
grid_horz_res = p.Results.grid_horz_res;

% prepare grids
[gridN,gridE,gridNan] = CFF_compute_2d_grid(fData,'grid_horz_res',grid_horz_res);
[N,E] = ndgrid(gridN,gridE);

% DEV NOTE: This doesn't work correctly for some kmall data... The bathy
% looks alright but not the BS. Figure why XXX1.

% grid BS (if it exists)
if isfield(fData,'X8_BP_ReflectivityBS')
    n_min = min(numel(fData.X8_BP_ReflectivityBS),numel(fData.X_BP_bottomNorthing));
    idx_min = (1:n_min)';
    idx_val = ~isnan(fData.X8_BP_ReflectivityBS(idx_min)) ...
        & ~isinf(fData.X8_BP_ReflectivityBS(idx_min)) ... 
        & ~isnan(fData.X_BP_bottomNorthing(idx_min)) ...
        & ~isnan(fData.X_BP_bottomEasting(idx_min));
    BSinterpolant = scatteredInterpolant(fData.X_BP_bottomNorthing(idx_min(idx_val)),fData.X_BP_bottomEasting(idx_min(idx_val)),fData.X8_BP_ReflectivityBS(idx_min(idx_val)),'natural','none');
    fData.X_NE_bs = BSinterpolant(N,E);
else
    fData.X_NE_bs = nan(size(E),'single');
end
fData.X_NE_bs(gridNan) = nan;

% grid bath
idx_val = ~isnan(fData.X_BP_bottomHeight) ...
    & ~isinf(fData.X_BP_bottomHeight) ...
    & ~isnan(fData.X_BP_bottomNorthing) ...
    & ~isnan(fData.X_BP_bottomEasting);
HeightInterpolant = scatteredInterpolant(fData.X_BP_bottomNorthing(idx_val),fData.X_BP_bottomEasting(idx_val),fData.X_BP_bottomHeight(idx_val),'natural','none');
fData.X_NE_bathy = HeightInterpolant(N,E);
fData.X_NE_bathy(gridNan) = nan;

% save grid coordinates and resolution
fData.X_1E_2DgridEasting  = gridE(:)';
fData.X_N1_2DgridNorthing = gridN(:);
fData.X_1_2DgridHorizontalResolution = grid_horz_res;