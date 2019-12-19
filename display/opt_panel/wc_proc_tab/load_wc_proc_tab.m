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


%% processing section

dh = 0.12;
h = (1-(1:10)*dh-dh);

% top "Processing" checkbox
proc_gr = uibuttongroup(wc_proc_tab_comp.wc_proc_tab,'Units','Norm','Position',[0.02 0.51 0.96 0.47],'BackgroundColor','White','Title','');
wc_proc_tab_comp.proc_bool = uicontrol(wc_proc_tab_comp.wc_proc_tab,'Style','checkbox','String','Data Processing',...
    'BackgroundColor','white',...
    'HorizontalAlignment','left',...
    'units','normalized',...
    'Fontsize',8,...
    'pos',[0.03 0.50+0.47-0.03 0.25 0.05],...
    'Value',1,...
    'tooltipstring','Applies data processing (as parameterized in this section) when the "Process" button is pressed');

% "Filter bottom" checkbox
wc_proc_tab_comp.bot_filtering = uicontrol(proc_gr,'Style','checkbox','String','Filter bottom of selected lines',...
    'BackgroundColor','White',...
    'HorizontalAlignment','left',...
    'units','normalized',...
    'pos',[0.05 h(1) 0.5 dh],...
    'Value',1,...
    'tooltipstring','Applies light median filter to the bottom detect in each ping');

% "mask selected data" checkbox
wc_proc_tab_comp.masking = uicontrol(proc_gr,'style','checkbox','String','Mask selected data',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.05 h(2) 0.5 dh],...
    'Value',1,...
    'tooltipstring','Removes data as per parameters in this section');

% outer beams selection
uicontrol(proc_gr,'style','text','String',['Outer Beams (' char(hex2dec('00B0')) ')'],...
    'BackgroundColor','White',...
    'units','normalized',...
    'HorizontalAlignment','left',...
    'fontangle','italic',...
    'position',[0.07 h(3) 0.3 dh],...
    'tooltipstring','Removes data from outer beams beyond angle indicated');
wc_proc_tab_comp.angle_mask = uicontrol(proc_gr,'style','edit','String','Inf',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.35 h(3) 0.1 dh],...
    'Callback',{@check_fmt_box,5,Inf,90,'%.0f'},...
    'tooltipstring','Min: 5. Max: Inf.');

% close range selection
uicontrol(proc_gr,'style','text','String','Close Range (m)',...
    'BackgroundColor','White',...
    'units','normalized',...
    'HorizontalAlignment','left',...
    'fontangle','italic',...
    'position',[0.07 h(4) 0.3 dh],...
    'HorizontalAlignment','left',...
    'tooltipstring','Removes data closest to sonar within range indicated');
wc_proc_tab_comp.r_min = uicontrol(proc_gr,'style','edit','String','1',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.35 h(4) 0.1 dh],...
    'Callback',{@check_fmt_box,0,Inf,1,'%.1f'},...
    'tooltipstring','Min: 0. Max: Inf.');

% above bottom selection
uicontrol(proc_gr,'style','text','String','Above Bottom (m)',...
    'BackgroundColor','White',...
    'units','normalized',...
    'HorizontalAlignment','left',...
    'fontangle','italic',...
    'position',[0.07 h(5) 0.3 dh],...
    'tooltipstring','Removes bottom echo footprint and data below it');
wc_proc_tab_comp.r_bot = uicontrol(proc_gr,'style','edit','String','0',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.35 h(5) 0.1 dh],...
    'Callback',{@check_fmt_box,-Inf,Inf,1,'%.1f'},...
    'tooltipstring','0: removes bottom echo footprint and data below it. Negative: removes below bottom echo footprint (min: -Inf). Positive: remove more than bottom echo footprint (max: +Inf)');

% bad pings selection
uicontrol(proc_gr,'style','text','String','Bad pings (%)',...
    'BackgroundColor','White',...
    'units','normalized',...
    'fontangle','italic',...
    'HorizontalAlignment','left',...
    'position',[0.53 h(4) 0.3 dh],...
    'tooltipstring','Removes pings presenting bad bottom detect in excess of indicated percentage');
