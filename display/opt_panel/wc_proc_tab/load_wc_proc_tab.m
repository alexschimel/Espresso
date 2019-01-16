%% load_wc_proc_tab.m
%
% Creates "WC Processing" tab (#3) in Espresso's Control Panel. Also has
% callback functions for when interacting with the tab's contents.
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |input_variable_1|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% * |output_variable_1|: TODO: write description and info on variable
%
% *DVPT NOTES*
%
% * XXX: check that if asking for "process", redo the "process" from
% scratch
%
% *NEW FEATURES*
%
% * 2018-10-05: general editing and commenting (Alex Schimel)
% * 2017-10-25: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, Alexandre Schimel NIWA. Type |help Espresso.m| for
% copyright information.

%% Function
function load_wc_proc_tab(main_figure,parent_tab_group)

%% create tab variable
switch parent_tab_group.Type
    case 'uitabgroup'
        wc_proc_tab_comp.wc_proc_tab = uitab(parent_tab_group,'Title','Data processing','Tag','wc_proc_tab','BackGroundColor','w');
    case 'figure'
        wc_proc_tab_comp.wc_proc_tab = parent_tab_group;
end

disp_config = getappdata(main_figure,'disp_config');


%% processing section

% filter bottom push button
uicontrol(wc_proc_tab_comp.wc_proc_tab,'Style','pushbutton','String','Filter bottom of selected lines',...
    'units','normalized',...
    'pos',[0.2 0.87 0.5 0.08],...
    'callback',{@filter_bottom_cback,main_figure});

% mask selected data
wc_proc_tab_comp.masking = uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','checkbox','String','Mask selected data',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.05 0.8 0.5 0.05],...
    'Value',1);
text_angle = uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','text','String',['Outer Beams (' char(hex2dec('00B0')) ')'],...
    'BackgroundColor','White',...
    'units','normalized',...
    'HorizontalAlignment','left',...
    'fontangle','italic',...
    'position',[0.15 0.75 0.3 0.05]);
wc_proc_tab_comp.angle_mask = uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','edit','String','Inf',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.45 0.75 0.1 0.05],...
    'Callback',{@check_fmt_box,5,Inf,90,'%.0f'});
text_rmin = uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','text','String','Close Range (m)',...
    'BackgroundColor','White',...
    'units','normalized',...
    'HorizontalAlignment','left',...
    'fontangle','italic',...
    'position',[0.15 0.7 0.3 0.05],...
    'HorizontalAlignment','left');
wc_proc_tab_comp.r_min = uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','edit','String','1',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.45 0.7 0.1 0.05],...
    'Callback',{@check_fmt_box,0,Inf,1,'%.1f'});
text_bot = uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','text','String','Above Bottom (m)',...
    'BackgroundColor','White',...
    'units','normalized',...
    'HorizontalAlignment','left',...
    'fontangle','italic',...
    'position',[0.15 0.65 0.3 0.05]);
wc_proc_tab_comp.r_bot = uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','edit','String','0',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.45 0.65 0.1 0.05],...
    'Callback',{@check_fmt_box,-Inf,Inf,1,'%.1f'});

% filter sidelobe artifact
wc_proc_tab_comp.sidelobe = uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','checkbox','String','Filter sidelobe artefacts',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.05 0.6 0.5 0.05],...
    'Value',1);

