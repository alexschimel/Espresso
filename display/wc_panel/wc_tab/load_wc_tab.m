%% load_wc_tab.m
%
% Creates the "WC" tab in Espresso, aka WC swath view
%
%% Help
%
% *USE*
%
% _This section contains a more detailed description of what the function
% does and how to use it, for the interested user to have an overall
% understanding of its function. Example below to replace. Delete these
% lines XXX._
%
% This is a text file containing the basic comment template to add at the
% start of any new ESP3 function to serve as function help. XXX
%
% *INPUT VARIABLES*
%
% _This section contains bullet points of input variables with description
% and information. Put input variable and other valid entries or defaults
% between | symbols so it shows as monospace. Information section to
% contain, in order: requirement (i.e. Required/Optional/Paramter), valid
% type (e.g. Num, Positive num, char, 1xN cell array, etc.) and default
% value if there is one (e.g. Default: '10'). Example below to replace.
% Delete these lines XXX._
%
% * |input_variable_1|: Description (Information). XXX
% * |input_variable_2|: Description (Information). XXX
% * |input_variable_3|: Description (Information). XXX
%
% *OUTPUT VARIABLES*
%
% _This section contains bullet points of output variables with description
% and information. See input variables for template. Example below to
% replace. Delete these lines XXX._
%
% * |output_variable_1|: Description (Information). XXX
% * |output_variable_2|: Description (Information). XXX
%
% *DEVELOPMENT NOTES*
%
% * XXX: switch automatically the WC panel to processed data on startup if
% processed data exists
%
% *NEW FEATURES*
%
% _This section contains dates and descriptions of major updates. Example
% below to replace. Delete these lines XXX._
%
% * YYYY-MM-DD: second version. Describes the update. XXX
% * YYYY-MM-DD: first version. XXX
%
% *EXAMPLE*
%
% _This section contains examples of valid function calls. Note that
% example lines start with 3 white spaces so that the publish function
% shows them correctly as matlab code. Example below to replace. Delete
% these lines XXX._
%
%   example_use_1; % comment on what this does. XXX
%   example_use_2: % comment on what this line does. XXX
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% _This last section contains at least author name and affiliation. Delete
% these lines XXX._
%
% Yoann Ladroit, Alexandre Schimel, NIWA. XXX

%% Function
function load_wc_tab(main_figure,parent_tab_group,str_disp)

disp_config = getappdata(main_figure,'disp_config');

switch parent_tab_group.Type
    case 'uitabgroup'
        wc_tab_comp.wc_tab = uitab(parent_tab_group,'Title','WC','Tag','wc_tab','BackGroundColor','w');
        tab_menu = uicontextmenu(ancestor(wc_tab_comp.wc_tab,'figure'));
        uimenu(tab_menu,'Label','Undock to External Window','Callback',{@undock_tab_callback,main_figure,'wc','new_fig'});
        wc_tab_comp.wc_tab.UIContextMenu = tab_menu;
    case 'figure'
        wc_tab_comp.wc_tab = parent_tab_group;
end

% str_disp empty at start
if isempty(str_disp)
    str_disp = 'Processed';
end



%
%% create the tab components
%

% data displayed
str_disp_list = {'Original' 'Phase' 'Processed'};
uicontrol(wc_tab_comp.wc_tab,'style','text','String','Data',...
    'BackgroundColor','White',...
    'units','pixels',...
    'position',[10 30 80 20]);
wc_tab_comp.data_disp = uicontrol(wc_tab_comp.wc_tab,...
    'style','popup',...
    'Units','pixels',...
    'position',[10 10 80 20],...
    'String',str_disp_list,...
    'Value',find(strcmpi(str_disp,str_disp_list)),...
    'Callback',{@change_wc_disp_cback,main_figure});

% stack view settings
uicontrol(wc_tab_comp.wc_tab,'style','text','String','Stack',...
    'BackgroundColor','White',...
    'units','pixels',...
    'position',[100 30 80 20]);
wc_tab_comp.data_disp_stack = uicontrol(wc_tab_comp.wc_tab,...
    'style','popup',...
    'Units','pixels',...
    'position',[100 10 80 20],...
    'String',{'Range' 'Depth'},...
    'Value',find(strcmpi(disp_config.StackAngularMode,{'Range' 'Depth'})),...
    'Callback',{@change_StackAngularMode_cback,main_figure});

% angular limits
uicontrol(wc_tab_comp.wc_tab,'style','text','String',['Angular lim. (' char(hex2dec('00B0')) ')'],...
    'BackgroundColor','White',...
    'units','pixels',...
    'position',[190 30 100 20]);
wc_tab_comp.alim_min = uicontrol(wc_tab_comp.wc_tab,'style','edit','String',num2str(disp_config.StackAngularWidth(1)),...
    'BackgroundColor','White',...
    'units','pixels',...
    'position',[190 10 40 20],...
    'Callback',{@change_alim_cback,main_figure});
