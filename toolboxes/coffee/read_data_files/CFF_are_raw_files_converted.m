function [idx_converted,flag_outdated_fdata] = CFF_are_raw_files_converted(rawfileslist)
%CFF_ARE_RAW_FILES_CONVERTED  Check if raw files are already converted.
%
%   For each input file, the test for conversion includes whether the
%   corresponding fData.mat file exists, and if its version matches the
%   current fData version. If the version does not match, then the file is
%   officially NOT converted.
%   If any file was converted but has the wrong version, it sets the output
%   flag flag_outdated_fdata to one.
%
%   See also ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

% exit if no input
if isempty(rawfileslist)
    idx_converted = [];
    flag_outdated_fdata = [];
    return
end

% list of names of converted files, if input were converted
wc_dir = CFF_converted_data_folder(rawfileslist);
mat_fdata_files = fullfile(wc_dir,'fdata.mat');
if ischar(mat_fdata_files)
    mat_fdata_files = {mat_fdata_files};
end
n_files = numel(mat_fdata_files);

% init output
idx_converted = false(n_files, 1);
flag_outdated_fdata = 0;

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
        
        % flag out the mismatch in version for output
        if ~flag_fdata_ver_ok
            flag_outdated_fdata = 1;
        end
    end
    
    % output
    idx_converted(ii,1) = flag_fdata_exist && flag_fdata_ver_ok;
    
end

