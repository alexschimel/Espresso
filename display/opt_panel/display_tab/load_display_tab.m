function load_display_tab(main_figure,parent_tab_group)

%% create tab variable
switch parent_tab_group.Type
    case 'uitabgroup'
        display_tab_comp.display_tab = uitab(parent_tab_group,'Title','Display','Tag','display_tab','BackGroundColor','w');
    case 'figure'
        display_tab_comp.display_tab = parent_tab_group;
end

disp_config = getappdata(main_figure,'disp_config');

uicontrol(display_tab_comp.display_tab,'style','text','String','Map display:',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.05 0.85 0.25 0.05]);
display_tab_comp.var_disp = uicontrol(display_tab_comp.display_tab,'style','popupmenu','String',{'Echo Integration' 'Bathy' 'BS'},...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.050 0.8 0.4 0.05],...
    'Callback',{@change_var_disp_cback,main_figure});




%% colour scales

% current map colour scale
cax = disp_config.get_cax();

uicontrol(display_tab_comp.display_tab,'style','text','String','Map colour scale (dB)',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.05 0.7 0.37 0.05]);
display_tab_comp.clim_min = uicontrol(display_tab_comp.display_tab,'style','edit','String',num2str(cax(1)),...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.41 0.7 0.1 0.05],...
    'Callback',{@change_cax_cback,main_figure});
display_tab_comp.clim_max = uicontrol(display_tab_comp.display_tab,'style','edit','String',num2str(cax(2)),...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.51 0.7 0.1 0.05],...
    'Callback',{@change_cax_cback,main_figure});


% swath display colour scale
cax = disp_config.Cax_wc;

uicontrol(display_tab_comp.display_tab,'style','text','String','Swath colour scale (dB)',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.05 0.65 0.35 0.05]);
display_tab_comp.clim_min_wc = uicontrol(display_tab_comp.display_tab,'style','edit','String',num2str(cax(1)),...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.41 0.65 0.1 0.05],...
    'Callback',{@change_wc_cax_cback,main_figure});
display_tab_comp.clim_max_wc = uicontrol(display_tab_comp.display_tab,'style','edit','String',num2str(cax(2)),...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.51 0.65 0.1 0.05],...
    'Callback',{@change_wc_cax_cback,main_figure});


% level of echo_integrated WC to be displayed

display_tab_comp.d_lim_ax = axes( display_tab_comp.display_tab,...
    'units','norm',...
    'Position', [0.1 0.1 0.05 0.5], ...
    'XLim', [0 1], ...
    'YLim', [0 1], ...
    'Box', 'on', ...
    'visible','on',...
    'ytick', [], ...
    'xtick', []);

display_tab_comp.d_lim_patch = patch( display_tab_comp.d_lim_ax,...
    'XData', [0 0 1 1], ...
    'visible','on',...
    'YData', [0 1 1 0],'FaceColor',[0 0 0.8],'FaceAlpha',0.2);

display_tab_comp.d_line_max=yline(display_tab_comp.d_lim_ax,1,'color',[0.8 0 0],'Tag','d_line_max','linewidth',2,'LabelHorizontalAlignment','right','LabelVerticalAlignment','middle',...
    'ButtonDownFcn',{@grab_vert_lim_cback,main_figure});
display_tab_comp.d_line_min=yline(display_tab_comp.d_lim_ax,0,'color',[0.8 0 0],'Tag','d_line_min','linewidth',2,'LabelHorizontalAlignment','left','LabelVerticalAlignment','middle',...
    'ButtonDownFcn',{@grab_vert_lim_cback,main_figure});

pointerBehavior.enterFcn = @(figHandle, currentPoint) set(figHandle, 'Pointer', 'fleur');
pointerBehavior.exitFcn  = @(figHandle, currentPoint) set(figHandle, 'Pointer', 'fleur');
pointerBehavior.traverseFcn = @(figHandle, currentPoint) set(figHandle, 'Pointer', 'fleur');
iptSetPointerBehavior(display_tab_comp.d_line_max,pointerBehavior);
iptSetPointerBehavior(display_tab_comp.d_line_min,pointerBehavior);

setappdata(main_figure,'display_tab',display_tab_comp);

end




%%
% Callback when changing current map colour scale
%
function change_cax_cback(~,~,main_figure)

% get current cax in disp_config
disp_config = getappdata(main_figure,'disp_config');
cax = disp_config.get_cax();

% check that modified values in the box are OK or change them back
display_tab_comp = getappdata(main_figure,'display_tab');
check_fmt_box(display_tab_comp.clim_min,[],-200,100,cax(1),'%.0f');
check_fmt_box(display_tab_comp.clim_max,[],-200,100,cax(2),'%.0f');

% grab those values from the boxes
cax_min = str2double(display_tab_comp.clim_min.String);
cax_max = str2double(display_tab_comp.clim_max.String);

% if the min is more than max, don't accept change and reset current values
if cax_min > cax_max
    display_tab_comp.clim_min.String = num2str(cax(1));
    display_tab_comp.clim_max.String = num2str(cax(2));
else
    % if all OK, update cax
    disp_config.set_cax([cax_min cax_max]);
end



end


function change_var_disp_cback(src,~,main_figure)
% get current cax_wc in disp_config
disp_config = getappdata(main_figure,'disp_config');
switch src.String{src.Value}
    case 'Echo Integration'
        disp_config.Var_disp='wc_int';
    case 'Bathy'
        disp_config.Var_disp='bathy';
    case 'BS'
        disp_config.Var_disp='bs';
end

end


%%
% Callback when changing swath display colour scale
%
function change_wc_cax_cback(~,~,main_figure)

% get current cax_wc in disp_config
disp_config = getappdata(main_figure,'disp_config');
cax_wc = disp_config.Cax_wc;

% check that modified values in the box are OK or change them back
display_tab_comp = getappdata(main_figure,'display_tab');
check_fmt_box(display_tab_comp.clim_min_wc,[],-200,100,cax_wc(1),'%.0f');
check_fmt_box(display_tab_comp.clim_max_wc,[],-200,100,cax_wc(2),'%.0f');

% grab those values from the boxes
cax_wc_min = str2double(display_tab_comp.clim_min_wc.String);
cax_wc_max = str2double(display_tab_comp.clim_max_wc.String);

% if the min is more than max, don't accept change and reset current values
if cax_wc_min >= cax_wc_max
    display_tab_comp.clim_min_wc.String = num2str(cax_wc(1));
    display_tab_comp.clim_max_wc.String = num2str(cax_wc(2));
else
    % if all OK, update cax_wc
    disp_config.Cax_wc = [cax_wc_min cax_wc_max];
end

end

