function mosaic = CFF_init_mosaic_v2(xy_roi,varargin)
%CFF_INIT_MOSAIC_V2  Initialize a new mosaic
%
%   MOSAIC = CFF_INIT_MOSAIC(XY_ROI) initializes a new mosaic to be later
%   iteratively filled with data using CFF_ADD_TO_MOSAIC. XY_ROI are the
%   x,y coordinates of the ROI to be mosaicked and can be of two types:
%   either a 4-elements vector containing the desired min and max limits in
%   x and y of a box [x_min x_max y_min y_max], OR a Nx2 array (with N>=3)
%   where each row is the x,y coordinates of a vertex of a polygon inside
%   which the mosaic is to be calculated. MOSAIC is a mosaic structure
%   whose fields include the two grids 'value' (containing the mosaicked
%   value) and 'weight' (containing the accumulated weight, see option
%   'mode' below), and other metadata. 
%
%   CFF_INIT_MOSAIC(...,'res',VALUE) specifies the desired grid size
%   (resolution). Use the same unit as XY_ROI. VALUE is 1 by default. 
%
%   CFF_INIT_MOSAIC(...,'mode',VALUE) specifies the mosaicking mode, i.e.
%   the rules of how new data gets merged with existing data when adding to
%   the mosaic. Options are 'blend' (default) or 'stitch'. With 'blend',
%   the new and existing data get (possibly weighted) averaged. Actual
%   weights can be used to privilege some data, but by default, the weight
%   of a cell is the number of data points that contributed to a cell
%   value, so the iterative weighted averaging is equivalent to a normal
%   averaging. With 'stitch', we retain for each cell whichever data has
%   largest weight. Actual weights can be used to privilege some data, but
%   by default, the new data takes precedence over the old. See
%   CFF_ADD_TO_MOSAIC for detail on accumulating algorithms.
%
%   Note: you need to run CFF_FINALIZE_MOSAIC when you have finished
%   mosaicking.
%
%   See also CFF_MOSAIC_LINES, CFF_ADD_TO_MOSAIC, CFF_FINALIZE_MOSAIC

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no)
%   2017-2022; Last revision: 23-03-2022

% input parser
p = inputParser;
addRequired(p,'xy_roi',@(u) validateattributes(u,{'numeric'},{'2d'}));
addParameter(p,'res',1,@(u) validateattributes(u,{'numeric'},{'scalar','positive'}));
addParameter(p,'mode','blend',@(u) ismember(u,{'blend','stitch'}));
parse(p,xy_roi,varargin{:});
res = p.Results.res;
mode = p.Results.mode;
clear p;

% reformat ROI x,y
if isvector(xy_roi) && numel(xy_roi)==4
    % x,y input was box limits
    x_lim = reshape(sort(xy_roi(1:2)),1,[]);
    y_lim = reshape(sort(xy_roi(3:4)),1,[]);
    
    % no polygon
    x_pol = [];
    y_pol = [];
elseif size(xy_roi,1)>2 && size(xy_roi,2)==2
    % x,y input was polygon vertices
    x_pol = xy_roi(:,1);
    y_pol = xy_roi(:,2);
    
    % define box limits from them
    x_lim = [min(x_pol), max(x_pol)];
    y_lim = [min(y_pol), max(y_pol)];
else
    error("'xy_roi' is not the correct format. Must be either a 4-elements vector or a N*2 array with N>2.");
end

% how mosaic grids are defined: the center of the bottom-left cell is
% x_lim(1),y_lim(1) and the cell side length is res. Any point falling
% between x_lim(1)-res/2 (included) and x_lim(1)+res/2 (excluded) will be
% in the first column. There are as many rows and columns as necessary to
% include a point at x_lim(2),y_lim(2). For example using x_lim = [2 5] and
% res = 2, then there are three columns: [1-3[, [3-5[, and [5-7[

% total number of rows and columns
n_cols = round((x_lim(2)-x_lim(1))./res+1);
n_rows = round((y_lim(2)-y_lim(1))./res+1);

% coordinates of middle of cells
% x_mcol = (0:1:n_cols-1).*res + x_lim(1);
% y_mrow = (0:1:n_rows-1)'.*res + y_lim(1);

% initialize value. These cannot be NaN because this would break the
% accumulation algorithm. We initialize with zero instead and we can refer
% the where weight = 0 at the end of the accumlation to identify where no
% data were contributed.
value = zeros(n_rows,n_cols);

% initialize weight. No need for NaN outside of ROI here.
weight = zeros(n_rows,n_cols);
    
% save in mosaic structure
mosaic.x_lim = x_lim;
mosaic.y_lim = y_lim;
mosaic.x_pol = x_pol;
mosaic.y_pol = y_pol;
mosaic.res   = res;
mosaic.mode  = mode;
mosaic.value = value;
mosaic.weight = weight;
