%% CFF_are_raw_files_converted.m
%
% Check if raw files are already  converteed.
%
%% Help
%
% *USE*
%
% Test for conversion includes whether the fData.mat file exists, and if
% its version matches the current fData version
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Alexandre Schimel (NGU, NIWA), Yoann Ladroit (NIWA). 
% Type |help Espresso.m| for copyright information.

%% Function
function idx_converted = CFF_are_raw_files_converted(rawfileslist)

if isempty(rawfileslist)
    idx_converted = [];
    return
end

% list of names of converted files
wc_dir = CFF_converted_data_folder(rawfileslist);
mat_fdata_files = fullfile(wc_dir,'fdata.mat');
if ischar(mat_fdata_files)
    mat_fdata_files = {mat_fdata_files};
end
n_files = numel(mat_fdata_files);

% init output
idx_converted = false(n_files, 1);

% test each file
for ii = 1:n_files
    
    % name of converted file
    mat_fdata_file = mat_fdata_files{ii};
    
    % check if converted file exists
    flag_fdata_exist = isfile(mat_fdata_file);
    
    % if it does, check version in the file and compare with current
    % conversion code version 
    if flag_fdata_exist
        file_ver = CFF_get_fData_version(mat_fdata_file);
        flag_fdata_ver_ok = strcmpi(file_ver,CFF_get_current_fData_version);
    end
    
    % output
    idx_converted(ii,1) = flag_fdata_exist && flag_fdata_ver_ok;
    
end

