function up_wc = update_map_tab(main_figure,varargin)
%UPDATE_MAP_TAB  Updates map tab in Espresso Map panel
%
%   See also CREATE_MAP_TAB, INITIALIZE_DISPLAY, ESPRESSO

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 11-11-2021

%% INIT

p = inputParser;
addOptional(p,'new_grid_flag',0);
addOptional(p,'new_mosaic_flag',0);
addOptional(p,'auto_zoom_extent_flag',0);
addOptional(p,'update_line_index',[]); % if empty update all lines
addOptional(p,'update_poly',0); % if empty update all lines
parse(p,varargin{:});
new_grid_flag         = p.Results.new_grid_flag;
new_mosaic_flag       = p.Results.new_mosaic_flag;
auto_zoom_extent_flag = p.Results.auto_zoom_extent_flag;
update_line_index     = p.Results.update_line_index;
update_poly           = p.Results.update_poly;

% up_wc will be 0 if the function finishes before updating all objects (ie.
% sliding windows etc), so that we do not open wc tabs in that case.
up_wc = 0;

% exit if no data loaded
fData_tot = getappdata(main_figure,'fData');

if isempty(fData_tot)
    return;
end

% get disp config
disp_config = getappdata(main_figure,'disp_config');

IDs = cellfun(@(c) c.ID,fData_tot);

if ~ismember(disp_config.Fdata_ID , IDs)
    disp_config.Fdata_ID = IDs(1);
    disp_config.Iping = 1;
    return;
end

fData = fData_tot{disp_config.Fdata_ID==IDs};

ip = disp_config.Iping;

if ip > numel(fData.X_1P_pingE)
    disp_config.Iping = 1;
    return;
end

% get map axes
map_tab_comp = getappdata(main_figure,'Map_tab');
ax = map_tab_comp.map_axes;

% initialize xlim and ylim for zoom extent
xlim = [nan nan];
ylim = [nan nan];


%% DISPLAY LINES' NAVIGATION AND GRIDS

% if empty update_line_index in input, take all available
if isempty(update_line_index)
    update_line_index = 1:length(fData_tot);
end

update_line_index(update_line_index>length(fData_tot)) = 1;
update_line_index = unique(update_line_index);

% set of active lines
fdata_tab_comp = getappdata(main_figure,'fdata_tab');
idx_active_lines = cell2mat(fdata_tab_comp.table.Data(:,3));

cax = [nan nan];
update_cax = 0;

