function fData = CFF_grid_watercolumn_v3(fData,varargin)

% XXX: check that gridding uses processed data if it exists, original data
% if not (instead of using the checkboxes)

%% input parsing

% init
p = inputParser;

% required
addRequired(p,'fData',@isstruct);

% optional
addParameter(p,'dataToGrid','processed',@(x) ischar(x));
addParameter(p,'res',1,@(x) isnumeric(x)&&x>0);
addParameter(p,'vert_res',1,@(x) isnumeric(x)&&x>0);
addParameter(p,'dim','3D',@(x) ismember(x,{'2D' '3D'}));
addParameter(p,'dr_sub',4,@(x) isnumeric(x)&&x>0);
addParameter(p,'db_sub',2,@(x) isnumeric(x)&&x>0);
addParameter(p,'e_lim',[],@isnumeric);
addParameter(p,'n_lim',[],@isnumeric);

% parse
parse(p,fData,varargin{:})

% get results
dataToGrid = p.Results.dataToGrid;
res        = p.Results.res;
vert_res   = p.Results.vert_res;
dim        = p.Results.dim;
dr_sub     = p.Results.dr_sub;
db_sub     = p.Results.db_sub;


%% pre processing

% source datagram
if isfield(fData,'WC_SBP_SampleAmplitudes')
    datagramSource = 'WC';
elseif isfield(fData,'WCAP_SBP_SampleAmplitudes')
    datagramSource = 'WCAP';
end

% get dimensions
[~,nBeams,nPings] = size(fData.(sprintf('%s_SBP_SampleAmplitudes',datagramSource)).Data.val);

% block processing setup
blockLength   = 10;
nBlocks       = ceil(nPings./blockLength);
blocks        = [ 1+(0:nBlocks-1)'.*blockLength , (1:nBlocks)'.*blockLength ];
blocks(end,2) = nPings;


%% find grid limits

% init vectors
minBlockE = nan(1,nBlocks);
minBlockN = nan(1,nBlocks);
maxBlockE = nan(1,nBlocks);
maxBlockN = nan(1,nBlocks);

switch dim
    case '3D'
        minBlockH = nan(1,nBlocks);
        maxBlockH = nan(1,nBlocks);
end

% block processing
nSamples = max(fData.WC_BP_DetectedRangeInSamples(:));

soundSpeed          = fData.WC_1P_SoundSpeed.*0.1; %m/s
samplingFrequencyHz = fData.WC_1P_SamplingFrequencyHz; %Hz
dr_samples          = soundSpeed./(samplingFrequencyHz.*2);

gridConvergenceDeg    = fData.X_1P_pingGridConv; %deg
vesselHeadingDeg      = fData.X_1P_pingHeading; %deg
sonarHeadingOffsetDeg = fData.IP_ASCIIparameters.S1H; %deg

fData.res = res;
fData.vert_res = vert_res;

sonarH =fData.X_1P_pingH; %m
sonarE = fData.X_1P_pingE; %m
sonarN = fData.X_1P_pingN; %m
heading = - mod( gridConvergenceDeg + vesselHeadingDeg + sonarHeadingOffsetDeg, 360 )/180*pi;

