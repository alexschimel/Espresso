function Espresso(varargin)


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

%% Do not relaunch window if already open (in Matlab)...
if ~isdeployed()
    wc_win = findobj(groot,'tag','Espresso');
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
                     'Name','Espresso',...
                     'Tag','Espresso',...
                     'NumberTitle','off',...   
                     'Resize','on',...
                     'MenuBar','none',...
                     'Toolbar','none',...
                     'visible','off',...
                     'WindowStyle','normal',...
                     'CloseRequestFcn',@closefcn_clean_espresso);
                 
%% Install mouse pointer manager in figure
iptPointerManager(main_figure);

%% Get Javaframe from Figure to set the Icon
if ispc
    javaFrame = get(main_figure,'JavaFrame');
    javaFrame.fHG2Client.setClientDockable(true);
    set(javaFrame,'GroupName','Espresso');
    javaFrame.setFigureIcon(javax.swing.ImageIcon(fullfile(whereisroot(),'icons','Espresso.png')));
end

%% Default font size for Controls and Panels
set(0,'DefaultUicontrolFontSize',10);
set(0,'DefaultUipanelFontSize',12);

%% Software main path
main_path = whereisroot();
if ~isdeployed
    update_path(main_path);
end

disp_config=display_config_cl();
setappdata(main_figure,'disp_config',disp_config);
setappdata(main_figure,'fData',{});
setappdata(main_figure,'grids',{});
setappdata(main_figure,'ext_figs',[]);

%% Initialize the display and the interactions with the user
initialize_display(main_figure);
init_listeners(main_figure);
initialize_interactions_v2(main_figure);

%update_cursor_tool(main_figure)%TODO
%init_listeners(main_figure);%TODO



end


