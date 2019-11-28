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
% current map colour scale
disp_config = getappdata(main_figure,'disp_config');
cax = disp_config.get_cax();


map_gr=uibuttongroup(display_tab_comp.display_tab,'Title','Map','units','norm','position',[0.02 0.61 0.96 0.37],'BackGroundColor','w');
grid_gr=uibuttongroup(display_tab_comp.display_tab,'Title','3D Grid','units','norm','position',[0.02 0.02 0.47 0.58],'BackGroundColor','w');
wc_gr=uibuttongroup(display_tab_comp.display_tab,'Title','Water Column','units','norm','position',[0.51 0.02 0.47 0.58],'BackGroundColor','w');

uicontrol(map_gr,'style','text','String','Variable:',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.05 0.7 0.3 0.15]);

display_tab_comp.var_disp = uicontrol(map_gr,'style','popupmenu','String',{'Echo Integration' 'Bathy' 'BS'},...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.35 0.7 0.4 0.2],...
    'Callback',{@change_var_disp_cback,main_figure});


%% colour scales


uicontrol(map_gr,'style','text','String','Col.scale (dB)',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.05 0.5 0.3 0.15]);
display_tab_comp.clim_min = uicontrol(map_gr,'style','edit','String',num2str(cax(1)),...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.35 0.5 0.1 0.15],...
    'Callback',{@change_cax_cback,main_figure});
display_tab_comp.clim_max = uicontrol(map_gr,'style','edit','String',num2str(cax(2)),...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.45 0.5 0.1 0.15],...
    'Callback',{@change_cax_cback,main_figure});






% swath display colour scale
cax = disp_config.Cax_wc;

uicontrol(wc_gr,'style','text','String','Col. scale (dB)',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.05 0.85 0.5 0.1]);
display_tab_comp.clim_min_wc = uicontrol(wc_gr,'style','edit','String',num2str(cax(1)),...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.55 0.85 0.2 0.1],...
    'Callback',{@change_wc_cax_cback,main_figure});
display_tab_comp.clim_max_wc = uicontrol(wc_gr,'style','edit','String',num2str(cax(2)),...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.75 0.85 0.2 0.1],...
    'Callback',{@change_wc_cax_cback,main_figure});

str_disp = 'Processed';

% data displayed
str_disp_list = {'Original' 'Phase' 'Processed'};
uicontrol(wc_gr,'style','text','String','Data:',...
    'BackgroundColor','White',...
    'units','norm',...
    'position',[0.05 0.7 0.3 0.1]);
display_tab_comp.data_disp = uicontrol(wc_gr,...
    'style','popup',...
    'Units','norm',...
    'position',[0.35 0.7 0.6 0.1],...
    'String',str_disp_list,...
    'Value',find(strcmpi(str_disp,str_disp_list)),...
    'Callback',{@change_wc_disp_cback,main_figure});

% stack view settings
uicontrol(wc_gr,'style','text','String','Stack:',...
    'BackgroundColor','White',...
    'units','norm',...
    'position',[0.05 0.55 0.3 0.1]);
display_tab_comp.data_disp_stack = uicontrol(wc_gr,...
    'style','popup',...
    'Units','norm',...
    'position',[0.35 0.55 0.6 0.1],...
    'String',{'Range' 'Depth'},...
    'Value',find(strcmpi(disp_config.StackAngularMode,{'Range' 'Depth'})),...
    'Callback',{@change_StackAngularMode_cback,main_figure});

% angular limits
uicontrol(wc_gr,'style','text','String',['Angular lim. (' char(hex2dec('00B0')) ')'],...
    'BackgroundColor','White',...
    'units','norm',...
    'position',[0.05 0.4 0.5 0.1]);
display_tab_comp.alim_min = uicontrol(wc_gr,'style','edit','String',num2str(disp_config.StackAngularWidth(1)),...
    'BackgroundColor','White',...
    'units','norm',...
    'position',[0.55 0.4 0.2 0.1],...
    'Callback',{@change_alim_cback,main_figure});
display_tab_comp.alim_max = uicontrol(wc_gr,'style','edit','String',num2str(disp_config.StackAngularWidth(2)),...
    'BackgroundColor','White',...
    'units','norm',...
    'position',[0.75 0.4 0.2 0.1],...
    'Callback',{@change_alim_cback,main_figure});

