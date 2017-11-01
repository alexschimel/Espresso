%% CFF_grid_watercolumn_v2_temp.m
%
% Grids multibeam water-column data now in 3D instead of per slice
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |fData|:
% * varargin{1}: data to grid: 'original' or 'L1' or a field of fData of SBP
% size
% * varargin{2}: grid resolution in m
%
% *OUTPUT VARIABLES*
%
% * |output_variable_1|: TODO: write description and info on variable
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-10-06: New header
% * 2016-12-01: Also gridding bottom detect
% * 2014-04-30: First version
%
% *EXAMPLE*
%
% [gridEasting,gridNorthing,gridHeight,gridLevel,gridDensity] = CFF_grid_watercolumn(fData,'original',0.1)
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Alexandre Schimel, NIWA.

%% Function
function fData = CFF_grid_watercolumn_v2_temp(fData,varargin)

%% input parsing

% init
p = inputParser;

% required
addRequired(p,'fData',@isstruct);

% optional
addOptional(p,'dataToGrid','original',@(x) ischar(x));
addOptional(p,'res',1,@(x) isnumeric(x)&&x>0);
addOptional(p,'vert_res',1,@(x) isnumeric(x)&&x>0);
addOptional(p,'dim','3D',@(x) ismember(x,{'2D' '3D'}));
addOptional(p,'e_lim',[],@isnumeric);
addOptional(p,'n_lim',[],@isnumeric);
% addOptional(p,'dr_sub',1,@(x) isnumeric(x)&&x>0);
% addOptional(p,'db_sub',1,@(x) isnumeric(x)&&x>0);

% parse
parse(p,fData,varargin{:})

% get results
dataToGrid = p.Results.dataToGrid;
res = p.Results.res;
vert_res= p.Results.vert_res;
% dr  = p.Results.dr_sub;
% db  = p.Results.db_sub;

% subsampling now happening in conv_mat_2_fabc so disable it here, but keep
% code, aka:
dr = 1;
db = 1;

dim=p.Results.dim;

% get dimensions
[~,nBeams,nPings] = size(fData.WC_SBP_SampleAmplitudes.Data.val);

% block processing setup
blockLength = 10;
nBlocks = ceil(nPings./blockLength);
blocks = [ 1+(0:nBlocks-1)'.*blockLength , (1:nBlocks)'.*blockLength ];
blocks(end,2) = nPings;

% step 1. find grid limits

% init vectors
minBlockE = nan(1,nBlocks);
minBlockN = nan(1,nBlocks);
maxBlockE = nan(1,nBlocks);
maxBlockN = nan(1,nBlocks);

switch dim
    case '3D'
        maxBlockH = nan(1,nBlocks);
        minBlockH = nan(1,nBlocks);
end

% block processing
%[nSamples,nBeams,nPings] = size(fData.WC_SBP_SampleAmplitudes.Data.val);

nSamples=max(fData.WC_BP_DetectedRangeInSamples(:));

soundSpeed          = fData.WC_1P_SoundSpeed.*0.1; %m/s
samplingFrequencyHz = fData.WC_1P_SamplingFrequencyHz; %Hz
dr_samples = soundSpeed./(samplingFrequencyHz.*2);

gridConvergenceDeg  = fData.X_1P_pingGridConv; %deg
vesselHeadingDeg    = fData.X_1P_pingHeading; %deg
sonarHeadingOffsetDeg = fData.IP_ASCIIparameters.S1H; %deg


sonarH         =fData.X_1P_pingH; %m
sonarE        = fData.X_1P_pingE; %m
sonarN       = fData.X_1P_pingN; %m
heading = - mod( gridConvergenceDeg + vesselHeadingDeg + sonarHeadingOffsetDeg, 360 )/180*pi;

