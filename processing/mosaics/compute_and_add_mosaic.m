function compute_and_add_mosaic(main_figure,E_lim,N_lim,mos_type)
%COMPUTE_AND_ADD_MOSAIC  One-line description
%
%   See also ESPRESSO.

%   Authors: Yoann Ladroit (NIWA, yoann.ladroit@niwa.co.nz) and Alex
%   Schimel (NIWA, alexandre.schimel@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

% get fData
fData_tot = getappdata(main_figure,'fData');
if isempty(fData_tot)
    disp('No mosaic created - no lines loaded');
    return
end

% restrict to selected lines
fdata_tab_comp = getappdata(main_figure,'fdata_tab');
idx_fData = find(cell2mat(fdata_tab_comp.table.Data(:,3)));
fData_tot = fData_tot(idx_fData);
if isempty(fData_tot)
    disp('No mosaic created - no lines selected');
    return
end

% find which fData can contribute to the mosaic.
idx_fDataKeep = false(size(fData_tot));
for iF = 1:numel(fData_tot)
    
    fData = fData_tot{iF};
    
    if ~isfield(fData,'X_1E_gridEasting')
        % fData does not have a grid
        continue
    end
    
    % a first easy check is compare the mosaic and grid boundaries to see
    % if they overlap
    E = fData.X_1E_gridEasting;
    N = fData.X_N1_gridNorthing;
    idx_keep_E = E>E_lim(1) & E<E_lim(2);
    idx_keep_N = N>N_lim(1) & N<N_lim(2);
    if ~any(idx_keep_E) || ~any(idx_keep_N)
        % no overlap
        continue
    end
    
    % It is still possible that the overlap area does not contain data, so
    % check for this too 
    
    % grab data and format if necessary
    L = fData.X_NEH_gridLevel;
    if isa(L,'gpuArray')
        L = gather(L);
    end
    if size(L,3)>1
        L = nanmean(L,3);
    end
    
    % check if overlap area contains data
    L(~idx_keep_N,:) = [];
    L(:,~idx_keep_E) = [];
    if all(isnan(L(:)))
        % no data within requested mosaic bounds for that fData
        continue;
    end
    
    % if here, it means this file can contribute to the mosaic
    idx_fDataKeep(iF) = true;
    
end

% mosaic requested outside of data available
if ~any(idx_fDataKeep)
    disp('No mosaic created - no data within requested bounds');
    return
end

% remove from fData_tot those that won't contribute to the mosaic
fData_tot = fData_tot(idx_fDataKeep);

% we can only grid data at the resolution that is the coarsest of the
% contributing grids
mosaicResolution = nanmax(cellfun(@(s)s.X_1_gridHorizontalResolution,fData_tot));

% initialize mosaic. Choose mode 'blend' (normal) or the new 'stitch'
mosaic_init = CFF_init_mosaic(E_lim,N_lim,mosaicResolution,'stitch');
mosaic_init.Fdata_ID = cellfun(@(s)s.ID,fData_tot);

% Code by Yoann. Not sure what these are about... Why does mosaicking needs
% those limits...
switch mos_type
    
    case '2D'
        display_tab_comp = getappdata(main_figure,'display_tab');
        d_lim_sonar_ref  = [sscanf(display_tab_comp.d_line_min.Label,'%fm');sscanf(display_tab_comp.d_line_max.Label,'%fm')];
        d_lim_bottom_ref = [sscanf(display_tab_comp.d_line_bot_min.Label,'%fm');sscanf(display_tab_comp.d_line_bot_max.Label,'%fm')];
        
    case '3D'
        wc_proc_tab_comp = getappdata(main_figure,'wc_proc_tab');
        fData_tot = getappdata(main_figure,'fData');

        d_max = 0;
        d_min = nan;
        
        d_max_bot = nan;
        d_min_bot = 0;
        
        for ui = 1:numel(fData_tot)
            d_min = nanmin(nanmin(fData_tot{ui}.X_BP_bottomHeight(:),d_min));
            d_max_bot = nanmax(d_max_bot,abs(d_min));
        end
        
        v_res = str2double(wc_proc_tab_comp.vert_grid_val.String);
        n_ref_bot = ceil(1/2*(d_max_bot-d_min_bot)/v_res);
        n_ref = ceil(1/2*(d_max-d_min)/v_res);
        d_ref_sonar  = linspace(d_min,d_max,n_ref);
        d_ref_bot  = linspace(d_min_bot,d_max_bot,n_ref_bot);
        d_lim_sonar_ref = [d_ref_sonar(1:end-1);d_ref_sonar(2:end)];
        d_lim_bottom_ref  = [d_ref_bot(1:end-1);d_ref_bot(2:end)];
        
end

% get existing mosaics
mosaics = getappdata(main_figure,'mosaics');

% compute sonar-referenced mosaics
for uir = 1:size(d_lim_sonar_ref,2)
    mosaic = compute_mosaic(mosaic_init,fData_tot,d_lim_sonar_ref(:,uir),[nan nan]);
    mosaic.name = sprintf('Sonar_ref_%.0f_%.0fm',d_lim_sonar_ref(1,uir),d_lim_sonar_ref(2,uir));
    mosaic.ID = str2double(datestr(now,'yyyymmddHHMMSSFFF'));
    if ~any(~isnan(mosaic.mosaic_level),'all')
        continue;
    end
    if numel(mosaics) >= 1
        id_g = mosaics(:).ID;
        idx_mosaic = find(id_g==mosaic.ID);
        if isempty(idx_mosaic)
            idx_mosaic = numel(mosaics)+1;
        end
        mosaics(idx_mosaic) = mosaic;
    else
        mosaics = mosaic;
    end
end

% compute bottom-referenced mosaics
for uir = 1:size(d_lim_bottom_ref,2)
    mosaic = compute_mosaic(mosaic_init,fData_tot,[nan nan],d_lim_bottom_ref(:,uir));
    mosaic.name = sprintf('Bottom_ref_%.0f_%.0fm',d_lim_bottom_ref(1,uir),d_lim_bottom_ref(2,uir));
    mosaic.ID = str2double(datestr(now,'yyyymmddHHMMSSFFF'));
    if ~any(~isnan(mosaic.mosaic_level),'all')
        continue;
    end
    if numel(mosaics) >= 1
        id_g = mosaics(:).ID;
        idx_mosaic = find(id_g==mosaic.ID);
        if isempty(idx_mosaic)
            idx_mosaic = numel(mosaics)+1;
        end
        mosaics(idx_mosaic) = mosaic;
    else
        mosaics = mosaic;
    end
    
end

% update mosaics in app
setappdata(main_figure,'mosaics',mosaics);

% update mosaic tab
update_mosaic_tab(main_figure);

% update map, calling for new mosaic. Adjusting zoom on lines that
% contributed to the mosaic
update_map_tab(main_figure,0,1,1,idx_fData);

end


