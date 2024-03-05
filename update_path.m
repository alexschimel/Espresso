function update_path(path)
%UPDATE_PATH  Add subfolders relevant to Espresso to Matlab path
%
%   See also ESPRESSO.

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann Ladroit
%   (NIWA, yoann.ladroit@niwa.co.nz) 
%   2017-2022; Last revision: 12-08-2022

addpath(path);
addpath(genpath(fullfile(path,'assets')));
addpath(genpath(fullfile(path,'classes')));
addpath(genpath(fullfile(path,'display')));
addpath(genpath(fullfile(path,'io')));
addpath(genpath(fullfile(path,'processing')));
addpath(genpath(fullfile(path,'toolboxes')));
addpath(genpath(fullfile(path,'general')));

end
