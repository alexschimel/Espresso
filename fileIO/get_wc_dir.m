% get_wc_dir.m
%
%
%
function wc_dir = get_wc_dir(ALLfilename)

[dir_data,fname,~] = fileparts(ALLfilename);

wc_dir = fullfile(dir_data,'wc_mat',fname);

if exist(wc_dir,'dir') == 0
    mkdir(wc_dir);
end