%% load_files_tab.m
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
function load_files_tab(main_figure,parent_tab_group)

switch parent_tab_group.Type
    case 'uitabgroup'
        file_tab_comp.file_tab=uitab(parent_tab_group,'Title','Loading','Tag','file_tab','BackGroundColor','w');
    case 'figure'
        file_tab_comp.file_tab=parent_tab_group;
end

fData=getappdata(main_figure,'fData');
if isempty(fData)
    path_init=whereisroot();
else
    [path_init,~,~]=fileparts(fData{end}.MET_MATfilename{1});
    i=strfind(path_init,filesep);
    path_init=path_init(1:i(end-1));
end


icon = get_icons_cdata(fullfile(whereisroot(),'icons'));


file_tab_comp.path_box = uicontrol(file_tab_comp.file_tab,'Style','edit',...
    'Units','normalized',...
    'Position',[0.0 0.91 0.9 0.08],...
    'BackgroundColor','w',...
    'string',path_init,...
    'HorizontalAlignment','left','Callback',{@select_folder_callback,main_figure});

file_tab_comp.path_choose = uicontrol(file_tab_comp.file_tab,'Style','pushbutton','units','normalized',...
    'pos',[0.9 0.91 0.1 0.08],...
    'String','',...
    'Cdata',icon.folder,...
    'callback',{@select_folder_callback,main_figure});

survDataSummary = {};

% Column names and column format
columnname = {'File' 'Folder'};
columnformat = {'char','char'};

% Create the uitable
file_tab_comp.table_main = uitable('Parent',file_tab_comp.file_tab,...
    'Data', survDataSummary,...
    'ColumnName', columnname,...
    'ColumnFormat', columnformat,...
    'CellSelectionCallback',{@cell_select_cback,main_figure},...
    'ColumnEditable', [false false],...
    'Units','Normalized','Position',[0 0.1 1 0.8],...
    'RowName',[]);

pos_t = getpixelposition(file_tab_comp.table_main);
set(file_tab_comp.table_main,'ColumnWidth',...
    num2cell(pos_t(3)*[10/20 10/20]));
set(file_tab_comp.file_tab,'SizeChangedFcn',{@resize_table,file_tab_comp.table_main});

%set(file_tab_comp.table_main,'CellEditCallback',{@edit_surv_data_db,surv_data_tab,main_figure});

uicontrol(file_tab_comp.file_tab,'Style','pushbutton','units','normalized',...
    'pos',[0.35 0.01 0.2 0.08],...
    'String','Convert',...
    'callback',{@convert_files_callback,main_figure,0});
uicontrol(file_tab_comp.file_tab,'Style','pushbutton','units','normalized',...
    'pos',[0.55 0.01 0.2 0.08],...
    'String','Re-Convert',...
    'callback',{@convert_files_callback,main_figure,1});
uicontrol(file_tab_comp.file_tab,'Style','pushbutton','units','normalized',...
    'pos',[0.75 0.01 0.15 0.08],...
    'String','Load',...
    'callback',{@load_files_callback,main_figure});

file_tab_comp.selected_idx=[];
file_tab_comp.files={};
file_tab_comp.processedd=[];

setappdata(main_figure,'file_tab',file_tab_comp);


update_file_tab(main_figure);

end


%% Subfunctions


function load_files_callback(src,~,main_figure)

file_tab_comp = getappdata(main_figure,'file_tab');

selected_idx=file_tab_comp.selected_idx;
processed=file_tab_comp.processed;
files=file_tab_comp.files;
files_to_load=files(selected_idx);
processed_selected=processed(selected_idx);

files_to_load=files_to_load(processed_selected);

if isempty(files_to_load)
    return;
end

[mat_all_files,mat_wcd_files]=matfilenames_from_all_filenames(files_to_load);


dr = 5; % samples subsampling factor
db = 2; % beam subsampling factor

fData=getappdata(main_figure,'fData');
files_loaded=cell(1,numel(fData));
for nF=1:numel(fData)
    files_loaded{nF}=fData{nF}.MET_MATfilename{1};
