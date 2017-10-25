function load_files_figure(main_figure)


%% Get monitor's dimensions
size_max = get(0, 'MonitorPositions');

icon=get_icons_cdata(fullfile(whereisroot(),'icons'));


%% Defining the app's main window
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

gui_elt.path_choose=uicontrol(load_file_fig,'Style','pushbutton','units','normalized',...
    'pos',[0.75 0.95 0.1 0.03],...
    'String','',...
    'Cdata',icon.folder,...
    'callback',{@select_folder_callback});


survDataSummary={};
    
    
    
    % Column names and column format
    columnname = {'' 'File' 'Folder'};
    columnformat = {'logical' 'char','char'};
    
    
    % Create the uitable
    gui_elt.table_main = uitable('Parent',load_file_fig,...
        'Data', survDataSummary,...
        'ColumnName', columnname,...
        'ColumnFormat', columnformat,...
        'CellSelectionCallback',{@cell_select_cback,main_figure},...
        'ColumnEditable', [true false false],...
        'Units','Normalized','Position',[0.05 0.2 0.9 0.7],...
        'KeyPressFcn',{@logbook_keypress_fcn,main_figure},...
        'RowName',[]);
    
    
    pos_t = getpixelposition(gui_elt.table_main);
    set(gui_elt.table_main,'ColumnWidth',...
        num2cell(pos_t(3)*[1/20 5/20 14/20]));
    %set(gui_elt.table_main,'CellEditCallback',{@edit_surv_data_db,surv_data_tab,main_figure});
  

setappdata(load_file_fig,'gui_elt',gui_elt)

centerfig(load_file_fig)
set(load_file_fig,'visible','on');

end


function select_folder_callback(src,~)
gui_elt=getappdata(ancestor(src,'figure'),'gui_elt');
path_ori=get(gui_elt.path_box,'string');
new_path = uigetdir(path_ori);
if new_path~=0
    set(gui_elt.path_box,'string',new_path);
    [~,folder_out_name,~]=fileparts(new_path);
    set(gui_elt.file_out_box,'string',fullfile(new_path,[folder_out_name '.shp']));
end
check_path_callback(gui_elt.path_box,[]);
end



function check_path_callback(src,~)

new_path=get(src,'string');
new_path=fileparts(new_path);
if ~isdir(new_path)
    set(src,'string','');
end

end