wc_proc_tab_comp.mask_badpings = uicontrol(proc_gr,'style','edit','String','100',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.75 h(4) 0.1 dh],...
    'Callback',{@check_fmt_box,0,100,100,'%.1f'},...
    'tooltipstring','Low value: aggressively removing pings if has few bad bottom detect (Min: 0). High value: only removing pings if most bottom detects failed (Max: 100).');

% "filter sidelobe artifact" checkbox
wc_proc_tab_comp.sidelobe = uicontrol(proc_gr,'style','checkbox','String','Filter sidelobe artefacts',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.05 h(6) 0.45 dh],...
    'Value',1,...
    'tooltipstring','Applies sidelobe artifact filtering algorithm');

% grid bathy/BS resolution
wc_proc_tab_comp.bs_grid_bool = uicontrol(proc_gr,'style','checkbox','String','Grid bathy/BS: res(m)',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.5 h(6) 0.35 dh],...
    'Value',1,...
    'tooltipstring','Horizontal gridding resolution for bathymetry and backscatter data');
wc_proc_tab_comp.bs_grid_res = uicontrol(proc_gr,'style','edit','String','5',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.85 h(6) 0.1 dh],...
    'Callback',{@check_fmt_box,0.1,500,5,'%.1f'},...
    'tooltipstring','Min: 0.1. Max: 500.');

%% gridding section

dh = 0.18;
h  = (1-(1:10)*dh-dh/2);

% top "gridding" checkbox
grid_gr = uibuttongroup(wc_proc_tab_comp.wc_proc_tab,'Units','Norm','Position',[0.02 0.11 0.96 0.38],'BackgroundColor','White','Title','');
wc_proc_tab_comp.grid_bool = uicontrol(wc_proc_tab_comp.wc_proc_tab,'Style','checkbox','String','Water-column Gridding',...
    'BackgroundColor','white',...
    'HorizontalAlignment','left',...
    'units','normalized',...
    'Fontsize',8,...
    'pos',[0.03 0.11+0.38-0.03 0.33 0.05],...
    'Value',1,...
    'tooltipstring','Applies gridding to water-column data (as parameterized in this section) when the "Process" button is pressed');

% Horizontal resolution
uicontrol(grid_gr,'style','text','String','Horiz. res. (m):',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.05 h(1) 0.25 dh],...
    'tooltipstring','Horizontal gridding resolution for water-column data');
wc_proc_tab_comp.grid_val = uicontrol(grid_gr,'style','edit',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.4 h(1) 0.1 dh],...
    'String','0.25',...
    'Callback',{@check_fmt_box,0.1,100,1,'%.2f'},...
    'tooltipstring','Min: 0.1. Max: 100.');

% gridding vertical reference
uicontrol(grid_gr,'style','text','String','Reference: ','tooltipstring','reference for gridding',....
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.5 h(1) 0.25 dh],...
    'tooltipstring','Reference height for vertical gridding');
wc_proc_tab_comp.grdlim_var = uicontrol(grid_gr,'style','popup','String',{'Sonar' 'Bottom'},...
    'Units','normalized',...
    'position',[0.75 h(1) 0.2 dh],...
    'Value',1,...
    'tooltipstring','Reference height for vertical gridding');

% sub-sampling
uicontrol(grid_gr,'style','text','String','Sub-sampling: ','tooltipstring','in samples/beams',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.05 h(2) 0.25 dh],...
    'tooltipstring','Decimation factor in samples and beams (use 1 for no decimation)');
wc_proc_tab_comp.dr = uicontrol(grid_gr,'style','edit','String','2',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.3 h(2) 0.1 dh],...
    'Callback',{@check_fmt_box,1,10,4,'%.0f'},...
    'tooltipstring','in samples');
wc_proc_tab_comp.db = uicontrol(grid_gr,'style','edit','String','2',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.4 h(2) 0.1 dh],...
    'Callback',{@check_fmt_box,1,10,2,'%.0f'},...
    'tooltipstring','in beams');

