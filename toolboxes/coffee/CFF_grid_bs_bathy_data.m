

%% Function
function fData = CFF_grid_2D_fields_data(fData,varargin)

%% input parsing

% init
p = inputParser;

addParameter(p,'grid_horz_res',1,@(x) isnumeric(x)&&x>0);
addParameter(p,'grid_vert_res',1,@(x) isnumeric(x)&&x>0);

addParameter(p,'grdlim_mindist',0,@isnumeric);
addParameter(p,'grdlim_maxdist',inf,@isnumeric);

addParameter(p,'grdlim_east',[],@isnumeric);
addParameter(p,'grdlim_north',[],@isnumeric);

addParameter(p,'grid_north',[],@isnumeric);
addParameter(p,'grid_east',[],@isnumeric);

addParameter(p,'fields_to_grid',{'bs' 'wc'},@iscell);


% parse
parse(p,varargin{:})

% get results
grid_type     = p.Results.grid_type;
grid_horz_res = p.Results.grid_horz_res;
grid_vert_res = p.Results.grid_vert_res;
dr_sub = p.Results.dr_sub;
db_sub = p.Results.db_sub;
grdlim_mode    = p.Results.grdlim_mode;
grdlim_var     = p.Results.grdlim_var;
grdlim_mindist = p.Results.grdlim_mindist;
grdlim_maxdist = p.Results.grdlim_maxdist;
grdlim_east    = p.Results.grdlim_east;
grdlim_north   = p.Results.grdlim_north;
fields_to_grid = p.Results.fields_to_grid;



%% Prepare needed 1xP data for computations

% Source datagram
datagramSource = CFF_get_datagramSource(fData);

% inter-sample distance
interSamplesDistance = CFF_inter_sample_distance(fData); % in m

% sonar location
sonarEasting  = fData.X_1P_pingE; %m
sonarNorthing = fData.X_1P_pingN; %m
sonarHeight   = fData.X_1P_pingH; %m

% sonar heading
gridConvergence    = fData.X_1P_pingGridConv; %deg
vesselHeading      = fData.X_1P_pingHeading; %deg
sonarHeadingOffset = fData.IP_ASCIIparameters.S1H; %deg
sonarHeading       = deg2rad(-mod(gridConvergence + vesselHeading + sonarHeadingOffset,360));

% block processing setup
mem_struct = memory;
blockLength = ceil(mem_struct.MemAvailableAllArrays/(nSamples*nBeams*8)/20);
nBlocks = ceil(nPings./blockLength);
blocks = [ 1+(0:nBlocks-1)'.*blockLength , (1:nBlocks)'.*blockLength ];
blocks(end,2) = nPings;


%% find grid limits

% initialize vectors
minBlockE = nan(1,nBlocks);
minBlockN = nan(1,nBlocks);
maxBlockE = nan(1,nBlocks);
maxBlockN = nan(1,nBlocks);

minBlockH = nan(1,nBlocks);
maxBlockH = nan(1,nBlocks);

%d_max=nanmax(fData.X_BP_bottomHeight(:));
% find grid limits for each block


[gridE,gridN,gridNan]=CFF_compute_grid(fData)


for iB = 1:nBlocks
    
    % list of pings in this block
    blockPings = blocks(iB,1):blocks(iB,2);
    

    idxSamples = [1 nSamples]';
    startSampleNumber = fData.(sprintf('%s_BP_StartRangeSampleNumber',datagramSource))([1 round(nBeams./2) nBeams],blockPings);
    beamPointingAngle = deg2rad(fData.(sprintf('%s_BP_BeamPointingAngle',datagramSource))([1 round(nBeams./2) nBeams],blockPings));
    
    % Get easting, northing and height
    [blockE, blockN, blockH] = CFF_georeference_sample(idxSamples, startSampleNumber, interSamplesDistance(blockPings), beamPointingAngle, ...
        sonarEasting(blockPings), sonarNorthing(blockPings), sonarHeight(blockPings), sonarHeading(blockPings));
    
    %id_keep=blockH<d_max;
    
    % these subset of all samples should be enough to find the bounds for the entire block
    minBlockE(iB) = min(blockE(:));
    maxBlockE(iB) = max(blockE(:));
    minBlockN(iB) = min(blockN(:));
    maxBlockN(iB) = max(blockN(:));
    
    minBlockH(iB) = min(blockH(:));
    maxBlockH(iB) = max(blockH(:));

    
end

