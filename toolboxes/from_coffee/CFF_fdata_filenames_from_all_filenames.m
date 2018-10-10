% fdata_filenames_from_all_filenames.m
%
% Create list of default Espresso internal path and filename from source
% files' names. 
%
% Each raw file to load will be saved with same name but with "_fdata"
% appended and ".mat" extension, in a "Coffee_files" folder when the raw files
% are found

function mat_fdata_files = CFF_fdata_filenames_from_all_filenames(files_full)

if ischar(files_full)
    files_full = {files_full};
end

[tet,rootfilename,ext] = cellfun(@fileparts,files_full,'UniformOutput',0);



for iF = 1:length(files_full)
    
    
    % coffee folder
    wc_dir = CFF_converted_data_folder(files_full{iF});
    
    mat_fdata_files = fullfile(wc_dir,file,'fdata.mat');
    
end

end