% data to be gridded
uicontrol(grid_gr,'style','text','String','Data to grid:',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.55 h(2) 0.2 dh],...
    'tooltipstring','Source of water-column data to be gridded');
wc_proc_tab_comp.data_type = uicontrol(grid_gr,'style','popup','String',{'Processed' 'Original'},'tooltipstring','data to grid',...
    'Units','normalized',...
    'position',[0.75 h(2) 0.2 dh],...
    'Value',1,...
    'tooltipstring','Original: data without processing applied (except radiometric corrections). Processed: data after processing applied');

% 2D gridding radiobutton and parameters
h = h-dh/2;
wc_proc_tab_comp.grid_2d = uicontrol(grid_gr,'style','radiobutton','String','2D',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.05 h(3) 0.1 dh],...
    'tooltipstring','2-D gridding - specify vertical extents of data to be gridded as a distance from vertical reference (depth below sonar, or height above bottom)');
uicontrol(grid_gr,'style','text','String','Grid only:',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.15 h(3) 0.25 dh],...
    'tooltipstring','(2-D gridding only)');
wc_proc_tab_comp.grdlim_mode = uicontrol(grid_gr,'style','popup','String',{'between' 'outside of'},...
    'Units','normalized',...
    'position',[0.40 h(3) 0.2 dh],...
    'Value',1,...
    'tooltipstring','Grid data between vertical extents indicated, or all data except between vertical extents indicated (2-D gridding only)');
wc_proc_tab_comp.grdlim_mindist = uicontrol(grid_gr,'style','edit',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.61 h(3) 0.1 dh],...
    'String','0',...
    'Callback',{@change_grdlim_mindist_cback,main_figure});
uicontrol(grid_gr,'style','text','String','&',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.71 h(3) 0.05 dh]);
wc_proc_tab_comp.grdlim_maxdist = uicontrol(grid_gr,'style','edit',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.76 h(3) 0.1 dh],...
    'String','inf',...
    'Callback',{@change_grdlim_maxdist_cback,main_figure});
uicontrol(grid_gr,'style','text','String','m',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.86 h(3) 0.1 dh]);

% 3D gridding radio button and parameters
h = h-dh/2;
wc_proc_tab_comp.grid_3d = uicontrol(grid_gr,'style','radiobutton','String','3D',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.05 h(4) 0.1 dh],...
    'tooltipstring','3-D gridding - all water-column data to be gridded at vertical resolution indicated, referenced to height reference indicated');
uicontrol(grid_gr,'style','text','String','Vert. res. (m):',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.15 h(4) 0.25 dh],...
    'tooltipstring','(3-D gridding only)');
wc_proc_tab_comp.vert_grid_val = uicontrol(grid_gr,'style','edit',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.4 h(4) 0.1 dh],...
    'String','1',...
    'Callback',{@check_fmt_box,0.1,100,1,'%.2f'},...
    'tooltipstring','(3-D gridding only)');

%% process button
uicontrol(wc_proc_tab_comp.wc_proc_tab,'Style','pushbutton','String','Process lines','Tooltipstring','(Filter bottom, mask data, filter sidelobes and grid)',...
    'units','normalized',...
    'pos',[0.25 0.01 0.5 0.08],...
    'callback',{@process_button_cback,main_figure},...
    'tooltipstring','Applies data processing and/or gridding (if selected) as per parameters indicated');

setappdata(main_figure,'wc_proc_tab',wc_proc_tab_comp);


end


%%
% Callbacks when changing min or max gridding limit distances
%
function change_grdlim_mindist_cback(~,~,main_figure)

default_mindist = 0;

wc_proc_tab_comp = getappdata(main_figure,'wc_proc_tab');

% check that modified value in the box is ok
check_fmt_box(wc_proc_tab_comp.grdlim_mindist,[],-inf,inf,0,'%.1f');

% grab the current values from both boxes
grdlim_mindist = str2double(wc_proc_tab_comp.grdlim_mindist.String);
grdlim_maxdist = str2double(wc_proc_tab_comp.grdlim_maxdist.String);

