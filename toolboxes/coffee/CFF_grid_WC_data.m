%% CFF_grid_WC_data.m
%
% _This section contains a very short description of the function, for the
% user to know this function is part of the software and what it does for
% it. Example below to replace. Delete these lines XXX._
%
% Template of ESP3 function header. XXX
%
%% Help
%
% *USE*
%
% _This section contains a more detailed description of what the function
% does and how to use it, for the interested user to have an overall
% understanding of its function. Example below to replace. Delete these
% lines XXX._
%
% This is a text file containing the basic comment template to add at the
% start of any new ESP3 function to serve as function help. XXX
%
% *INPUT VARIABLES*
%
% _This section contains bullet points of input variables with description
% and information. Put input variable and other valid entries or defaults
% between | symbols so it shows as monospace. Information section to
% contain, in order: requirement (i.e. Required/Optional/Paramter), valid
% type (e.g. Num, Positive num, char, 1xN cell array, etc.) and default
% value if there is one (e.g. Default: '10'). Example below to replace.
% Delete these lines XXX._
%
% * |fData|: Required. Structure for the storage of kongsberg EM series
% multibeam data in a format more convenient for processing. The data is
% recorded as fields coded "a_b_c" where "a" is a code indicating data
% origing, "b" is a code indicating data dimensions, and "c" is the data
% name. See the help of function CFF_convert_ALLdata_to_fData.m for
% description of codes.
% * |grid_horz_res|: Description (Information). Default: 1 XXX
% * |grid_vert_res|: Description (Information). Default: 1 XXX
% * |grid_type|: Description (Information). '2D' or '3D' (default) XXX
% * |dr_sub|: Description (Information). Default: 4 XXX
% * |db_sub|: Description (Information). Default: 2 XXX
% * |e_lim|: Description (Information). Default: [] XXX
% * |n_lim|: Description (Information). Default: [] XXX
%
% *OUTPUT VARIABLES*
%
% * |fData|: fData structure updated with fields for gridded data
%
% *DEVELOPMENT NOTES*
%
% * function formerly named CFF_grid_watercolumn.m
%
% *NEW FEATURES*
%
% _This section contains dates and descriptions of major updates. Example
% below to replace. Delete these lines XXX._
%
% * 2018-10-11: Updated header before adding to Coffee v3
% * YYYY-MM-DD: first version. XXX
%
% *EXAMPLE*
%
% _This section contains examples of valid function calls. Note that
% example lines start with 3 white spaces so that the publish function
% shows them correctly as matlab code. Example below to replace. Delete
% these lines XXX._
%
%   example_use_1; % comment on what this does. XXX
%   example_use_2: % comment on what this line does. XXX
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Alexandre Schimel, Deakin University, NIWA.
% Yoann Ladroit, NIWA.


%% Function
function fData = CFF_grid_WC_data(fData,varargin)

%% input parsing

% init
p = inputParser;

% grid mode (2D map or 3D) and resolution (horizontal and vertical)
addParameter(p,'grid_type','3D',@(x) ismember(x,{'2D' '3D'}));
addParameter(p,'grid_horz_res',1,@(x) isnumeric(x)&&x>0);
addParameter(p,'grid_vert_res',1,@(x) isnumeric(x)&&x>0);

% decimation factors
addParameter(p,'dr_sub',4,@(x) isnumeric(x)&&x>0);
addParameter(p,'db_sub',2,@(x) isnumeric(x)&&x>0);

% grid limitation parameters
addParameter(p,'grdlim_mode','between',@(x) ismember(x,{'between', 'outside of'}));
addParameter(p,'grdlim_var','depth below sonar',@(x) ismember(x,{'depth below sonar', 'height above bottom'}));
addParameter(p,'grdlim_mindist',0,@isnumeric);
addParameter(p,'grdlim_maxdist',inf,@isnumeric);
addParameter(p,'grdlim_east',[],@isnumeric);
addParameter(p,'grdlim_north',[],@isnumeric);

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


%% Extract info about WCD
if isfield(fData,'X_SBP_WaterColumnProcessed')
    field_to_grid = 'X_SBP_WaterColumnProcessed';
else
    field_to_grid = 'WC_SBP_SampleAmplitudes';
end

% size
[nSamples, nBeams, nPings] = size(fData.(field_to_grid).Data.val);

%% Prepare needed 1xP data for computations

% Source datagram
datagramSource = fData.MET_datagramSource;

