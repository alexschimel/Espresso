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
function update_map_tab(main_figure,new_res,new_zoom,idx_up)

map_tab_comp = getappdata(main_figure,'Map_tab');
fData_tot = getappdata(main_figure,'fData');
mosaics = getappdata(main_figure,'mosaics');

if isempty(fData_tot)
    return;
end

fdata_tab_comp = getappdata(main_figure,'fdata_tab');
mosaic_tab_comp = getappdata(main_figure,'mosaic_tab');
disp_config = getappdata(main_figure,'disp_config');

idx_active_lines = cell2mat(fdata_tab_comp.table.Data(:,3));

if ~isempty(mosaic_tab_comp.table_main.Data)
    idx_active_lines_mosaic = cell2mat(mosaic_tab_comp.table_main.Data(:,3));
else
    idx_active_lines_mosaic = [];
end

ax = map_tab_comp.map_axes;

% initialize xlim and ylim
xlim = [nan nan];
ylim = [nan nan];

if isempty(idx_up)
    idx_up = 1:length(fData_tot);
end


%% Display of navigation and grids
for i = idx_up
    
    % settings for navigation lines
    if idx_active_lines(i)
        % selected line
        wc_vis = 'on';
        nav_col = [0 0 0]; % black
    else
        % unselected line
        wc_vis = 'off';
        nav_col = [0.7 0.7 0.7]; % very light gray
    end
    
    % get data
    fData = fData_tot{i};
    
    % get line ID
    tag_id_line = num2str(fData.ID,'%.0f_line');
    obj_line = findobj(ax,'Tag',tag_id_line);
    set(obj_line,'Visible',wc_vis);
    
    
    %% Navigation
    tag_id = num2str(fData.ID,'%.0f');
    obj = findobj(ax,'Tag',tag_id);
    
    if isempty(obj)
        % line to be drawn for the first time
        
        % draw line navigation and ID it
        handle_plot = plot(ax,fData.X_1P_pingE,fData.X_1P_pingN,'Tag',tag_id,'Visible','on','Color',nav_col,'ButtonDownFcn',{@disp_wc_ping_cback,main_figure});
        
        % set hand pointer when on that line
        pointerBehavior.enterFcn    = @(figHandle, currentPoint) set(figHandle, 'Pointer', 'hand');
        pointerBehavior.exitFcn     = @(figHandle, currentPoint) set(figHandle, 'Pointer', 'hand');
        pointerBehavior.traverseFcn = @(figHandle, currentPoint) set(figHandle, 'Pointer', 'hand');
        iptSetPointerBehavior(handle_plot,pointerBehavior);
        
        % draw circle as start of line
        plot(ax,fData.X_1P_pingE(1),fData.X_1P_pingN(1),'o','Tag',tag_id,'Visible','on','Color',nav_col);
       
        % draw dots as subsampled navigation
        df = 10;
        plot(ax,[fData.X_1P_pingE(1:df:end),fData.X_1P_pingE(end)],[fData.X_1P_pingN(1:df:end),fData.X_1P_pingN(end)],'.','Tag',tag_id,'Visible','on','Color',nav_col);
        
        % draw end of line
        % plot(ax,fData.X_1P_pingE(end),fData.X_1P_pingN(end),'s','Tag',tag_id,'Visible','on','Color',nav_col);
        
    else
        % line already exists, just make visible
        
        set(obj,'Visible','on');
        set(obj(arrayfun(@(x) strcmp(x.Type,'line'),obj)),'Color',nav_col);
        
    end
    
    
    %% Processed water column grid
    tag_id_wc   = num2str(fData.ID,'%.0f_wc');
    obj_wc = findobj(ax,'Tag',tag_id_wc);
    
    % if requesting a new resolution, delete existing grid
    if new_res
        delete(obj_wc);
        obj_wc = [];
    end

    if isempty(obj_wc) && isfield(fData,'X_NEH_gridLevel')
        % grid to be drawn for the first time
        
        % grab data
        E = fData.X_1E_gridEasting;
        N = fData.X_N1_gridNorthing;
        L = fData.X_NEH_gridLevel;
        
        % get vertical mean whether data is in 2D already or in 3D
        switch disp_config.Var_disp
            case 'wc_int'
                if size(L,3)>1
                    data = pow2db_perso(nanmean(10.^(L/10),3));
                else
                    data = L;
                end
                
            % other cases perhaps for later devpt
            case 'bathy'
                data = nanmean(L,3);
            case 'bs'
                data = nanmean(L,3);
        end
        
        % draw grid as imagesc. Tag appropriately
        % temporary removing the callback here as I don't think it's
        % necessary anymore since we added panning to the entire map
        % obj_wc = imagesc(ax,E,N,data,'Visible',wc_vis,'Tag',tag_id_wc,'ButtonDownFcn',{@disp_wc_ping_cback,main_figure});
        obj_wc = imagesc(ax,E,N,data,'Visible',wc_vis,'Tag',tag_id_wc);
        
    else
        % grid already exists, just make visible if needed
        
        set(obj_wc,'Visible',wc_vis);

    end
    
    % grid transparency
    data = get(obj_wc,'CData');
    switch disp_config.Var_disp
        case 'wc_int'
            alphadata = data > disp_config.Cax_wc_int(1);
        case 'bathy'
            alphadata = ones(size(data));
        case 'bs'
            alphadata = ones(size(data));
    end
    set(obj_wc,'alphadata',alphadata);
    
    % push grid to the bottom of the display stack so navigation is ontop
    uistack(obj_wc,'bottom');
    
    
    %% Calculate zoom extents
    if idx_active_lines(i)
        
        if isfield(fData,'X_NEH_gridLevel')
            
            xlim(1) = nanmin(xlim(1),nanmin(fData.X_1E_gridEasting(:)));
            xlim(2) = nanmax(xlim(2),nanmax(fData.X_1E_gridEasting(:)));
            ylim(1) = nanmin(ylim(1),nanmin(fData.X_N1_gridNorthing(:)));
            ylim(2) = nanmax(ylim(2),nanmax(fData.X_N1_gridNorthing(:)));
            
        elseif isfield(fData,'X_1P_pingE')
            
            xlim(1) = nanmin(xlim(1),nanmin(fData.X_1P_pingE(:)));
            xlim(2) = nanmax(xlim(2),nanmax(fData.X_1P_pingE(:)));
            ylim(1) = nanmin(ylim(1),nanmin(fData.X_1P_pingN(:)));
            ylim(2) = nanmax(ylim(2),nanmax(fData.X_1P_pingN(:)));
            
        end
        
    end
    
