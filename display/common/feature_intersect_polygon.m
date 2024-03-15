function [intersection,features_intersecting] = feature_intersect_polygon(feature,poly)
%FEATURE_INTERSECT_POLYGON  One-line description
%
%   See also ESPRESSO.

%   Copyright 2017-2021 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

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
