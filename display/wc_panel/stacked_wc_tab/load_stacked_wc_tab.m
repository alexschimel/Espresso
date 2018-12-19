%% this_function_name.m
%
% _This section contains a very short description of the function, for the
% user to know this function is part of the software and what it does for
% it. Example below to replace. Delete these lines XXX._
%
% Template of ESP3 function header. XXX
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
% _This section describes what features are temporary, needed future
% developments and paper references. Example below to replace. Delete these
% lines XXX._
%
% * research point 1. XXX
% * research point 2. XXX
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
function load_stacked_wc_tab(main_figure,parent_tab_group)

disp_config = getappdata(main_figure,'disp_config');

switch parent_tab_group.Type
    case 'uitabgroup'
        stacked_wc_tab_comp.wc_tab = uitab(parent_tab_group,'Title','Stacked WC','Tag','stacked_wc_tab','BackGroundColor','w');
        tab_menu = uicontextmenu(ancestor(stacked_wc_tab_comp.wc_tab,'figure'));
        uimenu(tab_menu,'Label','Undock to External Window','Callback',{@undock_tab_callback,main_figure,'stacked_wc','new_fig'});
        stacked_wc_tab_comp.wc_tab.UIContextMenu = tab_menu;
    case 'figure'
        stacked_wc_tab_comp.wc_tab = parent_tab_group;
end
% pos = getpixelposition(stacked_wc_tab_comp.wc_tab);

stacked_wc_tab_comp.wc_axes = axes(stacked_wc_tab_comp.wc_tab,'Units','normalized','outerposition',[0 0 1 1],'nextplot','add','YDir','normal');

[cmap,col_ax,col_lab,col_grid,col_bot,col_txt] = init_cmap(disp_config.Cmap);

colorbar(stacked_wc_tab_comp.wc_axes,'southoutside');
colormap(stacked_wc_tab_comp.wc_axes,cmap);
title(stacked_wc_tab_comp.wc_axes,'','Interpreter','none');
caxis(stacked_wc_tab_comp.wc_axes,disp_config.Cax_wc);
xlabel(stacked_wc_tab_comp.wc_axes,'Ping Number');
ylabel(stacked_wc_tab_comp.wc_axes,'Range');
grid(stacked_wc_tab_comp.wc_axes,'on');
box(stacked_wc_tab_comp.wc_axes,'on')
axis(stacked_wc_tab_comp.wc_axes,'ij');
stacked_wc_tab_comp.wc_gh = pcolor(stacked_wc_tab_comp.wc_axes,[],[],[]);
stacked_wc_tab_comp.wc_gh.ButtonDownFcn={@goToPing_cback,main_figure};
set(stacked_wc_tab_comp.wc_gh,'facealpha','flat','LineStyle','none','AlphaData',[]);
stacked_wc_tab_comp.ping_gh = plot(stacked_wc_tab_comp.wc_axes,nan,nan,'--k','Tag','ac','linewidth',2);
% stacked_wc_tab_comp.bot_gh = plot(stacked_wc_tab_comp.wc_axes,nan,nan,'.k','Tag','ac','markersize',4);


setappdata(main_figure,'stacked_wc_tab',stacked_wc_tab_comp);
fData = getappdata(main_figure,'fData');

if isempty(fData)
    return;
end

update_wc_tab(main_figure);

end

function goToPing_cback(src,evt,main_figure)
disp_config = getappdata(main_figure,'disp_config');
disp_config.Iping=round(evt.IntersectionPoint(1));

end