% inter-sample distance
soundSpeed           = fData.(sprintf('%s_1P_SoundSpeed',datagramSource)).*0.1; %m/s
samplingFrequencyHz  = fData.(sprintf('%s_1P_SamplingFrequencyHz',datagramSource)); %Hz
interSamplesDistance = soundSpeed./(samplingFrequencyHz.*2); % in m

% sonar location
sonarEasting  = fData.X_1P_pingE; %m
sonarNorthing = fData.X_1P_pingN; %m
sonarHeight   = fData.X_1P_pingH; %m

% sonar heading
gridConvergence    = fData.X_1P_pingGridConv; %deg
vesselHeading      = fData.X_1P_pingHeading; %deg
sonarHeadingOffset = fData.IP_ASCIIparameters.S1H; %deg
sonarHeading       = deg2rad(-mod(gridConvergence + vesselHeading + sonarHeadingOffset,360));


%% block processing setup depending on memory available
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
switch grid_type
    case '3D'
        minBlockH = nan(1,nBlocks);
        maxBlockH = nan(1,nBlocks);
end

% find grid limits for each block
for iB = 1:nBlocks
    
    % list of pings in this block
    blockPings = blocks(iB,1):blocks(iB,2);
    
    % to define the limits of the grid for each block, we'll only consider
    % the easting and northing of the first and last sample for the central
    % beam and two outer beams, for all pings.
    idxSamples = [1 nSamples]';
    startSampleNumber = fData.(sprintf('%s_BP_StartRangeSampleNumber',datagramSource))([1 round(nBeams./2) nBeams],blockPings);
    beamPointingAngle = deg2rad(fData.(sprintf('%s_BP_BeamPointingAngle',datagramSource))([1 round(nBeams./2) nBeams],blockPings)/100);
    
    % Get easting, northing and height
    [blockE, blockN, blockH] = CFF_georeference_sample(idxSamples, startSampleNumber, interSamplesDistance(blockPings), beamPointingAngle, ...
        sonarEasting(blockPings), sonarNorthing(blockPings), sonarHeight(blockPings), sonarHeading(blockPings));
    
    % these subset of all samples should be enough to find the bounds for the entire block
    minBlockE(iB) = min(blockE(:));
    maxBlockE(iB) = max(blockE(:));
    minBlockN(iB) = min(blockN(:));
    maxBlockN(iB) = max(blockN(:));
    
    switch grid_type
        case '3D'
            minBlockH(iB) = min(blockH(:));
            maxBlockH(iB) = max(blockH(:));
    end
    
end

% Get grid boundaries from the min and max of those blocks
minGridE = floor(min(minBlockE));
maxGridE = ceil(max(maxBlockE));
numElemGridE = ceil((maxGridE-minGridE)./grid_horz_res)+1;
minGridN = floor(min(minBlockN));
maxGridN = ceil(max(maxBlockN));
numElemGridN = ceil((maxGridN-minGridN)./grid_horz_res)+1;
switch grid_type
    case '3D'
        minGridH = floor(min(minBlockH));
        maxGridH = ceil(max(maxBlockH));
        numElemGridH = ceil((maxGridH-minGridH)./grid_vert_res)+1;
end


%% initalize the grids (sum and points density per cell)

switch grid_type
    case '2D'
        gridSum   = zeros(numElemGridN,numElemGridE,'single');
        gridCount = zeros(numElemGridN,numElemGridE,'single');
    case '3D'
        gridSum   = zeros(numElemGridN,numElemGridE,numElemGridH,'single');
        gridCount = zeros(numElemGridN,numElemGridE,numElemGridH,'single');
end

% if GPU is avaialble for computation, setup for it
gpu_comp = get_gpu_comp_stat();
if gpu_comp > 0
    gridSum   = gpuArray(gridSum);
    gridCount = gpuArray(gridCount);
end


%% fill the grids with block processing

