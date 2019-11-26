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

dh=0.12;

h=(1-(1:10)*dh-dh/2);

%% processing section
proc_gr=uibuttongroup(wc_proc_tab_comp.wc_proc_tab,'Units','Norm','Position',[0.02 0.51 0.96 0.48],'BackgroundColor','White','Title','Processing');
% filter bottom push button
wc_proc_tab_comp.bot_filtering=uicontrol(proc_gr,'Style','checkbox','String','Filter bottom of selected lines',...
    'BackgroundColor','White',...
    'HorizontalAlignment','left',...
    'units','normalized',...
    'pos',[0.05 h(1) 0.5 dh],...
    'Value',1);%'callback',{@filter_bottom_cback,main_figure}

% mask selected data
wc_proc_tab_comp.masking = uicontrol(proc_gr,'style','checkbox','String','Mask selected data',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.05 h(2) 0.5 dh],...
    'Value',1);

text_angle = uicontrol(proc_gr,'style','text','String',['Outer Beams (' char(hex2dec('00B0')) ')'],...
    'BackgroundColor','White',...
    'units','normalized',...
    'HorizontalAlignment','left',...
    'fontangle','italic',...
    'position',[0.07 h(3) 0.3 dh]);
wc_proc_tab_comp.angle_mask = uicontrol(proc_gr,'style','edit','String','Inf',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.35 h(3) 0.1 dh],...
    'Callback',{@check_fmt_box,5,Inf,90,'%.0f'});
text_rmin = uicontrol(proc_gr,'style','text','String','Close Range (m)',...
    'BackgroundColor','White',...
    'units','normalized',...
    'HorizontalAlignment','left',...
    'fontangle','italic',...
    'position',[0.07 h(4) 0.3 dh],...
    'HorizontalAlignment','left');
wc_proc_tab_comp.r_min = uicontrol(proc_gr,'style','edit','String','1',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.35 h(4) 0.1 dh],...
    'Callback',{@check_fmt_box,0,Inf,1,'%.1f'});
text_bot = uicontrol(proc_gr,'style','text','String','Above Bottom (m)',...
    'BackgroundColor','White',...
    'units','normalized',...
    'HorizontalAlignment','left',...
    'fontangle','italic',...
    'position',[0.07 h(5) 0.3 dh]);
wc_proc_tab_comp.r_bot = uicontrol(proc_gr,'style','edit','String','0',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.35 h(5) 0.1 dh],...
    'Callback',{@check_fmt_box,-Inf,Inf,1,'%.1f'});

 uicontrol(proc_gr,'style','text','String','Bad pings (%)',...
    'BackgroundColor','White',...
    'units','normalized',...
    'fontangle','italic',...
    'HorizontalAlignment','left',...
    'position',[0.53 h(4) 0.3 dh]);
wc_proc_tab_comp.mask_badpings = uicontrol(proc_gr,'style','edit','String','100',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.75 h(4) 0.1 dh],...
    'Callback',{@check_fmt_box,0,100,100,'%.1f'});

% filter sidelobe artifact
wc_proc_tab_comp.sidelobe = uicontrol(proc_gr,'style','checkbox','String','Filter sidelobe artefacts',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.05 h(6) 0.5 dh],...
    'Value',1);

%process_wc_cback

%% gridding section
dh=0.18;

h=(1-(1:10)*dh-dh/4);

grid_gr=uibuttongroup(wc_proc_tab_comp.wc_proc_tab,'Units','Norm','Position',[0.02 0.11 0.96 0.38],'BackgroundColor','White','Title','');
wc_proc_tab_comp.grid_bool=uicontrol(wc_proc_tab_comp.wc_proc_tab,'Style','checkbox','String','Gridding',...
    'BackgroundColor','white',...
    'HorizontalAlignment','left',...
    'units','normalized',...
    'Fontsize',8,...
    'pos',[0.03 0.11+0.38-0.03 0.15 0.05],...
    'Value',1);
% grid resolution
uicontrol(grid_gr,'style','text','String','Horiz. res. (m):',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.15 h(1) 0.25 dh]); 

wc_proc_tab_comp.grid_val = uicontrol(grid_gr,'style','edit',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.4 h(1) 0.1 dh],... 
    'String','0.25',...
    'Callback',{@check_fmt_box,0.1,100,1,'%.2f'});