for iB = 1:nBlocks
    
    % list of pings in this block
    blockPings = (blocks(iB,1):blocks(iB,2));
    
    % Extract easting and northing of the first and last sample in outer
    % beams and central beam. Extract height of the first and last sample
    % in outer beams.

    
    [~,sampleAcrossDist,sampleUpDist]=get_samples_range_dist([1 nSamples]',...
        fData.WC_BP_StartRangeSampleNumber([1 round(nBeams./2) nBeams],blockPings)...
        ,dr_samples(blockPings),...
        fData.WC_BP_BeamPointingAngle([1 round(nBeams./2) nBeams],blockPings)/100/180*pi);
    
    [blockE,blockN,blockH]...
        =get_samples_ENH(...
        sonarE(blockPings),...
        sonarN(blockPings),...
        sonarH(blockPings),...
        heading(blockPings),...
        sampleAcrossDist,sampleUpDist);
    

    % these subset of all samples should be enough to find the bounds for
    % the entire block
    minBlockE(iB) = min(blockE(:));
    maxBlockE(iB) = max(blockE(:));
    minBlockN(iB) = min(blockN(:));
    maxBlockN(iB) = max(blockN(:));
    
    switch dim
        case '2D'
            clear blockPings blockE blockN
        case '3D'
            minBlockH(iB) = min(blockH(:));
            maxBlockH(iB) = max(blockH(:));
            clear blockPings blockE blockN blockH
    end
    
    
end

% Get grid boundaries from the min and max of those blocks
minGridE = floor(min(minBlockE));
minGridN = floor(min(minBlockN));

maxGridE = ceil(max(maxBlockE));
maxGridN = ceil(max(maxBlockN));

numElemGridE = ceil((maxGridE-minGridE)./res)+1;
numElemGridN = ceil((maxGridN-minGridN)./res)+1;

switch dim
    case '3D'
        maxGridH = ceil(max(maxBlockH));
        minGridH = floor(min(minBlockH));
        numElemGridH = ceil((maxGridH-minGridH)./vert_res)+1;
        
        gridSum   = zeros(numElemGridN,numElemGridE,numElemGridH,'single');
        gridCount = zeros(numElemGridN,numElemGridE,numElemGridH,'single');
    case '2D'
        gridSum   = zeros(numElemGridN,numElemGridE,'single');
        gridCount = zeros(numElemGridN,numElemGridE,'single');
end


% now with the grid ready, fill it in, again with block processing

% initialize grid

nSamples_tot=max(fData.WC_BP_DetectedRangeInSamples);
% block proc
for iB = 1:nBlocks
    
    % txt = sprintf('block #%i/%i',iB,nBlocks);
    % disp(txt);
    
    % list of pings in this block
       blockPings = (blocks(iB,1):blocks(iB,2));
        nSamples=max(nSamples_tot(blockPings));
       idx_samples = (1:nSamples)';

      [~,sampleUpDist,sampleAcrossDist]=get_samples_range_dist(...
          idx_samples,...
            fData.WC_BP_StartRangeSampleNumber(:,blockPings),...
            dr_samples(blockPings),...
            fData.WC_BP_BeamPointingAngle(:,blockPings)/100/180*pi);
        
        [blockE,blockN,blockH]...
            =get_samples_ENH(...
            sonarE(blockPings),...
            sonarN(blockPings),...
            sonarH(blockPings),...
            heading(blockPings),...
            sampleUpDist,sampleAcrossDist);
    % get field to grid
    switch dataToGrid
        case 'original'
            blockL = single(fData.WC_SBP_SampleAmplitudes.Data.val(1:dr:nSamples,1:db:nBeams,blockPings))./2;
        case 'masked original'
            blockL = single(fData.WC_SBP_SampleAmplitudes.Data.val(1:dr:nSamples,1:db:nBeams,blockPings))./2;
            blockL(fData.X_SBP_Mask.Data.val(1:dr:nSamples,1:db:nBeams,blockPings)==0)=nan;
        case 'L1'
            blockL = single(fData.X_SBP_L1.Data.val(1:dr:nSamples,1:db:nBeams,blockPings));
        case 'masked L1'
            blockL = single(fData.X_SBP_L1.Data.val(1:dr:nSamples,1:db:nBeams,blockPings));
            blockL(fData.X_SBP_Mask.Data.val(1:dr:nSamples,1:db:nBeams,blockPings)==0)=nan;
    end
    
    clear blockPings
    blockL(blockL==-128/2)=nan;
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
    % grid Level in natural before gridding
    
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
fData.X_NEH_gridLevel = single(10.*log10(gridSum./gridCount));
fData.X_NEH_gridDensity = gridCount;

%% saving more results
fData.X_1E_gridEasting  = (0:numElemGridE-1) .*res + minGridE;
fData.X_N1_gridNorthing = (0:numElemGridN-1)'.*res + minGridN;

switch dim
    case '3D'
        fData.X_11H_gridHeight  = permute((0:numElemGridH-1).*res + minGridH,[3,1,2]);
end
