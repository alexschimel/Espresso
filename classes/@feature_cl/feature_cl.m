classdef feature_cl
    %FEATURE_CL  Information for Espresso features (polygon, points)
    %
    %   See also ESPRESSO.
    
    %   Copyright 2017-2024 Alexandre Schimel, Yoann Ladroit, NIWA
    %   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/
    
    properties
        Class = 'unidentified'; % Feature class name
        Depth_min = 0; % Minimum depth
        Depth_max = 1e4; % Maximum depth
        Description = ' '; % Free text
        ID = 1; % Auto-incremented integer to count features
        Point = [] ; % Two-element vector if the feature is a point, empty if a polygon
        Polygon = []; % Polyshape if the feature is a polygon, empty if a point
        shapefile = [];
        Unique_ID = char(java.util.UUID.randomUUID); % Unique ID defined at creation
        Zone = ' '; % UTM zone in numeric (minus if southern hemisphere)
    end
    
    methods
        
        function obj = feature_cl(varargin)
            % instantiation method
            
            % input parser
            p = inputParser;
            check_class = @(class) ismember(class,get_feature_class_list());
            addParameter(p,'Class','unidentified',check_class);
            addParameter(p,'Depth_min',0,@isnumeric);
            addParameter(p,'Depth_max',1e4,@isnumeric);
            addParameter(p,'Description',' ',@ischar);
            addParameter(p,'ID',1,@isnumeric);
            addParameter(p,'Point',[]);
            addParameter(p,'Polygon',[]);
            addParameter(p,'shapefile',[],@(x) isfile(x)||isempty(x));
            addParameter(p,'Unique_ID',char(java.util.UUID.randomUUID),@ischar);
            addParameter(p,'Zone',1,@isnumeric);
            parse(p,varargin{:});
            
            % add to object
            props = properties(obj);
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
        
        function geostruct = feature_to_geostruct(obj)
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
            
            geostruct = feature_to_geostruct(obj);
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


