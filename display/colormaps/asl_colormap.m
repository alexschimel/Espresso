function cmap = asl_colormap()
%Colormap Provided by ASL

load(fullfile(whereisEcho,'private','AZFPColormap'));

cmap = double(myNewMap);