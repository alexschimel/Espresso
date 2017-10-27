function cmap=ek60_colormap()
% This is the same as the "EK500 (white)" colormap
% used in ESP2

%      Red Green Blue
load(fullfile(whereisEcho,'private','ek60_cmap.mat'));

cmap=double(ek60_cmap)/255;