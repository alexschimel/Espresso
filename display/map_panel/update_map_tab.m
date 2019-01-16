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
function update_map_tab(main_figure,varargin)


%% INTRO

% input parser
p = inputParser;
addOptional(p,'new_grid_flag',0);
addOptional(p,'new_mosaic_flag',0);
addOptional(p,'auto_zoom_extent_flag',0);
addOptional(p,'update_line_index',[]); % if empty update all lines
parse(p,varargin{:});
new_grid_flag = p.Results.new_grid_flag;
new_mosaic_flag = p.Results.new_mosaic_flag;
auto_zoom_extent_flag = p.Results.auto_zoom_extent_flag;
update_line_index = p.Results.update_line_index;

% exit if no data loaded
fData_tot = getappdata(main_figure,'fData');
if isempty(fData_tot)
    return;
end

% get disp config
disp_config = getappdata(main_figure,'disp_config');

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

% set of active lines
fdata_tab_comp = getappdata(main_figure,'fdata_tab');
idx_active_lines = cell2mat(fdata_tab_comp.table.Data(:,3));

for i = update_line_index
    
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
    
    %% Navigation
    tag_id_nav = num2str(fData.ID,'%.0f_nav');
    obj = findobj(ax,'Tag',tag_id_nav);
    
    if isempty(obj)
        % line to be drawn for the first time
        
        % draw line navigation and ID it
        handle_plot = plot(ax,fData.X_1P_pingE,fData.X_1P_pingN,'Tag',tag_id_nav,'Visible','on','Color',nav_col,'ButtonDownFcn',{@disp_wc_ping_cback,main_figure});
        
        % set hand pointer when on that line
        pointerBehavior.enterFcn    = @(figHandle, currentPoint) set(figHandle, 'Pointer', 'hand');
        pointerBehavior.exitFcn     = @(figHandle, currentPoint) set(figHandle, 'Pointer', 'hand');
        pointerBehavior.traverseFcn = @(figHandle, currentPoint) set(figHandle, 'Pointer', 'hand');
        iptSetPointerBehavior(handle_plot,pointerBehavior);
        
        % draw circle as start of line
        plot(ax,fData.X_1P_pingE(1),fData.X_1P_pingN(1),'o','Tag',tag_id_nav,'Visible','on','Color',nav_col);
       
        % draw dots as subsampled navigation
        df = 10;
        plot(ax,[fData.X_1P_pingE(1:df:end),fData.X_1P_pingE(end)],[fData.X_1P_pingN(1:df:end),fData.X_1P_pingN(end)],'.','Tag',tag_id_nav,'Visible','on','Color',nav_col);
        
        % draw end of line
        % plot(ax,fData.X_1P_pingE(end),fData.X_1P_pingN(end),'s','Tag',tag_id_nav,'Visible','on','Color',nav_col);
        
    else
        % line already exists, just set to proper color
        
        set(obj,'Visible','on');
        set(obj(arrayfun(@(x) strcmp(x.Type,'line'),obj)),'Color',nav_col);
        
    end
    
    
    %% Processed water column grid
    tag_id_wc = num2str(fData.ID,'%.0f_wc');
    obj_wc = findobj(ax,'Tag',tag_id_wc);
    
    % if new grid was computed delete existing image object before
    % recreating it
    if new_grid_flag
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
        obj_wc = imagesc(ax,E,N,data,'Visible',wc_vis,'Tag',tag_id_wc,'ButtonDownFcn',{@disp_wc_ping_cback,main_figure});
        
    else
        % grid already exists, just make visible if disp is checked
        
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

% set colour axis
cax = disp_config.get_cax();
caxis(ax,cax);



%% IF NO LINE IS ACTIVE, STOP HERE
if ~any(idx_active_lines)
    map_tab_comp.ping_window.Shape.Vertices = [NaN NaN];
    set(map_tab_comp.ping_swathe,'XData',nan,'YData',nan);
    return;
end




%% SLIDING WINDOW POLYGON

% get fdata of current line and current ping
fData       = fData_tot{disp_config.Fdata_idx};
ip          = disp_config.Iping;

% save info in usrdata as an ID
usrdata.ID = fData.ID;
wc_tab_comp  = getappdata(main_figure,'wc_tab');
wc_str = wc_tab_comp.data_disp.String;
str_disp = wc_str{wc_tab_comp.data_disp.Value};
usrdata.str_disp = str_disp;

