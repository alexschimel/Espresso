function [folders,files,processed]=list_files_in_dir(folder_init)
 folders={};
 files={};
 processed=[];

AllFilename_list=subdir(fullfile(folder_init,'*.all'));
if isempty(AllFilename_list)
    return;
end
AllFilename_cell={AllFilename_list([AllFilename_list(:).isdir]==0).name};


WCDFilename_list=subdir(fullfile(folder_init,'*.wcd'));
if isempty(WCDFilename_list)
    return;
end
WCDFilename_cell={WCDFilename_list([WCDFilename_list(:).isdir]==0).name};

[wcd_folders,wcd_files,~]=cellfun(@fileparts,WCDFilename_cell,'UniformOutput',0);
[all_folders,all_files,~]=cellfun(@fileparts,AllFilename_cell,'UniformOutput',0);

wcd_files=fullfile(wcd_folders,wcd_files);
all_files=fullfile(all_folders,all_files);

[files_full,~]=intersect(all_files,wcd_files);

[folders,files,~]=cellfun(@fileparts,files_full,'UniformOutput',0);

mat_all_files=fullfile(folders,'wc_mat',strcat(files,'_all.mat'));
mat_wcd_files=fullfile(folders,'wc_mat',strcat(files,'_wcd.mat'));

processed=cellfun(@(x) exist(x,'file')>0,mat_all_files)&...
    cellfun(@(x) exist(x,'file')>0,mat_wcd_files);



end