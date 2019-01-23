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
function display_features(main_figure,IDs,axes_to_up)

% this function calls for an update of displaying desired features on map
% and stacked view 

if ~iscell(IDs)
    IDs = {};
end

%% get fdata, current ping and pings to be displayed
disp_config = getappdata(main_figure,'disp_config');
fData_tot   = getappdata(main_figure,'fData');
if ~isempty(fData_tot)
    fData = fData_tot{disp_config.Fdata_idx};
else
    fData = [];
end


%% get list of features from appdata
features     = getappdata(main_figure,'features');
if ~isempty(features)
    features_id = {features(:).Unique_ID};
else
    features_id = {};
end



% get both map and stacked view axes
map_tab_comp = getappdata(main_figure,'Map_tab');
stacked_wc_tab_comp  = getappdata(main_figure,'stacked_wc_tab');
wc_tab_comp  = getappdata(main_figure,'wc_tab');

if isempty(axes_to_up)
    ah_tot = [map_tab_comp.map_axes stacked_wc_tab_comp.wc_axes wc_tab_comp.wc_axes];
else
    ah_tot=gobjects(1,numel(axes_to_up));
    for iax=1:numel(axes_to_up)
       switch axes_to_up{iax}
           case 'map'
               ah_tot(iax)=map_tab_comp.map_axes;
           case 'wc_tab'
               ah_tot(iax)=wc_tab_comp.wc_axes;
           case 'stacked_wc_tab'
               ah_tot(iax)=stacked_wc_tab_comp.wc_axes;
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
        id_rem = ~ismember(id_disp,features_id) | ismember(id_disp,IDs);
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
                
                E=get(map_tab_comp.ping_swathe,'XData');
                N=get(map_tab_comp.ping_swathe,'YData');
                xdata=get(wc_tab_comp.bot_gh,'XData');
                if ismember(features(idf).Unique_ID,disp_config.Act_features)
                    col_wc = 'r';
                else
                    col_wc = [0.1 0.1 0.1];
                end
                
                if isempty(features(idf).Polygon)
                    dr=nanmax(diff(xdata));
                    dist=sqrt((E-features(idf).Point(1)).^2+(N-features(idf).Point(2)).^2);
                    [dist_min,idx_pt]=min(dist);
                    
                    if dist_min<dr*5
                        ibeam=xdata(idx_pt);
                    else
                        continue;
                    end
                else
                    poly_feat=features(idf).Polygon;
                    isin = inpolygon(E,N,poly_feat.Vertices(:,1),poly_feat.Vertices(:,2));
                    if any(isin)
                        ibeam=xdata(isin);
                    else 
                        continue;                       
                    end
                end
                
                draw_feature_on_fan_display(wc_tab_comp.wc_axes,features(idf),ibeam,col_wc);

        end
        
    end
end

end

%% Subfunctions

function draw_feature_on_fan_display(ax,feature,ibeam,col)
range_lim = get(ax,'YLim');
new_feature = feature;
if ~isempty(feature.Polygon)    
    iRange = [nanmax(-feature.Depth_max,range_lim(1)) nanmin(-feature.Depth_min,range_lim(2))];
    new_feature.Polygon = polyshape([ibeam(1) ibeam(1) ibeam(end) ibeam(end)],[iRange(1) iRange(2) iRange(2) iRange(1)]);
    
else
    ir = 0.5*(feature.Depth_max+feature.Depth_min);
    
    if ir < range_lim(1) || ir > range_lim(2)
        ir = 0.5*sum(range_lim);
    end
    new_feature.Point = [ibeam,ir];
        
end
new_feature.draw_feature(ax,col);
end

function [intersection,features_intersecting] = feature_intersect_polygon(feature,poly)

if isempty(feature.Polygon)
    % feature is a point
    
    isin = inpolygon(feature.Point(1),feature.Point(2),poly.Vertices(:,1),poly.Vertices(:,2));
    if isin
        intersection  = feature.Point;
        features_intersecting = feature;
    else
        intersection = [];
        features_intersecting = [];
    end
    
else
    % feature is a polygon
    
    intersection = intersect(feature.Polygon,poly);
    
    if ~isempty(intersection.Vertices)
        features_intersecting = feature;
    else
        features_intersecting = [];
    end
    
end

end



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
        
        % copy the feature and jsut change its coordinates
        new_feature = feature;
        new_feature.Polygon = polyshape([iPings(1) iPings(1) iPings(2) iPings(2)],[iRange(1) iRange(2) iRange(2) iRange(1)]);
        
        % trigger display method
        new_feature.draw_feature(ax,col);
        
    end
    
end

end

