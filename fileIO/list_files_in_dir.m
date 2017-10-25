function [files,processed]=list_files_in_dir(folder_init)


AllFilename_list=subdir(fullfile(folder_init,'*.all'));
AllFilename_cell={AllFilename_list([AllFilename_list(:).isdir]==0).name};

WCDFilename_list=subdir(fullfile(folder_init,'*.wcd'));
WCDFilename_cell={AllFilename_list([AllFilename_list(:).isdir]==0).name};





end