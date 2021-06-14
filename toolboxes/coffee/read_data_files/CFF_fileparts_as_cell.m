%% CFF_fileparts_as_cell.m
%
% Like fileparts, but always returning cell arrays
%
%% Help
%
% *USE*
%
% Fileparts can take a cell array of file names as input. If this array has
% zero or N>2 elements, the parts are cell arrays. But if it has only one
% element, the returned parts are strings. Correct this silly behaviour.
%
% *OUTPUT VARIABLES*
%
% * |ext|: String filename extension, or cell array of string filenames
% extension
%
% *DEVELOPMENT NOTES*
%
% *NEW FEATURES*
%
% * 2021-06-15: As its own function. Alex
% * YYYY-MM-DD: first version as sub function of CFF_list_raw_files_in_dir
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Alexandre Schimel (NGU), Yoann Ladroit (NIWA).
% Type |help Espresso.m| for copyright information.

%% Function
function [filepath,name,ext] = CFF_fileparts_as_cell(file_list)

[filepath,name,ext] = fileparts(file_list);

if ischar(filepath)
    filepath = {filepath};
end
if ischar(name)
    name = {name};
end
if ischar(ext)
    ext = {ext};
end

end