for iB = 1:nBlocks
    
    % list of pings in this block
    blockPings = (blocks(iB,1):blocks(iB,2));
    
    % Get easting, northing and height of the first and last samples in the
    % outer beams and the central beam, for all pings in that block (aka
    % 2x3xblockLength matrices).
    sampleRange                     = CFF_get_samples_range([1 nSamples]',fData.WC_BP_StartRangeSampleNumber([1 round(nBeams./2) nBeams],blockPings),dr_samples(blockPings));
    [sampleAcrossDist,sampleUpDist] = CFF_get_samples_dist(sampleRange,fData.WC_BP_BeamPointingAngle([1 round(nBeams./2) nBeams],blockPings)/100/180*pi);    
    [blockE,blockN,blockH]          = CFF_get_samples_ENH( sonarE(blockPings), sonarN(blockPings), sonarH(blockPings), heading(blockPings), sampleAcrossDist, sampleUpDist );
    
    % these subset of all samples should be enough to find the bounds for the entire block
    minBlockE(iB) = min(blockE(:));
    maxBlockE(iB) = max(blockE(:));
    minBlockN(iB) = min(blockN(:));
    maxBlockN(iB) = max(blockN(:));
    
    switch dim
        case '3D'
            minBlockH(iB) = min(blockH(:));
            maxBlockH(iB) = max(blockH(:));
    end
    
end


%% Get grid boundaries from the min and max of those blocks

% in easting
minGridE = floor(min(minBlockE));
maxGridE = ceil(max(maxBlockE));
numElemGridE = ceil((maxGridE-minGridE)./res)+1;

% in northing
minGridN = floor(min(minBlockN));
maxGridN = ceil(max(maxBlockN));
numElemGridN = ceil((maxGridN-minGridN)./res)+1;

switch dim
    case '3D'
        % in height
        minGridH = floor(min(minBlockH));
        maxGridH = ceil(max(maxBlockH));
        numElemGridH = ceil((maxGridH-minGridH)./vert_res)+1;
end


%% initalize the grids (sum and points density per cell)
switch dim
    case '2D'
        gridSum   = zeros(numElemGridN,numElemGridE,'single');
        gridCount = zeros(numElemGridN,numElemGridE,'single');
    case '3D'
        gridSum   = zeros(numElemGridN,numElemGridE,numElemGridH,'single');
        gridCount = zeros(numElemGridN,numElemGridE,numElemGridH,'single');
end


%% fill the grids with block processing

nSamples_tot = max(fData.WC_BP_DetectedRangeInSamples);

for iB = 1:nBlocks
    
    % list of pings in this block
    blockPings  = (blocks(iB,1):blocks(iB,2));
    
    % Get easting, northing and height of all desired samples
    nSamples    = max(nSamples_tot(blockPings));
    idx_samples = (1:dr_sub:nSamples)';
    sampleRange                     = CFF_get_samples_range(idx_samples,fData.WC_BP_StartRangeSampleNumber(1:db_sub:end,blockPings),dr_samples(blockPings));
    [sampleAcrossDist,sampleUpDist] = CFF_get_samples_dist(sampleRange,fData.WC_BP_BeamPointingAngle(1:db_sub:end,blockPings)/100/180*pi);
    [blockE,blockN,blockH]          = CFF_get_samples_ENH( sonarE(blockPings), sonarN(blockPings), sonarH(blockPings), heading(blockPings), sampleAcrossDist,sampleUpDist );
    
    % get field to grid
    switch dataToGrid
        
        case 'original'
            
            blockL = CFF_get_wc_data(fData,sprintf('%s_SBP_SampleAmplitudes',datagramSource),blockPings,dr_sub,db_sub);
            
        case 'processed'
            
            blockL = single(fData.X_SBP_WaterColumnProcessed.Data.val(1:dr_sub:nSamples,1:db_sub:nBeams,blockPings));
            blockL(blockL==-64) = NaN;
            
    end
    
    % remove nans:
    indNan = isnan(blockL);
    blockL(indNan) = [];
    if isempty(blockL)
        continue;
    end
    blockE(indNan) = [];
    blockN(indNan) = [];
    
    switch dim
        case '3D'
            blockH(indNan) = [];
    end
    clear indNan
    
    if isempty(blockL)
        continue;
    end
    
    % pass grid Level in natural before gridding
    blockL = (10.^(blockL./10));
    
    % data indices in full grid
    E_idx = round((blockE-minGridE)/res+1);
    N_idx = round((blockN-minGridN)/res+1);
    
    % first index
    idx_E_start = min(E_idx);
    idx_N_start = min(N_idx);
    
    % data indices in temp grid
    E_idx = E_idx - min(E_idx) + 1;
    N_idx = N_idx - min(N_idx) + 1;
    
    % size of temp grid
    N_E = max(E_idx);
    N_N = max(N_idx);
    
    switch dim
        
        case '2D'
            subs = single([N_idx' E_idx']);
            clear N_idx E_idx
            
            % Number of data points in grid cell (density/weight)
            gridCountTemp = accumarray(subs,ones(size(blockL'),'single'),single([N_N N_E]),@sum,single(0));
            
            % Sum of data points in grid cell
            gridSumTemp = accumarray(subs,blockL',single([N_N N_E]),@sum,single(0));
            
            clear blockE blockN blockH blockL subs
            
            % Summing sums in full grid
            gridCount(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1) = ...
                gridCount(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1)+gridCountTemp;
            
            % Summing density in full grid
            gridSum(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1) = ...
                gridSum(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1)+gridSumTemp;
            
        case '3D'
            H_idx = round((blockH-minGridH)/vert_res+1);
            idx_H_start = min(H_idx);
            H_idx = H_idx - min(H_idx) + 1;
            N_H = max(H_idx);
            
            subs = single([N_idx' E_idx' H_idx']);
            clear N_idx E_idx H_idx
            
            % Number of data points in grid cell (density/weight)
            gridCountTemp = accumarray(subs,ones(size(blockH'),'single'),single([N_N N_E N_H]),@sum,single(0));
            
            % Sum of data points in grid cell
            gridSumTemp = accumarray(subs,blockL',single([N_N N_E N_H]),@sum,single(0));
            
            clear blockE blockN blockH blockL subs
            
            % Summing sums in full grid
            gridCount(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1,idx_H_start:idx_H_start+N_H-1) = ...
                gridCount(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1,idx_H_start:idx_H_start+N_H-1)+gridCountTemp;
            
            % Summing density in full grid
            gridSum(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1,idx_H_start:idx_H_start+N_H-1) = ...
                gridSum(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1,idx_H_start:idx_H_start+N_H-1)+gridSumTemp;
    end
    
    clear gridCountTemp gridSumTemp
    
end

% average, and back in dB
fData.X_NEH_gridLevel   = single(10.*log10(gridSum./gridCount));
fData.X_NEH_gridDensity = gridCount;

%% saving more results
fData.X_1E_gridEasting  = (0:numElemGridE-1) .*res + minGridE;
fData.X_N1_gridNorthing = (0:numElemGridN-1)'.*res + minGridN;

switch dim
    case '3D'
        fData.X_11H_gridHeight  = permute((0:numElemGridH-1).*res + minGridH,[3,1,2]);
end
