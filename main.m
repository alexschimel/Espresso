function main(varargin)


%% Debug
global DEBUG;
DEBUG=0;


%% Set java window style and remove Javaframe warning
if ispc
    javax.swing.UIManager.setLookAndFeel('com.sun.java.swing.plaf.windows.WindowsLookAndFeel');
end
warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');


%% Checking and parsing input variables
p = inputParser;
addOptional(p,'Filenames',{},@(x) ischar(x)|iscell(x));
parse(p,varargin{:});

%% Do not Relaunch ESP3 if already open (in Matlab)...
if ~isdeployed()
    wc_win = findobj(groot,'tag','WcProject');
    if~isempty(wc_win)
        figure(wc_win);
        return;
    end
end


%% Get monitor's dimensions
size_max = get(0, 'MonitorPositions');

%% Defining the app's main window
main_figure = figure('Units','pixels',...
                     'Position',[size_max(1,1) size_max(1,2)+1/8*size_max(1,4) size_max(1,3)/4*3 size_max(1,4)/4*3],... %Position and size normalized to the screen size ([left, bottom, width, height])
                     'Color','White',...
                     'Name','WC Project',...
                     'Tag','WcProject',...
                     'NumberTitle','off',...   
                     'Resize','on',...
                     'MenuBar','none',...
                     'Toolbar','none',...
                     'visible','off',...
                     'WindowStyle','normal',...
                     'CloseRequestFcn',@closefcn_clean);
                 
%% Install mouse pointer manager in figure
iptPointerManager(main_figure);

%% Get Javaframe from Figure to set the Icon
if ispc
    javaFrame = get(main_figure,'JavaFrame');
    javaFrame.fHG2Client.setClientDockable(true);
    set(javaFrame,'GroupName','WcProject');
    javaFrame.setFigureIcon(javax.swing.ImageIcon(fullfile(whereisEcho(),'icons','wcproject.png')));
end


%% Default font size for Controls and Panels
set(0,'DefaultUicontrolFontSize',10);
set(0,'DefaultUipanelFontSize',12);

%% Software main path
main_path = whereisEcho();
if ~isdeployed
    update_path(main_path);
end
update_java_path(main_path);

%% Check if GPU computation is available %%
gpu_comp=get_gpu_comp_stat();
if gpu_comp
    disp('GPU computation Availaible');
else
    disp('GPU computation Unavailaible');
end

%% Read ESP3 config file
[app_path,curr_disp_obj,~,~] = load_config_from_xml_v2(1,1,1);

%% Create temporary data folder
try
    if ~isdir(app_path.data_temp)
        mkdir(app_path.data_temp);
        disp('Data Temp Folder Created')
        disp(app_path.data_temp)
    end
    
catch 
    disp('Error: Unable to create temporary data Folder: ')
    disp('creating new config_path.xml file with standard path and options')
    [~,path_config_file,~]=get_config_files();
    delete(path_config_file);
    [app_path,~,~,~] = load_config_from_xml_v2(1,0,0);
end

%% Managing existing files in temporary data folder
files_in_temp=dir(fullfile(app_path.data_temp,'*.bin'));

% idx_old=[];
% for uu=1:numel(files_in_temp)
%     if (now-files_in_temp(uu).datenum)>1
%         idx_old = union(idx_old,uu);
%     end
% end

idx_old=1:numel(files_in_temp);%check all temp files...

if ~isempty(idx_old)
    
    % by default, don't delete
    delete_files=0;
    
    choice = questdlg('There are files your ESP3 temp folder, do you want to delete them?','Delete files?','Yes','No','No');
    
    switch choice
        case 'Yes'
            delete_files = 1;
        case 'No'
            delete_files = 0;
    end
    
    if isempty(choice)
        delete_files = 0;
    end
    
    if delete_files == 1
        for i = 1:numel(idx_old)
            if exist(fullfile(app_path.data_temp,files_in_temp(idx_old(i)).name),'file') == 2
                delete(fullfile(app_path.data_temp,files_in_temp(idx_old(i)).name));
            end
        end
    end
    
end

%% Initialize empty layer, process and layers objects
layer_obj=layer_cl.empty();
process_obj=process_cl.empty();
layers=layer_obj;

%% Store objects in app main figure
setappdata(main_figure,'Layers',layers);
setappdata(main_figure,'Layer',layer_obj);
setappdata(main_figure,'Curr_disp',curr_disp_obj);
setappdata(main_figure,'App_path',app_path);
setappdata(main_figure,'Process',process_obj);
setappdata(main_figure,'ExternalFigures',matlab.ui.Figure.empty());


%% Initialize the display and the interactions with the user
initialize_display(main_figure);
initialize_interactions_v2(main_figure);
init_java_fcn(main_figure);
update_cursor_tool(main_figure)
init_listeners(main_figure);

%% If files were loaded in input, load them now
if ~isempty(p.Results.Filenames)
    open_file([],[],p.Results.Filenames,main_figure);
    % If request was made to print display: print and close ESP3
    if p.Results.SaveEcho>0
        save_echo(main_figure,[],[]);
        cleanup_echo(main_figure);
        delete(main_figure);
    end
end

end