% if the min is more than max, don't accept change and reset default value
if grdlim_mindist > grdlim_maxdist
    wc_proc_tab_comp.grdlim_mindist.String = default_mindist;
end

end

function change_grdlim_maxdist_cback(~,~,main_figure)

default_maxdist = inf;

wc_proc_tab_comp = getappdata(main_figure,'wc_proc_tab');

% check that modified value in the box is ok
check_fmt_box(wc_proc_tab_comp.grdlim_maxdist,[],-inf,inf,default_maxdist,'%.1f');

% grab the current values from both boxes
grdlim_mindist = str2double(wc_proc_tab_comp.grdlim_mindist.String);
grdlim_maxdist = str2double(wc_proc_tab_comp.grdlim_maxdist.String);

% if the min is more than max, don't accept change and reset default value
if grdlim_mindist > grdlim_maxdist
    wc_proc_tab_comp.grdlim_maxdist.String = default_maxdist;
end

end


%%
% Callback when pressing the process button
%
function process_button_cback(~,~,main_figure)

fData_tot = getappdata(main_figure,'fData');

if isempty(fData_tot)
    return;
end

fdata_tab_comp = getappdata(main_figure,'fdata_tab');

idx_fData = find(cell2mat(fdata_tab_comp.table.Data(:,end-1)));

if isempty(idx_fData)
    fprintf('No lines are selected. Process aborted.\n');
    return;
end

wc_proc_tab_comp = getappdata(main_figure,'wc_proc_tab');

% processing parameters
procpar.bottomfilter_flag   = wc_proc_tab_comp.bot_filtering.Value;
procpar.masking_flag        = wc_proc_tab_comp.masking.Value;
procpar.sidelobefilter_flag = wc_proc_tab_comp.sidelobe.Value;
procpar.badpings_flag       = str2double(wc_proc_tab_comp.mask_badpings.String)<100;
procpar.mask_angle          =  str2double(get(wc_proc_tab_comp.angle_mask,'String'));
procpar.mask_closerange     =  str2double(get(wc_proc_tab_comp.r_min,'String'));
procpar.mask_bottomrange    = -str2double(get(wc_proc_tab_comp.r_bot,'String')); % NOTE inverting sign here.
procpar.mask_ping           =  str2double(get(wc_proc_tab_comp.mask_badpings,'String'));
procpar.gridbathyBS_flag    = wc_proc_tab_comp.bs_grid_bool.Value;
procpar.gridbathyBS_res     = str2double(get(wc_proc_tab_comp.bs_grid_res,'String'));


f_stack = 0;

if wc_proc_tab_comp.proc_bool.Value > 0
    
    % bottom filtering
    if procpar.bottomfilter_flag
        fData_tot = filter_bottomdetect(fData_tot, idx_fData);
    end
    
    % data processing
    if procpar.masking_flag || procpar.sidelobefilter_flag || procpar.badpings_flag
        
        fData_tot = process_watercolumn(fData_tot, idx_fData, procpar);
        
        f_stack = 1;
        
    end
    
    % bathy/BS gridding
    if procpar.gridbathyBS_flag
        fData_tot = gridbathyBS(fData_tot, idx_fData, procpar);
    end
    
    % save fData_tot
    setappdata(main_figure,'fData',fData_tot);
    disp_config = getappdata(main_figure,'disp_config');
    disp_config.Fdata_ID = fData_tot{idx_fData(end)}.ID;
    
    % update the WC view to "Processed"
    display_tab_comp = getappdata(main_figure,'display_tab');
    wc_tab_strings = display_tab_comp.data_disp.String;
    [~,idx] = ismember('Processed',wc_tab_strings);
    display_tab_comp.data_disp.Value = idx;
    
    % update stacked view
    switch disp_config.StackAngularMode
        case 'range'
            ylab = 'Range(m)';
        case 'depth'
            ylab = 'Depth (m)';
    end
    stacked_wc_tab_comp = getappdata(main_figure,'stacked_wc_tab');
    if ~strcmpi(ylab,stacked_wc_tab_comp.wc_axes.YLabel.String)
        stacked_wc_tab_comp.wc_axes.YLabel.String = ylab;
    end
    
