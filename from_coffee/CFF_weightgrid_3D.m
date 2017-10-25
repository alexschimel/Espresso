%% CFF_weightgrid_3D.m
%
% Weight gridding of 3D points. This function replaces CFF_weightgrid3, now
% obsolete. 
%
% IMPORTANT: CFF_weightgrid_2D.m does the same processin but in 2D. If you
% change this function, change the other one too.
%
%% Help
%
% *USE*
%
% [vi,wi] = CFF_weightgrid_3D(x,y,z,v,[],xi,yi,zi) grids 3D data defined
% with x, y and z as the coordinates and v the value, on a 3D grid with
% nodes defined by xi, yi and zi, resulting in gridded values vi.
% Since weight is not provided in input, the program sets a constant weight
% of 1 for all input points, which results in the calculation being a
% simple averaging and in the returned weight wi being the density of
% points that contributed to the node value. Note that xi, yi and zi can be
% defined either as the full vectors defining the grid nodes coordinates,
% or arrays as produced by meshgrid, or three elements vectors defining in
% order (1) the first node coordinate, (2) the step between nodes, and (3)
% the total number of nodes. That last option is simpler since the program
% only needs these elements and not the grids.
%
% [vi,wi] = CFF_weightgrid_3D(x,y,z,v,w,xi,yi,zi) does the same as above
% but with weights w provided in input for each data point. This is coded
% to allow gridding where some data points are given more importance than
% others.
%
% [vi,wi] = CFF_weightgrid_3D(x,y,z,v,w,xi,yi,zi,vi,wi) does the same as
% above but starting with a grid already filled with data vi and weights
% wi. In effect, the previous examples use the same function but after
% initiating an empty grid.
%
% *INPUT VARIABLES*
%
% * |input_variable_1|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% * |output_variable_1|: TODO: write description and info on variable
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-10-03: first version, inspired by CFF_weightgrid3, which is now
% obsolete (Alex Schimel) 
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Alexandre Schimel, NIWA.

%% Function
function [vi,wi] = CFF_weightgrid_3D(x,y,z,v,w,xi,yi,zi,vi,wi)


% IMPORTANT: CFF_weightgrid_2D.m does the same processin but in 2D. If you
% change this function, change the other one too.


%% INPUT VARIABLES MANAGEMENT

% OK our first work it to set the grids right.

if numel(xi)==3 && numel(yi)==3 && numel(zi)==3
    
    % xi, yi and zi are three elements vectors, aka:
    xi_firstval = xi(1);
    xi_step = xi(2);
    xi_numel = xi(3);
    
    % and
    yi_firstval = yi(1);
    yi_step = yi(2);
    yi_numel = yi(3);
    
    % and
    zi_firstval = zi(1);
    zi_step = zi(2);
    zi_numel = zi(3);
    
    % and the last nodes are obtained with:
    xi_lastval = (xi_numel-1).*xi_step + xi_firstval;
    yi_lastval = (yi_numel-1).*yi_step + yi_firstval;
    zi_lastval = (zi_numel-1).*zi_step + zi_firstval;

elseif isvector(xi) && isvector(yi) && isvector(zi)
    
    % xi, yi and zi are the full grid vectors, aka the relevant parameters:
    xi_firstval = xi(1);
    xi_step = CFF_get_vector_stepsize(xi);
    xi_numel = length(xi);
    xi_lastval = xi(end);
    
    % and
    yi_firstval = yi(1);
    yi_step = CFF_get_vector_stepsize(yi);
    yi_numel = length(yi);
    yi_lastval = yi(end);
    
    % and
    zi_firstval = zi(1);
    zi_step = CFF_get_vector_stepsize(zi);
    zi_numel = length(zi);
    zi_lastval = zi(end);

else
    
    % the last case is that xi, yi and zi are provided as if from meshgrid,
    % in which case, just extract the relevant parameters:
    xi_firstval = xi(1,1,1);
    xi_step = CFF_get_vector_stepsize(xi(1,:,1));
    xi_numel = size(xi,2);
    xi_lastval = xi(1,end,1);
    
    yi_firstval = yi(1,1,1);
    yi_step = CFF_get_vector_stepsize(yi(:,1,1));
    yi_numel = size(yi,1);
    yi_lastval = yi(end,1,1);
    
    zi_firstval = zi(1,1,1);
    zi_step = CFF_get_vector_stepsize(zi(1,1,:));
    zi_numel = size(zi,3);
    zi_lastval = zi(1,1,end);
    
