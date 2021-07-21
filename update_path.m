function update_path(path)
%UPDATE_PATH  Add subfolders relevant to Espresso to Matlab path
%
%   See also ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 21-07-2021

addpath(path);
addpath(genpath(fullfile(path,'classes')));
addpath(genpath(fullfile(path,'display')));
addpath(genpath(fullfile(path,'icons')));
addpath(genpath(fullfile(path,'io')));
addpath(genpath(fullfile(path,'processing')));
addpath(genpath(fullfile(path,'toolboxes')));

end
