function load_display_tab(main_figure,parent_tab_group)

if isappdata(main_figure,'display_tab')
    display_tab_comp=getappdata(main_figure,'display_tab');
    delete(display_tab_comp.display_tab);
end

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
%%Sonar referenced
uicontrol(display_tab_comp.display_tab,'Style','Text','String','3D Sonar Ref. grid','units','norm','position',[0.05 0.55 0.25 0.05],'backgroundcolor',[1 1 1]);
display_tab_comp.d_lim_ax = axes( display_tab_comp.display_tab,...
    'units','norm',...
    'Position', [0.1 0.05 0.05 0.45], ...
    'XLim', [0 1], ...
    'YLim', [0 1], ...
    'Box', 'on', ...
    'visible','on',...
    'ytick', [], ...
    'xtick', [],'clipping','off');


display_tab_comp.d_lim_patch = patch( display_tab_comp.d_lim_ax,...
    'XData', [0 0 1 1], ...
    'visible','on',...
    'YData', [0 1 1 0],'FaceColor',[0 0 0.8],'FaceAlpha',0.2);


display_tab_comp.d_line_max=yline(display_tab_comp.d_lim_ax,1,'color',[0.8 0 0],'Tag','d_line_max','linewidth',2,'LabelHorizontalAlignment','right','LabelVerticalAlignment','top',...
    'ButtonDownFcn',{@grab_vert_lim_cback,main_figure,'sonar'});
display_tab_comp.d_line_min=yline(display_tab_comp.d_lim_ax,0,'color',[0.8 0 0],'Tag','d_line_min','linewidth',2,'LabelHorizontalAlignment','left','LabelVerticalAlignment','bottom',...
    'ButtonDownFcn',{@grab_vert_lim_cback,main_figure,'sonar'});
display_tab_comp.d_line_mean=yline(display_tab_comp.d_lim_ax,0.5,'color',[0.8 0 0],'Tag','d_line_mean','linewidth',2,'LabelHorizontalAlignment','center','LabelVerticalAlignment','middle',...
    'ButtonDownFcn',{@grab_vert_lim_cback,main_figure,'sonar'});
icon = get_icons_cdata(fullfile(whereisroot(),'icons'));

uicontrol(display_tab_comp.display_tab,'Style','pushbutton','String','','CData',icon.up,...
    'units','normalized',...
    'pos',[0.20 0.30 0.04 0.05],...
    'callback',{@move_echo_slice_cback,main_figure,'up','sonar'});

uicontrol(display_tab_comp.display_tab,'Style','pushbutton','String','','CData',icon.down,...
    'units','normalized',...
    'pos',[0.20 0.25 0.04 0.05],...
    'callback',{@move_echo_slice_cback,main_figure,'down','sonar'});


%%Bottom referenced
uicontrol(display_tab_comp.display_tab,'Style','Text','String','3D Bottom Ref. grid','units','norm','position',[0.35 0.55 0.25 0.05],'backgroundcolor',[1 1 1]);
display_tab_comp.d_lim_bot_ax = axes( display_tab_comp.display_tab,...
    'units','norm',...
    'Position', [0.35 0.05 0.05 0.45], ...
    'XLim', [0 1], ...
    'YLim', [0 1], ...
    'Box', 'on', ...
    'visible','on',...
    'ytick', [], ...
    'xtick', [],'clipping','off');


display_tab_comp.d_lim_bot_patch = patch( display_tab_comp.d_lim_bot_ax,...
    'XData', [0 0 1 1], ...
    'visible','on',...
    'YData', [0 1 1 0],'FaceColor',[0 0 0.8],'FaceAlpha',0.2);
display_tab_comp.d_line_bot_max=yline(display_tab_comp.d_lim_bot_ax,1,'color',[0.8 0 0],'Tag','d_line_max','linewidth',2,'LabelHorizontalAlignment','right','LabelVerticalAlignment','top',...
    'ButtonDownFcn',{@grab_vert_lim_cback,main_figure,'bot'});
display_tab_comp.d_line_bot_min=yline(display_tab_comp.d_lim_bot_ax,0,'color',[0.8 0 0],'Tag','d_line_min','linewidth',2,'LabelHorizontalAlignment','left','LabelVerticalAlignment','bottom',...
    'ButtonDownFcn',{@grab_vert_lim_cback,main_figure,'bot'});