% Get grid boundaries from the min and max of those blocks
minGridE = floor(min(minBlockE));
maxGridE = ceil(max(maxBlockE));
numElemGridE = ceil((maxGridE-minGridE)./grid_horz_res)+1;
minGridN = floor(min(minBlockN));
maxGridN = ceil(max(maxBlockN));
numElemGridN = ceil((maxGridN-minGridN)./grid_horz_res)+1;

minGridH = floor(min(minBlockH));
maxGridH = ceil(max(maxBlockH));
numElemGridH = ceil((maxGridH-minGridH)./grid_vert_res)+1;



%% initalize the grids:
% * weighted sum and total sum of weights. In absence of weights, the total
% sum of weights is simply the count of points, and the weighted sum is
% simply the sum
% * Now also doing a grid containing the maximum horizontal distance to
% nadir, to be used when mosaicking using the "stitching" method.
switch grid_type
    case '2D'
        gridWeightedSum  = zeros(numElemGridN,numElemGridE,'single');
        gridTotalWeight  = zeros(numElemGridN,numElemGridE,'single');
        gridMaxHorizDist =   nan(numElemGridN,numElemGridE,'single');
    case '3D'
        gridWeightedSum  = zeros(numElemGridN,numElemGridE,numElemGridH,'single');
        gridTotalWeight  = zeros(numElemGridN,numElemGridE,numElemGridH,'single');
        gridMaxHorizDist =   nan(numElemGridN,numElemGridE,numElemGridH,'single');
        
end



% if GPU is avaialble for computation, setup for it
gpu_comp = get_gpu_comp_stat();

if gpu_comp > 0
    gpud=gpuDevice;
    if gpud.AvailableMemory>numel(gridMaxHorizDist)*32*3
        gridWeightedSum  = gpuArray(gridWeightedSum);
        gridTotalWeight  = gpuArray(gridTotalWeight);
        gridMaxHorizDist = gpuArray(gridMaxHorizDist);
    else
        gpu_comp=0;
    end
end


%% if gridding is in height above bottom, prepare the interpolant
% needed to calculate height above seafloor for each sample
idx_val = ~isnan(fData.X_BP_bottomHeight) & ~isinf(fData.X_BP_bottomHeight);
HeightInterpolant = scatteredInterpolant(fData.X_BP_bottomNorthing(idx_val),fData.X_BP_bottomEasting(idx_val),fData.X_BP_bottomHeight(idx_val),'natural','none');



