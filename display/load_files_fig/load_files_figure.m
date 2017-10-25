%% load_files_figure.m
%
% Main function for the figure to load files into app
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |input_variable_1|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% * |output_variable_1|: TODO: write description and info on variable
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-10-25: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help Espresso.m| for copyright information.

%% Function
function load_files_figure(main_figure)


% Get monitor's dimensions
size_max = get(0, 'MonitorPositions');

% ..
icon = get_icons_cdata(fullfile(whereisroot(),'icons'));


% ...
load_file_fig = figure('Units','pixels',...
    'Position',[size_max(1,1) size_max(1,2)+1/8*size_max(1,4) size_max(1,3)/8*3 size_max(1,4)/4*3],... %Position and size normalized to the screen size ([left, bottom, width, height])
    'Color','White',...
    'Name','Load Files',...
    'Tag','loadfiles',...
    'NumberTitle','off',...
    'Resize','off',...
    'MenuBar','none',...
    'Toolbar','none',...
    'visible','off',...
    'WindowStyle','modal');

gui_elt.path_box = uicontrol(load_file_fig,'Style','edit',...
    'Units','normalized',...
    'Position',[0.05 0.95 0.70 0.03],...
    'BackgroundColor','w',...
    'string',whereisroot(),...
    'HorizontalAlignment','left','Callback',@check_path_callback);

gui_elt.path_choose = uicontrol(load_file_fig,'Style','pushbutton','units','normalized',...
    'pos',[0.75 0.95 0.1 0.03],...
    'String','',...
    'Cdata',icon.folder,...
    'callback',{@select_folder_callback});

survDataSummary = {};

% Column names and column format
columnname = {'File' 'Folder'};
columnformat = {'char','char'};

% Create the uitable
gui_elt.table_main = uitable('Parent',load_file_fig,...
    'Data', survDataSummary,...
    'ColumnName', columnname,...
    'ColumnFormat', columnformat,...
    'CellSelectionCallback',@cell_select_cback,...
    'ColumnEditable', [false false],...
    'Units','Normalized','Position',[0.05 0.2 0.9 0.7],...
    'RowName',[]);

pos_t = getpixelposition(gui_elt.table_main);
set(gui_elt.table_main,'ColumnWidth',...
    num2cell(pos_t(3)*[10/20 10/20]));
%set(gui_elt.table_main,'CellEditCallback',{@edit_surv_data_db,surv_data_tab,main_figure});

setappdata(load_file_fig,'gui_elt',gui_elt)

setappdata(load_file_fig,'selected_files',[]);
setappdata(file_fig,'files',{});

centerfig(load_file_fig)
set(load_file_fig,'visible','on');

end


%% Subfunctions

function select_folder_callback(src,~)
file_fig = ancestor(src,'figure');
gui_elt = getappdata(ancestor(src,'figure'),'gui_elt');
path_ori = get(gui_elt.path_box,'string');
new_path = uigetdir(path_ori);
if new_path~=0
    set(gui_elt.path_box,'string',new_path);
end
booldir = check_path_callback(gui_elt.path_box,[]);

if booldir
    update_file_table(file_fig);
end

end

function update_file_table(file_fig)

gui_elt = getappdata(file_fig,'gui_elt');
path_ori = get(gui_elt.path_box,'string');
[folders,files,processed] = list_files_in_dir(path_ori);

nb_files = numel(folders);

new_entry = cell(nb_files,2);
new_entry(:,1) = files;
new_entry(:,2) = folders;

new_entry(~processed,1) = cellfun(@(x) strcat('<html><FONT color="Red"><b>',x,'</b></html>'),new_entry(~processed,1),'UniformOutput',0);
new_entry(processed,1) = cellfun(@(x) strcat('<html><FONT color="Green"><b>',x,'</b></html>'),new_entry(processed,1),'UniformOutput',0);

gui_elt.table_main.Data = new_entry;
setappdata(file_fig,'files',fullfile(folders,files));
end

function cell_select_cback(src,evt)
file_fig=ancestor(src,'figure');
filenames_ori=getappdata(file_fig,'files');
if ~isempty(evt.Indices)
    selected_files=filenames_ori(evt.Indices(:,1));
else
    selected_files={};
end
%selected_files'
setappdata(file_fig,'selected_files',selected_files);
end

function booldir = check_path_callback(src,~)

new_path = get(src,'string');
new_path = fileparts(new_path);
if ~isdir(new_path)
    set(src,'string','');
    booldir = 0;
else
    booldir = 1;
end

end