% Formerly "get_wc_dir.m". Just replace the function name
%
% This function gets the folder path for the memmap file where the WCD data
% from ALLfilename is stored
%
% For now, if the ALLfilename is X/filename.ext, the wc_dir will be
% X/Coffee_files/filename/
%
function wc_dir = CFF_converted_data_folder(files_full)

if ischar(files_full)
    files_full = {files_full};
end

% get file's path and filename
[filepath,name,~]  = cellfun(@fileparts,files_full,'UniformOutput',0);

% coffee folder
coffee_dir = 'Coffee_files';
coffee_dir = repmat({coffee_dir},size(files_full));

% putting everything together
wc_dir = cellfun(@fullfile,filepath,coffee_dir,name,'UniformOutput',0);

if numel(wc_dir) == 1
    wc_dir = cell2mat(wc_dir);
end