uicontrol(grid_gr,'style','text','String','Reference: ',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.5 h(1) 0.25 dh]);

wc_proc_tab_comp.grdlim_var = uicontrol(grid_gr,'style','popup','String',{'Sonar' 'Bottom'},...'depth below sonar' 'height above bottom'
    'Units','normalized',...
    'position',[0.7 h(1) 0.25 dh],...
    'Value',1);

uicontrol(grid_gr,'style','text','String','Data: ',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.5 h(2) 0.25 dh]);

wc_proc_tab_comp.data_type = uicontrol(grid_gr,'style','popup','String',{'Processed' 'Original'},...
    'Units','normalized',...
    'position',[0.7 h(2) 0.25 dh],...
    'Value',1);


h=h-dh/2;
% grid resolution
wc_proc_tab_comp.grid_2d=uicontrol(grid_gr,'style','radiobutton','String','2D',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.05 h(3) 0.1 dh]);

% gridding limitations
uicontrol(grid_gr,'style','text','String','Grid only:',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.15 h(3) 0.25 dh]);

wc_proc_tab_comp.grdlim_mode = uicontrol(grid_gr,'style','popup','String',{'between' 'outside of'},...
    'Units','normalized',...
    'position',[0.40 h(3) 0.2 dh],...
    'Value',1);
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

h=h-dh/2;
% grid resolution
wc_proc_tab_comp.grid_3d=uicontrol(grid_gr,'style','radiobutton','String','3D',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.05 h(4) 0.1 dh]);

uicontrol(grid_gr,'style','text','String','Vert. res. (m):',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.15 h(4) 0.25 dh]); 

wc_proc_tab_comp.vert_grid_val = uicontrol(grid_gr,'style','edit',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.4 h(4) 0.1 dh],... % [0.45 0.35 0.1 dh],...
    'String','1',...
    'Callback',{@check_fmt_box,0.1,100,1,'%.2f'});


% grid button
uicontrol(wc_proc_tab_comp.wc_proc_tab,'Style','pushbutton','String','Process lines','Tooltipstring','(Filter bottom, mask data, filter sidelobes and grid)',...
     'units','normalized',...
     'pos',[0.25 0.01 0.5 0.08],...
     'callback',{@apply_processing_cback,main_figure});
 
setappdata(main_figure,'wc_proc_tab',wc_proc_tab_comp);

end


function apply_processing_cback(src,evt,main_figure)

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


wc_proc_tab_comp=getappdata(main_figure,'wc_proc_tab');
f_stack=0;
if wc_proc_tab_comp.bot_filtering.Value>0
    filter_bottom_cback([],[],main_figure);
end
if wc_proc_tab_comp.masking.Value>0||wc_proc_tab_comp.sidelobe.Value>0||str2num(wc_proc_tab_comp.mask_badpings.String)<100
    process_wc_cback([],[],main_figure);
    f_stack=1;
end

if wc_proc_tab_comp.grid_bool.Value>0
    grid_cback([],[],main_figure);
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

for itt = idx_fData(:)'
    
    u = u+1;
    tic
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
setappdata(main_figure,'fData',fData_tot);

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
mask_angle       =  str2double(get(wc_proc_tab_comp.angle_mask,'String'));
mask_closerange  =  str2double(get(wc_proc_tab_comp.r_min,'String'));
mask_bottomrange = -str2double(get(wc_proc_tab_comp.r_bot,'String')); % NOTE inverting sign here.
mask_ping        =  str2double(get(wc_proc_tab_comp.mask_badpings,'String'));

% init counter
u = 0;

% general timer
timer_start = now;

