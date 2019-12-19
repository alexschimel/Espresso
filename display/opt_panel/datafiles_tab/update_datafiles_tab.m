%% update_datafiles_tab.m
%
% Update the "raw files" tab of Espresso's control panel
%
%% Help
%
% *USE*
%
% _This section contains a more detailed description of what the function
% does and how to use it, for the interested user to have an overall
% understanding of its function. Example below to replace. Delete these
% lines XXX._
%
% This is a text file containing the basic comment template to add at the
% start of any new ESP3 function to serve as function help. XXX
%
% *INPUT VARIABLES*
%
% _This section contains bullet points of input variables with description
% and information. Put input variable and other valid entries or defaults
% between | symbols so it shows as monospace. Information section to
% contain, in order: requirement (i.e. Required/Optional/Paramter), valid
% type (e.g. Num, Positive num, char, 1xN cell array, etc.) and default
% value if there is one (e.g. Default: '10'). Example below to replace.
% Delete these lines XXX._
%
% * |input_variable_1|: Description (Information). XXX
% * |input_variable_2|: Description (Information). XXX
% * |input_variable_3|: Description (Information). XXX
%
% *OUTPUT VARIABLES*
%
% _This section contains bullet points of output variables with description
% and information. See input variables for template. Example below to
% replace. Delete these lines XXX._
%
% * |output_variable_1|: Description (Information). XXX
% * |output_variable_2|: Description (Information). XXX
%
% *DEVELOPMENT NOTES*
%
% _This section describes what features are temporary, needed future
% developments and paper references. Example below to replace. Delete these
% lines XXX._
%
% * research point 1. XXX
% * research point 2. XXX
%
% *NEW FEATURES*
%
% _This section contains dates and descriptions of major updates. Example
% below to replace. Delete these lines XXX._
%
% * YYYY-MM-DD: second version. Describes the update. XXX
% * YYYY-MM-DD: first version. XXX
%
% *EXAMPLE*
%
% _This section contains examples of valid function calls. Note that
% example lines start with 3 white spaces so that the publish function
% shows them correctly as matlab code. Example below to replace. Delete
% these lines XXX._
%
%   example_use_1; % comment on what this does. XXX
%   example_use_2: % comment on what this line does. XXX
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% _This last section contains at least author name and affiliation. Delete
% these lines XXX._
%
% Yoann Ladroit, Alexandre Schimel, NIWA. XXX

%% Function
function update_datafiles_tab(main_figure)

file_tab_comp = getappdata(main_figure,'file_tab');

% list of fData files currently loaded
loaded_files = get_loaded_files(main_figure);
[~,loaded_filenames,~] = cellfun(@fileparts,loaded_files,'UniformOutput',0);

% list of raw and converted files
path_ori = get(file_tab_comp.path_box,'string');
[folders,raw_filenames,converted] = CFF_list_files_in_dir(path_ori);
nb_files = numel(folders);
[~,raw_filenames_t,~] = cellfun(@fileparts,raw_filenames,'UniformOutput',0);

% which of the raw files are loaded
loaded = ismember(raw_filenames_t,loaded_filenames);

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