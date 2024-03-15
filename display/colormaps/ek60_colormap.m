function cmap = ek60_colormap()
%EK60_COLORMAP  Same as the "EK60" colormap used in ESP2
%
%   See also ESPRESSO.

%   Copyright 2017-2024 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

load('EK60_colormap.mat');
cmap = double(ek60_cmap)/255;