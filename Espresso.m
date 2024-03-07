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

% Setup log file
startTime = now;
logfile = generate_Espresso_diary_filename;
if ~isfolder(fileparts(logfile))
    mkdir(fileparts(logfile));
end
if isfile(logfile)
    delete(logfile);
end
diary(logfile);
EspressoUserdata.logfile = logfile; % save to app in order to close diary at the end

% Getting software info for start-up message
[espressoVer, coffeeVer] = espresso_version();
licenseFilename = 'LICENSE';
licenseLines = readlines(licenseFilename);
espressoLicense = licenseLines(find(contains(licenseLines,"license",'IgnoreCase',true),1));
espressoCopyright = licenseLines(find(contains(licenseLines,"copyright",'IgnoreCase',true),1));
if isdeployed
    licenseLocation = 'About section';
else
    licenseLocation = sprintf('%s file',licenseFilename);
end

% Start-up message
introText = {};
introText{1,1} = sprintf('ESPRESSO v%s (powered by CoFFee v%s)\n',espressoVer,coffeeVer);
introText{2,1} = sprintf('%s\n',espressoCopyright);
introText{3,1} = sprintf('Licensed under the %s. See %s for details.\n',espressoLicense,licenseLocation);
introText{4,1} = sprintf('If you use this software, please acknowledge all authors listed in copyright.\n');
introLimsText = {char([61.*ones(1,max(cellfun(@length,introText))-1),10])};
introText = [introLimsText;introText;introLimsText];
cellfun(@fprintf,introText);

% Session start messages
fprintf('New session start at %s. Please wait...\n',datestr(startTime));
fprintf('Espresso user folder: %s.\n',espressoUserFolder);
fprintf('Espresso config file: %s.\n',espressoConfigFile);
fprintf('Log file for this session: %s.\n',logfile);

% If on MATLAB, need to find and add CoFFee to the path
if ~isdeployed
    % check coffee folder
    coffeeFolder = get_config_field('coffeeFolder');
    if ~is_coffee_folder(coffeeFolder)
        % throw an alert to find manually a suitable coffee folder
        fprintf('USER INPUT NEEDED. Select suitable CoFFee folder.\n');
        coffeeFolder = uigetdir(appRootFolder,'Select suitable CoFFee folder');
        % second check
        if ~is_coffee_folder(coffeeFolder)
            error('Not a CoFFee folder.');
        end
    end
    fprintf('CoFFee folder: %s.\n',coffeeFolder);
    % check coffee version is the one we need
    fprintf('Checking CoFFee version... ');
    isVersionOK = is_coffee_version(coffeeFolder,coffeeVer);
    fprintf('CoFFee v%s found.\n',get_coffee_version(coffeeFolder));
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
    figureVisibilityAtStart = 'on';
else
    figureVisibilityAtStart = 'off';
end
main_figure = figure('Units','pixels',...
    'Color','White',...
    'Name','Espresso',...
    'Tag','Espresso',...
    'NumberTitle','off',...
    'Resize','on',...
    'MenuBar','none',...
    'Toolbar','none',...
    'visible',figureVisibilityAtStart,...
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