%% fill the grids with block processing
for iB = 1:nBlocks
    
    % list of pings in this block
    blockPings  = blocks(iB,1):blocks(iB,2);
    
    % to speed up processing, we will only grid data decimated in samples
    % number and in beams
    
    % get data to grid
    blockL = CFF_get_WC_data(fData,field_to_grid,'iPing',blockPings,'dr_sub',dr_sub,'db_sub',db_sub,'output_format','true');
    switch data_type
        case 'Original'
            [blockL, warning_text] = CFF_WC_radiometric_corrections_CORE(blockL,fData);
    end
    nSamples_temp=size(blockL,1);
    
    idxSamples = (1:dr_sub:nSamples_temp*dr_sub)';
    
    startSampleNumber = fData.(sprintf('%s_BP_StartRangeSampleNumber',datagramSource))(1:db_sub:end,blockPings);
    beamPointingAngle = deg2rad(fData.(sprintf('%s_BP_BeamPointingAngle',datagramSource))(1:db_sub:end,blockPings));
    
    % Get easting, northing, height and across distance from the samples
    [blockE, blockN, blockH, blockAccD] = CFF_georeference_sample(idxSamples, startSampleNumber, interSamplesDistance(blockPings), beamPointingAngle, ...
        sonarEasting(blockPings), sonarNorthing(blockPings), sonarHeight(blockPings), sonarHeading(blockPings));
    blockAccD = single(blockAccD);
    
    
    % define weights here
    weighting_mode = 'none'; % 'SIAfilter' or 'none'
    switch weighting_mode
        case 'none'
            % all samples have the same weight (1) in the gridding
            blockW = ones(size(blockL),class(blockL));
        case 'SIAfilter'
            % samples have a weight dependent on how strongly they were
            % affected by the SIA filter. The ranges where specular occured
            % had a strong mean BS to which we will apply a small weight
            % (towards 0), while the ranges that had no speculars had a
            % relatively lower mean BS, and those we will apply a larger
            % weight (towards 1).
            % This correction requires to have saved the sidelobe artifact
            % correction at the processing stage.
            if isfield(fData, 'X_S1P_sidelobeArtifactCorrection')
                
                SIAcorrection = fData.X_S1P_sidelobeArtifactCorrection(1:dr_sub:end,1,blockPings);
                
                % define downramp function, going down linearly from
                % (X1,Y1) to (X2,Y2). Equals Y1 for x<X1, and equals Y2 for
                % x>X2.
                downramp_fun  = @(x,X1,X2,Y1,Y2) min(max(x.*(Y1-Y2)./(X1-X2)+(Y2.*X1-Y1.*X2)./(X1-X2),Y2),Y1);
                
                % use inverse percentiles to figure the start and end of
                % the ramp.
                start_ramp = CFF_invpercentile(SIAcorrection(:),20);
                end_ramp   = CFF_invpercentile(SIAcorrection(:),80);
                
                % apply to SIAcorrection to get the weight scores (between
                % 0 and 1)
                fact   = downramp_fun(SIAcorrection,start_ramp,end_ramp,1,0);
                blockW = single(repmat(fact,1,size(blockL,2),1));
            else
                warning('This weighting mode cannot be used because processed data do not include the needed field. Using no-weighting mode for now.');
                blockW = ones(size(blockL),class(blockL));
            end
    end
    
    % start with removing all data where level is NaN
    indNan = isnan(blockL) | isnan(blockW);
    blockL(indNan) = [];
    if isempty(blockL)
        continue;
    end
    blockW(indNan)    = [];
    blockE(indNan)    = [];
    blockN(indNan)    = [];
    blockH(indNan)    = [];
    blockAccD(indNan) = [];
    clear indNan
    
    % get indices of samples we want to keep in the calculation
    switch grdlim_var
        
        case 'Sonar'
            
            % H is already as depth below sonar so it's pretty easy
            if  strcmp(grid_type,'2D')
                switch grdlim_mode
                    case 'between'
                        idx_keep = blockH<=-grdlim_mindist & blockH>=-grdlim_maxdist;
                    case 'outside of'
                        idx_keep = blockH>=-grdlim_mindist | blockH<=-grdlim_maxdist;
                end
                idx_keep=idx_keep&~isnan(blockH)&blockH>=minGridH&blockH<=maxGridH;
            else
                idx_keep=~isnan(blockH)&blockH>=minGridH&blockH<=maxGridH;
            end
            %idx_keep=idx_keep&blockH<=0;
        case 'Bottom'
            
            block_bottomHeight = HeightInterpolant(blockN,blockE);
            blockH = blockH - block_bottomHeight;
            minGridH=0;
            if  strcmp(grid_type,'2D')
                switch grdlim_mode
                    case 'between'
                        idx_keep = block_sampleHeightAboveSeafloor>=grdlim_mindist & block_sampleHeightAboveSeafloor<=grdlim_maxdist;
                    case 'outside of'
                        idx_keep = block_sampleHeightAboveSeafloor<=grdlim_mindist | block_sampleHeightAboveSeafloor>=grdlim_maxdist;
                end
                idx_keep=idx_keep&blockH>=0;
            else
                idx_keep=~isnan(blockH)&blockH>=0;
            end
            clear block_bottomHeight block_sampleHeightAboveSeafloor
            
    end
    
    % and remove data that we don't want to grid
    blockL(~idx_keep) = [];
    if isempty(blockL)
        continue;
    end
    blockW(~idx_keep)    = [];
    blockE(~idx_keep)    = [];
    blockN(~idx_keep)    = [];
    blockH(~idx_keep)    = [];
    blockAccD(~idx_keep) = [];
    clear idx_keep
    
    % at this stage, pass blockL and blockW as GPU arrays if using GPUs
    if gpu_comp > 0
        blockL    = gpuArray(blockL);
        blockW    = gpuArray(blockW);
        blockAccD = gpuArray(blockAccD);
    end
    
    % pass grid level in natural before gridding
    blockL = 10.^(blockL./10);
    
    % also, turn across distance (signed) to horizontal distance from nadir
    % (unsigned)
    blockD = abs(blockAccD);
    clear blockAccD
    
    % data indices in the full grid
    E_idx = round((blockE-minGridE)/grid_horz_res+1);
    N_idx = round((blockN-minGridN)/grid_horz_res+1);
    clear blockE blockN
    
    % first index
    idx_E_start = min(E_idx);
    idx_N_start = min(N_idx);
    
    % data indices in the small grid built just for this block of pings
    E_idx = E_idx - min(E_idx) + 1;
    N_idx = N_idx - min(N_idx) + 1;
    
    % size of this small grid
    N_E = max(E_idx);
    N_N = max(N_idx);
    
    % now gridding...
    switch grid_type
        
        case '2D'
            
            clear blockH
            
            % we use the accumarray function to sum all values in both the
            % total weight grid, and the weighted sum grid. Prepare the
            % common values here
            subs    = single([N_idx' E_idx']); % indices in the temp grid of each data point
            sz      = single([N_N N_E]);       % size of ouptut
            clear N_idx E_idx
            
            % sum of weights per grid cell, and sum of weighted levels per
            % grid cell
            gridTotalWeight_forBlock = accumarray(subs,blockW',sz,@sum,single(0));
            gridWeightedSum_forBlock = accumarray(subs,blockW'.*blockL',sz,@sum,single(0));
            
            
            clear blockL blockW
            
            % maximum horiz distance from nadir per grid cell
            gridMaxHorizDist_forBlock = accumarray(subs,blockD',sz,@max,single(NaN));
            clear blockD subs
            
            % Add the block's small grid of weights sum to the full one,
            % and the block's small grid of sum of weighted levels to the
            % full one
            gridTotalWeight(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1) = ...
                gridTotalWeight(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1) + gridTotalWeight_forBlock;
            gridWeightedSum(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1) = ...
                gridWeightedSum(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1) + gridWeightedSum_forBlock;
            clear gridTotalWeight_forBlock gridWeightedSum_forBlock
            
            % Add the block's small grid of maximum horiz dist to the full
            % one: just keep in the grid whatever the maximum is per cell
            gridMaxHorizDist(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1) = nanmax( ...
                gridMaxHorizDist(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1), gridMaxHorizDist_forBlock);
            clear gridMaxHorizDist_forBlock
            
        case '3D'
            
            % prepare indices as we did before in E,N, this time in height
            H_idx = round((blockH-minGridH)/grid_vert_res+1);
            clear blockH
            idx_H_start = min(H_idx);
            H_idx = H_idx - min(H_idx) + 1;
            N_H = max(H_idx);
            
            % we use the accumarray function to sum all values in both the
            % total weight grid, and the weighted sum grid. Prepare the
            % common values here
            subs    = single([N_idx' E_idx' H_idx']); % indices in the temp grid of each data point
            sz      = single([N_N N_E N_H]);          % size of ouptut
            clear N_idx E_idx H_idx
            
            % sum of weights per grid cell, and sum of weighted levels per grid cell
            gridTotalWeight_forBlock = accumarray(subs,blockW',sz,@sum,single(0));
            gridWeightedSum_forBlock = accumarray(subs,blockW'.*blockL',sz,@sum,single(0));
            clear blockL blockW
            
            % maximum horiz distance from nadir per grid cell
            gridMaxHorizDist_forBlock = accumarray(subs,blockD',sz,@max,single(NaN));
            clear blockD subs
            
            % Add the block's small grid of weights sum to the full one,
            % and the block's small grid of sum of weighted levels to the
            % full one
            gridTotalWeight(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1,idx_H_start:idx_H_start+N_H-1) = ...
                gridTotalWeight(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1,idx_H_start:idx_H_start+N_H-1) + gridTotalWeight_forBlock;
            gridWeightedSum(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1,idx_H_start:idx_H_start+N_H-1) = ...
                gridWeightedSum(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1,idx_H_start:idx_H_start+N_H-1) + gridWeightedSum_forBlock;
            clear gridTotalWeight_forBlock gridWeightedSum_forBlock
            
            % Add the block's small grid of maximum horiz dist to the full
            % one: just keep in the grid whatever the maximum is per cell
            gridMaxHorizDist(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1,idx_H_start:idx_H_start+N_H-1) = nanmax( ...
                gridMaxHorizDist(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1,idx_H_start:idx_H_start+N_H-1), gridMaxHorizDist_forBlock);
            clear gridMaxHorizDist_forBlock
            
    end
    
end


%% crop the edges of the grids (they were built based on original data size)
switch grid_type
    
    case '2D'
        
        % dimensional sums
        sumgridTotalWeight_N = sum(gridTotalWeight,2);
        sumgridTotalWeight_E = sum(gridTotalWeight,1);
        
        % min and max indices for cropping
        minNidx = find(sumgridTotalWeight_N,1,'first');
        maxNidx = find(sumgridTotalWeight_N,1,'last');
        minEidx = find(sumgridTotalWeight_E,1,'first');
        maxEidx = find(sumgridTotalWeight_E,1,'last');
        
        % crop the grids
        gridTotalWeight  = gridTotalWeight(minNidx:maxNidx,minEidx:maxEidx);
        gridWeightedSum  = gridWeightedSum(minNidx:maxNidx,minEidx:maxEidx);
        gridMaxHorizDist = gridMaxHorizDist(minNidx:maxNidx,minEidx:maxEidx);
        
        % define and crop dim vectors
        gridNorthing = (0:numElemGridN-1)'.*grid_horz_res + minGridN;
        gridEasting  = (0:numElemGridE-1) .*grid_horz_res + minGridE;
        gridNorthing = gridNorthing(minNidx:maxNidx);
        gridEasting  = gridEasting(:,minEidx:maxEidx);
        
    case '3D'
        
        % dimensional sums
        sumgridTotalWeight_1EH = sum(gridTotalWeight,1);
        sumgridTotalWeight_N1H = sum(gridTotalWeight,2);
        sumgridTotalWeight_N = sum(sumgridTotalWeight_N1H,3);
        sumgridTotalWeight_E = sum(sumgridTotalWeight_1EH,3);
        sumgridTotalWeight_H = sum(sumgridTotalWeight_1EH,2);
        
        % min and max indices for cropping
        minNidx = find(sumgridTotalWeight_N,1,'first');
        maxNidx = find(sumgridTotalWeight_N,1,'last');
        minEidx = find(sumgridTotalWeight_E,1,'first');
        maxEidx = find(sumgridTotalWeight_E,1,'last');
        minHidx = find(sumgridTotalWeight_H,1,'first');
        maxHidx = find(sumgridTotalWeight_H,1,'last');
        
        % crop the grids
        gridTotalWeight  = gridTotalWeight(minNidx:maxNidx,minEidx:maxEidx,minHidx:maxHidx);
        gridWeightedSum  = gridWeightedSum(minNidx:maxNidx,minEidx:maxEidx,minHidx:maxHidx);
        gridMaxHorizDist = gridMaxHorizDist(minNidx:maxNidx,minEidx:maxEidx,minHidx:maxHidx);
        
        % define and crop dim vectors
        gridNorthing = (0:numElemGridN-1)'.*grid_horz_res + minGridN;
        gridEasting  = (0:numElemGridE-1) .*grid_horz_res + minGridE;
        gridHeight   = permute((0:numElemGridH-1).*grid_vert_res + minGridH,[3,1,2]);
        gridNorthing = gridNorthing(minNidx:maxNidx);
        gridEasting  = gridEasting(:,minEidx:maxEidx);
        gridHeight   = gridHeight(:,:,minHidx:maxHidx);
        
end

% final calculations: average and back in dB
gridLevel = 10.*log10(gridWeightedSum./gridTotalWeight);
clear gridWeightedSum

% revert gpuArrays back to regular arrays before storing so that data can
% be used even without the parallel computing toolbox and so that loading
% data don't overload the limited GPU memory
if gpu_comp > 0
    gridLevel        = gather(gridLevel);
    gridTotalWeight  = gather(gridTotalWeight);
    gridMaxHorizDist = gather(gridMaxHorizDist);
end

[N,E] = ndgrid(gridNorthing,gridEasting);
fData.X_NE_bathy = HeightInterpolant(N,E);

if isfield(fData,'X8_BP_ReflectivityBS')
    BSinterpolant = scatteredInterpolant(fData.X_BP_bottomNorthing(idx_val),fData.X_BP_bottomEasting(idx_val),fData.X8_BP_ReflectivityBS(idx_val),'natural','none');
    fData.X_NE_bs = BSinterpolant(N,E);
else
    fData.X_NE_bs=nan(size(E),'single');
end

ff=filter2(ones(5,5),nansum(gridTotalWeight,3));
fData.X_NE_bs(ff==0)=nan;
fData.X_NE_bathy(ff==0)=nan;
fData.X_grid_reference=grdlim_var;

%% saving results:

fData.X_NEH_gridLevel        = gridLevel;
fData.X_NEH_gridDensity      = gridTotalWeight;
fData.X_NEH_gridMaxHorizDist = gridMaxHorizDist;

fData.X_1E_gridEasting  = gridEasting;
fData.X_N1_gridNorthing = gridNorthing;

fData.X_1_gridHorizontalResolution = grid_horz_res;

switch grid_type
    case '3D'
        fData.X_11H_gridHeight = gridHeight;
        fData.X_1_gridVerticalResolution = grid_vert_res;
end
