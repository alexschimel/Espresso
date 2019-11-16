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
    'position',[0.07 0.75 0.3 0.05]);
wc_proc_tab_comp.angle_mask = uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','edit','String','Inf',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.35 0.75 0.1 0.05],...
    'Callback',{@check_fmt_box,5,Inf,90,'%.0f'});
text_rmin = uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','text','String','Close Range (m)',...
    'BackgroundColor','White',...
    'units','normalized',...
    'HorizontalAlignment','left',...
    'fontangle','italic',...
    'position',[0.07 0.7 0.3 0.05],...
    'HorizontalAlignment','left');
wc_proc_tab_comp.r_min = uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','edit','String','1',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.35 0.7 0.1 0.05],...
    'Callback',{@check_fmt_box,0,Inf,1,'%.1f'});
text_bot = uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','text','String','Above Bottom (m)',...
    'BackgroundColor','White',...
    'units','normalized',...
    'HorizontalAlignment','left',...
    'fontangle','italic',...
    'position',[0.07 0.65 0.3 0.05]);
wc_proc_tab_comp.r_bot = uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','edit','String','0',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.35 0.65 0.1 0.05],...
    'Callback',{@check_fmt_box,-Inf,Inf,1,'%.1f'});
text_badpings = uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','text','String','Bad pings (%)',...
    'BackgroundColor','White',...
    'units','normalized',...
    'HorizontalAlignment','left',...
    'fontangle','italic',...
    'position',[0.53 0.75 0.3 0.05]);
wc_proc_tab_comp.mask_badpings = uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','edit','String','100',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.75 0.75 0.1 0.05],...
    'Callback',{@check_fmt_box,0,100,100,'%.1f'});

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
uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','text','String','Grid resolution (m):',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.01 0.35 0.30 0.05]); % [0.05 0.35 0.3 0.05]);
uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','text','String','Horiz.',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.31 0.4 0.1 0.05]); % [0.35 0.4 0.1 0.05]);
wc_proc_tab_comp.grid_val = uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','edit',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.31 0.35 0.1 0.05],... % [0.35 0.35 0.1 0.05],...
    'String','0.25',...
    'Callback',{@check_fmt_box,0.1,100,1,'%.2f'});
uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','text','String','Vert.',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.42 0.4 0.1 0.05]); % [0.45 0.4 0.1 0.05]);
wc_proc_tab_comp.vert_grid_val = uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','edit',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.42 0.35 0.1 0.05],... % [0.45 0.35 0.1 0.05],...
    'String','1',...
    'Callback',{@check_fmt_box,0.1,100,1,'%.2f'});

% gridding type
uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','text','String','Grid type:',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.52 0.35 0.18 0.05]); % [0.05 0.28 0.3 0.05]);
wc_proc_tab_comp.dim_grid = uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','popup','String',{'2D' '3D'},...
    'Units','normalized',...
    'position',[0.70 0.37 0.15 0.05],... % [0.3 0.29 0.15 0.05],...
    'Value',1);

% gridding limitations
uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','text','String','Grid only data',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.01 0.28 0.20 0.05]);
wc_proc_tab_comp.grdlim_mode = uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','popup','String',{'between' 'outside of'},...
    'Units','normalized',...
    'position',[0.22 0.29 0.19 0.05],... 
    'Value',1);
wc_proc_tab_comp.grdlim_mindist = uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','edit',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.42 0.28 0.08 0.05],...
    'String','0',...
    'Callback',{@change_grdlim_mindist_cback,main_figure});
uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','text','String','&',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.50 0.28 0.04 0.05]);
wc_proc_tab_comp.grdlim_maxdist = uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','edit',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.54 0.28 0.08 0.05],...
    'String','inf',...
    'Callback',{@change_grdlim_maxdist_cback,main_figure});
uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','text','String','m in',...
    'BackgroundColor','White',...
    'units','normalized',...
    'position',[0.62 0.28 0.08 0.05]);
