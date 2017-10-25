
function update_path(path)
addpath(path);
addpath(genpath(fullfile(path, 'display')));
addpath(genpath(fullfile(path, 'icons')));
addpath(genpath(fullfile(path, 'fileIO')));
addpath(genpath(fullfile(path, 'toolboxes')));
end
