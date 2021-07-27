function cmap = ek500_colormap()
%EK500_COLORMAP  Same as the "EK500 (white)" colormap used in ESP2
%
%   Red Green Blue
%
%   See also ESPRESSO.

%   Authors: Yoann Ladroit (NIWA, yoann.ladroit@niwa.co.nz) and Alex
%   Schimel (NIWA, alexandre.schimel@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

cmap = [[255, 255, 255]; ... % White
    [255, 255, 255]; ...  % White
    [255, 255, 255]; ...  % White
    [255, 255, 255]; ...  % White
    [159, 159, 159]; ...  % Grey (62%)
    [ 95,  95,  95]; ...  % Grey (37%)
    [  0,   0, 255]; ...  % Blue
    [  0,   0, 127]; ...  % Blue (50%)
    [  0, 191,   0]; ...  % Green (75%)
    [  0, 127,   0]; ...  % Green (50%)
    [255, 255,   0]; ...  % Yellow
    [255, 127,   0]; ...  % Dark orange
    [255,   0, 191]; ...  % Magenta
    [255,   0,   0]; ...  % Red
    [166,  83,  60]; ...  % Brown (Desert)
    [120,  60,  40]]/255; % Brown (Copper Canyon)