end

% Next, onto the values and weights of the grid.
% One problem with the averaging is that if a grid value is NaN (its
% corresponding weight should be zero), then any update of that  value will
% remain NaN. So we need to use another value than NaN for "no value" just
% for the averaging. It does not matter which value, since its weight of
% zero means this value will be discarded. Plus we'll replace it with NaN
% at the end of the process if that grid point was not filled (aka, w still
% = 0).
NO_VALUE = -999;

if ~exist('vi','var') 
    
    % if vi not provided (and therefore not wi either), create empty vi and
    % wi  
    vi = NO_VALUE.*ones(yi_numel,xi_numel,zi_numel);
    wi = zeros(yi_numel,xi_numel,zi_numel);
    
elseif size(vi,1)~=yi_numel || size(vi,2)~=xi_numel || size(vi,3)~=zi_numel
    
    % it's possible vi is provided but not the right size. If so, same
    % result as above and set a warning
    vi = NO_VALUE.*ones(yi_numel,xi_numel,zi_numel);
    wi = zeros(yi_numel,xi_numel,zi_numel);
    warning('vi provided was not the right size. New empty grid (and weights) reinitialized');

elseif ~exist('wi','var') || numel(wi)==1
    
    % if we're here it means vi is good. But wi is either not provided,
    % or simply set to a single constant value. Create wi as a grid of ones
    wi = ones(yi_numel,xi_numel,zi_numel);
    
    % except where vi is nan of course
    wi(isnan(vi)) = 0;
    
    % oh and ensure we replace nans by NO_value in vi
    vi(isnan(vi)) = NO_VALUE;
    
elseif size(wi,1)~=yi_numel || size(wi,2)~=xi_numel || size(wi,3)~=zi_numel
    
    % there's still the case where wi was provided, but not at the right
    % dimensions, in which case we do same as above but adding a warning:
    wi = ones(yi_numel,xi_numel,zi_numel);
    wi(isnan(vi)) = 0;
    vi(isnan(vi)) = NO_VALUE;
    warning('wi provided was not the right size. New unit weights reinitialized');
    
else
    
    % if all above passed, it means vi and wi provided were good.
    % Just ensure there's no NaNs in that grid:
    wi(isnan(vi)) = 0;
    vi(isnan(vi)) = NO_VALUE;

end

% if weight is not provided in input, or set at single value (1), expand to
% size of other variables 
if isempty(w) || numel(w)==1
    w = ones(size(x));
end

%% PROCESSING

% now to the actual processing

% turn (x,y,z,v,w) variables to vectors
x = reshape(x,1,[]);
y = reshape(y,1,[]);
z = reshape(z,1,[]);
v = reshape(v,1,[]);
w = reshape(w,1,[]);

% remove any nan value
x(isnan(v)) = [];
y(isnan(v)) = [];
z(isnan(v)) = [];
w(isnan(v)) = [];
v(isnan(v)) = [];

% find x,y,z values that are outside the grid & remove them
indout = x<xi_firstval | x>xi_lastval | y<yi_firstval | y>yi_lastval | z<zi_firstval | z>zi_lastval;
x(indout)=[];
y(indout)=[];
z(indout)=[];
v(indout)=[];
w(indout)=[];

% perform weight gridding
for ii = 1:length(v)
    
    % find appropriate cell indices
    [i_xi,i_yi,i_zi] = CFF_index_in_grid_3D(x(ii),y(ii),z(ii),xi_firstval,yi_firstval,zi_firstval,xi_step,yi_step,zi_step);
    
    % add new value to cell according to its weight, and update weight
    [vi(i_yi,i_xi,i_zi),wi(i_yi,i_xi,i_zi)] = CFF_update_value_and_weight(v(ii),w(ii),vi(i_yi,i_xi,i_zi),wi(i_yi,i_xi,i_zi));
    
end

% put NaNs back in the grid cells that were not filled
vi(wi==0) = NaN;