for i = update_line_index(:)'
    
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
    
    
    %% Navigation tracks
    tag_id_nav = num2str(fData.ID,'%.0f_nav');
    obj = findobj(ax,'Tag',tag_id_nav);
    
    if isempty(obj)
        % line doesn't exist. To be drawn for the first time
        
        [~,fname,ext] = fileparts(fData.ALLfilename{1});
        user_data.Filename = [fname ext];
        
        % draw line navigation, with filename, ID, and callback when
        % clicking on it
        handle_plot_1 = plot(ax,fData.X_1P_pingE,fData.X_1P_pingN,...
            'Tag',tag_id_nav,...
            'Visible','on',...
            'Color',nav_col,...
            'ButtonDownFcn',{@disp_wc_ping_cback,main_figure},...
            'UserData',user_data);
        
        % draw points every dt seconds as subsampled navigation
        dt = 120; % in seconds
        % tt = nanmean(diff(fData.X_1P_pingTSMIM/1e3));
        idx_f = mod(floor(fData.X_1P_pingTSMIM/1e2)/10,dt)==0;
        idx_f(1) = 1;
        idx_f(end) = 1;
        
        handle_plot_2 = plot(ax,fData.X_1P_pingE(idx_f),fData.X_1P_pingN(idx_f),'.',...
            'Tag',tag_id_nav,...
            'Visible','on',...
            'Color',nav_col,...
            'ButtonDownFcn',{@disp_wc_ping_cback,main_figure},...
            'UserData',user_data);
        
        % combine the two
        handle_plot = [handle_plot_1 handle_plot_2];
        
        % set pointer interaction with the line
        pointerBehavior.enterFcn    = []; % Called when the mouse pointer moves over the object.
        pointerBehavior.exitFcn     = @(src, evt) exit_plot_fcn(src, evt,handle_plot); % Called when the mouse pointer leaves the object.
        pointerBehavior.traverseFcn = @(src, evt) traverse_plot_fcn(src, evt,handle_plot); % Called once when the mouse pointer moves over the object, and called again each time the mouse moves within the object.
        iptSetPointerBehavior(handle_plot,pointerBehavior);
        
        % draw circle as start of line
        plot(ax,fData.X_1P_pingE(1),fData.X_1P_pingN(1),'o','Tag',tag_id_nav,'Visible','on','Color',nav_col);
        
        % draw end of line
        plot(ax,fData.X_1P_pingE(end),fData.X_1P_pingN(end),'s','Tag',tag_id_nav,'Visible','on','Color',nav_col);
        
    else
        % line already exists, just set to proper color
        
        set(obj,'Visible','on');
        set(obj(arrayfun(@(x) strcmp(x.Type,'line'),obj)),'Color',nav_col);
        
    end
    
    
    %% Data being displayed
    tag_id_wc = num2str(fData.ID,'%.0f_wc');
    obj_wc = findobj(ax,'Tag',tag_id_wc);
    
    % if new grid was computed delete existing image object before
    % recreating it
    if new_grid_flag
        delete(obj_wc);
        obj_wc = [];
    end
    
    if isempty(obj_wc) && ...
            ((isfield(fData,'X_1E_gridEasting')&&strcmpi(disp_config.Var_disp,'wc_int'))||...
            ((isfield(fData,'X_1E_2DgridEasting')&&strcmpi(disp_config.Var_disp,'bs')))||...
            ((isfield(fData,'X_1E_2DgridEasting')&&strcmpi(disp_config.Var_disp,'bathy'))))
        
        % grab and adjust data to be displayed
        switch disp_config.Var_disp
            
            case 'wc_int'
                
                E = fData.X_1E_gridEasting;
                N = fData.X_N1_gridNorthing;
                
                % get vertical extent of 3D grid displayed
                display_tab_comp = getappdata(main_figure,'display_tab');
                d_lim_sonar_ref = [sscanf(display_tab_comp.d_line_min.Label,'%fm') sscanf(display_tab_comp.d_line_max.Label,'%fm')];
                d_lim_bottom_ref = [sscanf(display_tab_comp.d_line_bot_min.Label,'%fm') sscanf(display_tab_comp.d_line_bot_max.Label,'%fm')];
                
                % get data
                data = CFF_get_fData_wc_grid(fData,{'gridLevel'},d_lim_sonar_ref,d_lim_bottom_ref);
                data = data{1};
                if isa(data,'gpuArray')
                    data = gather(data);
                end
                
            case 'bathy'
                
                E = fData.X_1E_2DgridEasting;
                N = fData.X_N1_2DgridNorthing;
                data = fData.X_NE_bathy;
                
            case 'bs'
                
                E = fData.X_1E_2DgridEasting;
                N = fData.X_N1_2DgridNorthing;
                data = fData.X_NE_bs;
                
            otherwise
                % other cases perhaps for later devpt
                E = fData.X_1E_2DgridEasting;
                N = fData.X_N1_2DgridNorthing;
                data = nan(numel(N),numel(E));
                
        end
        
        % data display
        if ~isempty(E)
            obj_wc = imagesc(ax,E,N,data,'Visible',wc_vis,'Tag',tag_id_wc);
        end
        
        % NOTE: used to allow clicking on a grid to select a line/ping for
        % display but this conflicts with panning
        % obj_wc = imagesc(ax,E,N,data,'Visible',wc_vis,'Tag',tag_id_wc,'ButtonDownFcn',{@disp_wc_ping_cback,main_figure});
        
        update_cax = 1;
        
    else
        % data already exists, just make visible if disp is checked
        
        set(obj_wc,'Visible',wc_vis);
        
    end
    
    % push grid to the bottom of the display stack so navigation is ontop
    uistack(obj_wc,'bottom');
    
    %% Calculate zoom extents
    if idx_active_lines(i)
        
        if isfield(fData,'X_NEH_gridLevel') && ~isempty(fData.X_NEH_gridLevel)
            
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

%% update map colour scale
if update_cax > 0
    
    switch disp_config.Var_disp
        
        case 'wc_int'
            cax = disp_config.get_cax();
            
        case {'bathy' 'bs'}
            obj_wc_img = findobj(ax,'Type','image');
            if ~isempty(obj_wc_img)
                for uii = 1:numel(obj_wc_img)
                    if contains(obj_wc_img(uii).Tag,'_wc') && strcmpi(obj_wc_img(uii).Visible,'On')
                        data = obj_wc_img(uii).CData;
                        cax = [nanmin(prctile(data(:),2),cax(1)) nanmax(prctile(data(:),95),cax(2))];
                        if all(cax==0)
                            cax = [0 1];
                        end
                    end
                end
                
            end
    end
    
