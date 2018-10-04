%% list_files_in_dir.m
%
% List the files available for the app in input folder. Files are available
% only if the pair .all/.wcd exists. Also returns whether these pairs have
% been converted to .mat format.
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
function [folders,files,converted] = list_files_in_dir(folder_init)

% init
folders = {};
files = {};
converted = [];

% get .all files
AllFilename_list = subdir(fullfile(folder_init,'*.all'));
if isempty(AllFilename_list)
    return;
else
    AllFilename_cell = {AllFilename_list([AllFilename_list(:).isdir]==0).name};
end
% get .wcd files
WCDFilename_list = subdir(fullfile(folder_init,'*.wcd'));
if isempty(WCDFilename_list)
    return;
else
    WCDFilename_cell = {WCDFilename_list([WCDFilename_list(:).isdir]==0).name};
end

if isempty(WCDFilename_cell)&&isempty(AllFilename_cell)
    return;
end

% split in folders and file names
[all_folders,all_files,~] = cellfun(@fileparts,AllFilename_cell,'UniformOutput',0);
[wcd_folders,wcd_files,~] = cellfun(@fileparts,WCDFilename_cell,'UniformOutput',0);

% recombine
wcd_files = fullfile(wcd_folders,wcd_files);
all_files = fullfile(all_folders,all_files);

[files_full,~] = intersect(all_files,wcd_files);
%files_full = all_files;
[folders,files,~] = cellfun(@fileparts,files_full,'UniformOutput',0);

mat_fdata_files=fdata_filenames_from_all_filenames(files_full);

% boolean for whether these mat files exist
converted = cellfun(@(x) exist(x,'file')>0,mat_fdata_files);

end