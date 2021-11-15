function [gridV, gridX, gridY] = CFF_grid_2D_data(x,y,v,res)
%CFF_GRID_2D_DATA  Grid multiple scattered data into 2D grids
%
%   Grid data values 'v' at resolution 'res' given the data's 2D
%   coordinates 'x' and 'y'. 
%   Resolution is the same in x and y dimensions.
%   Dimensions of x, y and v must all match.
%   Multiple sets of data can be gridded, using a cell array for 'v'.
%
%   See also CFF_CREATE_BLANK_GRID.

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (ENSTA Bretagne, yoann.ladroit@ensta-bretagne.fr)
%   2021-2021; Last revision: 15-11-2021

% number of arrays to grid
if isnumeric(v)
    nV = 1;
elseif iscell(v)
    nV = numel(v);
else
    error('v must be numeric or cell array of numeric');
end

% check that all dimensions match
refDims = size(x);
if ~all(size(y)==refDims)
    error('dimensions of x and y do not match');
end
if ( nV==1 && ~all(size(v)==refDims) ) || ...
    ( nV>1 && any(cellfun(@(ii) ~all(size(ii)==refDims),v)) )
    error('dimensions of v do not match x and y');
end

% prepare grid coordinates, and the mask grid
[gridX,gridY,gridNaN] = CFF_create_blank_grid(x,y,res);
[gridY,gridX] = ndgrid(gridY,gridX);

% indices of data to keep, based on x and y only
idxXYKeep = ~isnan(x) & ~isinf(x) & ~isnan(y) & ~isinf(y);

% gridding v. Keeping single and multiple cases separate to keep code fast
if nV == 1
    % single v array to grid
    % indices of data to keep
    idxKeep = idxXYKeep & ~isnan(v) & ~isinf(v);
    % prepare and apply interpolant
    F = scatteredInterpolant(y(idxKeep),x(idxKeep),v(idxKeep),'natural','none');
    gridV = F(gridY,gridX);
    % mask data
    gridV(gridNaN) = NaN;
else
   % multiple v arrays to grid
    gridV = cell(size(v));
    for ii = 1:nV
        v_temp = v{ii};
        % indices of data to keep
        idxKeep = idxXYKeep & ~isnan(v_temp) & ~isinf(v_temp);
        % prepare and apply interpolant
        F = scatteredInterpolant(y(idxKeep),x(idxKeep),v_temp(idxKeep),'natural','none');
        gridV_temp = F(gridY,gridX);
        % mask data
        gridV_temp(gridNaN) = NaN;
        % save in output cell array
        gridV{ii} = gridV_temp;
    end
end