% number of pings
uicontrol(wc_gr,'style','text','String','Pings:',...
    'BackgroundColor','White',...
    'units','norm',...
    'position',[0.05 0.25 0.5 0.1]);
display_tab_comp.StackPingWidth = uicontrol(wc_gr,'style','edit','String',num2str(disp_config.StackPingWidth*2),...
    'BackgroundColor','White',...
    'units','norm',...
    'position',[0.55 0.25 0.2 0.1],...
    'Callback',{@change_StackPingWidth_cback,main_figure});

% number of pings
uicontrol(wc_gr,'style','text','String','Dg Source:',...
    'BackgroundColor','White',...
    'units','norm',...
    'position',[0.05 0.10 0.45 0.1]);

dg_source='WC';
display_tab_comp.dg_source = uicontrol(wc_gr,...
    'style','popup',...
    'Units','norm',...
    'position',[0.5 0.1 0.45 0.1],...
    'String',{'WC','AP'},...
    'Value',find(strcmpi(dg_source,{'WC','AP'})),...
    'Callback',{@change_dg_source_cback,main_figure});



% level of echo_integrated WC to be displayed
%%Sonar referenced
uicontrol(grid_gr,'Style','Text','String','Sonar Ref.','units','norm','position',[0.05 0.87 0.4 0.1],'backgroundcolor',[1 1 1]);
display_tab_comp.d_lim_ax = axes( grid_gr,...
    'units','norm',...
    'Position', [0.1 0.1 0.1 0.7], ...
    'XLim', [0 1], ...
    'YLim', [0 1], ...
    'Box', 'on', ...
    'visible','on',...
    'ytick', [], ...
    'xtick', [],'clipping','off');
p_col=[0.5 0.5 0.5];

display_tab_comp.d_lim_patch = patch( display_tab_comp.d_lim_ax,...
    'XData', [0 0 1 1], ...
    'visible','on',...
    'YData', [0 1 1 0],'FaceColor',p_col,'FaceAlpha',0.2);

l_col=[0.1 0.1 0.1];

display_tab_comp.d_line_max=yline(display_tab_comp.d_lim_ax,1,'color',l_col,'Tag','d_line_max','linewidth',2,'fontsize',8,'LabelHorizontalAlignment','right','LabelVerticalAlignment','top',...
    'ButtonDownFcn',{@grab_vert_lim_cback,main_figure,'sonar'});
display_tab_comp.d_line_min=yline(display_tab_comp.d_lim_ax,0,'color',l_col,'Tag','d_line_min','linewidth',2,'fontsize',8,'LabelHorizontalAlignment','left','LabelVerticalAlignment','bottom',...
    'ButtonDownFcn',{@grab_vert_lim_cback,main_figure,'sonar'});
display_tab_comp.d_line_mean=yline(display_tab_comp.d_lim_ax,0.5,'color',l_col,'Tag','d_line_mean','linewidth',2,'fontsize',8,'LabelHorizontalAlignment','center','LabelVerticalAlignment','middle',...
    'ButtonDownFcn',{@grab_vert_lim_cback,main_figure,'sonar'});
icon = get_icons_cdata(fullfile(whereisroot(),'icons'));

uicontrol(grid_gr,'Style','pushbutton','String','','CData',icon.up,...
    'units','normalized',...
    'pos',[0.25 0.45 0.1 0.1],'backgroundcolor',[1 1 1],...
    'callback',{@move_echo_slice_cback,main_figure,'up','sonar'});

uicontrol(grid_gr,'Style','pushbutton','String','','CData',icon.down,...
    'units','normalized',...
    'pos',[0.25 0.35 0.1 0.1],'backgroundcolor',[1 1 1],...
    'callback',{@move_echo_slice_cback,main_figure,'down','sonar'});


%%Bottom referenced
uicontrol(grid_gr,'Style','Text','String','Bottom Ref.','units','norm','position',[0.55 0.87 0.4 0.1],'backgroundcolor',[1 1 1]);
display_tab_comp.d_lim_bot_ax = axes(grid_gr,...
    'units','norm',...
    'Position', [0.6 0.1 0.1 0.7], ...
    'XLim', [0 1], ...
    'YLim', [0 1], ...
    'Box', 'on', ...
    'visible','on',...
    'ytick', [], ...
    'xtick', [],'clipping','off');


