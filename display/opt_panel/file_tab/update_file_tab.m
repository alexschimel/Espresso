% update_file_tab.m
%
% Update the "raw files" tab of Espresso's control panel
%
function update_file_tab(main_figure)

file_tab_comp = getappdata(main_figure,'file_tab');

% list of fData files currently loaded
loaded_files = get_loaded_files(main_figure);
[~,loaded_filenames,~] = cellfun(@fileparts,loaded_files,'UniformOutput',0);

% list of raw and converted files
path_ori = get(file_tab_comp.path_box,'string');
[folders,raw_filenames,converted] = CFF_list_files_in_dir(path_ori);
nb_files = numel(folders);

% which of the raw files are loaded
loaded = ismember(raw_filenames,loaded_filenames);

% prep new_entry array
new_entry = cell(nb_files,2);
new_entry(:,1) = raw_filenames;
new_entry(:,2) = folders;

% raw files not even converted
new_entry(~converted,1) = cellfun(@(x) strcat('<html><FONT color="Gray">',x,'</html>'),new_entry(~converted,1),'UniformOutput',0);

% files converted, but not loaded
new_entry(converted&~loaded,1) = cellfun(@(x) strcat('<html><FONT color="Black"><b>',x,'</b></html>'),new_entry(converted&~loaded,1),'UniformOutput',0);

% files converted and loaded
new_entry(converted&loaded,1) = cellfun(@(x) strcat('<html><FONT color="Green"><b>',x,'</b></html>'),new_entry(converted&loaded,1),'UniformOutput',0);

% differentiate the loaded files between those that have been processed
% already, and those that didn't... XXX

% update file_tab_comp
file_tab_comp.table_main.Data = new_entry;
file_tab_comp.files = fullfile(folders,raw_filenames);
file_tab_comp.converted = converted;

setappdata(main_figure,'file_tab',file_tab_comp);

end