% processing per file
for itt = idx_fData(:)'
    
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
    
    file_X_SBP_WaterColumnRaw=cell(1,numel(nSamples));
    file_X_SBP_WaterColumnProcessed=cell(1,numel(nSamples));
    
    fid=-ones(1,numel(nSamples));
    
    if isfield(fData_tot{itt},'X_SBP_WaterColumnProcessed')
        for uig=1:numel(fData_tot{itt}.X_SBP_WaterColumnProcessed)
            fData_tot{itt}.X_SBP_WaterColumnProcessed{uig}=[];
        end
        
        fData_tot{itt} = rmfield(fData_tot{itt},'X_SBP_WaterColumnProcessed');
    end
    ping_gr_start=fData_tot{itt}.(sprintf('%s_n_start',dg_source));
    ping_gr_end=fData_tot{itt}.(sprintf('%s_n_end',dg_source));
    for uig=1:numel(ping_gr_start)
        file_X_SBP_WaterColumnRaw{uig} = fullfile(wc_dir,sprintf('%s_SBP_SampleAmplitudes_%.0f_%.0f.dat',dg_source,...
            ping_gr_start(uig),ping_gr_end(uig)));
        
        file_X_SBP_WaterColumnProcessed{uig} = fullfile(wc_dir,sprintf('X_SBP_WaterColumnProcessed_%.0f_%.0f.dat',...
            ping_gr_start(uig),ping_gr_end(uig)));
        
    end
    
    
    for ig=1:numel(nSamples)
        % processed data format
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
        
        % memmap if possible
        if isfile(file_X_SBP_WaterColumnProcessed{ig}) && ...
                isfield(fData_tot{itt},'X_SBP_WaterColumnProcessed') && ...
                numel(fData_tot{itt}.X_SBP_WaterColumnProcessed)>=ig && ...
                isa(fData_tot{itt}.X_SBP_WaterColumnProcessed{ig},'memmapfile') &&...
                strcmpi(fData_tot{itt}.X_SBP_WaterColumnProcessed{ig}.Filename,file_X_SBP_WaterColumnProcessed{ig}) && ...
                all(fData_tot{itt}.X_SBP_WaterColumnProcessed{ig}.Format{2}==[nSamples(ig),nBeams(ig),nPings(ig)]) && ...
                strcmp(fData_tot{itt}.X_1_WaterColumnProcessed_Class,wcdataproc_class) && ...
                fData_tot{itt}.X_1_WaterColumnProcessed_Factor == wcdataproc_factor && ...
                (isnan(fData_tot{itt}.X_1_WaterColumnProcessed_Nanval) || ...
                fData_tot{itt}.X_1_WaterColumnProcessed_Nanval == wcdataproc_nanval)
            
            % Processed data file exists, is memmapped to fData, and the
            % dimensions and format as recorded in fData correspond to what we
            % want, it's ready for saving processed data through memmap.
            % Nothing else to do.
            flag_memmap = 1;
            
        else
            
            % Processed data file doesn't exist yet or isn't mapped, or
            % recorded dimensions or file format don't correspond to what we
            % want... then redo from scratch.
            
            if exist(file_X_SBP_WaterColumnProcessed{ig},'file')
                delete(file_X_SBP_WaterColumnProcessed{ig});
            end
            
            % Then, re-initialize
            if strcmp(saving_method,'low_precision')
                % copy original data file as processed data file
                if ~isfile(file_X_SBP_WaterColumnProcessed{ig})
                    copyfile(file_X_SBP_WaterColumnRaw{ig},file_X_SBP_WaterColumnProcessed{ig});
                end
                
            end
            
            if isfile(file_X_SBP_WaterColumnProcessed{ig})
                % add to fData as a memmapfile
                fData_tot{itt}.X_SBP_WaterColumnProcessed{ig} = memmapfile(file_X_SBP_WaterColumnProcessed{ig}, 'Format',{wcdataproc_class [nSamples(ig) nBeams(ig) nPings(ig)] 'val'},'repeat',1,'writable',true);
                % and record same info as original
                fData_tot{itt}.X_1_WaterColumnProcessed_Class  = wcdataproc_class;
                fData_tot{itt}.X_1_WaterColumnProcessed_Factor = wcdataproc_factor;
                fData_tot{itt}.X_1_WaterColumnProcessed_Nanval = wcdataproc_nanval;
                
                % ready for data saving through memmap
                flag_memmap = 1;
                
            else

                % can't memmap something that don't exist yet, open the file
                % as binary and set the flag to write in it
                fid(uig) = fopen(file_X_SBP_WaterColumnProcessed{uig},'w+');
                flag_memmap = 0;
                
            end
            
        end
        
        % block processing setup
        mem_struct = memory;
        blockLength = ceil(mem_struct.MemAvailableAllArrays/(nSamples(ig)*nBeams(ig)*8)/20);
        nBlocks = ceil(nPings(ig)./blockLength);
        blocks = [ 1+(0:nBlocks-1)'.*blockLength , (1:nBlocks)'.*blockLength ];
        blocks(end,2) = nPings(ig);
        iPings=ping_gr_start(ig):ping_gr_end(ig);
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
            if wc_proc_tab_comp.sidelobe.Value
                [data, correction] = CFF_filter_WC_sidelobe_artifact_CORE(data, fData_tot{itt}, blockPings_f);
                % uncomment this for weighted gridding based on sidelobe
                % correction
                % fData_tot{itt}.X_S1P_sidelobeArtifactCorrection(:,:,blockPings) = correction;
            end
            
            % masking data
            if wc_proc_tab_comp.masking.Value
                data = CFF_mask_WC_data_CORE(data, fData_tot{itt}, blockPings_f, mask_angle, mask_closerange, mask_bottomrange, [], mask_ping);
            end
            if wcdataproc_factor ~= 1
                data = data./wcdataproc_factor;
            end
            
            if ~isnan(wcdataproc_nanval)
                data(isnan(data)) = wcdataproc_nanval;
            end
            % saving
            if flag_memmap          
                % convert result back to raw format and store through memmap
                if strcmp(class(data),wcdataproc_class)
                    fData_tot{itt}.X_SBP_WaterColumnProcessed{ig}.Data.val(:,:,blockPings) = data;
                else
                    fData_tot{itt}.X_SBP_WaterColumnProcessed{ig}.Data.val(:,:,blockPings) = cast(data,wcdataproc_class);
                end
                
            else
                
                % write data to binary file
                fwrite(fid(ig),data,wcdataproc_class);
                
            end
            
            % disp block processing progress
            textprogressbar(round(iB.*100./nBlocks)-1);
            
        end
        
        if ~flag_memmap
            
            % close
            fclose(fid(ig));
            
            % add to fData as memmapfile
            fData_tot{itt}.X_SBP_WaterColumnProcessed{ig} = memmapfile(file_X_SBP_WaterColumnProcessed{ig}, 'Format',{wcdataproc_class [nSamples(ig) nBeams(ig) nPings(ig)] 'val'},'repeat',1,'writable',true);
            
            % and record info
            fData_tot{itt}.X_1_WaterColumnProcessed_Class  = wcdataproc_class;
            fData_tot{itt}.X_1_WaterColumnProcessed_Factor = wcdataproc_factor;
            fData_tot{itt}.X_1_WaterColumnProcessed_Nanval = wcdataproc_nanval;
            
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
    