end

% gridding
if wc_proc_tab_comp.grid_bool.Value>0
    grid_watercolumn(main_figure);
end

disp_config = getappdata(main_figure,'disp_config');
disp_config.Fdata_ID = fData_tot{idx_fData(end)}.ID;

% update map with new grid, zoom on changed lines
up_wc = update_map_tab(main_figure,1,0,1,idx_fData);

% update WC view and stacked view
if up_wc>0||f_stack>0
    update_wc_tab(main_figure);
    update_stacked_wc_tab(main_figure,f_stack);
end

end



function fData_tot = gridbathyBS(fData_tot, idx_fData, procpar)

% timer
timer_start = now;
u = 0;

for itt = idx_fData(:)'
    
    % disp
    u = u+1;
    fprintf('Gridding BS and Bathy in file "%s" (%i/%i)...\n',fData_tot{itt}.ALLfilename{1},u,numel(idx_fData));
    fprintf('...Started at %s...\n',datestr(now));
    
    tic
    fData_tot{itt} = CFF_grid_2D_fields_data(fData_tot{itt},...
        'grid_horz_res',procpar.gridbathyBS_res);
    
    % disp
    fprintf('...Done. Elapsed time: %f seconds.\n',toc);

end
timer_end = now;
fprintf('\nTotal time for gridding bathy and BS: %f seconds (~%.2f minutes).\n',(timer_end-timer_start)*24*60*60,(timer_end-timer_start)*24*60);


end



%%
function fData_tot = process_watercolumn(fData_tot, idx_fData, procpar)


% init counter
u = 0;

% general timer
timer_start = now;