for iB = 1:nBlocks
    
    % list of pings in this block
    blockPings  = blocks(iB,1):blocks(iB,2);
    
    % to speed up processing, we will only grid data decimated in samples
    % number and in beams
    idxSamples = (1:dr_sub:nSamples)';
    startSampleNumber = fData.(sprintf('%s_BP_StartRangeSampleNumber',datagramSource))(1:db_sub:end,blockPings);
    beamPointingAngle = deg2rad(fData.(sprintf('%s_BP_BeamPointingAngle',datagramSource))(1:db_sub:end,blockPings)/100);
    
    % Get easting, northing and height
    [blockE, blockN, blockH] = CFF_georeference_sample(idxSamples, startSampleNumber, interSamplesDistance(blockPings), beamPointingAngle, ...
        sonarEasting(blockPings), sonarNorthing(blockPings), sonarHeight(blockPings), sonarHeading(blockPings));
    
    % get data to grid
    blockL = CFF_get_WC_data(fData,field_to_grid,'iPing',blockPings,'dr_sub',dr_sub,'db_sub',db_sub,'output_format','true');
    
    % start with removing all data where level is NaN
    indNan = isnan(blockL);
    blockL(indNan) = [];
    if isempty(blockL)
        continue;
    end
    blockE(indNan) = [];
    blockN(indNan) = [];
    blockH(indNan) = [];
    clear indNan
    
    % get indices of samples we want to keep in the calculation
    switch grdlim_var
        
        case 'depth below sonar'
            
            % H is already as depth below sonar so it's pretty easy
            switch grdlim_mode
                case 'between'
                    idx_keep = blockH<=-grdlim_mindist & blockH>=-grdlim_maxdist;
                case 'outside of'
                    idx_keep = blockH>=-grdlim_mindist | blockH<=-grdlim_maxdist;
            end
            
        case 'height above bottom'
            
            % first need to calculate height above seafloor for each sample
            % and the interpolation takes a while
            idx_val=~isnan(fData.X_BP_bottomHeight)&~isinf(fData.X_BP_bottomHeight);
            F = scatteredInterpolant(fData.X_BP_bottomEasting(idx_val),fData.X_BP_bottomNorthing(idx_val),fData.X_BP_bottomHeight(idx_val));
            block_bottomHeight = F(blockE,blockN);
            block_sampleHeightAboveSeafloor = blockH - block_bottomHeight;
            
            switch grdlim_mode
                case 'between'
                    idx_keep = block_sampleHeightAboveSeafloor>=grdlim_mindist & block_sampleHeightAboveSeafloor<=grdlim_maxdist;
                case 'outside of'
                    idx_keep = block_sampleHeightAboveSeafloor<=grdlim_mindist | block_sampleHeightAboveSeafloor>=grdlim_maxdist;
            end
            
            clear block_bottomHeight block_sampleHeightAboveSeafloor
            
    end
    
    % and remove data that we don't want to grid
    blockL(~idx_keep) = [];
    if isempty(blockL)
        continue;
    end
    blockE(~idx_keep) = [];
    blockN(~idx_keep) = [];
    blockH(~idx_keep) = [];
    block_size = size(blockN');
    clear idx_keep
    
    % pass grid level in natural before gridding
    if gpu_comp > 0
        blockL = 10.^(gpuArray(blockL)./10);
    else
        blockL = 10.^(blockL./10);
    end
    
    % data indices in full grid
    E_idx = round((blockE-minGridE)/grid_horz_res+1);
    N_idx = round((blockN-minGridN)/grid_horz_res+1);
    
    clear blockE blockN
    
    % first index
    idx_E_start = min(E_idx);
    idx_N_start = min(N_idx);
    
    % data indices in temp grid
    E_idx = E_idx - min(E_idx) + 1;
    N_idx = N_idx - min(N_idx) + 1;
    
    % size of temp grid
    N_E = max(E_idx);
    N_N = max(N_idx);
    
    % now gridding...
    switch grid_type
        
        case '2D'
            
            clear blockH
            
            % prepare indices
            subs = single([N_idx' E_idx']);
            clear N_idx E_idx
            
            if gpu_comp > 0
                gridCountTemp = gather(accumarray(subs,gpuArray(ones(block_size,'single')),single([N_N N_E]),@sum,single(0)));
                gridSumTemp   = gather(accumarray(subs,gpuArray(blockL'),single([N_N N_E]),@sum,single(0)));
            else
                gridCountTemp = accumarray(subs,ones(block_size,'single'),single([N_N N_E]),@sum,single(0));
                gridSumTemp   = accumarray(subs,blockL',single([N_N N_E]),@sum,single(0));
            end
            
            clear blockL subs
            
            % Summing sums in full grid
            gridCount(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1) = ...
                gridCount(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1)+gridCountTemp;
            
            % Summing density in full grid
            gridSum(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1) = ...
                gridSum(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1)+gridSumTemp;
            
        case '3D'
            
            % prepare indices
            H_idx = round((blockH-minGridH)/grid_vert_res+1);
            clear blockH
            idx_H_start = min(H_idx);
            H_idx = H_idx - min(H_idx) + 1;
            N_H = max(H_idx);
            subs = single([N_idx' E_idx' H_idx']);
            clear N_idx E_idx H_idx
            
            if gpu_comp > 0
                gridCountTemp = gather(accumarray(subs,gpuArray(ones(block_size,'single')),single([N_N N_E N_H]),@sum,single(0)));
                gridSumTemp   = gather(accumarray(subs,gpuArray(blockL'),single([N_N N_E N_H]),@sum,single(0)));
            else
                gridCountTemp = accumarray(subs,gpuArray(ones(block_size,'single'),single([N_N N_E N_H]),@sum,single(0)));
                gridSumTemp   = accumarray(subs,blockL',single([N_N N_E N_H]),@sum,single(0));
            end
            clear blockL subs
            
            % Summing sums in full grid
            gridCount(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1,idx_H_start:idx_H_start+N_H-1) = ...
                gridCount(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1,idx_H_start:idx_H_start+N_H-1)+gridCountTemp;
            
            % Summing density in full grid
            gridSum(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1,idx_H_start:idx_H_start+N_H-1) = ...
                gridSum(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1,idx_H_start:idx_H_start+N_H-1)+gridSumTemp;
            
    end
    
    clear gridCountTemp gridSumTemp
    
end


%% crop the edges of the grids (they were built based on original data size)
switch grid_type
    
    case '2D'
        
        % dimensional sums
        sumGridCount_N = sum(gridCount,2);
        sumGridCount_E = sum(gridCount,1);
        
        % min and max indices for cropping
        minNidx = find(sumGridCount_N,1,'first');
        maxNidx = find(sumGridCount_N,1,'last');
        minEidx = find(sumGridCount_E,1,'first');
        maxEidx = find(sumGridCount_E,1,'last');
        
        % crop count and sum
        gridCount = gridCount(minNidx:maxNidx,minEidx:maxEidx);
        gridSum   = gridSum(minNidx:maxNidx,minEidx:maxEidx);
        
        % define and crop dim vectors
        gridNorthing = (0:numElemGridN-1)'.*grid_horz_res + minGridN;
        gridEasting  = (0:numElemGridE-1) .*grid_horz_res + minGridE;
        gridNorthing = gridNorthing(minNidx:maxNidx);
        gridEasting  = gridEasting(:,minEidx:maxEidx);
        
    case '3D'
        
        % dimensional sums
        sumGridCount_1EH = sum(gridCount,1);
        sumGridCount_N1H = sum(gridCount,2);
        sumGridCount_N = sum(sumGridCount_N1H,3);
        sumGridCount_E = sum(sumGridCount_1EH,3);
        sumGridCount_H = sum(sumGridCount_1EH,2);
        
        % min and max indices for cropping
        minNidx = find(sumGridCount_N,1,'first');
        maxNidx = find(sumGridCount_N,1,'last');
        minEidx = find(sumGridCount_E,1,'first');
        maxEidx = find(sumGridCount_E,1,'last');
        minHidx = find(sumGridCount_H,1,'first');
        maxHidx = find(sumGridCount_H,1,'last');
        
        % crop count and sum
        gridCount = gridCount(minNidx:maxNidx,minEidx:maxEidx,minHidx:maxHidx);
        gridSum   = gridSum(minNidx:maxNidx,minEidx:maxEidx,minHidx:maxHidx);
        
        % define and crop dim vectors
        gridNorthing = (0:numElemGridN-1)'.*grid_horz_res + minGridN;
        gridEasting  = (0:numElemGridE-1) .*grid_horz_res + minGridE;
        gridHeight   = permute((0:numElemGridH-1).*grid_horz_res + minGridH,[3,1,2]);
        gridNorthing = gridNorthing(minNidx:maxNidx);
        gridEasting  = gridEasting(:,minEidx:maxEidx);
        gridHeight   = gridHeight(:,:,minHidx:maxHidx);
        
end

% final calculations: average and back in dB
gridLevel = 10.*log10(gridSum./gridCount);

% revert gpuArrays back to regular arrays before storing so that data can
% be used even without the parallel computing toolbox and so that loading
% data don't overload the limited GPU memory
if gpu_comp > 0
    gridLevel = gather(gridLevel);
    gridCount = gather(gridCount);
end


%% saving results:

fData.X_NEH_gridLevel   = gridLevel;
fData.X_NEH_gridDensity = gridCount;
fData.X_1E_gridEasting  = gridEasting;
fData.X_N1_gridNorthing = gridNorthing;
fData.X_1_gridHorizontalResolution = grid_horz_res;

switch grid_type
    case '3D'
        fData.X_11H_gridHeight = gridHeight;
        fData.X_1_gridVerticalResolution = grid_vert_res;
end


