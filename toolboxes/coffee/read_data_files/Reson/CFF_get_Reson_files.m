function [Reson_files,fileroot_reshaped] = CFF_get_Reson_files(fileroot)

if ischar(fileroot)
    fileroot = {fileroot};
end

fileroot_reshaped = reshape(fileroot,[numel(fileroot),1]);

Reson_files = cell(length(fileroot_reshaped),1);

for ii = 1:length(fileroot_reshaped)
    
    Reson_files{ii,1} = strcat(fileroot_reshaped{ii}, '.s7k');
    
end
