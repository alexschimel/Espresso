%% CFF_is_fData_version_current.m
%
% Check if fData version of an input fData.mat file is the current code
% version.
%
%% Help
%
% *USE*
%
% input can be either the filepath to a fData.mat file, OR a fData
% structure.
%
% *NEW FEATURES*
%
% * 2021-05-24: first version (Alex)
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, Alexandre Schimel NIWA. Type |help Espresso.m| for
% copyright information.

%% Function
function bool = CFF_is_fData_version_current(fdata_input)

% version if the fData file
fdata_ver = CFF_get_fData_version(fdata_input);

% current version for the conversion code
curr_ver = CFF_get_current_fData_version();

% match?
bool = strcmpi(fdata_ver,curr_ver);