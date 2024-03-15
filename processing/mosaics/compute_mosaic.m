function mosaic = compute_mosaic(mosaic, fData_tot, d_lim_sonar_ref, d_lim_bottom_ref)
%COMPUTE_MOSAIC  One-line description
%
%   See also ESPRESSO.

%   Copyright 2017-2021 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

E_lim = mosaic.E_lim;
N_lim = mosaic.N_lim;
res   = mosaic.res;

%% initalize the mosaic:
% * weighted sum and total sum of weights. In absence of weights, the total
% sum of weights is simply the count of points, and the weighted sum is
% simply the sum
% * Now also doing a grid containing the maximum horizontal distance to
% nadir, to be used when mosaicking using the "stitching" method.
[numElemGridN,numElemGridE] = size(mosaic.mosaic_level);
mosaicWeightedSum  = zeros(numElemGridN,numElemGridE,'single');
mosaicTotalWeight  = zeros(numElemGridN,numElemGridE,'single');
mosaicMaxHorizDist =   nan(numElemGridN,numElemGridE,'single');

% Test if GPU is available for computation and setup for it
if CFF_is_parallel_computing_available()
    mosaicWeightedSum  = gpuArray(mosaicWeightedSum);
    mosaicTotalWeight  = gpuArray(mosaicTotalWeight);
    mosaicMaxHorizDist = gpuArray(mosaicMaxHorizDist);
end

% loop over all files loaded
for iF = 1:numel(fData_tot)
    
    % get data
    fData = fData_tot{iF};
    if ~all(isfield(fData,{'X_1E_gridEasting' 'X_N1_gridNorthing'}))
        continue;
    end
    E = fData.X_1E_gridEasting;
    N = fData.X_N1_gridNorthing;
    data = CFF_get_fData_wc_grid(fData,{'gridLevel' 'gridDensity' 'gridMaxHorizDist'}, d_lim_sonar_ref, d_lim_bottom_ref);
    L = data{1};
    W = data{2};
    D = data{3};
    if isempty(L)
        continue;
    end
    % remove all data outside of mosaic boundaries
    idx_keep_E = E>E_lim(1) & E<E_lim(2);
    idx_keep_N = N>N_lim(1) & N<N_lim(2);
    E(~idx_keep_E) = [];
    N(~idx_keep_N) = [];
    L(~idx_keep_N,:) = [];
    L(:,~idx_keep_E) = [];
    W(~idx_keep_N,:) = [];
    W(:,~idx_keep_E) = [];
    D(~idx_keep_N,:) = [];
    D(:,~idx_keep_E) = [];
    
    % vectorize
    [numel_N, numel_E] = size(L);
    E = repmat(E,numel_N,1);
    N = repmat(N,1,numel_E);
    E = E(:);
    N = N(:);
    L = L(:);
    W = W(:);
    D = D(:);
    
    % remove nans
    indNan = isnan(L);
    E(indNan) = [];
    N(indNan) = [];
    L(indNan) = [];
    W(indNan) = [];
    D(indNan) = [];
    
    % This should not happen as it's been checked already but if no data
    % within mosaic bounds, continue to next file
    if isempty(L)
        continue;
    end
    
    % pass grid level in natural before gridding.
    L = 10.^(L./10);
    
    % data indices in the mosaic
    E_idx = round((E-E_lim(1))/res+1);
    N_idx = round((N-N_lim(1))/res+1);
    
    % first index
    idx_E_start = min(E_idx);
    idx_N_start = min(N_idx);
    
    % data indices in temp mosaic (mosaic just for this file)
    E_idx = E_idx - min(E_idx) + 1;
    N_idx = N_idx - min(N_idx) + 1;
    
    % size of temp mosaic
    N_E = max(E_idx);
    N_N = max(N_idx);
    
    % we use the accumarray function to sum all values in both the
    % total weight mosaic, and the weighted sum mosaic. Prepare the
    % common values here
    subs = single([N_idx E_idx]); % indices in the temp grid of each data point
    sz   = single([N_N N_E]);     % size of ouptut
    
    % calculate the sum of weights per mosaic cell, and the sum of weighted
    % levels per mosaic cell
    mosaicTotalWeightTemp = accumarray(subs,W',sz,@sum,single(0));
    mosaicWeightedSumTemp = accumarray(subs,W'.*L',sz,@sum,single(0));
    
    switch mosaic.mode
        
        case 'blend'
            % In this mode, any cell of the mosaic will contain the
            % weighted average of all grids that contribute to it, as per
            % their weight. It effectively "blends" grids together.
            
            % Add the temp mosaic of weights sum to the full one
            mosaicTotalWeight(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1) = ...
                mosaicTotalWeight(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1) + mosaicTotalWeightTemp;
            
            % Add the temp mosaic of sum of weighted levels to the full one
            mosaicWeightedSum(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1) = ...
                mosaicWeightedSum(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1) + mosaicWeightedSumTemp;
            
        case 'stitch'
            % In this mode, any cell of the mosaic will contain the value
            % of the grid for which this cell was closest to nadir. It
            % effectively "stitches" grids together with stitches occuring
            % at equidistance from the vessel tracks.
            
            % calculate maximum horiz distance from nadir per grid cell
            mosaicMaxHorizDistTemp = accumarray(subs,D',sz,@max,single(NaN));
            
            % Add the temp grid of maximum horiz dist
            mosaicMaxHorizDistExtract = mosaicMaxHorizDist(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1);
            [~,ind] = nanmin( [mosaicMaxHorizDistExtract(:),mosaicMaxHorizDistTemp(:)],[],2 );
            ind = reshape(ind,size(mosaicMaxHorizDistExtract));
            mosaicMaxHorizDistExtract(ind==2) = mosaicMaxHorizDistTemp(ind==2);
            mosaicMaxHorizDist(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1) = mosaicMaxHorizDistExtract;
            
            mosaicTotalWeightExtract = mosaicTotalWeight(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1);
            mosaicTotalWeightExtract(ind==2) = mosaicTotalWeightTemp(ind==2);
            mosaicTotalWeight(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1) = mosaicTotalWeightExtract;
            
            mosaicWeightedSumExtract = mosaicWeightedSum(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1);
            mosaicWeightedSumExtract(ind==2) = mosaicWeightedSumTemp(ind==2);
            mosaicWeightedSum(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1) = mosaicWeightedSumExtract;
            
    end
    
end

% final calculations: average and back in dB
mosaic_level = 10.*log10(mosaicWeightedSum./mosaicTotalWeight);

if isa(mosaic_level,'gpuArray')
    mosaic_level = gather(mosaic_level);
end

% save
mosaic.mosaic_level = mosaic_level;

end



