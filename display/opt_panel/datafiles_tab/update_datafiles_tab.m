function update_datafiles_tab(main_figure)
%UPDATE_DATAFILES_TAB  Updates datafiles tab in Espresso Control panel
%
%   See also CREATE_DATAFILES_TAB, INITIALIZE_DISPLAY, ESPRESSO.

%   Copyright 2017-2021 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

fprintf('Updating list of files... ');

% get relevant stuff from main figure
file_tab_comp = getappdata(main_figure,'file_tab');
fData = getappdata(main_figure,'fData');

% list raw_files in search path
search_path = get(file_tab_comp.path_box,'string');
rawfileslist = CFF_list_raw_files_in_dir(search_path);

% check which are already converted
idx_converted = CFF_are_raw_files_converted(rawfileslist);
     
% check which are currently loaded
idx_loaded = CFF_are_raw_files_loaded(rawfileslist, fData);

% prepare array, without HTML tags yet
n_rawfiles = numel(rawfileslist);
[disp_folder, filename, ext] = CFF_fileparts_as_cell(CFF_onerawfileonly(rawfileslist));
disp_files = strcat(filename, ext);
for ii = 1:n_rawfiles
    if iscell(rawfileslist{ii})
        % paired file
        disp_files{ii} = strcat(disp_files{ii}, ' (paired)');
    end
end
new_entry = [disp_files, disp_folder];

%% add HTML tags

% raw files not even converted
new_entry(~idx_converted, 1) = cellfun(@(x) strcat('<html><FONT color="Gray">',x,'</html>'),new_entry(~idx_converted,1),'UniformOutput',0);

% files converted, but not loaded
new_entry(idx_converted & ~idx_loaded, 1) = cellfun(@(x) strcat('<html><FONT color="Black"><b>',x,'</b></html>'),new_entry(idx_converted&~idx_loaded,1),'UniformOutput',0);

% files converted and loaded
new_entry(idx_converted & idx_loaded, 1) = cellfun(@(x) strcat('<html><FONT color="Green"><b>',x,'</b></html>'),new_entry(idx_converted&idx_loaded,1),'UniformOutput',0);

% ideally, also differentiate the loaded files between those that have been
% already processed, and that did not XXX2

%% update file_tab_comp
file_tab_comp.table_main.Data = new_entry;
file_tab_comp.files = rawfileslist;
file_tab_comp.idx_converted = idx_converted;
setappdata(main_figure,'file_tab',file_tab_comp);

fprintf('Done.\n');

end