% fdata_filenames_from_all_filenames.m
%
% Create list of default Espresso internal path and filename from source
% files' names. 
%
function mat_fdata_files = fdata_filenames_from_all_filenames(files_full)

if ischar(files_full)
    files_full = {files_full};
end

[folders,files,~] = cellfun(@fileparts,files_full,'UniformOutput',0);

% Each raw file to load will be saved with same name but with "_fdata"
% appended and ".mat" extension, in a "wc_mat" folder when the raw files
% are found
mat_fdata_files = fullfile(folders,'wc_mat',strcat(files,'_fdata.mat'));

end
