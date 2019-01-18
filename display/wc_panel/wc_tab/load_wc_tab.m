%% load_wc_tab.m
%
% Creates "WC" tab in Espresso's Swath Panel
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
function load_wc_tab(main_figure,parent_tab_group)

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

% pos = getpixelposition(wc_tab_comp.wc_tab);
wc_tab_comp.data_disp = uicontrol(wc_tab_comp.wc_tab,...
    'style','popup',...
    'Units','pixels',...
    'position',[20 20 120 20],...
    'String',{'Original' 'Phase' 'Processed'},...
    'Value',1,...
    'Callback',{@change_wc_disp_cback,main_figure});

wc_tab_comp.wc_axes = axes(wc_tab_comp.wc_tab,...
    'Units','normalized',...
    'outerposition',[0 0 1 1],...
    'nextplot','add',...
    'YDir','normal',...
    'Tag','wc');

[cmap,col_ax,col_lab,col_grid,col_bot,col_txt] = init_cmap(disp_config.Cmap);
title(wc_tab_comp.wc_axes,'N/A','Interpreter','none','FontSize',10,'FontWeight','normal');
colorbar(wc_tab_comp.wc_axes,'southoutside');
colormap(wc_tab_comp.wc_axes,cmap);
caxis(wc_tab_comp.wc_axes,disp_config.Cax_wc);
xlabel(wc_tab_comp.wc_axes,'Across Distance (m)','FontSize',10);
ylabel(wc_tab_comp.wc_axes,'Depth (m)','FontSize',10);
grid(wc_tab_comp.wc_axes,'on');
box(wc_tab_comp.wc_axes,'on')
wc_tab_comp.wc_gh = pcolor(wc_tab_comp.wc_axes,[],[],[]);
set(wc_tab_comp.wc_gh,'facealpha','flat','LineStyle','none','AlphaData',[]);
wc_tab_comp.ac_gh = plot(wc_tab_comp.wc_axes,nan,nan,'--k','Tag','ac','linewidth',2);
wc_tab_comp.bot_gh = plot(wc_tab_comp.wc_axes,nan,nan,'.k','Tag','ac','markersize',4);

%axis(wc_tab_comp.wc_axes,'equal');

setappdata(main_figure,'wc_tab',wc_tab_comp);
fData = getappdata(main_figure,'fData');

if isempty(fData)
    return;
end

update_wc_tab(main_figure);

end

function change_wc_disp_cback(~,~,main_figure)

update_wc_tab(main_figure);
update_stacked_wc_tab(main_figure);

end

