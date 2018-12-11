classdef feature_cl
    
    properties
        Unique_ID = char(java.util.UUID.randomUUID);
        Type =' ';
        Tag='Feature';
        Polygon =[];%empty if the feature is ponctual,  is a polyshape object otherwise
        Point=[];%empty if the feature is an area,  is a two-elt vector otherwise otherwise
        Projection=' ';
        Depth_min=0;
        Depth_max=inf;
        ID=1;
        
    end
    
    methods
        function obj = feature_cl(varargin)
            p = inputParser;
            
            check_type=@(type) ismember(type,init_feature_type());
            
            addParameter(p,'Unique_ID',char(java.util.UUID.randomUUID),@ischar);
            addParameter(p,'Type',' ',check_type);
            addParameter(p,'Tag','Feature',@ischar);
            addParameter(p,'Projection','',@ischar);
            addParameter(p,'Polygon',[]);
             addParameter(p,'Point',[]);
            addParameter(p,'Depth_min',0,@isnumeric);
            addParameter(p,'Depth_max',inf,@isnumeric);
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
        
        function  feature_to_shapefile(obj,fname)
            
              
%             if isempty(idx_pings)
%                 idx_pings=1:length(obj.Lat);
%             end
%             
%             [lat,lon]
%             geostruct.Geometry='Line';
%             geostruct.BoundingBox=[[min(obj.Long(idx_pings)) min(obj.Lat(idx_pings))];[max(obj.Long(idx_pings)) max(obj.Lat(idx_pings))]];
%             geostruct.Lat=obj.Lat(idx_pings);
%             geostruct.Lon=obj.Long(idx_pings);
%             geostruct.Date=datestr(nanmean(obj.Time(idx_pings)));
%              shapewrite()
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
            end
        end
        
        function  str=disp_str(obj)
            str=sprintf('%s %s (%d)',obj.Type,obj.Tag,obj.ID);
        end
        
        
    end
    
    
end


