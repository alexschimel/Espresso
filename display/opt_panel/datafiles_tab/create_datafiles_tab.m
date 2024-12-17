function create_datafiles_tab(main_figure,parent_tab_group)
%CREATE_DATAFILES_TAB  Creates datafiles tab in Espresso Control panel
%
%   See also UPDATE_DATAFILES_TAB, INITIALIZE_DISPLAY, ESPRESSO.

%   Copyright 2017-2024 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

%% create tab variable
switch parent_tab_group.Type
    case 'uitabgroup'
        file_tab_comp.file_tab = uitab(parent_tab_group,'Title','Data files','Tag','file_tab','BackGroundColor','w');
    case 'figure'
        file_tab_comp.file_tab = parent_tab_group;
end


%% folder push button

% create button
file_tab_comp.path_choose = uicontrol(file_tab_comp.file_tab,'Style','pushbutton',...
    'units','normalized',...
    'pos',[0.0 0.91 0.1 0.08],...
    'String','',...
    'Cdata',read_icon('iconFolder.gif'),...
    'callback',{@callback_select_folder,main_figure});


%% folder text field

% get initial data path from config file
path_init = get_config_field('lastDataPath');
if isempty(path_init) || ~isfolder(path_init)
    path_init = whereisroot(); % default data path
end

% create text field
file_tab_comp.path_box = uicontrol(file_tab_comp.file_tab,'Style','edit',...
    'Units','normalized',...
    'Position',[0.1 0.91 0.9 0.08],...
    'BackgroundColor','w',...
    'string',path_init,...
    'HorizontalAlignment','left',...
    'Callback',{@callback_select_folder,main_figure});



%% files list

% Column names and format
columnname = {'File' 'Folder'};
columnformat = {'char','char'};

% Create the files list (uitable)
file_tab_comp.table_main = uitable('Parent',file_tab_comp.file_tab,...
    'Data', {},...
    'ColumnName', columnname,...
    'ColumnEditable', [false false],...
    'ColumnFormat', columnformat,...
    'RowName',[],...
    'Tooltip','Gray: not converted. Black: converted/loadable. Green: loaded',...
    'Units','Normalized','Position',[0 0.1 1 0.8],...
    'CellSelectionCallback',{@callback_select_cell,main_figure});

% Set widths of columns in table and add callback for automatic resizing
pos_t = getpixelposition(file_tab_comp.table_main);
set(file_tab_comp.table_main,'ColumnWidth',num2cell(pos_t(3)*[10/20 10/20]));
set(file_tab_comp.file_tab,'SizeChangedFcn',{@resize_table,file_tab_comp.table_main});


%% "convert", "reconvert" and "load" push buttons

uicontrol(file_tab_comp.file_tab,'Style','pushbutton','String','Convert',...
    'units','normalized',...
    'pos',[0.00 0.01 0.2 0.08],...
    'callback',{@callback_press_convert_button,main_figure,0});

uicontrol(file_tab_comp.file_tab,'Style','pushbutton','String','Re-Convert',...
    'units','normalized',...
    'pos',[0.20 0.01 0.2 0.08],...
    'callback',{@callback_press_convert_button,main_figure,1});

uicontrol(file_tab_comp.file_tab,'Style','pushbutton','String','Load',...
    'units','normalized',...
    'pos',[0.40 0.01 0.2 0.08],...
    'callback',{@callback_press_load_button,main_figure});

uicontrol(file_tab_comp.file_tab,'Style','pushbutton','String','Convert, Load & Process',...
    'units','normalized',...
    'pos',[0.60 0.01 0.4 0.08],...
    'callback',{@callback_press_convertloadprocess_button,main_figure});

%% finalize

% empties
file_tab_comp.idx_selected = [];
file_tab_comp.files = {};
file_tab_comp.idx_converted = [];

% add tab to appdata
setappdata(main_figure,'file_tab',file_tab_comp);

