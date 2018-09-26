%% load_wc_proc_tab.m
%
% Creates "WC Processing" tab (#3) in Espresso's Control Panel
%
function load_wc_proc_tab(main_figure,parent_tab_group)

switch parent_tab_group.Type
    case 'uitabgroup'
        wc_proc_tab_comp.wc_proc_tab = uitab(parent_tab_group,'Title','Data processing','Tag','wc_proc_tab','BackGroundColor','w');
    case 'figure'
        wc_proc_tab_comp.wc_proc_tab = parent_tab_group;
end

disp_config = getappdata(main_figure,'disp_config');

uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','text','BackgroundColor','White','units','normalized','position',[0.05 0.9 0.8 0.05],'String','Water-column data processing:','fontweight','bold');
wc_proc_tab_comp.bot_filter = uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','checkbox','BackgroundColor','White','units','normalized','position',[0.05 0.85 0.5 0.05],'String','Filter bottom detect','Value',1);
wc_proc_tab_comp.masking = uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','checkbox','BackgroundColor','White','units','normalized','position',[0.05 0.8 0.5 0.05],'String','Mask selected data','Value',1);

text_angle = uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','text','BackgroundColor','White','units','normalized','position',[0.15 0.75 0.3 0.05],'String',['Outer Beams (' char(hex2dec('00B0')) ')']);
wc_proc_tab_comp.angle_mask = uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','edit','BackgroundColor','White','units','normalized','position',[0.45 0.75 0.1 0.05],'String','Inf','Callback',{@check_fmt_box,5,Inf,90,'%.0f'});

text_rmin = uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','text','BackgroundColor','White','units','normalized','position',[0.15 0.7 0.3 0.05],'String','Close Range (m)','HorizontalAlignment','left');
wc_proc_tab_comp.r_min = uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','edit','BackgroundColor','White','units','normalized','position',[0.45 0.7 0.1 0.05],'String','1','Callback',{@check_fmt_box,0,Inf,1,'%.1f'});

text_bot = uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','text','BackgroundColor','White','units','normalized','position',[0.15 0.65 0.3 0.05],'String','Above Bottom (m)');
wc_proc_tab_comp.r_bot = uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','edit','BackgroundColor','White','units','normalized','position',[0.45 0.65 0.1 0.05],'String','1','Callback',{@check_fmt_box,-Inf,Inf,1,'%.1f'});

set([text_angle text_rmin text_bot],'HorizontalAlignment','left','fontangle','italic');

wc_proc_tab_comp.sidelobe = uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','checkbox','BackgroundColor','White','units','normalized','position',[0.05 0.6 0.5 0.05],'String','Filter sidelobe artefacts','Value',1);

% callback on check boxes
set([wc_proc_tab_comp.masking wc_proc_tab_comp.bot_filter wc_proc_tab_comp.sidelobe],'callback',{@update_str_disp_cback,main_figure})

uicontrol(wc_proc_tab_comp.wc_proc_tab,'Style','pushbutton','units','normalized',...
    'pos',[0.2 0.51 0.5 0.08],...
    'String','Process selected lines',...
    'callback',{@process_wc_cback,main_figure});



%% gridding section


% grid resolution
uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','text','String','Grid resolution (m)',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.05 0.35 0.3 0.05]);
uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','text','String','Horiz.',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.35 0.4 0.1 0.05]);
wc_proc_tab_comp.grid_val = uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','edit',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.35 0.35 0.1 0.05],...
    'String','0.25',...
    'Callback',{@check_fmt_box,0.1,100,1,'%.2f'});
uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','text','String','Vert.',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.45 0.4 0.1 0.05]);
wc_proc_tab_comp.vert_grid_val = uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','edit',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.45 0.35 0.1 0.05],...
    'String','1',...
    'Callback',{@check_fmt_box,0.1,100,1,'%.2f'});

% gridding type
uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','text','String','Gridding type',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.05 0.28 0.3 0.05]);
wc_proc_tab_comp.dim_grid = uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','popup','String',{'2D' '3D'},...
    'Units','normalized',...
    'position',[0.3 0.29 0.15 0.05],...
    'Value',1);

