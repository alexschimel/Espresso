function [new_vert,idx_pings,idx_angles] = poly_vertices_from_fData(fData,disp_config,idx_pings_red)
%POLY_VERTICES_FROM_FDATA  Calculate variables of sliding window polygon
%
%   See also UPDATE_MAP_TAB, ESPRESSO.

%   Authors: Yoann Ladroit (NIWA, yoann.ladroit@niwa.co.nz) and Alex
%   Schimel (NIWA, alexandre.schimel@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

nPings = size(fData.X_BP_bottomEasting,2);
new_vert = [];
idx_angles = [];

% define the pings making up the window
if ~isempty(disp_config)
    ip = disp_config.Iping;
    idx_pings = ip-disp_config.StackPingWidth:ip+disp_config.StackPingWidth-1;
    idx_pings = idx_pings + nansum(idx_pings<1);
    idx_pings = idx_pings - nansum(idx_pings>nPings);
    idx_pings(idx_pings<1|idx_pings>nPings) = []; % crop the window to bounds
else
    idx_pings = 1:nPings;
end

% crop idx_pings to input
if ~isempty(idx_pings_red)
    idx_pings = intersect(idx_pings,idx_pings_red);
end

if isempty(idx_pings)
    return;
end

if isfield(fData,'X_PB_beamPointingAngleRad')
    
    % limit angles in radians
    if ~isempty(disp_config)
        angle_lim = [disp_config.StackAngularWidth(1)/180*pi disp_config.StackAngularWidth(2)/180*pi];
    else
        angle_lim = [-inf inf];
    end
    
    % indices of beams to keep for computation of stack view
    idx_angles = angle_lim(1)<=fData.X_PB_beamPointingAngleRad(:,idx_pings) & angle_lim(2)>=fData.X_PB_beamPointingAngleRad(:,idx_pings);
    
    % list the pings we'll actually use to form the rough polygon
    poly_vert_num = 20; % approximate max number of vertices composing the polygon on each side
    dp_sub = ceil(numel(idx_pings)./poly_vert_num); % decimation factor
    idx_poly_pings = unique([1:dp_sub:numel(idx_pings),numel(idx_pings)]);
    
    % get easting coordinates of sliding window polygon
    e_p = fData.X_BP_bottomEasting(:,idx_pings);
    e_p(~idx_angles) = NaN;
    e_p = e_p(:,idx_poly_pings);
    e_p = e_p(:,~all(isnan(e_p),1));
    e_p_s = arrayfun(@(col) e_p(find(~isnan(e_p(:, col)),1,'first'),col), 1:size(e_p,2), 'UniformOutput', 1);
    e_p_e = arrayfun(@(col) e_p(find(~isnan(e_p(:, col)),1,'last'),col), 1:size(e_p,2), 'UniformOutput', 1);
    
    % get northing coordinates of sliding window polygon
    n_p = fData.X_BP_bottomNorthing(:,idx_pings);
    n_p(~idx_angles) = NaN;
    n_p = n_p(:,idx_poly_pings);
    n_p = n_p(:,~all(isnan(n_p),1));
    n_p_s = arrayfun(@(col) n_p(find(~isnan(n_p(:, col)),1,'first'),col), 1:size(n_p,2), 'UniformOutput', 1);
    n_p_e = arrayfun(@(col) n_p(find(~isnan(n_p(:, col)),1,'last'),col), 1:size(n_p,2), 'UniformOutput', 1);
    
    % compiling vertices for polygon
    new_vert = [[e_p_s fliplr(e_p_e)];[n_p_s fliplr(n_p_e)]]';
    
    % if new_vert has only two vertices (will happen if fData has only one
    % ping), add another vertex between the two
    if size(new_vert,1)==2
        new_vert(3,:) = new_vert(2,:);
        new_vert(2,:) = (new_vert(1,:)+new_vert(3,:))./2;
    end
    
end