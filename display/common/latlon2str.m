function [lat_str,lon_str]=latlon2str(lat,lon,prec)
lon(lon>180)=lon(lon>180)-360;
if lat>0
    str_lat='N';
else
    str_lat='S';
end

if lon>180||lon<0
    str_lon='W';
else
    str_lon='E';
end

lat_str=sprintf(['%.0f^\\circ' prec ' %s'],abs(lat),(abs(lat)-floor(abs(lat)))*1e2,str_lat);
lon_str=sprintf(['%.0f^\\circ' prec ' %s'],abs(lon),(abs(lon)-floor(abs(lon)))*1e2,str_lon);

end