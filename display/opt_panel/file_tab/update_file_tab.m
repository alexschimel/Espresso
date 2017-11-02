
function update_file_tab(main_figure)

file_tab_comp = getappdata(main_figure,'file_tab');

loaded_files=get_loaded_files(main_figure);

path_ori = get(file_tab_comp.path_box,'string');

[folders,files,processed] = list_files_in_dir(path_ori);

nb_files = numel(folders);

new_entry = cell(nb_files,2);
new_entry(:,1) = files;
new_entry(:,2) = folders;
loaded=ismember(fullfile(folders,files),loaded_files);

new_entry(~processed,1) = cellfun(@(x) strcat('<html><FONT color="Red"><b>',x,'</b></html>'),new_entry(~processed,1),'UniformOutput',0);
new_entry(processed&~loaded,1) = cellfun(@(x) strcat('<html><FONT color="Blue"><b>',x,'</b></html>'),new_entry(processed&~loaded,1),'UniformOutput',0);
new_entry(processed&loaded,1) = cellfun(@(x) strcat('<html><FONT color="Green"><b>',x,'</b></html>'),new_entry(processed&loaded,1),'UniformOutput',0);

file_tab_comp.table_main.Data = new_entry;
file_tab_comp.files=fullfile(folders,files);
file_tab_comp.processed=processed;

setappdata(main_figure,'file_tab',file_tab_comp);
end