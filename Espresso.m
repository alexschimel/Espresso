function Espresso(varargin)
%ESPRESSO  Start Espresso
%
%   ESPRESSO() starts an Espresso session or activates the main window if a
%   session is already running.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 21-07-2021

% Debug
global DEBUG;
DEBUG = 0;

% input parser
p = inputParser;
addOptional(p,'Filenames',{},@(x) ischar(x)|iscell(x));
parse(p,varargin{:});

% Set java window style and remove Javaframe warning
if ispc
    javax.swing.UIManager.setLookAndFeel('com.sun.java.swing.plaf.windows.WindowsLookAndFeel');
end
warning('off','MATLAB:ui:javacomponent:FunctionToBeRemoved');
warning('off','MATLAB:ui:javaframe:PropertyToBeRemoved');
warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
warning('off','MATLAB:polyshape:repairedBySimplify');
warning('off','MATLAB:polyshape:boundaryLessThan2Points');
warning('off','MATLAB:polyshape:boundary3Points');
warning('off','MATLAB:chckxy:IgnoreNaN');

% In Matlab, if a session is already running, activate the window and exit
if ~isdeployed()
    wc_win = findobj(groot,'tag','Espresso');
    if ~isempty(wc_win)
        fprintf('Espresso already running. Activating window...\n');
        figure(wc_win);
        fprintf('Done. Espresso is ready for use.\n\n')
        return;
    end
end

% Starting diary
if ~isfolder(Espresso_user_folder)
    mkdir(Espresso_user_folder);
end
logfile = generate_Espresso_diary_filename;
if isfile(logfile)
    delete(logfile);
end
diary(logfile);
EspressoUserdata.logfile = logfile;

% Starting messages
fprintf('Starting Espresso at %s... \n',datestr(now));
fprintf('Find a log of this output at %s.\n',logfile);

% Add relevant subfolders to Matlab path
main_path = whereisroot();
if ~isdeployed
    update_path(main_path);
end

% check for possibility of GPU computation
fprintf('Checking for GPU computation availability and compatibility...');
[gpu_comp,~] = get_gpu_comp_stat();
if gpu_comp > 0
    fprintf(' Available.\n');
else
    fprintf(' Unavailable.\n');
end

% monitor's dimensions
size_max = get(0, 'MonitorPositions');

% Espresso's window position and size
Espresso_window_position = [size_max(1,1), ... % bottom-left corner X
    size_max(1,2)+1/8*size_max(1,4), ... % bottom-left corner Y
    size_max(1,3)/4*3, ... % width
    size_max(1,4)/4*3]; % height

% create main_figure
fprintf('Creating main figure...\n');
if ~isdeployed()
    Espresso_start_visibility = 'on';
else
    Espresso_start_visibility = 'off';
end
main_figure = figure('Units','pixels',...
    'Position',Espresso_window_position,...
    'Color','White',...
    'Name','Espresso',...
    'Tag','Espresso',...
    'NumberTitle','off',...
    'Resize','on',...
    'MenuBar','none',...
    'Toolbar','none',...
    'visible',Espresso_start_visibility,...
    'WindowStyle','normal',...
    'UserData',EspressoUserdata,...
    'CloseRequestFcn',@closefcn_clean_espresso,...
    'ResizeFcn',@resize_espresso);

% Install mouse pointer manager in figure
iptPointerManager(main_figure);

% Add Espresso icon
set_icon_espresso(main_figure);

% Default font size for Controls and Panels
set(0,'DefaultUicontrolFontSize',10);
set(0,'DefaultUipanelFontSize',12);
set(0,'DefaultAxesLooseInset',[0,0,0,0]);

% initialize and attach to the main figure the disp_config object, which
% will hold all information about what is currently on screen
disp_config = display_config_cl();
setappdata(main_figure,'disp_config',disp_config);

% initialize and attach to the main figure all other future data
setappdata(main_figure,'fData',{});
setappdata(main_figure,'grids',[]);
setappdata(main_figure,'ext_figs',[]);
setappdata(main_figure,'features',[]);

% Create the contents of main figure
initialize_display(main_figure);

% Initialize disp_config listeners and button controls
fprintf('Initializing listeners and controls...\n');
init_listeners(main_figure);
initialize_interactions_v2(main_figure);

% Final message
fprintf('Done. Espresso is ready for use.\n\n')

end


