classdef feature_cl
    
    properties
        Unique_ID = char(java.util.UUID.randomUUID);
        Type =' ';
        Tag='Feature';
        Polygon =[];%empty if the feature is ponctual,  is a polyshape object otherwise
        Point=[];%empty if the feature is an area,  is a two-elt vector otherwise otherwise
        Zone=' ';
        Depth_min=0;
        Depth_max=1e4;
        ID=1;
        
    end
    
    methods
        function obj = feature_cl(varargin)
            p = inputParser;
            
            check_type=@(type) ismember(type,init_feature_type());
            
            addParameter(p,'Unique_ID',char(java.util.UUID.randomUUID),@ischar);
            addParameter(p,'Type',' ',check_type);
            addParameter(p,'Tag','Feature',@ischar);
            addParameter(p,'Zone',1,@isnumeric);
            addParameter(p,'Polygon',[]);
             addParameter(p,'Point',[]);
            addParameter(p,'Depth_min',0,@isnumeric);
            addParameter(p,'Depth_max',1e4,@isnumeric);
            addParameter(p,'ID',1,@isnumeric);
            
            
            parse(p,varargin{:});
            results=p.Results;
            props=properties(obj);
            for i=1:length(props)
                if isfield(results,props{i})
                    obj.(props{i})=results.(props{i});
                end
            end
            
            
        end
        
        function  feature_to_shapefile(obj,folder)
            if ~isempty(obj.Polygon)
                [lat,lon] = utm2ll(obj.Polygon.Vertices(:,1),obj.Polygon.Vertices(:,2),obj.Zone);
                geostruct.Geometry='Polygon';
                geostruct.BoundingBox=[[min(lon) min(lat)];[max(lon) max(lon)]];
                geostruct.Lat=[lat;lat(1)];
                geostruct.Lon=[lon ;lon(1)];
            else
                [lat,lon] = utm2ll(obj.Point(1),obj.Point(2),obj.Zone);
                geostruct.Geometry='Point';
                geostruct.BoundingBox=[[min(lon) min(lat)];[max(lon) max(lon)]];
                geostruct.Lat=lat;
                geostruct.Lon=lon;
            end
            geostruct.Depth_min=obj.Depth_min;
            geostruct.Depth_max=obj.Depth_max;
            geostruct.Tag=obj.Tag;
            geostruct.Type=obj.Type;
            geostruct.ID=obj.ID;
            geostruct.Zone=obj.Zone;
            shapewrite(geostruct,fullfile(folder,obj.Unique_ID));
        end
         
%         function  obj=feature_from_shapefile(fname)
%             
%          end
        
        function  [h_p,h_t]=draw_feature(obj,ax,col)
            
            if ~isempty(obj.Polygon)
                h_p=plot(ax,obj.Polygon, 'FaceColor',col,...
                    'parent',ax,'FaceAlpha',0.2,...
                    'EdgeColor',col,...
                    'LineWidth',1,...
                    'tag','feature',...
                    'UserData',obj.Unique_ID);
                
                h_t=text(nanmean(obj.Polygon.Vertices(:,1)),nanmean(obj.Polygon.Vertices(:,2)),obj.disp_str(),'FontWeight','Bold','Fontsize',...
                    12,'Tag','feature_text','color','k','parent',ax,'UserData',obj.Unique_ID,'Clipping', 'on');
            else
                h_p=plot(ax,obj.Point(1),obj.Point(2), 'Color',col,...
                    'MarkerFaceColor',col,...
                    'parent',ax,'Marker','h',...
                    'MarkerSize',15,...
                    'tag','feature',...
                    'UserData',obj.Unique_ID);
                 h_t=text(obj.Point(1),obj.Point(2),obj.disp_str(),'FontWeight','Bold','Fontsize',...
                    12,'Tag','feature_text','color','k','parent',ax,'UserData',obj.Unique_ID,'Clipping', 'on');
            end
        end
        
        function  str=disp_str(obj)
            str=sprintf('%s %s (%d)',obj.Type,obj.Tag,obj.ID);
        end
        
        
    end
    
    
end