wc_proc_tab_comp.grdlim_var = uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','popup','String',{'depth below sonar' 'height above bottom'},...
    'Units','normalized',...
    'position',[0.70 0.29 0.30 0.05],... 
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
    tic
    % disp
    fprintf('Filtering bottom in file "%s" (%i/%i)...\n',fData_tot{i}.ALLfilename{1},u,numel(idx_fData));
    fprintf('...Started at %s...\n',datestr(now));
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
disp_config.Fdata_ID =fData_tot{idx_fData(end)}.ID;

% update the map, no zoom adjustment
up_wc=update_map_tab(main_figure,0,0,0,[]);
if up_wc>0
    update_wc_tab(main_figure);
    update_stacked_wc_tab(main_figure);
end

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
for i = idx_fData(:)'
    
    u = u+1;
    
    % disp
    fprintf('Processing file "%s" (%i/%i)...\n',fData_tot{i}.ALLfilename{1},u,numel(idx_fData));
    textprogressbar(sprintf('...Started at %s. Progress: ',datestr(now)));
    textprogressbar(0);
    tic
    
    % Data dimensions
    [nSamples, nBeams, nPings] = size(fData_tot{i}.(sprintf('%s_SBP_SampleAmplitudes',fData_tot{i}.MET_datagramSource)).Data.val);
    
    % original data filename and format info
    wc_dir = CFF_converted_data_folder(fData_tot{i}.ALLfilename{1});
    file_X_SBP_WaterColumnRaw  = fullfile(wc_dir,sprintf('%s_SBP_SampleAmplitudes.dat',fData_tot{i}.MET_datagramSource));
    wcdata_class  = fData_tot{i}.(sprintf('%s_1_SampleAmplitudes_Class',fData_tot{i}.MET_datagramSource)); % int8 or int16
    wcdata_factor = fData_tot{i}.(sprintf('%s_1_SampleAmplitudes_Factor',fData_tot{i}.MET_datagramSource));
    wcdata_nanval = fData_tot{i}.(sprintf('%s_1_SampleAmplitudes_Nanval',fData_tot{i}.MET_datagramSource));
    
    % processed data filename
    file_X_SBP_WaterColumnProcessed  = fullfile(wc_dir,'X_SBP_WaterColumnProcessed.dat');
    
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
    if exist(file_X_SBP_WaterColumnProcessed,'file') && ...
            isfield(fData_tot{i},'X_SBP_WaterColumnProcessed') && ...
            all(fData_tot{i}.X_SBP_WaterColumnProcessed.Format{2}==[nSamples,nBeams,nPings]) && ...
            strcmp(fData_tot{i}.X_1_WaterColumnProcessed_Class,wcdataproc_class) && ...
            fData_tot{i}.X_1_WaterColumnProcessed_Factor == wcdataproc_factor && ...
            (isnan(fData_tot{i}.X_1_WaterColumnProcessed_Nanval) || ...
            fData_tot{i}.X_1_WaterColumnProcessed_Nanval == wcdataproc_nanval)
        
        % Processed data file exists, is memmapped to fData, and the
        % dimensions and format as recorded in fData correspond to what we
        % want, it's ready for saving processed data through memmap.
        % Nothing else to do. 
        flag_memmap = 1;
        
    else
        
        % Processed data file doesn't exist yet or isn't mapped, or
        % recorded dimensions or file format don't correspond to what we
        % want... then redo from scratch.
        
        % First, Delete memmap field, and file if they exist
        if isfield(fData_tot{i},'X_SBP_WaterColumnProcessed')
            fData_tot{i} = rmfield(fData_tot{i},'X_SBP_WaterColumnProcessed');
        end
        if exist(file_X_SBP_WaterColumnProcessed,'file')
            delete(file_X_SBP_WaterColumnProcessed);
        end
        
        % Then, re-initialize
        if strcmp(saving_method,'low_precision')
            
            % copy original data file as processed data file
            copyfile(file_X_SBP_WaterColumnRaw,file_X_SBP_WaterColumnProcessed);
            
            % add to fData as a memmapfile
            fData_tot{i}.X_SBP_WaterColumnProcessed = memmapfile(file_X_SBP_WaterColumnProcessed, 'Format',{wcdataproc_class [nSamples nBeams nPings] 'val'},'repeat',1,'writable',true);
            
            % and record same info as original
            fData_tot{i}.X_1_WaterColumnProcessed_Class  = wcdataproc_class;
            fData_tot{i}.X_1_WaterColumnProcessed_Factor = wcdataproc_factor;
            fData_tot{i}.X_1_WaterColumnProcessed_Nanval = wcdataproc_nanval;
            
            % ready for data saving through memmap
            flag_memmap = 1;
            
        else
            
            % can't memmap something that don't exist yet, open the file
            % as binary and set the flag to write in it
            fid = fopen(file_X_SBP_WaterColumnProcessed,'w+');
            flag_memmap = 0;
            
        end
        
    end

    % block processing setup
    mem_struct = memory;
    blockLength = ceil(mem_struct.MemAvailableAllArrays/(nSamples*nBeams*8)/20);
    nBlocks = ceil(nPings./blockLength);
    blocks = [ 1+(0:nBlocks-1)'.*blockLength , (1:nBlocks)'.*blockLength ];
    blocks(end,2) = nPings;
    
    % processing per block of pings in file
    for iB = 1:nBlocks
        
        % list of pings in this block
        blockPings  = (blocks(iB,1):blocks(iB,2));
        
        % grab original data in dB
        data = CFF_get_WC_data(fData_tot{i},sprintf('%s_SBP_SampleAmplitudes',fData_tot{i}.MET_datagramSource),'iPing',blockPings,'output_format','true');
        
        % radiometric corrections
        % add a radio button to possibly turn this off too? TO DO XXX
        [data, warning_text] = CFF_WC_radiometric_corrections_CORE(data,fData_tot{i});
        
        % filtering sidelobe artefact
        if wc_proc_tab_comp.sidelobe.Value
            [data, correction] = CFF_filter_WC_sidelobe_artifact_CORE(data, fData_tot{i}, blockPings);
            % uncomment this for weighted gridding based on sidelobe
            % correction
            % fData_tot{i}.X_S1P_sidelobeArtifactCorrection(:,:,blockPings) = correction;
        end
        
        % masking data
        if wc_proc_tab_comp.masking.Value
            data = CFF_mask_WC_data_CORE(data, fData_tot{i}, blockPings, mask_angle, mask_closerange, mask_bottomrange, [], mask_ping);
        end
        
        % saving
        if flag_memmap
            
            % convert result back to raw format and store through memmap
            if wcdataproc_factor ~= 1
                data = data./wcdataproc_factor;
            end
            if ~isnan(wcdataproc_nanval)
                data(isnan(data)) = wcdataproc_nanval;
            end
            if strcmp(class(data),wcdataproc_class)
                fData_tot{i}.X_SBP_WaterColumnProcessed.Data.val(:,:,blockPings) = data;
            else
                fData_tot{i}.X_SBP_WaterColumnProcessed.Data.val(:,:,blockPings) = cast(data,wcdataproc_class);
            end
            
        else
            
            % write data to binary file
            fwrite(fid,data,wcdataproc_class);
            
        end
        
        % disp block processing progress
        textprogressbar(round(iB.*100./nBlocks)-1);

    end
    
    if ~flag_memmap
        
        % close
        fclose(fid);
        
        % add to fData as memmapfile
        fData_tot{i}.X_SBP_WaterColumnProcessed = memmapfile(file_X_SBP_WaterColumnProcessed, 'Format',{wcdataproc_class [nSamples nBeams nPings] 'val'},'repeat',1,'writable',true);
        
        % and record info
        fData_tot{i}.X_1_WaterColumnProcessed_Class  = wcdataproc_class;
        fData_tot{i}.X_1_WaterColumnProcessed_Factor = wcdataproc_factor;
        fData_tot{i}.X_1_WaterColumnProcessed_Nanval = wcdataproc_nanval;
        
    end

    % get folder for converted data and converted filename
    folder_for_converted_data = CFF_converted_data_folder(fData_tot{i}.ALLfilename{1});
    mat_fdata_file = fullfile(folder_for_converted_data,'fdata.mat');
    
    % save
    fData = fData_tot{i};
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
fprintf('Total time for processing: %f seconds (~%.2f minutes).\n',(timer_end-timer_start)*24*60*60,(timer_end-timer_start)*24*60);

