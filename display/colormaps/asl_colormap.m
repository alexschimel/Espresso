function cmap = asl_colormap()
%ASL_COLORMAP  Colormap provided by ASL
%
%   See also ESPRESSO.

%   Authors: Yoann Ladroit (NIWA, yoann.ladroit@niwa.co.nz) and Alex
%   Schimel (NIWA, alexandre.schimel@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

load(fullfile(whereisEcho,'private','AZFPColormap'));

cmap = double(myNewMap);