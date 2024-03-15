function update_path(path)
%UPDATE_PATH  Add subfolders relevant to Espresso to Matlab path
%
%   See also ESPRESSO.

%   Copyright 2017-2024 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

addpath(path);
addpath(genpath(fullfile(path,'assets')));
addpath(genpath(fullfile(path,'classes')));
addpath(genpath(fullfile(path,'display')));
addpath(genpath(fullfile(path,'io')));
addpath(genpath(fullfile(path,'processing')));
addpath(genpath(fullfile(path,'toolboxes')));
addpath(genpath(fullfile(path,'general')));

end