% calculate pings making up the stack
idx_pings = ip-disp_config.StackPingWidth:ip+disp_config.StackPingWidth-1;
id_min = nansum(idx_pings<1);
idx_pings = idx_pings + id_min;
nb_pings = size(fData.X_BP_bottomEasting,2);
id_max = nansum(idx_pings>nb_pings);
idx_pings = idx_pings-id_max;
idx_pings(idx_pings<1|idx_pings>nb_pings) = [];

% indices of beams to keep for computation of stack view
idx_angles = ~( disp_config.StackAngularWidth(1)/180*pi<=fData.X_PB_beamPointingAngleRad(:,idx_pings) & disp_config.StackAngularWidth(2)/180*pi>=fData.X_PB_beamPointingAngleRad(:,idx_pings) );

% save all of these in usrdata for later retrieval in stacked view
usrdata.idx_pings  = idx_pings;
usrdata.idx_angles = idx_angles;

% next, list the pinge we'll actually use to form the rough polygon
ping_decimate_factor = 3;
dp_sub = ceil(numel(idx_pings)./ping_decimate_factor);
idx_poly_pings = unique([1:dp_sub:numel(idx_pings),numel(idx_pings)]);

% get easting coordinates of sliding window polygon
e_p = fData.X_BP_bottomEasting(:,idx_pings);
e_p(idx_angles) = NaN;
e_p = e_p(:,idx_poly_pings);
e_p = e_p(:,~all(isnan(e_p),1));
e_p_s = arrayfun(@(col) e_p(find(~isnan(e_p(:, col)),1,'first'),col), 1:size(e_p,2), 'UniformOutput', 1);
e_p_e = arrayfun(@(col) e_p(find(~isnan(e_p(:, col)),1,'last'),col), 1:size(e_p,2), 'UniformOutput', 1);

% get northing coordinates of sliding window polygon
n_p = fData.X_BP_bottomNorthing(:,idx_pings);
n_p(idx_angles) = NaN;
n_p = n_p(:,idx_poly_pings);
n_p = n_p(:,~all(isnan(n_p),1));
n_p_s = arrayfun(@(col) n_p(find(~isnan(n_p(:, col)),1,'first'),col), 1:size(n_p,2), 'UniformOutput', 1);
n_p_e = arrayfun(@(col) n_p(find(~isnan(n_p(:, col)),1,'last'),col), 1:size(n_p,2), 'UniformOutput', 1);

% compiling vertices for polygon
new_vert = [[e_p_s fliplr(e_p_e)];[n_p_s fliplr(n_p_e)]]';

% update vertices and tag in sliding window polygon
map_tab_comp.ping_window.Shape.Vertices = new_vert;
map_tab_comp.ping_window.Tag = sprintf('%.0f0_pingwindow',fData.ID);

% add usrdata for later retrieval in stacked view
map_tab_comp.ping_window.UserData = usrdata;

% update xlim and ylim
xlim(1) = nanmin(xlim(1),nanmin(new_vert(:,1)));
xlim(2) = nanmax(xlim(2),nanmax(new_vert(:,1)));
ylim(1) = nanmin(ylim(1),nanmin(new_vert(:,2)));
ylim(2) = nanmax(ylim(2),nanmax(new_vert(:,2)));


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
    
    ratio_data = diff(ylim)./diff(xlim);
    
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


%% xlabel and ylabel
ytick = get(ax,'ytick');
xtick = get(ax,'xtick');
zone = disp_config.get_zone();
[lat,~] = utm2ll(xtick,ylim(1)*ones(size(xtick)),zone);
[~,lon] = utm2ll(xlim(1)*ones(size(ytick)),ytick,zone);
lon(lon>180) = lon(lon>180)-360;
fmt = '%.2f';
[~,x_labels] = cellfun(@(x,y) latlon2str(x,y,fmt),num2cell(lon),num2cell(lon),'un',0);
[y_labels,~] = cellfun(@(x,y) latlon2str(x,y,fmt),num2cell(lat),num2cell(lat),'un',0);
set(ax,'yticklabel',y_labels);
set(ax,'xticklabel',x_labels);


end


function db = pow2db_perso(pow)

pow(pow<0) = nan;
db = 10*log10(pow);

end