wc_tab_comp.alim_max = uicontrol(wc_tab_comp.wc_tab,'style','edit','String',num2str(disp_config.StackAngularWidth(2)),...
    'BackgroundColor','White',...
    'units','pixels',...
    'position',[240 10 40 20],...
    'Callback',{@change_alim_cback,main_figure});

% number of pings
uicontrol(wc_tab_comp.wc_tab,'style','text','String','Pings',...
    'BackgroundColor','White',...
    'units','pixels',...
    'position',[290 30 40 20]);
wc_tab_comp.StackPingWidth = uicontrol(wc_tab_comp.wc_tab,'style','edit','String',num2str(disp_config.StackPingWidth*2),...
    'BackgroundColor','White',...
    'units','pixels',...
    'position',[290 10 40 20],...
    'Callback',{@change_StackPingWidth_cback,main_figure});

% axes and contents
wc_tab_comp.wc_axes = axes(wc_tab_comp.wc_tab,...
    'Units','normalized',...
    'outerposition',[0 0 1 0.9],...
    'nextplot','add',...
    'YDir','normal',...
    'Tag','wc');

axis(wc_tab_comp.wc_axes,'equal');
[cmap,col_ax,col_lab,col_grid,col_bot,col_txt] = init_cmap(disp_config.Cmap);
colorbar(wc_tab_comp.wc_axes,'southoutside');
colormap(wc_tab_comp.wc_axes,cmap);
caxis(wc_tab_comp.wc_axes,disp_config.Cax_wc);
wc_tab_comp.wc_axes.XAxisLocation='top';
wc_tab_comp.wc_axes.XAxis.TickLabelFormat='%.0fm';
wc_tab_comp.wc_axes.YAxis.TickLabelFormat='%.0fm';
wc_tab_comp.wc_axes.YAxis.FontSize=8;
wc_tab_comp.wc_axes.XAxis.FontSize=8;

grid(wc_tab_comp.wc_axes,'on');
box(wc_tab_comp.wc_axes,'on')
wc_tab_comp.wc_gh = pcolor(wc_tab_comp.wc_axes,[],[],[]);
set(wc_tab_comp.wc_gh,'facealpha','flat','LineStyle','none','AlphaData',[]);
wc_tab_comp.ac_gh = plot(wc_tab_comp.wc_axes,nan,nan,'--k','Tag','ac','linewidth',2);
wc_tab_comp.bot_gh = plot(wc_tab_comp.wc_axes,nan,nan,'.k','Tag','ac','markersize',4);
% axis(wc_tab_comp.wc_axes,'equal');

wc_tab_comp.wc_axes_tt = uicontrol(wc_tab_comp.wc_tab,...
    'Units','normalized',...
    'Style','Text',...
    'position',[0 0.9 1 0.1],'BackgroundColor',[1 1 1]);

% save the tab to appdata
setappdata(main_figure,'wc_tab',wc_tab_comp);

% update tab if data is loaded
fData = getappdata(main_figure,'fData');
if isempty(fData)
    return;
end
update_wc_tab(main_figure);

end

function change_StackAngularMode_cback(src,~,main_figure)
disp_config = getappdata(main_figure,'disp_config');

if ~strcmpi(disp_config.StackAngularMode,src.String{src.Value})
    disp_config.StackAngularMode=lower(src.String{src.Value});
end

end

function change_wc_disp_cback(~,~,main_figure)

update_wc_tab(main_figure);
update_stacked_wc_tab(main_figure);
src.Name='Cax_wc';
listenCax(src,[],main_figure);

end

function change_StackPingWidth_cback(~,~,main_figure)

% get current cax in disp_config
disp_config = getappdata(main_figure,'disp_config');
spw=disp_config.StackPingWidth;

% check that modified values in the box are OK or change them back
wc_tab_comp = getappdata(main_figure,'wc_tab');
check_fmt_box(wc_tab_comp.StackPingWidth,[],1,Inf,spw*2,'%.0f');
% grab those values from the boxes
spw_box = str2double(wc_tab_comp.StackPingWidth.String);

if (disp_config.StackPingWidth~=ceil(spw_box/2))
disp_config.StackPingWidth=ceil(spw_box/2);
end

end

%%
% Callback when changing current map colour scale
%
function change_alim_cback(~,~,main_figure)

% get current cax in disp_config
disp_config = getappdata(main_figure,'disp_config');
saw=disp_config.StackAngularWidth;

% check that modified values in the box are OK or change them back
wc_tab_comp = getappdata(main_figure,'wc_tab');
check_fmt_box(wc_tab_comp.alim_min,[],-90,90,saw(1),'%.0f');
check_fmt_box(wc_tab_comp.alim_max,[],-90,90,saw(2),'%.0f');

% grab those values from the boxes
a_min = str2double(wc_tab_comp.alim_min.String);
a_max = str2double(wc_tab_comp.alim_max.String);

% if the min is more than max, don't accept change and reset current values
if a_min > a_max
    wc_tab_comp.alim_min.String = num2str(saw(1));
    wc_tab_comp.alim_max.String = num2str(saw(2));
else
    % if all OK, update cax
    disp_config.StackAngularWidth=[a_min a_max];
end

end

