function [new_vert,idx_pings,idx_angles] = poly_vertices_from_fData(fData,disp_config,idx_pings_red)

nb_pings = size(fData.X_BP_bottomEasting,2);
new_vert = [];
idx_angles = [];

if ~isempty(disp_config)
    ip = disp_config.Iping;
    % calculate pings making up the stack
    idx_pings = ip-disp_config.StackPingWidth:ip+disp_config.StackPingWidth-1;
    angle_lim = [disp_config.StackAngularWidth(1)/180*pi disp_config.StackAngularWidth(2)/180*pi];
else
    idx_pings = 1:nb_pings;
    angle_lim = [-inf inf];
end

id_min = nansum(idx_pings<1);
idx_pings = idx_pings + id_min;

id_max = nansum(idx_pings>nb_pings);
idx_pings = idx_pings-id_max;
idx_pings(idx_pings<1|idx_pings>nb_pings) = [];

if isempty(idx_pings)
    return;
end

if ~isempty(idx_pings_red)
    idx_pings = intersect(idx_pings,idx_pings_red);
end

if isfield(fData,'X_PB_beamPointingAngleRad')
    % indices of beams to keep for computation of stack view
    idx_angles = ~( angle_lim(1)<=fData.X_PB_beamPointingAngleRad(:,idx_pings) & angle_lim(2)>=fData.X_PB_beamPointingAngleRad(:,idx_pings) );
    
    
    % next, list the pinge we'll actually use to form the rough polygon
    poly_vert_num = 20; % approximate max number of vertices composing the polygon on each side
    dp_sub = ceil(numel(idx_pings)./poly_vert_num);
    idx_poly_pings = unique([1:dp_sub:numel(idx_pings),numel(idx_pings)]);
    
    % get easting coordinates of sliding window polygon
    e_p = fData.X_BP_bottomEasting(:,idx_pings);
    e_p(idx_angles) = NaN;
    e_p = e_p(:,idx_poly_pings);
    e_p = e_p(:,~all(isnan(e_p),1));
    e_p_s = arrayfun(@(col) e_p(find(~isnan(e_p(:, col)),1,'first'),col), 1:size(e_p,2), 'UniformOutput', 1);
    e_p_e = arrayfun(@(col) e_p(find(~isnan(e_p(:, col)),1,'last'),col), 1:size(e_p,2), 'UniformOutput', 1);
    
    % get northing coordinates of sliding window polygon
    n_p = fData.X_BP_bottomNorthing(:,idx_pings);
    n_p(idx_angles) = NaN;
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