% processing per file
for itt = idx_fData(:)'
    try
        u = u+1;
        
        % disp
        fprintf('Processing file "%s" (%i/%i)...\n',fData_tot{itt}.ALLfilename{1},u,numel(idx_fData));
        textprogressbar(sprintf('...Started at %s. Progress:',datestr(now)));
        textprogressbar(0);
        tic
        
        % original data filename and format info
        wc_dir = CFF_converted_data_folder(fData_tot{itt}.ALLfilename{1});
        
        dg_source = CFF_get_datagramSource(fData_tot{itt});
        
        [nSamples, nBeams, nPings] = cellfun(@(x) size(x.Data.val),fData_tot{itt}.(sprintf('%s_SBP_SampleAmplitudes',dg_source)));
        
        wcdata_class  = fData_tot{itt}.(sprintf('%s_1_SampleAmplitudes_Class',CFF_get_datagramSource(fData_tot{itt}))); % int8 or int16
        wcdata_factor = fData_tot{itt}.(sprintf('%s_1_SampleAmplitudes_Factor',CFF_get_datagramSource(fData_tot{itt})));
        wcdata_nanval = fData_tot{itt}.(sprintf('%s_1_SampleAmplitudes_Nanval',CFF_get_datagramSource(fData_tot{itt})));
        
        % processed data filename
        
        ping_gr_start = fData_tot{itt}.(sprintf('%s_n_start',dg_source));
        ping_gr_end   = fData_tot{itt}.(sprintf('%s_n_end',dg_source));
        
        fData_tot{itt} = CFF_init_memmapfiles(fData_tot{itt},...
            'wc_dir',wc_dir,...
            'field','X_SBP_WaterColumnProcessed',...
            'Class',wcdata_class,...
            'Factor',wcdata_factor,...
            'Nanval',wcdata_nanval,...
            'MaxSamples',nSamples,...
            'MaxBeams',nanmax(nBeams),...
            'ping_group_start',ping_gr_start,...
            'ping_group_end',ping_gr_end);
        
        saving_method = 'low_precision'; % 'low_precision' or 'high_precision'
        
        switch saving_method
            case 'low_precision'
                % processed data will be saved in the same format as original
                % raw data, aka in its possibly quite low resolution, but it
                % saves space on the disk
                wcdataproc_class   = wcdata_class;
                wcdataproc_factor  = wcdata_factor;
                wcdataproc_nanval  = wcdata_nanval;
            case 'high_precision'
                % processed data will be saved in "single" format to retain the
                % precision of computations, but it will take a bit more space
                % on the disk
                wcdataproc_class   = 'single';
                wcdataproc_factor  = 1;
                wcdataproc_nanval  = NaN;
        end
        
        for ig = 1:numel(nSamples)
            % processed data format
            
            % block processing setup
            mem_struct = memory;
            blockLength = ceil(mem_struct.MemAvailableAllArrays/(nSamples(ig)*nBeams(ig)*8)/20);
            nBlocks = ceil(nPings(ig)./blockLength);
            blocks = [ 1+(0:nBlocks-1)'.*blockLength , (1:nBlocks)'.*blockLength ];
            blocks(end,2) = nPings(ig);
            iPings = ping_gr_start(ig):ping_gr_end(ig);
            % processing per block of pings in file
            for iB = 1:nBlocks
                
                % list of pings in this block
                blockPings_f  = iPings(blocks(iB,1):blocks(iB,2));
                blockPings  = (blocks(iB,1):blocks(iB,2));
                
                % grab original data in dB
                data = CFF_get_WC_data(fData_tot{itt},sprintf('%s_SBP_SampleAmplitudes',CFF_get_datagramSource(fData_tot{itt})),'iPing',blockPings_f,'iRange',1:nSamples(ig),'output_format','true');
                
                % radiometric corrections
                % add a radio button to possibly turn this off too? TO DO XXX
                [data, warning_text] = CFF_WC_radiometric_corrections_CORE(data,fData_tot{itt});
                
                % filtering sidelobe artefact
                if procpar.sidelobefilter_flag
                    [data, correction] = CFF_filter_WC_sidelobe_artifact_CORE(data, fData_tot{itt}, blockPings_f);
                    % uncomment this for weighted gridding based on sidelobe
                    % correction
                    % fData_tot{itt}.X_S1P_sidelobeArtifactCorrection(:,:,blockPings) = correction;
                end
                
                % masking data
                if procpar.masking_flag
                    data = CFF_mask_WC_data_CORE(data, fData_tot{itt}, blockPings_f, procpar.mask_angle, procpar.mask_closerange, procpar.mask_bottomrange, [], procpar.mask_ping);
                end
                if wcdataproc_factor ~= 1
                    data = data./wcdataproc_factor;
                end
                
                if ~isnan(wcdataproc_nanval)
                    data(isnan(data)) = wcdataproc_nanval;
                end
                
                % convert result back to raw format and store through memmap
                if strcmp(class(data),wcdataproc_class)
                    fData_tot{itt}.X_SBP_WaterColumnProcessed{ig}.Data.val(:,:,blockPings) = data;
                else
                    fData_tot{itt}.X_SBP_WaterColumnProcessed{ig}.Data.val(:,:,blockPings) = cast(data,wcdataproc_class);
                end
                
                % disp block processing progress
                textprogressbar(round(iB.*100./nBlocks)-1);
                
            end
            
            
        end
        % get folder for converted data and converted filename
        folder_for_converted_data = CFF_converted_data_folder(fData_tot{itt}.ALLfilename{1});
        mat_fdata_file = fullfile(folder_for_converted_data,'fData.mat');
        
        % save
        fData = fData_tot{itt};
        save(mat_fdata_file,'-struct','fData','-v7.3');
        clear fData;
        
        % disp
        textprogressbar(100)
        textprogressbar(sprintf(' done. Elapsed time: %f seconds.\n',toc));
        
        % throw warning
        if ~isempty(warning_text)
            warning(warning_text);
        end
        
    catch err
        [~,f_temp,e_temp] = fileparts(err.stack(1).file);
        err_str = sprintf('Error in file %s, line %d',[f_temp e_temp],err.stack(1).line);
        fprintf('%s: ERROR processing file %s \n%s\n',datestr(now,'HH:MM:SS'),fData_tot{itt}.ALLfilename{1},err_str);
        fprintf('%s\n\n',err.message);
    end
end

