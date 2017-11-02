function mat_fdata_files=fdata_filenames_from_all_filenames(files_full)
[folders,files,~] = cellfun(@fileparts,files_full,'UniformOutput',0);

% default names for mat versions of those files
mat_fdata_files = fullfile(folders,'wc_mat',strcat(files,'_fdata.mat'));
