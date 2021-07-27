function cmap = esp2_colormap()
%ESP2_COLORMAP  RED, GREEN, BLUE
%
%   See also ESPRESSO.

%   Authors: Yoann Ladroit (NIWA, yoann.ladroit@niwa.co.nz) and Alex
%   Schimel (NIWA, alexandre.schimel@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

cmap =  [[0, 0, 0];...      % Black
    [60,60,60];...      % Grey (23%)
    [80,80,80];...      % Grey (31%)
    [100,100,100];...   % Grey (39%)
    [120,120,120];...   % Grey (50%)
    [150,135,0];...     % ?
    [255,0, 112];...    % ?
    [230,0, 0];...      % Red  (90%)
    [0, 200,0];...      % Green (80%)
    [0, 255,100];...    % ?
    [255,60,160];...    % ?
    [255,70,170];...    % ?
    [255,80,180];...    % ?
    [255,150,190];...   % ?
    [255,255,255];...   % White (100%)
    [255,255,255]]/255;