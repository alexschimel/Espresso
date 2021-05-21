%% CFF_get_fData_version.m
%
% Get the fData version of a fData mat file
%
%% Help
%
% *USE*
%
% Get the content of the field MET_Fmt_version in fData without loading
% fData into memory.
%
% Note: Oldest versions of fData had no version stored in it, so we return
% the appropriate version, which was '0.0'.
% If the file does not exist, returns empty
%
% Warning: do not confuse this function with
% "CFF_get_current_fData_version.m", which gives the latest version of
% fData used by the converting code
%
% *NEW FEATURES*
%
% * 2021-05-21: first versiokn (Alex)
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, Alexandre Schimel NIWA. Type |help Espresso.m| for
% copyright information.

%% Function
function ver = CFF_get_fData_version(mat_fdata_file)

if isfile(mat_fdata_file)
    % file exists
    
    % check for existence of version field (older versions of fData didn't)
    matObj = matfile(mat_fdata_file);
    if isfield(matObj.fData, 'MET_Fmt_version')
        ver = getfield(matObj.fData,'MET_Fmt_version');
    else
        ver = '0.0';
    end
    
else
    % file doesn't exist
    ver = '';
    
end
