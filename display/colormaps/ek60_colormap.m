function cmap = ek60_colormap()
%EK60_COLORMAP  Same as the "EK60" colormap used in ESP2
%
%   See also ESPRESSO.

%   Authors: Yoann Ladroit (NIWA, yoann.ladroit@niwa.co.nz) and Alex
%   Schimel (NIWA, alexandre.schimel@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

load(fullfile(whereisroot,'private','ek60_cmap.mat'));

cmap = double(ek60_cmap)/255;