% general processing timer
timer_end = now;
fprintf('\nTotal time for processing: %f seconds (~%.2f minutes).\n',(timer_end-timer_start)*24*60*60,(timer_end-timer_start)*24*60);

end




%%
function grid_watercolumn(main_figure)

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
grid_horz_res = str2double(get(wc_proc_tab_comp.grid_val,'String'));
grid_vert_res = str2double(get(wc_proc_tab_comp.vert_grid_val,'String'));
data_type     = wc_proc_tab_comp.data_type.String{wc_proc_tab_comp.data_type.Value};
grdlim_mode    = wc_proc_tab_comp.grdlim_mode.String{wc_proc_tab_comp.grdlim_mode.Value};
grdlim_var     = wc_proc_tab_comp.grdlim_var.String{wc_proc_tab_comp.grdlim_var.Value};

if wc_proc_tab_comp.grid_2d.Value>0
    grid_type    = '2D';
else
    grid_type    = '3D';
end

grdlim_mindist = str2double(get(wc_proc_tab_comp.grdlim_mindist,'String'));
grdlim_maxdist = str2double(get(wc_proc_tab_comp.grdlim_maxdist,'String'));

dr_sub = str2double(wc_proc_tab_comp.dr.String);
db_sub = str2double(wc_proc_tab_comp.db.String);

% init counter
u = 0;

% general timer
timer_start = now;


for itt = idx_fData(:)'
    
    u = u+1;
    try
        % disp
        fprintf('Gridding file "%s" (%i/%i)...\n',fData_tot{itt}.ALLfilename{1},u,numel(idx_fData));
        fprintf('...Started at %s...\n',datestr(now));
        tic
        
        % gridding
        fData_tot{itt} = CFF_grid_WC_data(fData_tot{itt},...
            'grid_horz_res',grid_horz_res,...
            'grid_vert_res',grid_vert_res,...
            'grid_type',grid_type,...
            'dr_sub',dr_sub,...
            'db_sub',db_sub,...
            'grdlim_mode',grdlim_mode,...
            'grdlim_var',grdlim_var,...
            'grdlim_mindist',grdlim_mindist,...
            'grdlim_maxdist',grdlim_maxdist,...
            'data_type',data_type);
        
        % disp
        fprintf('...Done. Elapsed time: %f seconds.\n',toc);
        
        % get folder for converted data
        folder_for_converted_data = CFF_converted_data_folder(fData_tot{itt}.ALLfilename{1});
        
        fData = fData_tot{itt};
        
        % converted filename fData
        mat_fdata_file = fullfile(folder_for_converted_data,'fdata.mat');
        save(mat_fdata_file,'-struct','fData','-v7.3');
        clear fData;
        
    catch err
        [~,f_temp,e_temp] = fileparts(err.stack(1).file);
        err_str = sprintf('Error in file %s, line %d',[f_temp e_temp],err.stack(1).line);
        fprintf('%s: ERROR gridding file %s \n%s\n',datestr(now,'HH:MM:SS'),fData_tot{itt}.ALLfilename{1},err_str);
        fprintf('%s\n\n',err.message);
    end
    
end

% general timer
timer_end = now;
fprintf('\nTotal time for gridding: %f seconds (~%.2f minutes).\n',(timer_end-timer_start)*24*60*60,(timer_end-timer_start)*24*60);

setappdata(main_figure,'fData',fData_tot);


end


%%
function fData_tot = filter_bottomdetect(fData_tot, idx_fData)

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

for itt = idx_fData(:)'
    
    u = u+1;
    
    % disp
    fprintf('Filtering bottom in file "%s" (%i/%i)...\n',fData_tot{itt}.ALLfilename{1},u,numel(idx_fData));
    fprintf('...Started at %s...\n',datestr(now));
    tic

    % filtering bottom
    fData_tot{itt} = CFF_filter_WC_bottom_detect(fData_tot{itt},...
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
fprintf('\nTotal time for processing: %f seconds (~%.2f minutes).\n',(timer_end-timer_start)*24*60*60,(timer_end-timer_start)*24*60);

end