setappdata(main_figure,'fData',fData_tot);

disp_config = getappdata(main_figure,'disp_config');
 
disp_config.Fdata_ID = fData_tot{idx_fData(end)}.ID;

% update the WC view to "Processed"
wc_tab_comp = getappdata(main_figure,'wc_tab');
wc_tab_strings = wc_tab_comp.data_disp.String;
[~,idx] = ismember('Processed',wc_tab_strings);
wc_tab_comp.data_disp.Value = idx;

update_wc_tab(main_figure);
update_stacked_wc_tab(main_figure,1); % force the update of stacked view

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
grid_type     = wc_proc_tab_comp.dim_grid.String{wc_proc_tab_comp.dim_grid.Value};
grdlim_mode    = wc_proc_tab_comp.grdlim_mode.String{wc_proc_tab_comp.grdlim_mode.Value};
grdlim_var     = wc_proc_tab_comp.grdlim_var.String{wc_proc_tab_comp.grdlim_var.Value};
grdlim_mindist = str2double(get(wc_proc_tab_comp.grdlim_mindist,'String'));
grdlim_maxdist = str2double(get(wc_proc_tab_comp.grdlim_maxdist,'String'));
dr_sub = 4;
db_sub = 2;

% init counter
u = 0;

% general timer
timer_start = now;