display_tab_comp.d_lim_bot_patch = patch( display_tab_comp.d_lim_bot_ax,...
    'XData', [0 0 1 1], ...
    'visible','on',...
    'YData', [0 1 1 0],'FaceColor',p_col,'FaceAlpha',0.2);
display_tab_comp.d_line_bot_max=yline(display_tab_comp.d_lim_bot_ax,1,'color',l_col,'Tag','d_line_max','fontsize',8,'linewidth',2,'LabelHorizontalAlignment','right','LabelVerticalAlignment','top',...
    'ButtonDownFcn',{@grab_vert_lim_cback,main_figure,'bot'});
display_tab_comp.d_line_bot_min=yline(display_tab_comp.d_lim_bot_ax,0,'color',l_col,'Tag','d_line_min','fontsize',8,'linewidth',2,'LabelHorizontalAlignment','left','LabelVerticalAlignment','bottom',...
    'ButtonDownFcn',{@grab_vert_lim_cback,main_figure,'bot'});
display_tab_comp.d_line_bot_mean=yline(display_tab_comp.d_lim_bot_ax,0.5,'color',l_col,'Tag','d_line_mean','fontsize',8,'linewidth',2,'LabelHorizontalAlignment','center','LabelVerticalAlignment','middle',...
    'ButtonDownFcn',{@grab_vert_lim_cback,main_figure,'bot'});

uicontrol(grid_gr,'Style','pushbutton','String','','CData',icon.up,...
    'units','normalized',...
    'pos',[0.75 0.45 0.1 0.1],'backgroundcolor',[1 1 1],...
    'callback',{@move_echo_slice_cback,main_figure,'up','bot'});

uicontrol(grid_gr,'Style','pushbutton','String','','CData',icon.down,...
    'units','normalized',...
    'pos',[0.75 0.35 0.1 0.1],'backgroundcolor',[1 1 1],...
    'callback',{@move_echo_slice_cback,main_figure,'down','bot'});



pointerBehavior.enterFcn = @(figHandle, currentPoint) set(figHandle, 'Pointer', 'fleur');
pointerBehavior.exitFcn  = @(figHandle, currentPoint) set(figHandle, 'Pointer', 'arrow');
pointerBehavior.traverseFcn = @(figHandle, currentPoint) set(figHandle, 'Pointer', 'fleur');
iptSetPointerBehavior(display_tab_comp.d_line_max,pointerBehavior);
iptSetPointerBehavior(display_tab_comp.d_line_min,pointerBehavior);

setappdata(main_figure,'display_tab',display_tab_comp);

end

function change_dg_source_cback(~,~,main_figure)
fData_tot = getappdata(main_figure,'fData');

if isempty(fData_tot)
    return;
end

% disp_config = getappdata(main_figure,'disp_config');
display_tab_comp = getappdata(main_figure,'display_tab');

dg_source=display_tab_comp.dg_source.String{display_tab_comp.dg_source.Value};
for ui=1:numel(fData_tot)
    if isfield(fData_tot{ui},'MET_datagramSource')
        fData_tot{ui}.MET_datagramSource=CFF_get_datagramSource(fData_tot{ui},dg_source);
    end
end
setappdata(main_figure,'fData',fData_tot);
update_wc_tab(main_figure);
update_stacked_wc_tab(main_figure,1);

end


function move_echo_slice_cback(~,~,main_figure,direction,ref)
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
display_tab_comp = getappdata(main_figure,'display_tab');
check_fmt_box(display_tab_comp.StackPingWidth,[],1,Inf,spw*2,'%.0f');
% grab those values from the boxes
spw_box = str2double(display_tab_comp.StackPingWidth.String);

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
display_tab_comp = getappdata(main_figure,'display_tab');
check_fmt_box(display_tab_comp.alim_min,[],-90,90,saw(1),'%.0f');
check_fmt_box(display_tab_comp.alim_max,[],-90,90,saw(2),'%.0f');

% grab those values from the boxes
a_min = str2double(display_tab_comp.alim_min.String);
a_max = str2double(display_tab_comp.alim_max.String);

% if the min is more than max, don't accept change and reset current values
if a_min >= a_max
    display_tab_comp.alim_min.String = num2str(saw(1));
    display_tab_comp.alim_max.String = num2str(saw(2));
else
    % if all OK, update cax
    disp_config.StackAngularWidth=[a_min a_max];
end

end