% process push button
uicontrol(wc_proc_tab_comp.wc_proc_tab,'Style','pushbutton','String','Process selected lines',...
    'units','normalized',...
    'pos',[0.2 0.51 0.5 0.08],...
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

end



%% CALLBACKS

%%
% Callback when pressing bottom-filter button
%
function filter_bottom_cback(~,~,main_figure)

fData_tot = getappdata(main_figure,'fData');

if isempty(fData_tot)
    return;
end

fdata_tab_comp = getappdata(main_figure,'fdata_tab');

idx_fData = find(cell2mat(fdata_tab_comp.table.Data(:,end-1)));

if isempty(idx_fData)
    fprintf('No lines are selected. Bottom-filtering aborted.\n');
    return;
end

% hardcoded parameters for filtering
botfilter.method = 'filter';
botfilter.pingBeamWindowSize = [3 3];
botfilter.maxHorizDist = inf;
botfilter.flagParams.type = 'all';
botfilter.flagParams.variable = 'slope';
botfilter.flagParams.threshold = 30;
botfilter.interpolate = 'yes';

% init counter
u = 0;

% general timer
timer_start = now;

for i = idx_fData(:)'
    
    u = u+1;
    
    % disp
    fprintf('Filtering bottom in file "%s" (%i/%i). Started at %s...\n',fData_tot{i}.ALLfilename{1},u,numel(idx_fData),datestr(now));
    tic
    
    % filtering bottom
    fData_tot{i} = CFF_filter_WC_bottom_detect(fData_tot{i},...
        'method',botfilter.method,...
        'pingBeamWindowSize',botfilter.pingBeamWindowSize,...
        'maxHorizDist',botfilter.maxHorizDist,...
        'flagParams',botfilter.flagParams,...
        'interpolate',botfilter.interpolate);
    
    % disp
    fprintf('...Done. Elapsed time: %f seconds.\n',toc);
    
end

% general timer
timer_end = now;
fprintf('Total time for processing: %f seconds (~%.2f minutes).\n',(timer_end-timer_start)*24*60*60,(timer_end-timer_start)*24*60);

setappdata(main_figure,'fData',fData_tot);

disp_config = getappdata(main_figure,'disp_config');
disp_config.Fdata_idx = idx_fData(end);


% update the map, no zoom adjustment
update_map_tab(main_figure,0,0,0,[]);

update_wc_tab(main_figure);
update_stacked_wc_tab(main_figure);


end


%%
% Callback when pressing process push button
%
function process_wc_cback(~,~,main_figure)

fData_tot = getappdata(main_figure,'fData');

if isempty(fData_tot)
    return;
end

fdata_tab_comp = getappdata(main_figure,'fdata_tab');

idx_fData = find(cell2mat(fdata_tab_comp.table.Data(:,end-1)));

if isempty(idx_fData)
    fprintf('No lines are selected. Processing aborted.\n');
    return;
end

% get processing parameters
wc_proc_tab_comp = getappdata(main_figure,'wc_proc_tab');
mask_params.remove_angle       =  str2double(get(wc_proc_tab_comp.angle_mask,'String'));
mask_params.remove_closerange  =  str2double(get(wc_proc_tab_comp.r_min,'String'));
mask_params.remove_bottomrange = -str2double(get(wc_proc_tab_comp.r_bot,'String')); % NOTE inverting sign here.

% init counter
u = 0;

% general timer
timer_start = now;

for i = idx_fData(:)'
    
    u = u+1;
    
    % disp
    fprintf('Processing file "%s" (%i/%i). Started at %s...\n',fData_tot{i}.ALLfilename{1},u,numel(idx_fData),datestr(now));
    tic
    
    % initialize processing
    disp('...Initializing processing...');
    fData_tot{i} = CFF_initialize_WC_processing(fData_tot{i},'fast');
    
    % filtering sidelobe artefact
    if wc_proc_tab_comp.sidelobe.Value
        
        disp('...Filtering sidelobe artifacts...');
        fData_tot{i} = CFF_filter_WC_sidelobe_artifact(fData_tot{i},2);
        
    end
    
    % masking
    if wc_proc_tab_comp.masking.Value
        
        disp('...Creating mask...');
        fData_tot{i} = CFF_mask_WC_data(fData_tot{i},...
            mask_params.remove_angle,...
            mask_params.remove_closerange,...
            mask_params.remove_bottomrange);
        
    end
    
    % disp
    fprintf('...Done. Elapsed time: %f seconds.\n',toc);
    
end

% general timer
timer_end = now;
fprintf('Total time for processing: %f seconds (~%.2f minutes).\n',(timer_end-timer_start)*24*60*60,(timer_end-timer_start)*24*60);

setappdata(main_figure,'fData',fData_tot);

disp_config = getappdata(main_figure,'disp_config');
disp_config.Fdata_idx = idx_fData(end);

% update the WC view to "Processed"
wc_tab_comp = getappdata(main_figure,'wc_tab');
wc_tab_strings = wc_tab_comp.data_disp.String;
[~,idx] = ismember('Processed',wc_tab_strings);
wc_tab_comp.data_disp.Value = idx;

update_wc_tab(main_figure);
update_stacked_wc_tab(main_figure,1); % force the update of stacked view

end


%%
% Callback when pushing grid button
%
function grid_cback(~,~,main_figure)

fData_tot = getappdata(main_figure,'fData');

if isempty(fData_tot)
    return;
end

fdata_tab_comp = getappdata(main_figure,'fdata_tab');

idx_fData = find(cell2mat(fdata_tab_comp.table.Data(:,end-1)));

if isempty(idx_fData)
    fprintf('No lines are selected. Gridding aborted.\n');
    return;
end

% getting gridding parameters
wc_proc_tab_comp = getappdata(main_figure,'wc_proc_tab');
res      = str2double(get(wc_proc_tab_comp.grid_val,'String'));
vert_res = str2double(get(wc_proc_tab_comp.vert_grid_val,'String'));
grid_dim = wc_proc_tab_comp.dim_grid.String{wc_proc_tab_comp.dim_grid.Value};
dr_sub = 4;
db_sub = 2;

% init counter
u = 0;

% general timer
timer_start = now;

for i = idx_fData(:)'
    
    u = u+1;
    
    % disp
    fprintf('Gridding file "%s" (%i/%i). Started at %s...\n',fData_tot{i}.ALLfilename{1},u,numel(idx_fData),datestr(now));
    tic
    
    % gridding
    fData_tot{i} = CFF_grid_WC_data(fData_tot{i},...
        'res',res,...
        'vert_res',vert_res,...
        'dim',grid_dim,...
        'dr_sub',dr_sub,...
        'db_sub',db_sub,...
        'e_lim',[],...
        'n_lim',[]);
    
    % disp
    fprintf('...Done. Elapsed time: %f seconds.\n',toc);
    
end

% general timer
timer_end = now;
fprintf('Total time for gridding: %f seconds (~%.2f minutes).\n',(timer_end-timer_start)*24*60*60,(timer_end-timer_start)*24*60);

setappdata(main_figure,'fData',fData_tot);

disp_config = getappdata(main_figure,'disp_config');
disp_config.Fdata_idx = idx_fData(end);

% update map with new grid, zoom on changed lines
update_map_tab(main_figure,1,0,1,disp_config.Fdata_idx);

% update WC view and stacked view
update_wc_tab(main_figure);
update_stacked_wc_tab(main_figure);

end


%%
% Callback when changing current map colour scale
%
function change_cax_cback(~,~,main_figure)

% get current cax in disp_config
disp_config = getappdata(main_figure,'disp_config');
cax = disp_config.get_cax();

% check that modified values in the box are OK or change them back
wc_proc_tab_comp = getappdata(main_figure,'wc_proc_tab');
check_fmt_box(wc_proc_tab_comp.clim_min,[],-200,100,cax(1),'%.0f');
check_fmt_box(wc_proc_tab_comp.clim_max,[],-200,100,cax(2),'%.0f');

% grab those values from the boxes
cax_min = str2double(wc_proc_tab_comp.clim_min.String);
cax_max = str2double(wc_proc_tab_comp.clim_max.String);

% if the min is more than max, don't accept change and reset current values
if cax_min > cax_max
    wc_proc_tab_comp.clim_min.String = num2str(cax(1));
    wc_proc_tab_comp.clim_max.String = num2str(cax(2));
else
    % if all OK, update cax
    disp_config.set_cax([cax_min cax_max]);
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
wc_proc_tab_comp = getappdata(main_figure,'wc_proc_tab');
check_fmt_box(wc_proc_tab_comp.clim_min_wc,[],-200,100,cax_wc(1),'%.0f');
check_fmt_box(wc_proc_tab_comp.clim_max_wc,[],-200,100,cax_wc(2),'%.0f');

% grab those values from the boxes
cax_wc_min = str2double(wc_proc_tab_comp.clim_min_wc.String);
cax_wc_max = str2double(wc_proc_tab_comp.clim_max_wc.String);

% if the min is more than max, don't accept change and reset current values
if cax_wc_min > cax_wc_max
    wc_proc_tab_comp.clim_min_wc.String = num2str(cax_wc(1));
    wc_proc_tab_comp.clim_max_wc.String = num2str(cax_wc(2));
else
    % if all OK, update cax_wc
    disp_config.Cax_wc = [cax_wc_min cax_wc_max];
end

end
