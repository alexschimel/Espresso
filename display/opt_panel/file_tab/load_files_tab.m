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
            % get warnings for this initial load
            CFF_list_files_in_dir(new_path,'warning_on');
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

% HARD-CODED PARAMETER:
% the source datagram that will be used throughout the program for
% processing
% by default is 'WC' but 'AP' can be used for Amplitude-Phase datagrams
% instead. If there is no water-column datagram, you can still use Espresso
% to convert and load and display data, using the depths datagrams 'De' or
% 'X8'

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
    
    
    [folder_f,file_to_convert_name,f_ext]=fileparts(file_to_convert);
    
    if isempty(f_ext)
        if isfile([file_to_convert,'.wcd'])
            f_ext='.wcd';
        elseif isfile([file_to_convert,'.all'])
            f_ext='.all';
        elseif isfile([file_to_convert,'.s7k'])
            f_ext='.s7k';
        end
    end
    
    % if file already converted and not asking for reconversion, exit here
    if files_already_converted(nF) && ~reconvert
        fprintf('File "%s" (%i/%i) is already converted.\n',file_to_convert,nF,numel(files_to_convert));
        continue
    end
    
    % Otherwise, starting conversion...
    fprintf('Converting file "%s" (%i/%i)...\n',file_to_convert,nF,numel(files_to_convert));
    textprogressbar(sprintf('...Started at %s. Progress: ',datestr(now)));
    textprogressbar(0);
    tic
    
    % get folder for converted data
    folder_for_converted_data = CFF_converted_data_folder(file_to_convert);
    % converted filename fData
    mat_fdata_file = fullfile(folder_for_converted_data,'fdata.mat');
    
    % if output folder doesn't exist, create it
    MATfilepath = fileparts(mat_fdata_file);
    if ~exist(MATfilepath,'dir') && ~isempty(MATfilepath)
        mkdir(MATfilepath);
    end
    
    switch f_ext
        case {'.all' '.wcd'}
            datagramSource = 'WC'; % 'WC', 'AP', 'De', 'X8'
            
            switch datagramSource
                case 'WC'
                    wc_d = 107;
                case 'AP'
                    wc_d = 114;
                case 'De'
                    wc_d = 68;
                case 'X8'
                    wc_d = 88;
            end
            
            % We also need installation parameters (73), position (80), and runtime
            % parameters (82) datagrams. List datagrams required
            dg_wc = [73 80 82 wc_d];
            
            % conversion to ALLdata format
            [EMdata,datags_parsed_idx] = CFF_read_all(file_to_convert, dg_wc);
            textprogressbar(50);
            
            % if not all datagrams were found at this point, message and abort
            if ~all(datags_parsed_idx)
                if ismember(wc_d,dg_wc(~datags_parsed_idx))
                    textprogressbar(' error. File does not contain required water-column datagrams. Check file contents. Conversion aborted.');
                else
                    textprogressbar(' error. File does not contain all necessary datagrams. Check file contents. Conversion aborted.');
                end
                continue
            end
            
        case '.s7k'
            datagramSource = 'AP'; % 'WC', 'AP', 'De', 'X8'
            wc_d=7042;
            %dg={'R1015_Navigation' 'R1003_Position' 'R7042_CompressedWaterColumn' 'R7000_SonarSettings' 'R7001_7kConfiguration' 'R7004_7kBeamGeometry' 'R7027_RAWdetection'};
            dg_wc = [1015 1003 7042 7000 7001 7004 7027];
                     
            [RESONdata,datags_parsed_idx] = CFF_read_s7k(file_to_convert,dg_wc);
            % if not all datagrams were found at this point, message and abort
            if ~all(datags_parsed_idx)
                if ismember(wc_d,dg_wc(~datags_parsed_idx))
                    textprogressbar(' error. File does not contain required water-column datagrams. Check file contents. Conversion aborted.');
                    continue;
                elseif nansum(datags_parsed_idx(1:2))==0
                    textprogressbar(' error. File does not contain all necessary datagrams. Check file contents. Conversion aborted.');
                    continue;
                end          
            end       
        otherwise
            continue;
    end
    
    % subsampling factors:
    dr_sub = 1; % none for now
    db_sub = 1; % none for now
    
    % conversion and saving on the disk
    if ~exist(mat_fdata_file,'file') || reconvert
        
        switch f_ext
            case {'.all' '.wcd'}
                % if output file does not exist OR if forcing reconversion, simply convert
                fData = CFF_convert_ALLdata_to_fData(EMdata,dr_sub,db_sub);
                textprogressbar(90);
                
                % add datagram source
                fData.MET_datagramSource = datagramSource;
                
                % and save
                save(mat_fdata_file,'-struct','fData','-v7.3');
                clear fData;
                
            case '.s7k'
                % if output file does not exist OR if forcing reconversion, simply convert
                fData = CFF_convert_S7Kdata_to_fData(RESONdata,dr_sub,db_sub);
                textprogressbar(90);
                
                % add datagram source
                fData.MET_datagramSource = datagramSource;
                
                % and save
                save(mat_fdata_file,'-struct','fData','-v7.3');
                clear fData;
        end
        
    else
        
        % If output file already exists (and not forcing reconversion), see
        % if existing file cannot be fully or partly reused to save time
        %
        % NOTE: as coded now, this will never occur as we have an escape
        % clause in case the file already exists and asking to "convert"
        % instead of "reconvert"... TO DO XXX
        
        % load existing file
        fData = load(mat_fdata_file);
        textprogressbar(75);
        switch f_ext
            case {'.all' '.wcd'}
                % compare data to that already existing
                [fData,update_flag] = CFF_convert_ALLdata_to_fData(EMdata,dr_sub,db_sub,fData);
            case '.s7k'
                [fData,update_flag] = CFF_convert_S7Kdata_to_fData(RESONdata,dr_sub,db_sub,fData);
        end
        textprogressbar(90);
        % if it's different, update the result
        if update_flag > 0
            save(mat_fdata_file,'-struct','fData','-v7.3');
            clear fData;
        end
        
    end
    
    % End of conversion
    textprogressbar(100);
    textprogressbar(sprintf(' done. Elapsed time: %f seconds.',toc));
    
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
    
    %% first checks then loading data
    
    % check if file was converted
    if files_not_converted(nF)
        fprintf('File "%s" (%i/%i) has not been converted yet. Loading aborted.\n',file_to_load,nF,numel(files_to_load));
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
    
    % Loading can begin
    fprintf('Loading converted file "%s" (%i/%i)...\n',file_to_load,nF,numel(files_to_load));
    fprintf('...Started at %s...\n',datestr(now));
    tic
    
    % loading temp
    fData_temp = load(mat_fdata_file);
    
    
    %% Check if paths in fData are accurate and change them if necessary
    
    % flag to trigger re-save data
    dirchange_flag = 0;
    
    % checking paths to .all/.wcd
    for nR = 1:length(fData_temp.ALLfilename)
        [filepath_in_fData,name,ext] = fileparts(fData_temp.ALLfilename{nR});
        filepath_actual = fileparts(file_to_load);
        if ~strcmp(filepath_in_fData,filepath_actual)
            fData_temp.ALLfilename{nR} = fullfile(filepath_actual,[name ext]);
            dirchange_flag = 1;
        end
    end
    
    % checking path to water-column data binary file
    if isfield(fData_temp,'WC_SBP_SampleAmplitudes')
        [filepath_in_fData,name,ext] = fileparts(fData_temp.WC_SBP_SampleAmplitudes.Filename);
        if ~strcmp(filepath_in_fData,folder_for_converted_data)
            fData_temp.WC_SBP_SampleAmplitudes.Filename = fullfile(folder_for_converted_data,[name ext]);
            dirchange_flag = 1;
        end
    end
    
    if isfield(fData_temp,'AP_SBP_SampleAmplitudes')
        [filepath_in_fData,name,ext] = fileparts(fData_temp.AP_SBP_SampleAmplitudes.Filename);
        if ~strcmp(filepath_in_fData,folder_for_converted_data)
            fData_temp.AP_SBP_SampleAmplitudes.Filename = fullfile(folder_for_converted_data,[name ext]);
            dirchange_flag = 1;
        end
    end
    
    if isfield(fData_temp,'AP_SBP_SamplePhase')
        [filepath_in_fData,name,ext] = fileparts(fData_temp.AP_SBP_SamplePhase.Filename);
        if ~strcmp(filepath_in_fData,folder_for_converted_data)
            fData_temp.AP_SBP_SamplePhase.Filename = fullfile(folder_for_converted_data,[name ext]);
            dirchange_flag = 1;
        end
    end
    
    % checking path to processed water-column data binary file
    if isfield(fData_temp,'X_SBP_WaterColumnProcessed')
        [filepath_in_fData,name,ext] = fileparts(fData_temp.X_SBP_WaterColumnProcessed.Filename);
        if ~strcmp(filepath_in_fData,folder_for_converted_data)
            fData_temp.X_SBP_WaterColumnProcessed.Filename = fullfile(folder_for_converted_data,[name ext]);
            dirchange_flag = 1;
        end
    end
    
    % saving on disk if changes have been made
    if dirchange_flag
        fprintf('...This file has been moved from the directory where it was originally converted/processed. Paths were fixed. Now saving the data back onto disk...\n');
        try
            save(mat_fdata_file,'-struct','fData_temp','-v7.3');
        catch
            warning('Saving file not possible, but fixed data are loaded in Espresso and session can continue.');
        end
    end
    
    
    %% Interpolating navigation data from ancillary sensors to ping time
    
    if strcmp(disp_config.MET_tmproj,'')
        % Project has no projection yet, let's use the one for that file.
        
        % First, test if file has already been projected...
        if isfield(fData_temp,'MET_tmproj')
            % File has already been projected, no need to do it again. Use
            % that info for project
            
            fprintf('...This file''s navigation data has already been processed.\n');
            
            % save the info in disp_config
            disp_config.MET_datagramSource = fData_temp.MET_datagramSource;
            disp_config.MET_ellips         = fData_temp.MET_ellips;
            disp_config.MET_tmproj         = fData_temp.MET_tmproj;
            
        else
            % first time processing this file, use the default ellipsoid
            % and projection that are relevant to the data
            
            % Interpolating navigation data from ancillary sensors to ping
            % time
            fprintf('...Interpolating navigation data from ancillary sensors to ping time...\n');
            fData_temp = CFF_compute_ping_navigation(fData_temp);
            
            % save the info in disp_config
            disp_config.MET_datagramSource = fData_temp.MET_datagramSource;
            disp_config.MET_ellips         = fData_temp.MET_ellips;
            disp_config.MET_tmproj         = fData_temp.MET_tmproj;
            
        end
        
        fprintf('...Projection for this session defined from navigation data in this first loaded file (ellipsoid: %s, UTM zone: %s).\n', disp_config.MET_ellips, disp_config.MET_tmproj);
        
    else
        % Project already has a projection so use this one. Note that this
        % means we may force the use of a UTM projection for navigation
        % data that is outside that zone. It should still work.
        
        if isfield(fData_temp,'MET_tmproj')
            % if this file already has a projection
            
            if strcmp(fData_temp.MET_tmproj,disp_config.MET_tmproj)
                % file has already been projected at the same projection as
                % project, no need to do it again.
                
                fprintf('...This file''s navigation data has already been processed.\n');
                
            else
                % file has already been projected but at a different
                % projection than project. We're going to reprocess the
                % navigation, but any gridding needs to be removed first.
                % Throw a warning if we do that.
                if isfield(fData_temp,'X_NEH_gridLevel')
                    fData_temp = rmfield(fData_temp,{'X_1_gridHorizontalResolution','X_1E_gridEasting','X_N1_gridNorthing','X_NEH_gridDensity','X_NEH_gridLevel'});
                    warning('This file contains gridded data in a projection that is different than that of the project. These gridded data were removed.')
                end
                
                % Interpolating navigation data from ancillary sensors to
                % ping time
                fprintf('...Interpolating navigation data from ancillary sensors to ping time...\n');
                fData_temp = CFF_compute_ping_navigation(fData_temp, ...
                    disp_config.MET_datagramSource, ...
                    disp_config.MET_ellips, ...
                    disp_config.MET_tmproj);
                
            end
            
        else
            % File has not been projected yet, just do it now using
            % project's info
            
            % Interpolating navigation data from ancillary sensors to ping
            % time
            fprintf('...Interpolating navigation data from ancillary sensors to ping time...\n');
            fData_temp = CFF_compute_ping_navigation(fData_temp, ...
                disp_config.MET_datagramSource, ...
                disp_config.MET_ellips, ...
                disp_config.MET_tmproj);
            
        end
        
    end
    
    %% Processing bottom detect
    if ismember(fData_temp.MET_datagramSource,{'WC' 'AP'})
        fprintf('...Processing bottom detect...\n');
        fData_temp = CFF_georeference_WC_bottom_detect(fData_temp);
    end
    
    %% Finish-up
    
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

% update file tab for colors
update_file_tab(main_figure);

% update tab of lines loaded
update_fdata_tab(main_figure);
if isempty(fData)
    return;
end

% update dispconfig to focus on the last line loaded
disp_config.Fdata_ID = fData{end}.ID;

% update map adjusting the zoom on all lines loaded
update_map_tab(main_figure,0,0,1,[]);

% update WC view and stacked view
update_wc_tab(main_figure);
update_stacked_wc_tab(main_figure);



% not sure the following is needed...
% enabled_obj = findobj(main_figure,'Enable','off');
% set(enabled_obj,'Enable','on');

% general timer
timer_end = now;
fprintf('Total time for loading: %f seconds (~%.2f minutes).\n',(timer_end-timer_start)*24*60*60,(timer_end-timer_start)*24*60);

end




