% Formerly "get_wc_dir.m". Just replace the function name
%
% This function gets the folder path for the memmap file where the WCD data
% from ALLfilename is stored
%
% For now, if the ALLfilename is X/filename.ext, the wc_dir will be
% X/wc_mat/filename/
%
function wc_dir = CFF_WCD_memmap_folder(ALLfilename)

% get root folder X and file name without the extension
[dir_data,fname,~] = fileparts(ALLfilename);

% get the folder name
wc_dir = fullfile(dir_data,'wc_mat',fname);

% create it if it doesn't exist
if exist(wc_dir,'dir') == 0
    mkdir(wc_dir);
end