% run the update function
update_datafiles_tab(main_figure);

end


%% Callback when pressing the "Folder" button or interacting with folder
function callback_select_folder(src,~,main_figure)

% get tab data
file_tab_comp = getappdata(main_figure,'file_tab');

switch src.Style
    
    case 'edit'
        % if interacting with folder text field
        % get the new path
        new_path = get(src,'string');
        
        if new_path ~= 0
            if isfolder(new_path)
                % folder is valid, update the tab
                update_datafiles_tab(main_figure);
                % save it in config file
                set_config_field('lastDataPath',new_path);
            end
        else
            return;
        end
        
    case 'pushbutton'
        % if pressing the folder button
        % open a getdir prompt for new directory, starting from old
        % directory
        path_ori = get(file_tab_comp.path_box,'string');
        new_path = uigetdir(path_ori,'Select folder of raw data files (.wcd) to open');
        
        % update the field and the entire tab if valid
        if new_path ~= 0
            set(file_tab_comp.path_box,'string',new_path);
            update_datafiles_tab(main_figure);
            % save it in config file
            set_config_field('lastDataPath',new_path);
        end
        
end



end


%% Callback when selecting a cell in files list
function callback_select_cell(~,evt,main_figure)

% get tab data
file_tab_comp = getappdata(main_figure,'file_tab');

% init output
n_files = numel(file_tab_comp.files);
idx_selected = false(n_files,1);

% fill in indices
if ~isempty(evt.Indices)
    idx = unique(evt.Indices(:,1));
    idx_selected(idx) = 1;
end

% update the selected file(s)
file_tab_comp.idx_selected = idx_selected;
setappdata(main_figure,'file_tab',file_tab_comp);

end




%% Callback when pressing the "Convert" or "Re-convert" button
function callback_press_convert_button(~,~,main_figure,flag_force_convert)

% get tab data
file_tab_comp = getappdata(main_figure,'file_tab');

% list of files requested for conversion
files = file_tab_comp.files;
idx_selected = file_tab_comp.idx_selected;
files_to_convert = files(idx_selected);

% convert files
%convert_files(files_to_convert, flag_force_convert); % OBSOLETE
CFF_convert_raw_files(files_to_convert,...
    'conversionType','seafloorOrWCD',...
    'saveFDataToDrive',1,...
    'forceReconvert',flag_force_convert,...
    'outputFData',0,...
    'continueOnError',1,...
    'convertEvenIfDtgrmsMissing',0,...
    'dr_sub',1,...
    'db_sub',1,...
    'comms','multilines');

% update display
update_datafiles_tab(main_figure);

end



%% Callback when pressing the "Load" button
function callback_press_load_button(~,~,main_figure)

% get tab data
file_tab_comp = getappdata(main_figure,'file_tab');

% get existing fData and disp_config
fData = getappdata(main_figure,'fData');
disp_config = getappdata(main_figure,'disp_config');

% list of files
files = file_tab_comp.files;

% check which are...
idxConverted = CFF_are_raw_files_converted(files);
idxAlreadyLoaded = CFF_are_raw_files_loaded(files, fData);
idxSelected = file_tab_comp.idx_selected;
idxFilesToLoad = idxSelected & ~idxAlreadyLoaded;
idxNeedConversionFirst = idxFilesToLoad & ~idxConverted;

% prompt to convert those unconverted yet
if any(idxNeedConversionFirst)
    N = sum(idxNeedConversionFirst);
    if N == 1
        questDlgTxt = sprintf('1 file for which loading was requested has not been converted yet.\n\nDo you want to convert it and load it?');
    else
        questDlgTxt = sprintf('%i files for which loading was requested have not been converted yet.\n\nDo you want to convert them and load them?',N);
    end
    answer = questdlg(questDlgTxt, ...
        'Converted Files Loading', ...
        'Yes','No','Cancel','Cancel');
    switch answer
        case 'Yes'
            % Convert those files
            CFF_convert_raw_files(files(idxNeedConversionFirst),...
                'conversionType','seafloorOrWCD',...
                'saveFDataToDrive',1,...
                'forceReconvert',1,...
                'outputFData',0,...
                'continueOnError',1,...
                'convertEvenIfDtgrmsMissing',0,...
                'dr_sub',1,...
                'db_sub',1,...
                'comms','multilines');
        case 'No'
            % Remove non-converted files from loading list
            idxFilesToLoad = idxFilesToLoad & idxConverted;
        case 'Cancel'
            % abort loading
            return
    end