% grid button
uicontrol(wc_proc_tab_comp.wc_proc_tab,'Style','pushbutton','String','Grid processed lines',...
    'units','normalized',...
    'pos',[0.2 0.18 0.5 0.08],...
    'callback',{@grid_cback,main_figure});


%% colour scales

% current map colour scale
cax = disp_config.get_cax();

uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','text','String','Map colour scale (dB)',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.05 0.1 0.37 0.05]);
wc_proc_tab_comp.clim_min = uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','edit','String',num2str(cax(1)),...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.41 0.1 0.1 0.05],...
    'Callback',{@change_cax_cback,main_figure});
wc_proc_tab_comp.clim_max = uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','edit','String',num2str(cax(2)),...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.51 0.1 0.1 0.05],...
    'Callback',{@change_cax_cback,main_figure});

% swath display colour scale
cax = disp_config.Cax_wc;

uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','text','String','Swath colour scale (dB)',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.05 0.05 0.35 0.05]);
wc_proc_tab_comp.clim_min_wc = uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','edit','String',num2str(cax(1)),...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.41 0.05 0.1 0.05],...
    'Callback',{@change_wc_cax_cback,main_figure});
wc_proc_tab_comp.clim_max_wc = uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','edit','String',num2str(cax(2)),...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.51 0.05 0.1 0.05],...
    'Callback',{@change_wc_cax_cback,main_figure});


setappdata(main_figure,'wc_proc_tab',wc_proc_tab_comp);
update_str_disp_cback([],[],main_figure)

end


function change_wc_cax_cback(src,evt,main_figure)

wc_proc_tab_comp = getappdata(main_figure,'wc_proc_tab');
disp_config = getappdata(main_figure,'disp_config');

cax = disp_config.Cax_wc;
check_fmt_box(wc_proc_tab_comp.clim_min_wc,[],-200,100,cax(1),'%.0f');
check_fmt_box(wc_proc_tab_comp.clim_max_wc,[],-200,100,cax(2),'%.0f');

cax_min = str2double(wc_proc_tab_comp.clim_min_wc.String);
cax_max = str2double(wc_proc_tab_comp.clim_max_wc.String);

if cax_min<cax_max
    disp_config.Cax_wc = [cax_min cax_max];
    
else
    wc_proc_tab_comp.clim_min_wc.String = num2str(cax(1));
    wc_proc_tab_comp.clim_max_wc.String = num2str(cax(2));
    disp_config.Cax_wc = cax;
end

end


function change_cax_cback(src,evt,main_figure)

wc_proc_tab_comp = getappdata(main_figure,'wc_proc_tab');
disp_config = getappdata(main_figure,'disp_config');

cax = disp_config.get_cax();
check_fmt_box(wc_proc_tab_comp.clim_min,[],-200,100,cax(1),'%.0f');
check_fmt_box(wc_proc_tab_comp.clim_max,[],-200,100,cax(2),'%.0f');

cax_min = str2double(wc_proc_tab_comp.clim_min.String);
cax_max = str2double(wc_proc_tab_comp.clim_max.String);

if cax_min<cax_max
    disp_config.set_cax([cax_min cax_max]);
else
    wc_proc_tab_comp.clim_min.String = num2str(cax(1));
    wc_proc_tab_comp.clim_max.String = num2str(cax(2));
    disp_config.set_cax(cax);
end

end

function grid_cback(~,~,main_figure)

fData_tot = getappdata(main_figure,'fData');

if isempty(fData_tot)
    return;
end

fdata_tab_comp = getappdata(main_figure,'fdata_tab');

idx_zoom = find(cell2mat(fdata_tab_comp.table.Data(:,end-1)));

if isempty(idx_zoom)
    fprintf('No lines are selected.\n');
    return;
end

wc_proc_tab_comp = getappdata(main_figure,'wc_proc_tab');

res = str2double(get(wc_proc_tab_comp.grid_val,'String'));
vert_res = str2double(get(wc_proc_tab_comp.vert_grid_val,'String'));

mask_params.angle_mask = str2double(get(wc_proc_tab_comp.angle_mask,'String'));
mask_params.r_min = str2double(get(wc_proc_tab_comp.r_min,'String'));
mask_params.r_bot = str2double(get(wc_proc_tab_comp.r_bot,'String'));