end

% general timer
timer_end = now;
fprintf('\nTotal time for processing: %f seconds (~%.2f minutes).\n',(timer_end-timer_start)*24*60*60,(timer_end-timer_start)*24*60);

setappdata(main_figure,'fData',fData_tot);

disp_config = getappdata(main_figure,'disp_config');

disp_config.Fdata_ID = fData_tot{idx_fData(end)}.ID;

% update the WC view to "Processed"
wc_tab_comp = getappdata(main_figure,'wc_tab');
wc_tab_strings = wc_tab_comp.data_disp.String;
[~,idx] = ismember('Processed',wc_tab_strings);
wc_tab_comp.data_disp.Value = idx;

switch disp_config.StackAngularMode
    case 'range'
        ylab='Range(m)';
    case 'depth'
        ylab='Depth (m)';
end
stacked_wc_tab_comp=getappdata(main_figure,'stacked_wc_tab');
if ~strcmpi(ylab,stacked_wc_tab_comp.wc_axes.YLabel.String)
    stacked_wc_tab_comp.wc_axes.YLabel.String=ylab;
end


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



% init counter
u = 0;

% general timer
timer_start = now;

for itt = idx_fData(:)'
    
    u = u+1;
    
    
    dr_sub = 4;
    db_sub = 2;
    
    
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
    
end

% general timer
timer_end = now;
fprintf('\nTotal time for gridding: %f seconds (~%.2f minutes).\n',(timer_end-timer_start)*24*60*60,(timer_end-timer_start)*24*60);

setappdata(main_figure,'fData',fData_tot);


end