end

% in case no lines are active, set the ping swathe line to nan
if nansum(idx_active_lines) == 0
    set(map_tab_comp.ping_swathe,'XData',nan,'YData',nan);
end


%% MOSAICS
for imosaic = 1:numel(mosaics)
    
    if idx_active_lines_mosaic(imosaic)
        vis = 'on';
    else
        vis = 'off';
    end
    
    mosaic = mosaics(imosaic);
    tag_id_mosaic = num2str(mosaic.ID,'%.0f_mosaic');
    tag_id_box = num2str(mosaic.ID,'%.0f_box');
    [numElemGridN,numElemGridE] = size(mosaic.mosaic_level);
    mosaicEasting  = (0:numElemGridE-1) .*mosaic.res + mosaic.E_lim(1);
    mosaicNorthing = (0:numElemGridN-1)'.*mosaic.res +mosaic.N_lim(1);
    alphadata = mosaic.mosaic_level>disp_config.Cax_wc_int(1);
    obj_mosaic = findobj(ax,'Tag',tag_id_mosaic);
    obj_box = findobj(ax,'Tag',tag_id_box);
    
    if isempty(obj_box)
        rectangle(ax,'Position',[mosaic.E_lim(1),mosaic.N_lim(1),diff(mosaic.E_lim),diff(mosaic.N_lim)],'Tag',tag_id_box,'EdgeColor','b');
    else
        set(obj_box,'Position',[mosaic.E_lim(1),mosaic.N_lim(1),diff(mosaic.E_lim),diff(mosaic.N_lim)]);
    end
    
    if new_res
        delete(obj_mosaic);
        obj_mosaic = [];
    end
    
    if isempty(obj_mosaic)
        obj_mosaic = imagesc(ax,mosaicEasting,mosaicNorthing,mosaic.mosaic_level,'Tag',tag_id_mosaic,'alphadata',alphadata,'ButtonDownFcn',{@move_map_cback,main_figure});
    else
        set(obj_mosaic,'XData',mosaicEasting,'YData',mosaicNorthing,'CData',mosaic.mosaic_level,'alphadata',alphadata);
    end
    
    set(obj_mosaic,'Visible',vis);
    uistack(obj_mosaic,'bottom');
    
end

cax = disp_config.get_cax();
caxis(ax,cax);

if ~any(idx_active_lines)
    return;
end

%% set the zoom extent
if new_zoom>0 && all(~isnan(xlim)) && all(~isnan(ylim))
    
    % get current window size ratio
    pos = getpixelposition(ax);
    ratio_window = pos(4)/pos(3);
    
    ratio_data = diff(ylim)./diff(xlim);
    
    if ratio_data>ratio_window
        % ylim_new = [ylim(1) ylim(2)];
        ylim_new = [-diff(ylim),diff(ylim)]*1.2/2 + ylim(1) + diff(ylim)/2;
        dx = diff(ylim)/ratio_window;
        xlim_new = [-dx/2,dx/2] + xlim(1) + diff(xlim)/2;
    else
        % xlim_new = xlim;
        xlim_new = [-diff(xlim),diff(xlim)]*1.2/2 + xlim(1) + diff(xlim)/2;
        dy = diff(xlim)*ratio_window;
        ylim_new = [-dy/2,dy/2] + ylim(1) + diff(ylim)/2;
    end

    % set those new values to window
    set(ax,'YLim',ylim_new,'XLim',xlim_new);
       
end

% get current ticks position
ytick = get(ax,'ytick');
xtick = get(ax,'xtick');

disp_config = getappdata(main_figure,'disp_config');

zone = disp_config.get_zone();

[lat,~] = utm2ll(xtick,ylim(1)*ones(size(xtick)),zone);
[~,lon] = utm2ll(xlim(1)*ones(size(ytick)),ytick,zone);
lon(lon>180) = lon(lon>180)-360;

fmt = '%.2f';
[~,x_labels] = cellfun(@(x,y) latlon2str(x,y,fmt),num2cell(lon),num2cell(lon),'un',0);
[y_labels,~] = cellfun(@(x,y) latlon2str(x,y,fmt),num2cell(lat),num2cell(lat),'un',0);

% update strings
set(ax,'yticklabel',y_labels);
set(ax,'xticklabel',x_labels);

end


function db = pow2db_perso(pow)

pow(pow<0) = nan;
db = 10*log10(pow);

end