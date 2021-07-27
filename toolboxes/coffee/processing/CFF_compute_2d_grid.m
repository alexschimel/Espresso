function [gridN, gridE, gridNan] = CFF_compute_2d_grid(fData,varargin)
%CFF_COMPUTE_2D_GRID  One-line description
%
%   See also ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

% init
p = inputParser;
addParameter(p,'grid_horz_res',1,@(x) isnumeric(x)&&x>0);
addParameter(p,'grdlim_east',[],@isnumeric);
addParameter(p,'grdlim_north',[],@isnumeric);
parse(p,varargin{:})
res = p.Results.grid_horz_res;

% get data
E = fData.X_BP_bottomEasting;
N = fData.X_BP_bottomNorthing;

% set grids
idx_keep = ~isnan(E(:)) & ~isnan(N(:));
gridE = min(E(idx_keep)):res:max(E(idx_keep));
gridN = min(N(idx_keep)):res:max(N(idx_keep));

% indices of data in grids
E_idx = floor((E(idx_keep)-gridE(1))/res)+1;
N_idx = floor((N(idx_keep)-gridN(1))/res)+1;

% we use the accumarray function to sum all values in both the
% total weight grid, and the weighted sum grid. Prepare the
% common values here
subs = single([N_idx E_idx]);               % indices in the temp grid of each data point
sz   = single([numel(gridN) numel(gridE)]); % size of ouptut

% generate empty grid
gridNan = accumarray(subs,ones(numel(E(idx_keep)),1),sz,@(x) sum(x),0);
gridNan = gridNan==0;

