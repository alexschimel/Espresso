function [mat_all_files,mat_wcd_files] = matfilenames_from_all_filenames(files_full)

[folders,files,~] = cellfun(@fileparts,files_full,'UniformOutput',0);

% default names for mat versions of those files
mat_all_files = fullfile(folders,'wc_mat',strcat(files,'_all.mat'));
mat_wcd_files = fullfile(folders,'wc_mat',strcat(files,'_wcd.mat'));