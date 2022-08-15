function Espresso(varargin)
%ESPRESSO  Start Espresso
%
%   ESPRESSO() starts an Espresso session or activates the main window if a
%   session is already running.

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann Ladroit
%   (NIWA, yoann.ladroit@niwa.co.nz) 
%   2017-2022; Last revision: 12-08-2022

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

% If on MATLAB, add relevant folders to path
if ~isdeployed
    appRootFolder = whereisroot();
    update_path(appRootFolder);
end

% Starting message
[espressoVer, coffeeVer] = espresso_version();
fprintf('Starting Espresso v%s (powered by CoFFee v%s) at %s. Please wait...\n',espressoVer,coffeeVer,datestr(now));

% Create Espresso user folder if needed
espressoUserFolder = espresso_user_folder();
if ~isfolder(espressoUserFolder)
    mkdir(espressoUserFolder);
end

% Init config file if needed
espressoConfigFile = espresso_config_file();
if ~isfile(espressoConfigFile)
    init_config_file();
end

% Setup diary
logfile = generate_Espresso_diary_filename;
if ~isfolder(fileparts(logfile))
    mkdir(fileparts(logfile));
end
if isfile(logfile)
    delete(logfile);
end
diary(logfile);
EspressoUserdata.logfile = logfile; % save to app in order to close diary at the end
fprintf('Find a log of this output at %s.\n',logfile);

% If on MATLAB, need to find and add CoFFee to the path
if ~isdeployed
    % check coffee folder
    coffeeFolder = get_config_field('coffeeFolder');
    if ~is_coffee_folder(coffeeFolder)
        % throw an alert to find manually a suitable coffee folder
        coffeeFolder = uigetdir(appRootFolder,'Select suitable CoFFee folder');
        % second check
        if ~is_coffee_folder(coffeeFolder)
            error('Not a CoFFee folder.');
        end
    end
    % check coffee version is the one we need
    isVersionOK = is_coffee_version(coffeeFolder,coffeeVer);
    if ~isVersionOK
        warning(['This version of Espresso (%s) was built with a version'...
            ' of CoFFee (%s) that is different from that (%s) of the toolbox'...
            ' you have specified (%s). Proceeding, but you may experience'...
            ' issues. If you intend to simply use Espresso, consider'...
            ' checking out the correct CoFFee version. If you intend to'...
            ' develop Espresso, you should fix the version discrepancy.'],...
            espressoVer,coffeeVer,get_coffee_version(coffeeFolder),coffeeFolder);
    end
    % add coffee to path
    addpath(genpath(coffeeFolder));
    % save that path in config file
    set_config_field('coffeeFolder',coffeeFolder);
end

% check for possibility of GPU computation
[~,info] = CFF_is_parallel_computing_available();
fprintf('%s\n',info);

% create main_figure
fprintf('Creating main figure...\n');
if ~isdeployed()
    Espresso_start_visibility = 'on';
else
    Espresso_start_visibility = 'off';
end
main_figure = figure('Units','pixels',...
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


