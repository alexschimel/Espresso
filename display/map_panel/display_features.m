function display_features(main_figure,IDs_to_up,axes_to_up)
%DISPLAY_FEATURES  Update display of features on map and other views
%
%   See also ESPRESSO.

%   Authors: Yoann Ladroit (NIWA, yoann.ladroit@niwa.co.nz) and Alex
%   Schimel (NIWA, alexandre.schimel@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

if ~iscell(IDs_to_up)
    IDs_to_up = {};
end


%% get fdata, current ping and pings to be displayed
disp_config = getappdata(main_figure,'disp_config');
fData_tot   = getappdata(main_figure,'fData');

if ~isempty(fData_tot)
    
    IDs = cellfun(@(c) c.ID,fData_tot);
    
    if ~ismember(disp_config.Fdata_ID , IDs)
        disp_config.Fdata_ID = IDs(1);
        disp_config.Iping = 1;
        return;
    end
    
    fData = fData_tot{disp_config.Fdata_ID ==IDs};
    
else
    fData = [];
end


%% get list of features from appdata
features = getappdata(main_figure,'features');
if ~isempty(features)
    features_id = {features(:).Unique_ID};
else
    features_id = {};
end


% get both map and stacked view axes
map_tab_comp         = getappdata(main_figure,'Map_tab');
wc_tab_comp          = getappdata(main_figure,'wc_tab');
stacked_wc_tab_comp  = getappdata(main_figure,'stacked_wc_tab');

if isempty(axes_to_up)
    ah_tot = [map_tab_comp.map_axes stacked_wc_tab_comp.wc_axes wc_tab_comp.wc_axes];
else
    ah_tot = gobjects(1,numel(axes_to_up));
    for iax = 1:numel(axes_to_up)
        switch axes_to_up{iax}
            case 'map'
                ah_tot(iax) = map_tab_comp.map_axes;
            case 'wc_tab'
                ah_tot(iax) = wc_tab_comp.wc_axes;
            case 'stacked_wc_tab'
                ah_tot(iax) = stacked_wc_tab_comp.wc_axes;
        end
    end
end

% repeat on both map then stacked view
for iax = 1:numel(ah_tot)
    
    % get axes
    ah = ah_tot(iax);
    
    % delete temporary polygon features if they're still there
    features_h = findobj(ah,{'tag','feature_tmp'});
    delete(features_h);
    
    % get current drawn features and their labels
    features_h = findobj(ah,{'tag','feature','-or','tag','feature_text'});
    
    switch ah.Tag
        case {'stacked_wc','wc'}
            delete(features_h);
            features_h=[];
    end
    % if a drawn feature is not in the list recorded in appdata, OR if a
    % drawn feature is in the list of features we want to update, delete
    % them.
    if ~isempty(features_h)
        id_disp = get(features_h,'UserData');
        id_rem = ~ismember(id_disp,features_id) | ismember(id_disp,IDs_to_up);
        delete(features_h(id_rem));
        features_h(id_rem) = [];
    end
    
    % get list of drawn features after that
    if ~isempty(features_h)
        id_disp = get(features_h,'UserData');
    else
        id_disp = {};
    end
    
    % features in appdata that are not drawn (or were deleted for
    % update) and need to be added
    features_to_add = ~contains(features_id,id_disp);
    features_id_to_add = features_id(features_to_add);
    
    % vectors of appropriate colors depending on whether features are
    % active or not
    idx_act = ismember(features_id,disp_config.Act_features);
    col_map = cell(1,numel(idx_act));
    col_map(idx_act) = {'r'};
    col_map(~idx_act) = {[0.1 0.1 0.1]};
    
    % get sliding polygon info (for calculation of intersection)
    if ~isempty(fData)
        usrdata = get(map_tab_comp.ping_window,'UserData');
        idx_pings = usrdata.idx_pings;
        ping_window_poly = map_tab_comp.ping_window.Shape;
    end
    
    % for each feature to add to the display
    for id = 1:numel(features_id_to_add)
        
        % index in "features" of this feature
        idf = find(strcmp(features_id,features_id_to_add{id}));
        
        switch ah.Tag
            case 'main'
                % on map
                
                % draw that feature in appropriate color
                features(idf).draw_feature(ah,col_map{id});
                
            case 'stacked_wc'
                % on stack view
                
                if ~isempty(fData)
                    % find intersection of feature with sliding polygon
                    [intersection,features_intersecting] = feature_intersect_polygon(features(idf),ping_window_poly);
                    
                    if isempty(features_intersecting)
                        % escape if no intersection. No polygon to draw on
                        % stacked view
                        continue;
                    end
                    
                    % colour of the intersecting polygon
                    if ismember(features_intersecting.Unique_ID,disp_config.Act_features)
                        col_stacked = 'r';
                    else
                        col_stacked = [0.1 0.1 0.1];
                    end
                    
                    % get coordinates of sliding polygon vertices
                    E_stacked = fData.X_1P_pingE(idx_pings);
                    N_stacked = fData.X_1P_pingN(idx_pings);
                    
                    % draw intersection of feature with sliding polygon on
                    % stacked view
                    draw_feature_on_stacked_display(stacked_wc_tab_comp.wc_axes,intersection,features_intersecting,E_stacked,N_stacked,col_stacked);
                end
                
            case 'wc'
                
                E = get(map_tab_comp.ping_swathe,'XData');
                N = get(map_tab_comp.ping_swathe,'YData');
                xdata = get(wc_tab_comp.bot_gh,'XData');
                
                if ismember(features(idf).Unique_ID,disp_config.Act_features)
                    col_wc = 'r';
                else
                    col_wc = [0.1 0.1 0.1];
                end
                
                if isempty(features(idf).Polygon)
                    % feature is  point
                    
                    dr = nanmax(diff(xdata));
                    dist = sqrt((E-features(idf).Point(1)).^2+(N-features(idf).Point(2)).^2);
                    [dist_min,idx_pt] = min(dist);
                    
                    if dist_min<dr*5
                        ibeam = xdata(idx_pt);
                    else
                        continue;
                    end
                    
                    draw_feature_on_fan_display(wc_tab_comp.wc_axes,features(idf),ibeam,[],col_wc);
                    
                else
                    % feature is a polygon
                    
                    poly_feat = features(idf).Polygon;
                    isin = inpolygon(E,N,poly_feat.Vertices(:,1),poly_feat.Vertices(:,2));
                    if any(isin)
                        ibeam = xdata(isin);
                    else
                        continue;
                    end
                    
                    draw_feature_on_fan_display(wc_tab_comp.wc_axes,features(idf),ibeam,find(isin),col_wc);
                end
                
                
                
        end
        
    end
end

end


%%
function draw_feature_on_fan_display(ax,feature,ibeam,isin,col)

range_lim = get(ax,'YLim');
new_feature = feature;

if ~isempty(feature.Polygon)
    % feature is a polygon
    
    iRange = [nanmax(-feature.Depth_max,range_lim(1)) nanmin(-feature.Depth_min,range_lim(2))];
    dibeam = diff(isin);
    id = find(dibeam>1);
    id = ibeam([1 id id+1 numel(dibeam)]);
    new_poly = [];
    
    for idi = 1:2:numel(id)
        p_tmp = polyshape([id(idi) id(idi) id(idi+1) id(idi+1)],[iRange(1) iRange(2) iRange(2) iRange(1)]);
        if ~isempty(new_poly)
            new_poly = union(p_tmp,new_poly);
        else
            new_poly = p_tmp;
        end
    end
    
    new_feature.Polygon = new_poly;
    
else
    % feature is a point
    
    ir = -0.5*(feature.Depth_max + feature.Depth_min);
    
    if ir < range_lim(1) || ir > range_lim(2)
        ir = 0.5*sum(range_lim);
    end
    
    new_feature.Point = [ibeam,ir];
    
end

new_feature.draw_feature(ax,col);

end


%%
function draw_feature_on_stacked_display(ax,intersection,feature,easting,northing,col)

% extents
range_lim = get(ax,'YLim');
ping_lim = get(ax,'XLim');

if isempty(feature.Polygon)
    % feature is a point
    
    % find closest ping nav to point
    [~,ip] = min(sqrt((intersection(1)-easting).^2+(intersection(2)-northing).^2),[],2);
    
    % default range will be half way between bounds recorded
    ir = 0.5*(feature.Depth_max+feature.Depth_min);
    
    % if this is outside of stack view, use half way through range
    % displayed
    if ir < range_lim(1) || ir > range_lim(2)
        ir = 0.5*sum(range_lim);
    end
    
    % copy the feature and jsut change its coordinates
    new_feature = feature;
    new_feature.Point = [ip+ping_lim(1)-1,ir];
    
    % trigger display method
    new_feature.draw_feature(ax,col);
    
    
else
    % feature is a polygon
    
    poly_regions = intersection.regions;
    
    for ireg = 1:numel(poly_regions)
        
        % find closest ping nav to each vertex
        [~,ip] = min(sqrt((poly_regions(ireg).Vertices(:,1)-easting).^2+(poly_regions(ireg).Vertices(:,2)-northing).^2),[],2);
        
        % get vertices in stack display
        iPings = [nanmin(ip) nanmax(ip)];
        iPings = iPings+ping_lim(1)-1;
        iRange = [nanmax(feature.Depth_min,range_lim(1)) nanmin(feature.Depth_max,range_lim(2))];
        
        % copy the feature and just change its coordinates
        new_feature = feature;
        new_feature.Polygon = polyshape([iPings(1) iPings(1) iPings(2) iPings(2)],[iRange(1) iRange(2) iRange(2) iRange(1)]);
        
        % trigger display method
        new_feature.draw_feature(ax,col);
        
    end
    
end

end