end

if all(~isnan(cax))
    switch disp_config.Var_disp
        case 'wc_int'
            disp_config.Cax_wc_int = cax;
        case 'bs'
            disp_config.Cax_bs = cax;
        case 'bathy'
            disp_config.Cax_bathy = cax;
    end
end


%% MOSAICS

mosaics = getappdata(main_figure,'mosaics');
mosaic_tab_comp = getappdata(main_figure,'mosaic_tab');

if ~isempty(mosaic_tab_comp.table_main.Data)
    idx_active_mosaics = cell2mat(mosaic_tab_comp.table_main.Data(:,3));
else
    idx_active_mosaics = [];
end

for imosaic = 1:numel(mosaics)
    
    % get this mosaic
    mosaic = mosaics(imosaic);
    
    % mosaic box
    tag_id_box = num2str(mosaic.ID,'%.0f_box');
    obj_box = findobj(ax,'Tag',tag_id_box);
    if isempty(obj_box)
        % not created yet, create now
        rectangle(ax,'Position',[mosaic.E_lim(1),mosaic.N_lim(1),diff(mosaic.E_lim),diff(mosaic.N_lim)],'Tag',tag_id_box,'EdgeColor','b');
    else
        % already exists. Update position in case of (but this should not
        % change as these limits are set at creation and never updated
        % after
        % set(obj_box,'Position',[mosaic.E_lim(1),mosaic.N_lim(1),diff(mosaic.E_lim),diff(mosaic.N_lim)]);
    end
    
    % get the mosaic object
    tag_id_mosaic = num2str(mosaic.ID,'%.0f_mosaic');
    obj_mosaic = findobj(ax,'Tag',tag_id_mosaic);
    
    % if mosaic was updated, delete the existing image object before
    % recreating it
    if new_mosaic_flag
        delete(obj_mosaic);
        obj_mosaic = [];
    end
    
    % compute X and Y vectors and alphadata
    [numElemGridN,numElemGridE] = size(mosaic.mosaic_level);
    mosaicEasting  = (0:numElemGridE-1) .*mosaic.res + mosaic.E_lim(1);
    mosaicNorthing = (0:numElemGridN-1)'.*mosaic.res + mosaic.N_lim(1);
    alphadata = mosaic.mosaic_level>disp_config.Cax_wc_int(1);
    
    if isempty(obj_mosaic)
        % mosaic does not exist yet or was deleted. (re)Create now.
        
        % the mosaic object used to have the panning interaction but now
        % it's the default behaviour on the map so remove it
        % obj_mosaic = imagesc(ax,mosaicEasting,mosaicNorthing,mosaic.mosaic_level,'Tag',tag_id_mosaic,'alphadata',alphadata,'ButtonDownFcn',{@move_map_cback,main_figure});
        obj_mosaic = imagesc(ax,mosaicEasting,mosaicNorthing,mosaic.mosaic_level,'Tag',tag_id_mosaic,'alphadata',alphadata);
    else
        % mosaic already exists.
        set(obj_mosaic,'XData',mosaicEasting,'YData',mosaicNorthing,'CData',mosaic.mosaic_level,'alphadata',alphadata);
    end
    
    % set the appropriate visibility
    if idx_active_mosaics(imosaic)
        set(obj_mosaic,'Visible','on');
    else
        set(obj_mosaic,'Visible','off');
    end
    
    % set image at bottom of stack display (aka, under the line grids)
    uistack(obj_mosaic,'bottom');
    
end


%% IF NO LINE IS ACTIVE, STOP HERE
if ~any(idx_active_lines)
    map_tab_comp.ping_window.Visible = 'off';
    set(map_tab_comp.ping_swathe,'XData',nan,'YData',nan);
    return;
else
    map_tab_comp.ping_window.Visible = 'on';
end

%% SLIDING WINDOW POLYGON

IDs = cellfun(@(c) c.ID,fData_tot);
if ~ismember(disp_config.Fdata_ID,IDs)
    return;
end
fData = fData_tot{disp_config.Fdata_ID==IDs};

% update sliding window polygon only if...
if update_poly || ... % forcing update
        ~isfield(map_tab_comp.ping_window.UserData,'idx_pings') || ... % polygon doesn't exist yet
        disp_config.Fdata_ID~=map_tab_comp.ping_window.UserData.ID || ... % we changed line
        ~any(ip==map_tab_comp.ping_window.UserData.idx_pings) % ping is outside current polygon
    
    % data type
    display_tab_comp = getappdata(main_figure,'display_tab');
    wc_str = display_tab_comp.data_disp.String;
    str_disp = wc_str{display_tab_comp.data_disp.Value};
    
    % get polygon vertices and indeices of pings and beams
    [new_vert,idx_pings,idx_angles] = poly_vertices_from_fData(fData,disp_config,[]);
    
    % save all of these in UserData for later retrieval in stacked view
    UserData = struct();
    UserData.ID = fData.ID;
    UserData.str_disp = str_disp;
    UserData.idx_pings  = idx_pings;
    UserData.idx_angles = idx_angles;
    map_tab_comp.ping_window.UserData = UserData;
    
    % update vertices and tag in sliding window polygon
    map_tab_comp.ping_window.Shape.Vertices = new_vert;
    map_tab_comp.ping_window.Tag = sprintf('%.0f0_pingwindow',fData.ID);
    
    % update xlim and ylim
    if ~isempty(new_vert)
        xlim(1) = nanmin(xlim(1),nanmin(new_vert(:,1)));
        xlim(2) = nanmax(xlim(2),nanmax(new_vert(:,1)));
        ylim(1) = nanmin(ylim(1),nanmin(new_vert(:,2)));
        ylim(2) = nanmax(ylim(2),nanmax(new_vert(:,2)));
    end
end


%% CURRENT PING SWATH LINE

set(map_tab_comp.ping_swathe,'XData',fData.X_BP_bottomEasting(:,ip),'YData',fData.X_BP_bottomNorthing(:,ip));

% update xlim and ylim
xlim(1) = nanmin(xlim(1),nanmin(fData.X_BP_bottomEasting(:,ip)));
xlim(2) = nanmax(xlim(2),nanmax(fData.X_BP_bottomEasting(:,ip)));
ylim(1) = nanmin(ylim(1),nanmin(fData.X_BP_bottomNorthing(:,ip)));
ylim(2) = nanmax(ylim(2),nanmax(fData.X_BP_bottomNorthing(:,ip)));

% set ping swathe back ontop so it can be grabbed
uistack(map_tab_comp.ping_swathe,'top');


%% ZOOM VIEW ADJUST
if auto_zoom_extent_flag>0 && all(~isnan(xlim)) && all(~isnan(ylim))
    
    % get current window size ratio
    pos = getpixelposition(ax);
    ratio_window = pos(4)/pos(3);
    
    ratio_data = diff(ylim)/diff(xlim);
    
    if ratio_data > ratio_window
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


% %% xlabel and ylabel
% ytick = get(ax,'ytick');
% xtick = get(ax,'xtick');
% zone = disp_config.get_zone();
% [lat,~] = utm2ll(xtick,ylim(1)*ones(size(xtick)),zone);
% [~,lon] = utm2ll(xlim(1)*ones(size(ytick)),ytick,zone);
% lon(lon>180) = lon(lon>180)-360;
% fmt = '%.2f';
% [~,x_labels] = cellfun(@(x,y) latlon2str(x,y,fmt),num2cell(lon),num2cell(lon),'un',0);
% [y_labels,~] = cellfun(@(x,y) latlon2str(x,y,fmt),num2cell(lat),num2cell(lat),'un',0);
% set(ax,'yticklabel',y_labels);
% set(ax,'xticklabel',x_labels);

up_wc = 1;

end


%% SUBFUNCTIONS

%%
function traverse_plot_fcn(src,~,hplot)
%TRAVERSE_PLOT_FCN Called when mouse pointer on a line

set(src, 'Pointer', 'hand');
ax = ancestor(hplot(1),'axes');
cp = ax.CurrentPoint;
objt = findobj(ax,'Tag','tooltipt');
xlim = get(ax,'XLim');
dx = diff(xlim)/1e2;

txt = hplot(1).UserData.Filename; % tooltip text
ttpos = [cp(1,1)+dx,cp(1,2)]; % tooltip position

if isempty(objt)
    % tip doesn't exist yet, create it
    text(ax,ttpos(1),ttpos(2),txt,...
        'Tag','tooltipt',...
        'EdgeColor','k',...
        'BackgroundColor','y',...
        'VerticalAlignment','Bottom',...
        'Interpreter','none');
else
    % update existing tip's position and text
    set(objt,'Position',ttpos,...
        'String',txt);
end

end

%%
function exit_plot_fcn(src,~,hplot)
%EXIT_PLOT_FCN Called when mouse pointer leaves a line

set(src, 'Pointer', 'arrow');
ax = ancestor(hplot(1),'axes');
objt = findobj(ax,'Tag','tooltipt');
delete(objt);
end
