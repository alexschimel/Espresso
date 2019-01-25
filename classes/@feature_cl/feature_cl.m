    %% feature_cl.m
%
% Class for Espresso features (polygon and points)
%
%% Help
%
% *PROPERTIES*
%
% * |Unique_ID|: Unique ID defined at creation.
% * |Class|: Class of object as per types xml file (Default: "unidentified").
% * |Description|: Free-text (Default: empty).
% * |Polygon|: Polyshape if the feature is a polygon, empty if a point (Default: empty).
% * |Point|: Two-element vector if the feature is a point, empty if a polygon (Default: empty).
% * |Zone|: UTM zone in numeric (minus if southern hemisphere) (Default: empty).
% * |Depth_min|: Minimum depth (Default: 0).
% * |Depth_max|: Maximum depth (Default: 1e4).
% * |ID|: Auto-incremented integer to count features (Default: 1).
%
% *METHODS*
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
classdef feature_cl
    
    properties
        % default properties
        Unique_ID = char(java.util.UUID.randomUUID);
        Class = 'unidentified'; % empty class by default
        Description = ' ';
        Polygon = []; % polyshape if the feature is a polygon, empty if a point
        Point = [] ; % two-element vector if the feature is a point, empty if a polygon
        Zone = ' '; % UTM zone
        Depth_min = 0;
        Depth_max = 1e4;
        ID = 1;
        shapefile = [];
    end
    
    methods
        
        function obj = feature_cl(varargin)
            % instantiation method
            
            % input parser
            p = inputParser;
            check_class = @(class) ismember(class,init_feature_class());
            addParameter(p,'Unique_ID',char(java.util.UUID.randomUUID),@ischar);
            addParameter(p,'Class','unidentified',check_class);
            addParameter(p,'Description',' ',@ischar);
            addParameter(p,'Zone',1,@isnumeric);
            addParameter(p,'Polygon',[]);
            addParameter(p,'Point',[]);
            addParameter(p,'Depth_min',0,@isnumeric);
            addParameter(p,'Depth_max',1e4,@isnumeric);
            addParameter(p,'ID',1,@isnumeric);
            addParameter(p,'shapefile',[],@(x) isfile(x)||isempty(x));
            parse(p,varargin{:});
            
            % get properties
            props = properties(obj);
            
            % add input properties to object
            for i = 1:length(props)
                if isfield(p.Results,props{i})
                    obj.(props{i}) = p.Results.(props{i});
                end
            end
            
            % if shapefile in input, add/replace properties with its properties
            if ~isempty(p.Results.shapefile)
                
                % read shapefile
                geostruct = shaperead(p.Results.shapefile);
                
                % get easting/northing in input zone
                [X,Y,utmzone] = ll2utm(geostruct.Y,geostruct.X);
                X(isnan(utmzone)) = [];
                Y(isnan(utmzone)) = [];
                utmzone(isnan(utmzone)) = [];
                utmzone = unique(utmzone);
                if numel(utmzone)>1
                    error('problem here')
                end
                
                switch geostruct.Geometry
                    case 'Polygon'
                        obj.Polygon = polyshape(X,Y);
                    case 'Point'
                        obj.Point = [X Y];
                end
                
                obj.Zone = utmzone;
                geostruct = rmfield(geostruct,'Zone');
                
                % add shapefile fields to obj
                fields = fieldnames(geostruct);
                for ii = 1:numel(fields)
                    if isprop(obj,fields{ii})
                        obj.(fields{ii}) = geostruct.(fields{ii});
                    end
                end
                
            end
            
            
        end
        
        function geostruct=feature_to_geostruct(obj)
            % save feature as shapefile
            
            if ~isempty(obj.Polygon)
                % feature is a polygon. Set polygon-specific properties
                
                [lat,lon] = utm2ll(obj.Polygon.Vertices(:,1),obj.Polygon.Vertices(:,2),obj.Zone);
                
                geostruct.Geometry = 'Polygon';
                geostruct.Lat = [lat;lat(1)];
                geostruct.Lon = [lon ;lon(1)];
                
            else
                % feature is a point. Set point-specific properties
                
                [lat,lon] = utm2ll(obj.Point(1),obj.Point(2),obj.Zone);
                
                geostruct.Geometry = 'Point';
                geostruct.Lat = lat;
                geostruct.Lon = lon;
                
            end
            
            % common porperties
            geostruct.BoundingBox = [[min(lon) min(lat)];[max(lon) max(lon)]];
            geostruct.Depth_min = obj.Depth_min;
            geostruct.Depth_max = obj.Depth_max;
            geostruct.Description = obj.Description;
            geostruct.Class = obj.Class;
            geostruct.ID = obj.ID;
            geostruct.Zone = obj.Zone;
            
        end
        
        function feature_to_shapefile(obj,folder)
            % save feature as shapefile
            
            geostruct=feature_to_geostruct(obj);
            % save that shapefile. Using Unique_ID for filename
            try
                if ~isfolder(folder)
                    mkdir(folder);
                end
                shapewrite(geostruct,fullfile(folder,obj.Unique_ID));
            catch
                warning('Could not use Map toolbox function shapewrite. Feature created but not saved.')
            end
            
        end
        
        function [h_p,h_t] = draw_feature(obj,ax,col)
            % draw finalized feature on the map
            
            if ~isempty(obj.Polygon)
                % feature is a polygon
                
                poly_regs = obj.Polygon.regions;
                h_p = gobjects(numel(poly_regs),1);
                h_t = gobjects(numel(poly_regs),1);
                
                for ireg = 1:numel(poly_regs)
                    
                    % polygon plot
                    h_p(ireg) = plot(ax,poly_regs(ireg), ...
                        'FaceColor',col,...
                        'parent',ax,...
                        'FaceAlpha',0.2,...
                        'EdgeColor',col,...
                        'LineWidth',1,...
                        'tag','feature',...
                        'UserData',obj.Unique_ID);
                    
                    % polygon label
                    h_t(ireg) = text(nanmean(poly_regs(ireg).Vertices(:,1)),nanmean(poly_regs(ireg).Vertices(:,2)),obj.disp_str(),...
                        'FontWeight','normal',...
                        'Fontsize',10,...
                        'HorizontalAlignment','center',...
                        'VerticalAlignment','middle',...
                        'Tag','feature_text',...
                        'color','k',...
                        'parent',ax,...
                        'UserData',obj.Unique_ID,...
                        'Clipping','on');
                end
                
            else
                % feature is a point
                
                % point plot
                h_p = plot(ax,obj.Point(1),obj.Point(2),...
                    'Color',col,...
                    'MarkerFaceColor',col,...
                    'parent',ax,...
                    'Marker','h',...
                    'MarkerSize',12,...
                    'tag','feature',...
                    'UserData',obj.Unique_ID);
                
                % point label
                h_t = text(obj.Point(1),obj.Point(2),['   ' obj.disp_str()],... % adding spaces to label to separate from marker
                    'FontWeight','normal',...
                    'Fontsize',10,...
                    'Tag','feature_text',...
                    'color','k',...
                    'parent',ax,...
                    'UserData',obj.Unique_ID,...
                    'Clipping','on');
            end
        end
        
        function str = disp_str(obj)
            % get label for feature drawing on map
            if isempty(obj.Description) || strcmp(obj.Description,' ')
                str = sprintf('%i. %s',obj.ID, obj.Class);
            else
                str = sprintf('%i. %s (%s)',obj.ID, obj.Class, obj.Description);
            end
        end
        
    end
    
end


