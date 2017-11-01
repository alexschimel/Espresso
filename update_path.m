%% update_path.m
%
% Add subfolders to Matlab path
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |input_variable_1|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% * |output_variable_1|: TODO: write description and info on variable
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-10-25: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help Espresso.m| for copyright information.

%% Function
function update_path(path)

addpath(path);
addpath(genpath(fullfile(path,'display')));
addpath(genpath(fullfile(path,'icons')));
addpath(genpath(fullfile(path,'fileIO')));
addpath(genpath(fullfile(path,'toolboxes')));
addpath(genpath(fullfile(path,'classes')));
addpath(genpath(fullfile(path,'general')));


end
