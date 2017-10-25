%% CFF_weightgrid_2D.m
%
% Weight gridding of 2D points. This function replaces CFF_weightgrid, now
% obsolete.
%
% IMPORTANT: CFF_weightgrid_3D.m does the same processing but in 3D. If you
% change this function, change the other one too.
%
%% Help
%
% *USE*
%
% [vi,wi] = CFF_weightgrid_2D(x,y,v,[],xi,yi) grids 2D data defined with x
% and y as the coordinates and v the value, on a grid with nodes defined by
% xi and yi, resulting in gridded values vi.
% Since weight is not provided in input, the program sets a constant weight
% of 1 for all input points, which results in the calculation being a
% simple averaging and in the returned weight wi being the density of
% points that contributed to the node value. Note that xi and yi can be
% defined either as the full vectors defining the grid nodes coordinates,
% or arrays as produced by meshgrid, or three elements vectors defining in
% order (1) the first node coordinate, (2) the step between nodes, and (3)
% the total number of nodes. That last option is simpler since the program
% only needs these elements and not the grids.
%
% [vi,wi] = CFF_weightgrid_2D(x,y,v,w,xi,yi) does the same as above but
% with weights w provided in input for each data point. This is coded to
% allow gridding where some data points are given more importance than
% others.
%
% [vi,wi] = CFF_weightgrid_2D(x,y,v,w,xi,yi,vi,wi) does the same as above
% but starting with a grid already filled with data vi and weights wi. In
% effect, the previous examples use the same function but after initiating
% an empty grid.
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
% * 2017-10-03: first version, inspired by CFF_weightgrid, which is now
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
function [vi,wi] = CFF_weightgrid_2D(x,y,v,w,xi,yi,vi,wi)


% IMPORTANT: CFF_weightgrid_3D.m does the same processin but in 3D. If you
% change this function, change the other one too.


%% INPUT VARIABLES MANAGEMENT

% OK our first work it to set the grids right.

if numel(xi)==3 && numel(yi)==3
    
    % xi and yi are three elements vectors, aka:
    xi_firstval = xi(1);
    xi_step = xi(2);
    xi_numel = xi(3);
    
    % and
    yi_firstval = yi(1);
    yi_step = yi(2);
    yi_numel = yi(3);
    
    % and the last nodes are obtained with:
    xi_lastval = (xi_numel-1).*xi_step + xi_firstval;
    yi_lastval = (yi_numel-1).*yi_step + yi_firstval;

elseif isvector(xi) && isvector(yi)
    
    % xi and yi are the full grid vectors, aka the relevant parameters:
    xi_firstval = xi(1);
    xi_step = CFF_get_vector_stepsize(xi);
    xi_numel = length(xi);
    xi_lastval = xi(end);
    
    % and
    yi_firstval = yi(1);
    yi_step = CFF_get_vector_stepsize(yi);
    yi_numel = length(yi);
    yi_lastval = yi(end);

else
    
    % the last case is that xi and yi are provided as if from meshgrid, in
    % which case, just extract the relevant parameters:
    xi_firstval = xi(1,1);
    xi_step = CFF_get_vector_stepsize(xi(1,:));
    xi_numel = size(xi,2);
    xi_lastval = xi(1,end);
    
    yi_firstval = yi(1,1);
    yi_step = CFF_get_vector_stepsize(yi(:,1));
    yi_numel = size(yi,1);
    yi_lastval = yi(end,1);
    
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
    vi = NO_VALUE.*ones(yi_numel,xi_numel);
    wi = zeros(yi_numel,xi_numel);
    
elseif size(vi,1)~=yi_numel || size(vi,2)~=xi_numel
    
    % it's possible vi is provided but not the right size. If so, same
    % result as above and set a warning
    vi = NO_VALUE.*ones(yi_numel,xi_numel);
    wi = zeros(yi_numel,xi_numel);
    warning('vi provided was not the right size. New empty grid (and weights) reinitialized');

elseif ~exist('wi','var') || wi==1
    
    % if we're here it means vi is good. But wi is either not provided,
    % or simply set to the value 1. Create wi as a grid of ones
    wi = ones(yi_numel,xi_numel);
    
    % except where vi is nan of course
    wi(isnan(vi)) = 0;
    
    % oh and ensure we replace nans by NO_value in vi
    vi(isnan(vi)) = NO_VALUE;
    
elseif size(wi,1)~=yi_numel || size(wi,2)~=xi_numel
    
    % there's still the case where wi was provided, but not at the right
    % dimensions, in which case we do same as above but adding a warning:
    wi = ones(yi_numel,xi_numel);
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
if isempty(w) || w==1
    w = ones(size(x));
end


%% PROCESSING

% now to the actual processing

% turn (x,y,v,w) variables to vectors
x = reshape(x,1,[]);
y = reshape(y,1,[]);
v = reshape(v,1,[]);
w = reshape(w,1,[]);

% remove any nan value
x(isnan(v)) = [];
y(isnan(v)) = [];
w(isnan(v)) = [];
v(isnan(v)) = [];

% find x,y values that are outside the grid & remove them
indout = x<xi_firstval | x>xi_lastval | y<yi_firstval | y>yi_lastval;
x(indout)=[];
y(indout)=[];
v(indout)=[];
w(indout)=[];

% perform weight gridding
for ii = 1:length(v)
    
    % find appropriate cell indices
    [i_xi,i_yi] = CFF_index_in_grid_2D(x(ii),y(ii),xi_firstval,yi_firstval,xi_step,yi_step);
    
    % add new value to cell according to its weight, and update weight
    [vi(i_yi,i_xi),wi(i_yi,i_xi)] = CFF_update_value_and_weight(v(ii),w(ii),vi(i_yi,i_xi),wi(i_yi,i_xi));
    
end

% put NaNs back in the grid cells that were not filled
vi(wi==0) = NaN;