end
disp_config=getappdata(main_figure,'disp_config');


for nF = 1:numel(mat_all_files)
    
    %% Start Display
    fprintf('Loading file "%s" - started on: %s\n',files_to_load{nF}, datestr(now));
    
    if ismember(mat_all_files{nF},files_loaded)
        fprintf('%s already loaded\n',files_to_load{nF});
        continue;
    end
    %% convert mat to fabc format
    
    disp('CFF_convert_mat_to_fabc_v2...');
    fData_temp = CFF_convert_mat_to_fabc_v2({mat_all_files{nF};mat_wcd_files{nF}},dr,db);
    disp('CFF_process_ping_v2...');
    

        fData_temp = CFF_process_ping_v2(fData_temp,'WC');
        if strcmp(disp_config.MET_tmproj,'')
            disp_config.MET_tmproj=fData_temp.MET_tmproj;
        elseif ~strcmp(disp_config.MET_tmproj,fData_temp.MET_tmproj)
            disp('Data using another UTM zone for pojection. You cannot load them in the current project.');
             clean_fdata(fData_temp);
           return; 
        end
    
    fData_temp.ID=str2double(datestr(now,'yyyymmddHHMMSSFFF'));
    pause(1e-3);
    fData{numel(fData)+1}=fData_temp;
    
    
end
setappdata(main_figure,'fData',fData);
update_file_tab(main_figure);
update_display(main_figure);

end

function convert_files_callback(src,~,main_figure,re)
file_tab_comp = getappdata(main_figure,'file_tab');


selected_idx=file_tab_comp.selected_idx;
processed=file_tab_comp.processed;
files=file_tab_comp.files;

files_to_process=files(selected_idx);

processed_selected=processed(selected_idx);
if re==0
    files_to_process=files_to_process(~processed_selected);
end

if isempty(files_to_process)
    return;
end

[mat_all_files,mat_wcd_files]=matfilenames_from_all_filenames(files_to_process);
all_files_to_process=strcat(files_to_process,'.all');
wcd_files_to_process=strcat(files_to_process,'.wcd');

if numel(mat_all_files)==0
    disp('All selected files are already pre-processed.')
    return;
end
enabled_on=findobj(file_tab_comp.file_tab,'Enable','on','-and','Style','pushbutton');

set(enabled_on,'Enable','off');


for nF = 1:numel(mat_all_files)
    txt = sprintf('Converting file "%s" - started on: %s', all_files_to_process{nF}, datestr(now));
    disp(txt);
    CFF_convert_all_to_mat_v2(all_files_to_process{nF},mat_all_files{nF},'datagrams',[73 80 107]);
    
    txt = sprintf('Converting file "%s" - started on: %s', wcd_files_to_process{nF}, datestr(now));
    disp(txt);
    CFF_convert_all_to_mat_v2(wcd_files_to_process{nF},mat_wcd_files{nF},'datagrams',[107]);
end


update_file_tab(main_figure);
set(enabled_on,'Enable','on');
end


function select_folder_callback(src,~,main_figure)
file_tab_comp = getappdata(main_figure,'file_tab');

switch src.Style
    case 'edit'
        new_path=get(src,'string');
    case 'pushbutton'
        path_ori = get(file_tab_comp.path_box,'string');
        new_path = uigetdir(path_ori);
        if new_path~=0
            set(file_tab_comp.path_box,'string',new_path);
        end
        
end

if new_path~=0
    booldir = check_path(new_path);
else
    return;
end

if booldir
    update_file_tab(main_figure);
end

end


function cell_select_cback(~,evt,main_figure)
file_tab_comp = getappdata(main_figure,'file_tab');

if ~isempty(evt.Indices)
    selected_idx=(evt.Indices(:,1));
else
    selected_idx=[];
end
%selected_idx'
file_tab_comp.selected_idx=selected_idx;
setappdata(main_figure,'file_tab',file_tab_comp);

end

function booldir = check_path(new_path)

if ~isdir(new_path)
    booldir = 0;
else
    booldir = 1;
end

end