display_tab_comp.d_line_bot_mean=yline(display_tab_comp.d_lim_bot_ax,0.5,'color',[0.8 0 0],'Tag','d_line_mean','linewidth',2,'LabelHorizontalAlignment','center','LabelVerticalAlignment','middle',...
    'ButtonDownFcn',{@grab_vert_lim_cback,main_figure,'bot'});

uicontrol(display_tab_comp.display_tab,'Style','pushbutton','String','','CData',icon.up,...
    'units','normalized',...
    'pos',[0.45 0.30 0.04 0.05],...
    'callback',{@move_echo_slice_cback,main_figure,'up','bot'});

uicontrol(display_tab_comp.display_tab,'Style','pushbutton','String','','CData',icon.down,...
    'units','normalized',...
    'pos',[0.45 0.25 0.04 0.05],...
    'callback',{@move_echo_slice_cback,main_figure,'down','bot'});

pointerBehavior.enterFcn = @(figHandle, currentPoint) set(figHandle, 'Pointer', 'fleur');
pointerBehavior.exitFcn  = @(figHandle, currentPoint) set(figHandle, 'Pointer', 'arrow');
pointerBehavior.traverseFcn = @(figHandle, currentPoint) set(figHandle, 'Pointer', 'fleur');
iptSetPointerBehavior(display_tab_comp.d_line_max,pointerBehavior);
iptSetPointerBehavior(display_tab_comp.d_line_min,pointerBehavior);

setappdata(main_figure,'display_tab',display_tab_comp);

end

function move_echo_slice_cback(src,evt,main_figure,direction,ref)
fData_tot = getappdata(main_figure,'fData');

if isempty(fData_tot)
    return;
end

% disp_config = getappdata(main_figure,'disp_config');
display_tab_comp = getappdata(main_figure,'display_tab');

depth_min=nan;
for ui=1:numel(fData_tot)
    depth_min =  nanmin(depth_min,nanmin(fData_tot{ui}.X_BP_bottomHeight(:)));
end

switch ref
    case'bot'
        d_min=0;
        d_max=abs(depth_min);
        d_line_max_h=display_tab_comp.d_line_bot_max;
        d_line_min_h=display_tab_comp.d_line_bot_min;
        d_patch_h=display_tab_comp.d_lim_bot_patch;
        d_line_mean_h=display_tab_comp.d_line_bot_mean;
    case 'sonar'
        d_max=0;
        d_min=depth_min;
        d_line_max_h=display_tab_comp.d_line_max;
        d_line_min_h=display_tab_comp.d_line_min;
        d_patch_h=display_tab_comp.d_lim_patch;
        d_line_mean_h=display_tab_comp.d_line_mean;
end

d_line_max_val=d_line_max_h.Value;
d_line_min_val=d_line_min_h.Value;
dr=d_line_max_val-d_line_min_val;
ip = d_line_mean_h.Value;
switch direction
    case 'up'
        ip = d_line_mean_h.Value*1.1;
        
    case 'down'
        ip = d_line_mean_h.Value*0.9;
        
end

if ip+dr/2<=1&&ip-dr/2>0
    d_line_max_h.Value=ip+dr/2;
    d_line_min_h.Value=ip-dr/2;
else
    return;
end
y_patch=[d_line_min_h.Value d_line_max_h.Value d_line_max_h.Value d_line_min_h.Value];
d_patch_h.YData=y_patch;
d_line_max_h.Label=sprintf('%.1fm',d_min+(d_max-d_min)*d_line_max_h.Value);
d_line_min_h.Label=sprintf('%.1fm',d_min+(d_max-d_min)*d_line_min_h.Value);
d_line_mean_h.Value=(d_line_min_h.Value+d_line_max_h.Value)/2;
fdata_tab_comp = getappdata(main_figure,'fdata_tab');

selected_idx = find([fdata_tab_comp.table.Data{:,end-1}]);
if ~isempty(selected_idx)
    update_map_tab(main_figure,1,0,0,selected_idx);
end

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