for i = idx_fData(:)'
    
    u = u+1;
    
    % disp
    fprintf('Gridding file "%s" (%i/%i)...\n',fData_tot{i}.ALLfilename{1},u,numel(idx_fData));
    fprintf('...Started at %s...\n',datestr(now));
    tic
    
    % gridding
    fData_tot{i} = CFF_grid_WC_data(fData_tot{i},...
        'grid_horz_res',grid_horz_res,...
        'grid_vert_res',grid_vert_res,...
        'grid_type',grid_type,...
        'dr_sub',dr_sub,...
        'db_sub',db_sub,...
        'grdlim_mode',grdlim_mode,...
        'grdlim_var',grdlim_var,...
        'grdlim_mindist',grdlim_mindist,...
        'grdlim_maxdist',grdlim_maxdist);
    
    % disp
    fprintf('...Done. Elapsed time: %f seconds.\n',toc);
    
    % get folder for converted data
    folder_for_converted_data = CFF_converted_data_folder(fData_tot{i}.ALLfilename{1});
    
    fData = fData_tot{i};
    
    % converted filename fData
    mat_fdata_file = fullfile(folder_for_converted_data,'fdata.mat');
    save(mat_fdata_file,'-struct','fData','-v7.3');
    clear fData;
    
end

% general timer
timer_end = now;
fprintf('Total time for gridding: %f seconds (~%.2f minutes).\n',(timer_end-timer_start)*24*60*60,(timer_end-timer_start)*24*60);

setappdata(main_figure,'fData',fData_tot);

disp_config = getappdata(main_figure,'disp_config');
disp_config.Fdata_ID = fData_tot{idx_fData(end)}.ID;


% update map with new grid, zoom on changed lines
up_wc = update_map_tab(main_figure,1,0,1,idx_fData);

% update WC view and stacked view
if up_wc>0
    update_wc_tab(main_figure);
    update_stacked_wc_tab(main_figure);
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
