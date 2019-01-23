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
function draw_new_feature(~,~,main_figure)


% get data
disp_config = getappdata(main_figure,'disp_config');
fData_tot = getappdata(main_figure,'fData');
features = getappdata(main_figure,'features');
map_tab_comp = getappdata(main_figure,'Map_tab');

% exit if no data loaded yet
if isempty(fData_tot)
    return;
end

% ID for this new feature
if isempty(features)
    ID = 1;
else
    ID = nanmax([features(:).ID])+1;
end

% map axes
ah = map_tab_comp.map_axes;

% delete temporary features
features_h = findobj(ah,{'tag','feature_temp'});
delete(features_h);

% get current point and figures' current bounds
cp = ah.CurrentPoint;
x_lim = get(ah,'xlim');
y_lim = get(ah,'ylim');

% exit if current point outside bounds
if cp(1,1)<x_lim(1) || cp(1,1)>x_lim(end) || cp(1,2)<y_lim(1) || cp(1,2)>y_lim(end)
    return;
end

% get current point coordinates in latitude/longitude
zone = disp_config.get_zone();
[lat,lon] = utm2ll(cp(1,1),cp(1,2),zone);


%% core of function
switch main_figure.SelectionType
    
    case 'normal'
        % if first click was left-click, start a polygon
        
        % initializing a series of vertex coordinates starting with the current
        % point
        maxNumberVertices = 1e4;
        xinit = nan(1,maxNumberVertices);
        yinit = nan(1,maxNumberVertices);
        xinit(1) = cp(1,1);
        yinit(1) = cp(1,2);
        
        % initializing index of next vertex
        u = 2;
        
        % colour of lines when making a polygon
        col_line = 'r';
        
        % plot the polygon so far
        hp = plot(ah,xinit,yinit,'color',col_line,'linewidth',1,'Tag','feature_temp');
        
        % add coordinates as text
        txt = text(ah,cp(1,1),cp(1,2),sprintf('%.6f,%.6f',lat,lon),'color',col_line,'Tag','feature_temp');
        
        % now that a polygon has been started, replace figure callbacks for
        % mouse motion and mouse click to continue/finalize it
        replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2,'interaction_fcn',@wbmcb_ext);
        replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',@wbdcb_ext);
        
    case 'alt'
        % if first click was right-click or control-click, do a point
        
        % create a new point
        new_feature = feature_cl('Point',[cp(1,1) cp(1,2)],'Zone',zone,'ID',ID);
        
        % save as shapefile
        new_feature.feature_to_shapefile(fullfile(whereisroot,'feature_files'));
        
        % finalize new feature
        save_new_feature();
        
    otherwise
        
        return;
        
end




%% nested subfunctions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    function wbmcb_ext(~,~)
        % callback for when mouse is moving after a polygon is started
        
        % get current pointer location and temporarily add to polygon
        cp = ah.CurrentPoint;
        xinit(u) = cp(1,1);
        yinit(u) = cp(1,2);
        
        % update/create polygon plot
        if isvalid(hp)
            set(hp,'XData',xinit,'YData',yinit);
        else
            hp = plot(ah,xinit,yinit,'color',col_line,'linewidth',1,'Tag','feature_temp');
        end
        
        % get lat long of current point for coordinates display
        [lat,lon] = utm2ll(cp(1,1),cp(1,2),zone);
        
        % update/create coordinates text for current point
        if isvalid(txt)
            set(txt,'position',[cp(1,1) cp(1,2) 0],'string',sprintf('%.6f,%.6f',lat,lon));
        else
            txt = text(ah,cp(1,1),cp(1,2),sprintf('%.6f,%.6f',lat,lon),'color',col_line,'Tag','feature_temp');
        end
        
    end

    function wbdcb_ext(~,~)
        % callback for when clicking on a mouse button after polygon is
        % started
        
        switch main_figure.SelectionType
            
            case 'normal'
                % if left-click, add a vertex
                
                % check we're in map and remove those outside
                xinit(isnan(xinit)) = [];
                yinit(isnan(yinit)) = [];
                id_rem = xinit>x_lim(end) | xinit<x_lim(1) | yinit>y_lim(end) | yinit<y_lim(1);
                
                xinit(id_rem) = [];
                yinit(id_rem) = [];

                % update/create polygon plot
                if isvalid(hp)
                    set(hp,'XData',xinit,'YData',yinit);
                else
                    hp = plot(ah,xinit,yinit,'color',col_line,'linewidth',1,'Tag','feature_temp');
                end
                
                % and update index for next vertex
                u = length(xinit)+1;
                
            case 'open'
                % if double-click, complete the polygon
                
                % remove the last point?
                xinit(u) = NaN;
                yinit(u) = NaN;
                
                % finish the polygon
                finish_polygon(main_figure);
                
                % ?
                replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',{@draw_new_feature,main_figure});
                
                return;
                
            case 'alt'
                % if right-click or control-click, complete the polygon
                
                % finish the polygon
                finish_polygon(main_figure);
                
                % ?
                replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',{@draw_new_feature,main_figure});
                
                return;
                
        end
        
    end


    function finish_polygon(main_figure)
        % complete a polygon
        
        replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2);
        
        % if only 1 or 2 vertices, delete it as incomplete
        if u <= 2
            features_h = findobj(ah,{'tag','feature_temp'});
            delete(features_h);
            return;
        end
        
        % duplicate first vertex as last vertex to close polygon
        xinit(u+1) = xinit(1);
        yinit(u+1) = yinit(1);
        
        % remove all remaining nans
        xinit(isnan(xinit)|xinit==0) = [];
        yinit(isnan(yinit)|yinit==0) = [];
        
        % remove all points outside of the map
%         xinit(xinit>x_lim(end)) = x_lim(end);
%         xinit(xinit<x_lim(1)) = x_lim(1);
%         yinit(yinit>y_lim(end)) = y_lim(end);
%         yinit(yinit<y_lim(1)) = y_lim(1);
        
        % if only 1 or 2 vertices after that, delete the polygon as
        % incomplete
        if length(yinit) <= 2
            features_h = findobj(ah,{'tag','feature_temp'});
            delete(features_h);
            return;
        end
        
        % delete the lat/long text and the temporary polygon
        delete(txt);
        delete(hp);
        
        % create a polyshape object with polygon vertices. Note that a
        % polyshape seems to remove the last vertex that duplicates the
        % first
        poly = polyshape(xinit,yinit);
        
        % add it as a new feature
        new_feature = feature_cl('Polygon',poly,'Zone',disp_config.get_zone(),'ID',ID);
        
        % save as shapefile
        new_feature.feature_to_shapefile(fullfile(whereisroot,'feature_files'));
        
        % finalize new feature
        save_new_feature();
        
    end


    function save_new_feature()
        % finalize new feature
        
        % add new feature to the list of features
        if isempty(features)
            features = new_feature;
        else
            features = [features new_feature];
        end
        
        % save/overwrite features into main figure
        setappdata(main_figure,'features',features);
        
        % trigger an update of displaying features on map and stacked view
        display_features(main_figure,{},[]);
        
        % trigger an update of the feature list tab
        update_feature_list_tab(main_figure);
        
    end

end
