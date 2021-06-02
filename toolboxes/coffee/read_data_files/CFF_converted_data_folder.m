%% CFF_converted_data_folder.m
%
% Gets the path to the folder for data converted by CoFFee from a raw
% filename.
%
%% Help
%
% *USE*
%
% wc_dir = CFF_converted_data_folder(files_full) returns the folder path
% X/Coffee_files/filename/ for filename X/filename.ext. ALso works with
% cell arrays of string filenames.
%
% *INPUT VARIABLES*
%
% * |files_full|: Required. Description (Information). XXX
%
% *OUTPUT VARIABLES*
%
% * |wc_dir|: Description (Information). XXX
%
% *DEVELOPMENT NOTES*
%
% * Formerly "get_wc_dir.m" then revamped
%
% *NEW FEATURES*
%
% * 2018-10-11: first version.
%
% *EXAMPLE*
%
%   example_use_1; % comment on what this does. XXX
%   example_use_2: % comment on what this line does. XXX
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, Alexandre Schimel, NIWA.

%% Function
function wc_dir = CFF_converted_data_folder(rawfileslist)

if isempty(rawfileslist)
    wc_dir = [];
    return
end

if ischar(rawfileslist)
    rawfileslist = {rawfileslist};
end

% simplify rawfileslist when pairs occur
rawfileslist = CFF_onerawfileonly(rawfileslist);
n_files = numel(rawfileslist);

% get path and filename (without extension) for each file
[filepath,filename,~]  = cellfun(@fileparts,rawfileslist,'UniformOutput',0);

% define coffee folder
coffee_dir_name = 'Coffee_files';
coffee_dir_name = repmat({coffee_dir_name},[n_files, 1]);

% putting everything together
wc_dir = cellfun(@fullfile,filepath,coffee_dir_name,filename,'UniformOutput',0);

if numel(wc_dir) == 1
    wc_dir = cell2mat(wc_dir);
end