end

% name of files to load
files_to_load = files(idxFilesToLoad);
nFiles = numel(files_to_load);
if isempty(files_to_load)
   return
end

% load files
fData_new = CFF_load_converted_files(files_to_load,...
    'fixPaths',1,...
    'continueOnError',1,...
    'comms','multilines');

% initialize navigation processing parameters
navProcParams = struct(); 

% reuse parameters in disp_config, if they exist. Those that don't exist
% will be initialized in the first file
if ~isempty(disp_config.MET_datagramSource)
    navProcParams.datagramSource = disp_config.MET_datagramSource;
end
if ~isempty(disp_config.MET_ellips)
    navProcParams.ellips = disp_config.MET_ellips;
end
if ~isempty(disp_config.MET_tmproj)
    navProcParams.tmproj = disp_config.MET_tmproj;
end

% chain process: 
% 1) navigation processing
% 2) georeference WC bottom detect
procFun{1} = @CFF_compute_ping_navigation_v2;
procMsg{1} = 'Processing navigation and heading';
procParams{1} = navProcParams;
procFun{2} = @CFF_georeference_bottom_detect;
procMsg{2} = 'Georeferencing the bottom detections';
procParams{2} = struct(); % no parameters needed for that function
[fData_new,outParams] = CFF_group_processing(fData_new,...
    procFun,procParams,...
    'procMsg',procMsg,...
    'saveFDataToDrive',1,...
    'pipeParams',1,...
    'continueOnError',1,...
    'comms','multilines');
navProcParams = outParams{1};

% and save navigation processing parameters to disp_config
if isempty(disp_config.MET_datagramSource)
    disp_config.MET_datagramSource = navProcParams.datagramSource;
end
if isempty(disp_config.MET_ellips)
    disp_config.MET_ellips = navProcParams.ellips;
end
if isempty(disp_config.MET_tmproj)
    disp_config.MET_tmproj = navProcParams.tmproj;
end

% add new fData to old one
fData = [fData,fData_new];

% add fData to appdata
setappdata(main_figure,'fData',fData);

% update file tab for colors
update_datafiles_tab(main_figure);

% update tab of lines loaded
update_loadedlines_tab(main_figure);
if isempty(fData)
    return;
end

% update dispconfig to focus on the last line loaded
disp_config.Fdata_ID = fData{end}.ID;

update_display_tab(main_figure);
% update map adjusting the zoom on all lines loaded
update_map_tab(main_figure,0,0,1,[]);

% update WC view and stacked view
update_wc_tab(main_figure);
update_stacked_wc_tab(main_figure);

end


%% Callback when pressing the "Convert, Load & Process" button
function callback_press_convertloadprocess_button(src,evt,main_figure)

% Write a pop-up window asking to confirm
% to do
dlg_title = 'Have you set the processing parameters?';
dlg_text = 'The selected files will be converted, loaded, then processed using the parameters as currently set in the "Data Processing" tab. Proceed?';
answer = question_dialog_fig(main_figure,dlg_title,dlg_text);

switch answer
    case 'Yes'
        % run conversion
        callback_press_convert_button(src,evt,main_figure,0);
        
        % load
        callback_press_load_button(src,evt,main_figure);
        
        % process
        % note this callback is not part of this tab but we can call it
        % here anyway
        callback_press_process_button(src,evt,main_figure);
end

end




