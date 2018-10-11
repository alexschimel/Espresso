%% load_files_tab.m
%
% Creates "Data files" tab (#1) in Espresso's Control Panel. Also has
% callback functions for when interacting with the tab's contents.
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
% * 2018-10-05: general editing and commenting (Alex Schimel)
% * 2017-10-25: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, Alexandre Schimel NIWA. Type |help Espresso.m| for
% copyright information. 

%% Function
function load_files_tab(main_figure,parent_tab_group)

%% create tab variable
switch parent_tab_group.Type
    case 'uitabgroup'
        file_tab_comp.file_tab = uitab(parent_tab_group,'Title','Data files','Tag','file_tab','BackGroundColor','w');
    case 'figure'
        file_tab_comp.file_tab = parent_tab_group;
end


%% folder push button

% get icon
icon = get_icons_cdata(fullfile(whereisroot(),'icons'));

% create button
file_tab_comp.path_choose = uicontrol(file_tab_comp.file_tab,'Style','pushbutton',...
    'units','normalized',...
    'pos',[0.0 0.91 0.1 0.08],...
    'String','',...
    'Cdata',icon.folder,...
    'callback',{@select_folder_callback,main_figure});


%% folder text field

% define initial path from last data available (or root)
fData = getappdata(main_figure,'fData');
if isempty(fData)
    path_init = whereisroot();
else
    [path_init,~,~] = fileparts(fData{end}.ALLfilename{1});
    i = strfind(path_init,filesep);
    path_init = path_init(1:i(end-1));
end

% create text field
file_tab_comp.path_box = uicontrol(file_tab_comp.file_tab,'Style','edit',...
    'Units','normalized',...
    'Position',[0.1 0.91 0.9 0.08],...
    'BackgroundColor','w',...
    'string',path_init,...
    'HorizontalAlignment','left',...
    'Callback',{@select_folder_callback,main_figure});



%% files list

% Column names and format
columnname = {'File' 'Folder'};
columnformat = {'char','char'};

% Create the files list (uitable)
file_tab_comp.table_main = uitable('Parent',file_tab_comp.file_tab,...
    'Data', {},...
    'ColumnName', columnname,...
    'ColumnFormat', columnformat,...
    'CellSelectionCallback',{@cell_select_cback,main_figure},...
    'ColumnEditable', [false false],...
    'Units','Normalized','Position',[0 0.1 1 0.8],...
    'RowName',[]);

% Set widths of columns in table and add callback for automatic resizing
pos_t = getpixelposition(file_tab_comp.table_main);
set(file_tab_comp.table_main,'ColumnWidth',num2cell(pos_t(3)*[10/20 10/20]));
set(file_tab_comp.file_tab,'SizeChangedFcn',{@resize_table,file_tab_comp.table_main});


%% "convert", "reconvert" and "load" push buttons

uicontrol(file_tab_comp.file_tab,'Style','pushbutton','String','Convert',...
    'units','normalized',...
    'pos',[0.35 0.01 0.2 0.08],...
    'callback',{@convert_files_callback,main_figure,0});

uicontrol(file_tab_comp.file_tab,'Style','pushbutton','String','Re-Convert',...
    'units','normalized',...
    'pos',[0.55 0.01 0.2 0.08],...
    'callback',{@convert_files_callback,main_figure,1});

uicontrol(file_tab_comp.file_tab,'Style','pushbutton','String','Load',...
    'units','normalized',...
    'pos',[0.75 0.01 0.15 0.08],...
    'callback',{@load_files_callback,main_figure});

%% finalize

% empties
file_tab_comp.selected_idx = [];
file_tab_comp.files = {};
file_tab_comp.converted = [];

% add tab to appdata
setappdata(main_figure,'file_tab',file_tab_comp);

% run the update function
update_file_tab(main_figure);

end



%% CALLBACKS


%%
% Callback when pressing the "Folder" button or interacting with folder
% text field
%
function select_folder_callback(src,~,main_figure)

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
                update_file_tab(main_figure);
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
        
        if new_path ~= 0
            % update the tab
            set(file_tab_comp.path_box,'string',new_path);
            update_file_tab(main_figure);
        end
        
end

end



%%
% Callback when selecting a cell in files list
%
function cell_select_cback(~,evt,main_figure)

% get tab data
file_tab_comp = getappdata(main_figure,'file_tab');

if ~isempty(evt.Indices)
    selected_idx = (evt.Indices(:,1));
else
    selected_idx = [];
end

% update the selected file(s)
file_tab_comp.selected_idx = unique(selected_idx);
setappdata(main_figure,'file_tab',file_tab_comp);

end



%%
% Callback when pressing the "Convert" button
%
function convert_files_callback(~,~,main_figure,reconvert)

% PARAMS:
% list of datagram needed for conversion
wc_d = 107; % for traditional water column datagram
% wc_d = 114; % for amplitude and phase datagram
dg_wc = [73 80 82 wc_d];

% get tab data
file_tab_comp = getappdata(main_figure,'file_tab');

% get list of files requested for conversion
files = file_tab_comp.files;
selected_idx = file_tab_comp.selected_idx;
files_to_convert = files(selected_idx);

% get list of files already converted
files_converted = file_tab_comp.converted;
files_already_converted = files_converted(selected_idx);

% general timer
timer_start = now;

% for each file
for nF = 1:numel(files_to_convert)
    
    % get file to convert
    file_to_convert = files_to_convert{nF};

    % if file already converted and not asking for reconversion, exit here
    if files_already_converted(nF) && ~reconvert
        fprintf('File "%s" (%i/%i) is already converted.\n',file_to_convert,nF,numel(files_to_convert));
        continue
    end
    
    % Otherwise, starting conversion...
    fprintf('Converting file "%s" (%i/%i). Started at %s... \n',file_to_convert,nF,numel(files_to_convert),datestr(now));
    tic
    
    % original files to convert
    all_file_to_convert = strcat(file_to_convert,'.all');
    wcd_file_to_convert = strcat(file_to_convert,'.wcd');
    
    % get folder for converted data
    folder_for_converted_data = CFF_converted_data_folder(file_to_convert);
    
    % converted filename fData
    mat_fdata_file = fullfile(folder_for_converted_data,'fdata.mat');
    
    % initialize which datagrams were read
    datags_parsed_idx = zeros(size(dg_wc));
    
    % check datagrams available in WCD file (if it exists)
    if exist(wcd_file_to_convert,'file')>0
        
        % get WCD file info and find list of datagrams available
        WCDfile_info = CFF_all_file_info(wcd_file_to_convert);
        WCDfile_datag_types = unique(WCDfile_info.datagTypeNumber);
        
        % find which datagrams can be read here
        datags_parsed_idx = ismember(dg_wc,WCDfile_datag_types);
        
        % if any, read those datagrams
        if any(datags_parsed_idx)
            datags_to_read_idx = ismember(WCDfile_info.datagTypeNumber,dg_wc(datags_parsed_idx));
            WCDfile_info.parsed(datags_to_read_idx) = 1;
            WCDdata = CFF_read_all_from_fileinfo(wcd_file_to_convert, WCDfile_info);
        end
        
    end
    
    if ~all(datags_parsed_idx) 
        % if not all datagrams needed were in the WCD file...
        
        % ...check the all file (if it exists)
        if exist(all_file_to_convert,'file')>0

            % get ALL file info and find list of datagrams available
            ALLfile_info = CFF_all_file_info(all_file_to_convert);
            ALLfile_datag_types = unique(ALLfile_info.datagTypeNumber);
            
            % find which remaining datagram types can be read here
            yesthose_idx = ismember(dg_wc,ALLfile_datag_types) & ~datags_parsed_idx;
            
            % if any, read those datagrams
            if any(yesthose_idx)
                
                ALLfile_info.parsed(ismember(ALLfile_info.datagTypeNumber,dg_wc(yesthose_idx))) = 1;
                ALLdata = CFF_read_all_from_fileinfo(all_file_to_convert, ALLfile_info);
                
                datags_parsed_idx = datags_parsed_idx | yesthose_idx;
                
            end
            
        end
    end
    
    % combining existing data
    if exist('WCDdata','var') && exist('ALLdata','var')
        EMdata = {WCDdata ALLdata};
    elseif exist('WCDdata','var') && ~exist('ALLdata','var')
        EMdata = {WCDdata};
    elseif ~exist('WCDdata','var') && exist('ALLdata','var')
        EMdata = {ALLdata};
    else
        EMdata = {};
    end
    
    % if not all datagrams were found at this point, message and abort
    if ~all(datags_parsed_idx)
        if ismember(wc_d,dg_wc(~datags_parsed_idx))
            fprintf('...File does not contain required water-column datagrams. Check file contents. Conversion aborted.\n');
        else
            fprintf('...File does not contain all necessary datagrams. Check file contents. Conversion aborted.\n');
        end
        continue
    end
    
    % if output folder doesn't exist, create it
    MATfilepath = fileparts(mat_fdata_file);
    if ~exist(MATfilepath,'dir') && ~isempty(MATfilepath)
        mkdir(MATfilepath);
    end
    
    % subsampling factors:
    dr_sub = 1; % none for now
    db_sub =1; % none for now
    
    % converstion and saving on the disk
    if ~exist(mat_fdata_file,'file') || reconvert
        
        % if output file does not exist OR if forcing reconversion, simply
        % convert and save
        fData = CFF_convert_ALLdata_to_fData(EMdata,dr_sub,db_sub);
        save(mat_fdata_file,'-struct','fData','-v7.3');
        clear fData;
        
    else
        
        % If output file already exists (and not forcing reconversion), see
        % if existing file cannot be fully or partly reused to save time
        %
        % NOTE: as coded now, this will never occur as we have an escape
        % clause in case the file already exists and asking to "convert"
        % instead of "reconvert"
        
        % load existing file
        fData = load(mat_fdata_file);
        
        % compare data to that already existing
        [fData,update_flag] = CFF_convert_ALLdata_to_fData(EMdata,dr_sub,db_sub,fData);
        
        % if it's different, update the result
        if update_flag > 0
            save(mat_fdata_file,'-struct','fData','-v7.3');
            clear fData;
        end
        
    end
    
    % End of conversion
    fprintf('...Done. Elapsed time: %f seconds.\n',toc);
    
end

% update display
update_file_tab(main_figure);

% general timer
timer_end = now;
fprintf('Total time for conversion: %f seconds (~%.2f minutes).\n',(timer_end-timer_start)*24*60*60,(timer_end-timer_start)*24*60);

end




%%
% Callback when pressing the "Load" button
%
function load_files_callback(~,~,main_figure)

% get tab data
file_tab_comp = getappdata(main_figure,'file_tab');

% get existing fData and disp_config
fData = getappdata(main_figure,'fData');
disp_config = getappdata(main_figure,'disp_config');

% get list of files requested for loading
files = file_tab_comp.files;
selected_idx = file_tab_comp.selected_idx;
files_to_load = files(selected_idx);

% get list of files not converted
list_of_files_not_converted = ~file_tab_comp.converted;
files_not_converted = list_of_files_not_converted(selected_idx);

% get list of files already loaded
loaded_files = get_loaded_files(main_figure);
files_already_loaded = ismember(files_to_load,loaded_files);

% general timer
timer_start = now;

% for each file
for nF = 1:numel(files_to_load)

    file_to_load = files_to_load{nF};
    
    % check if file was converted
    if files_not_converted(nF)
        fprintf('File "%s" (%i/%i) has not been converted yet. Loading aborted.\n',nF,numel(files_to_load),file_to_load);
        continue
    end
        
    % check if file not already loaded
    if files_already_loaded(nF)
        fprintf('File "%s" (%i/%i) is already loaded.\n',file_to_load,nF,numel(files_to_load));
        continue
    end
        
    % converted filename fData
    folder_for_converted_data = CFF_converted_data_folder(file_to_load);
    mat_fdata_file = fullfile(folder_for_converted_data,'fdata.mat');
    
    % check if converted file exists
    if ~isfile(mat_fdata_file)
        fprintf('File "%s" (%i/%i) is marked as converted and loadable but converted file cannot be found. Try re-convert. Loading aborted.\n',file_to_load,nF,numel(files_to_load));
        continue
    end
    
    % all tests passed. Loading can begin
    fprintf('Loading converted file "%s" (%i/%i). Started at %s... \n',file_to_load,nF,numel(files_to_load),datestr(now));
    tic
    
    % loading temp
    fData_temp = load(mat_fdata_file);
    
    % getting source of water-column data and prefix right
    if isfield(fData_temp,'WC_SBP_SampleAmplitudes')
        datagramSource = 'WC';
    elseif isfield(fData_temp,'AP_SBP_SampleAmplitudes')
        datagramSource = 'AP';
    end
    
    % Interpolating navigation data from ancillary sensors to ping time
    fprintf('...Interpolating navigation data from ancillary sensors to ping time...\n');
    fData_temp = CFF_compute_ping_navigation(fData_temp,datagramSource);
    
    % checking UTM zone for projection
    if strcmp(disp_config.MET_tmproj,'')
        % first file, use its projection
        disp_config.MET_tmproj = fData_temp.MET_tmproj;
    elseif ~strcmp(disp_config.MET_tmproj,fData_temp.MET_tmproj)
        % different projection. Abandon loading
        fprintf('... File is using different UTM zone for projection than project. Loading aborted.\n');
        clean_fdata(fData_temp);
        continue;
    end
    
    % Processing bottom detect
    fprintf('...Processing bottom detect...\n');
    fData_temp = CFF_georeference_WC_bottom_detect(fData_temp,datagramSource);
    
    % Time-tag that fData
    fData_temp.ID = str2double(datestr(now,'yyyymmddHHMMSSFFF'));
    
%     % If data have already been processed, load the binary file into fData
%     % NOTE: if data have already been processed, the fData and the binary
%     % files should already exist and should already been attached, without
%     % need to re-memmap them... So verify if there is actual need for this
%     % part... XXX
%     wc_dir = CFF_converted_data_folder(fData_temp.ALLfilename{1});
%     WaterColumnProcessed_file = fullfile(wc_dir,'X_SBP_WaterColumnProcessed.dat');
%     if isfile(WaterColumnProcessed_file)
%         [nSamples,nBeams,nPings] = size(fData_temp.([datagramSource '_SBP_SampleAmplitudes']).Data.val);
%         fData_temp.X_SBP_WaterColumnProcessed = memmapfile(WaterColumnProcessed_file, 'Format',{'int8' [nSamples nBeams nPings] 'val'},'repeat',1,'writable',true);
%     end
    
    % why pause here? XXX
    pause(1e-3);
    
    % add this file's data to the full fData
    fData{numel(fData)+1} = fData_temp;
    
    % disp
    fprintf('...Done. Elapsed time: %f seconds.\n',toc);
    
end

% add fData to appdata
setappdata(main_figure,'fData',fData);

% update display
update_file_tab(main_figure);
update_display(main_figure);

% general timer
timer_end = now;
fprintf('Total time for loading: %f seconds (~%.2f minutes).\n',(timer_end-timer_start)*24*60*60,(timer_end-timer_start)*24*60);

end