u = 0;

% general timer
timer_start = now;

for i = idx_zoom(:)'
    
    u = u+1;
    
    % disp
    fprintf('Gridding file "%s" (%i/%i). Started at %s...\n',fData_tot{i}.ALLfilename{1},u,numel(idx_zoom),datestr(now));
    tic
    
    % gridding
    fData_tot{i} = process_n_grid_WC(fData_tot{i},...
        'bot_filter',wc_proc_tab_comp.bot_filter.Value,...
        'masking',wc_proc_tab_comp.masking.Value,...
        'mask_params',mask_params,...
        'sidelobe',wc_proc_tab_comp.sidelobe.Value,...
        'dataToGrid',wc_proc_tab_comp.str_disp,...
        'res',res,...
        'vert_res',vert_res,...
        'dim',wc_proc_tab_comp.dim_grid.String{wc_proc_tab_comp.dim_grid.Value},...
        'dr_sub',4,...
        'db_sub',2,...
        'e_lim',[],...
        'n_lim',[],...
        'process',0,...
        'grid',1);
    
    % disp
    fprintf('...Done. Elapsed time: %f seconds.\n',toc);
    
end

% general timer
timer_end = now;
fprintf('Total time for gridding: %f seconds (~%.2f minutes).\n',(timer_end-timer_start)*24*60*60,(timer_end-timer_start)*24*60);



setappdata(main_figure,'fData',fData_tot);

disp_config = getappdata(main_figure,'disp_config');

disp_config.Fdata_idx = idx_zoom(end);

update_map_tab(main_figure,1,0,[]);
update_wc_tab(main_figure);

end

function update_str_disp_cback(~,~,main_figure)

wc_proc_tab_comp = getappdata(main_figure,'wc_proc_tab');

str_disp = 'original';

if wc_proc_tab_comp.masking.Value>0||wc_proc_tab_comp.sidelobe.Value>0
    str_disp = 'processed';
end

wc_proc_tab_comp.str_disp = str_disp;

setappdata(main_figure,'wc_proc_tab',wc_proc_tab_comp);

end


function process_wc_cback(~,~,main_figure)

fData_tot = getappdata(main_figure,'fData');

if isempty(fData_tot)
    return;
end

fdata_tab_comp = getappdata(main_figure,'fdata_tab');

idx_zoom = find(cell2mat(fdata_tab_comp.table.Data(:,end-1)));

if isempty(idx_zoom)
    fprintf('No lines are selected. Processing aborted.\n');
    return;
end

wc_proc_tab_comp = getappdata(main_figure,'wc_proc_tab');

mask_params.angle_mask = str2double(get(wc_proc_tab_comp.angle_mask,'String'));
mask_params.r_min = str2double(get(wc_proc_tab_comp.r_min,'String'));
mask_params.r_bot = str2double(get(wc_proc_tab_comp.r_bot,'String'));

u = 0;

% general timer
timer_start = now;

for i = idx_zoom(:)'
    
    u = u+1;
    
    % disp
    fprintf('Processing file "%s" (%i/%i). Started at %s...\n',fData_tot{i}.ALLfilename{1},u,numel(idx_zoom),datestr(now));
    tic
    
    % processing
    fData_tot{i} = process_n_grid_WC(fData_tot{i},...
        'bot_filter',wc_proc_tab_comp.bot_filter.Value,...
        'masking',wc_proc_tab_comp.masking.Value,...
        'mask_params',mask_params,...
        'sidelobe',wc_proc_tab_comp.sidelobe.Value,...
        'process',1,...
        'grid',0);
    
    % disp
    fprintf('...Done. Elapsed time: %f seconds.\n',toc);
    
end

% general timer
timer_end = now;
fprintf('Total time for processing: %f seconds (~%.2f minutes).\n',(timer_end-timer_start)*24*60*60,(timer_end-timer_start)*24*60);




setappdata(main_figure,'fData',fData_tot);

disp_config = getappdata(main_figure,'disp_config');

disp_config.Fdata_idx = idx_zoom(end);
update_wc_tab(main_figure);

end
