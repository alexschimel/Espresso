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

if isnumeric(fData.WC_SBP_SampleAmplitudes)
    
    % if data is small enough to have been fitted in memory, run
    % calculations in memory
    
    % get field to grid
    switch varargin{1}
        case 'original'
            L = fData.WC_SBP_SampleAmplitudes./2;
        case 'L1'
            L = fData.X_SBP_L1;
        case 'masked L1'
            L = fData.X_SBP_L1 .* fData.X_SBP_Mask;
        otherwise
            if isfield(fData,varargin{1})
                Lfield = varargin{1};
                expression = ['L = fData.' Lfield ';'];
                eval(expression);
            else
                error('field not recognized')
            end
    end
    
    % get samples coordinates
    E = reshape(fData.X_SBP_sampleEasting,1,[]);
    N = reshape(fData.X_SBP_sampleNorthing,1,[]);
    H = reshape(fData.X_SBP_sampleHeight,1,[]);
    L = reshape(L,1,[]);
    
    % remove useless nans
    indLnan = isnan(L);
    E(indLnan) = [];
    N(indLnan) = [];
    H(indLnan) = [];
    L(indLnan) = [];
    
    % Use the min easting, northing and height (floored) in all non-NaN
    % samples as the first value for grids.
    minGridE = floor(min(E));
    minGridN = floor(min(N));
    minGridH = floor(min(H));
    
    % Idem for the last value to cover:
    maxGridE = ceil(max(E));
    maxGridN = ceil(max(N));
    maxGridH = ceil(max(H));
    
    % get grid resolution
    res = varargin{2};
    
    % define number of elements needed to cover max easting, northing and height
    numElemGridE = ceil((maxGridE-minGridE)./res)+1;
    numElemGridN = ceil((maxGridN-minGridN)./res)+1;
    numElemGridH = ceil((maxGridH-minGridH)./res)+1;
    
    % grid Level in natural before gridding
    L = 10.^(L./10);

    [gridLevel,gridDensity] = CFF_weightgrid_3D(E,N,H,L,[],[minGridE,res,numElemGridE],[minGridN,res,numElemGridN],[minGridH,res,numElemGridH]);

    % level back in dB
    gridLevel = 10.*log10(gridLevel);
    
    %% saving results
    fData.X_1E_gridEasting  = (0:numElemGridE-1) .*res + minGridE;
    fData.X_N1_gridNorthing = (0:numElemGridN-1)'.*res + minGridN;
    fData.X_11H_gridHeight  = permute((0:numElemGridH-1).*res + minGridH,[3,1,2]);
    fData.X_NEH_gridLevel   = gridLevel;
    fData.X_NEH_gridDensity = gridDensity;
    
    
elseif isobject(fData.WC_SBP_SampleAmplitudes)
    
    % if data were too big to have been fitted in memory, and were recorded
    % as binary files, run block-processing calculations and save results
    % as binary files.
    
    % get dimensions
    [nSamples,nBeams,nPings] = size(fData.X_SBP_sampleEasting.Data.val);
    
    % block processing setup
    blockLength = 10;
    nBlocks = ceil(nPings./blockLength);
    blocks = [ 1+(0:nBlocks-1)'.*blockLength , (1:nBlocks)'.*blockLength ];
    blocks(end,2) = nPings;
    
    % step 1. find grid limits
    
    % init vectors
    minBlockE = nan(1,nBlocks);
    minBlockN = nan(1,nBlocks);
    minBlockH = nan(1,nBlocks);
    maxBlockE = nan(1,nBlocks);
    maxBlockN = nan(1,nBlocks);
    maxBlockH = nan(1,nBlocks);
    
    % block processing
    for iB = 1:nBlocks
        
        % list of pings in this block
        blockPings = (blocks(iB,1):blocks(iB,2));
        
        % coordinates of the first and last sample in outer beams and
        % central beam, for each ping 
        blockE = double(fData.X_SBP_sampleEasting.Data.val([1 nSamples],[1 round(nBeams./2) nBeams],blockPings));
        blockN = double(fData.X_SBP_sampleNorthing.Data.val([1 nSamples],[1 round(nBeams./2) nBeams],blockPings));
        
        % height of the first and last sample in outer beams,for each ping 
        blockH = fData.X_SBP_sampleHeight.Data.val([1 nSamples],[1 nBeams],blockPings);
        
        % these subset of all samples should be enough to find the bounds
        % for the entire block
        minBlockE(iB) = min(blockE(:));
        maxBlockE(iB) = max(blockE(:));
        minBlockN(iB) = min(blockN(:));
        maxBlockN(iB) = max(blockN(:));
        minBlockH(iB) = min(blockH(:));
        maxBlockH(iB) = max(blockH(:));
        
    end

    % Get grid boundaries from the min and max of those blocks
    minGridE = floor(min(minBlockE));
    minGridN = floor(min(minBlockN));
    minGridH = floor(min(minBlockH));
    maxGridE = ceil(max(maxBlockE));
    maxGridN = ceil(max(maxBlockN));
    maxGridH = ceil(max(maxBlockH));
    
    % grid resolution from input
    res = varargin{2};
    
    % number of elements per grid
    numElemGridE = ceil((maxGridE-minGridE)./res)+1;
    numElemGridN = ceil((maxGridN-minGridN)./res)+1;
    numElemGridH = ceil((maxGridH-minGridH)./res)+1;
    
    % now with the grid ready, fill it in, again with block processing
    
    % first off, define decimtion factors
    dr = 5; % for range
    db = 2; % for beams
    
%     % TEST 1. averaging through the water column directly
%     
%     % initialize grid
%     gridSum_1 = zeros(numElemGridN,numElemGridE);
%     gridCount_1 = zeros(numElemGridN,numElemGridE);
%     
%     for iB = 1:nBlocks
%         
%         % txt = sprintf('block #%i/%i',iB,nBlocks);
%         % disp(txt);
%         
%         % list of pings in this block
%         blockPings = (blocks(iB,1):blocks(iB,2));
%         
%         % extract data needed
%         blockE = fData.X_SBP_sampleEasting.Data.val(1:dr:nSamples,1:db:nBeams,blockPings);
%         blockN = fData.X_SBP_sampleNorthing.Data.val(1:dr:nSamples,1:db:nBeams,blockPings);
%         blockL = fData.WC_SBP_SampleAmplitudes.Data.val(1:dr:nSamples,1:db:nBeams,blockPings)./2;
%         
%         % remove nans:
%         indNan = isnan(blockL);
%         blockE(indNan) = [];
%         blockN(indNan) = [];
%         blockL(indNan) = [];
%         
%         % data Level in natural before gridding
%         blockL = 10.^(blockL./10);
%         
%         % data indices in full grid
%         E_idx = round((blockE-minGridE)/res+1);
%         N_idx = round((blockN-minGridN)/res+1);
%         
%         % first index
%         idx_E_start = min(E_idx);
%         idx_N_start = min(N_idx);
%         
%         % data indices in temp grid
%         E_idx = E_idx - min(E_idx) + 1;
%         N_idx = N_idx - min(N_idx) + 1;
%         
%         % size of temp grid
%         N_E = max(E_idx);
%         N_N = max(N_idx);
%         
%         % data indices in temp grid
%         subs = [N_idx' E_idx'];
%         
%         % Number of data points in grid cell (density/weight)
%         gridCountTemp = accumarray(subs,ones(size(blockE')),[N_N N_E],@sum,0);
%         
%         % Sum of data points in grid cell
%         gridSumTemp = accumarray(subs,blockL',[N_N N_E],@sum,single(0));
%         
%         % Summing sums in full grid
%         gridCount_1(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1)=...
%             gridCount_1(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1) + gridCountTemp;
%         
%         % Summing density in full grid
%         gridSum_1(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1)=...
%             gridSum_1(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1) + gridSumTemp;
% 
%         
%     end
%     
%     % average, and back in dB
%     gridMeanLevel_1 = 10.*log10(gridSum_1./gridCount_1);
    
    
    % TEST 2. gridding in 3D (averaging later)
    
    % initialize grid
    gridSum = zeros(numElemGridN,numElemGridE,numElemGridH);
    gridCount = zeros(numElemGridN,numElemGridE,numElemGridH);
    
    for iB = 1:nBlocks
        
        % txt = sprintf('block #%i/%i',iB,nBlocks);
        % disp(txt);
        
        % list of pings in this block
        blockPings = (blocks(iB,1):blocks(iB,2));
        
        % extract data needed
        blockE = double(fData.X_SBP_sampleEasting.Data.val(1:dr:nSamples,1:db:nBeams,blockPings));
        blockN = double(fData.X_SBP_sampleNorthing.Data.val(1:dr:nSamples,1:db:nBeams,blockPings));
        blockH = double(fData.X_SBP_sampleHeight.Data.val(1:dr:nSamples,1:db:nBeams,blockPings));
        blockL = double(fData.WC_SBP_SampleAmplitudes.Data.val(1:dr:nSamples,1:db:nBeams,blockPings))./2;
        
        % remove nans:
        indNan = isnan(blockL);
        blockE(indNan) = [];
        blockN(indNan) = [];
        blockH(indNan) = [];
        blockL(indNan) = [];
        
        % data Level in natural before gridding
        blockL = 10.^(blockL./10);
        
        % data indices in full grid
        E_idx = round((blockE-minGridE)/res+1);
        N_idx = round((blockN-minGridN)/res+1);
        H_idx = round((blockH-minGridH)/res+1);
        
        % first index
        idx_E_start = min(E_idx);
        idx_N_start = min(N_idx);
        idx_H_start = min(H_idx);
        
        % data indices in temp grid
        E_idx = E_idx - min(E_idx) + 1;
        N_idx = N_idx - min(N_idx) + 1;
        H_idx = H_idx - min(H_idx) + 1;
        
        % size of temp grid
        N_E = max(E_idx);
        N_N = max(N_idx);
        N_H = max(H_idx);
        
        % data indices in temp grid
        subs = [N_idx' E_idx' H_idx'];
        
        % Number of data points in grid cell (density/weight)
        gridCountTemp = accumarray(subs,ones(size(blockH')),[N_N N_E N_H],@sum,0);
        
        % Sum of data points in grid cell
        gridSumTemp = accumarray(subs,blockL',[N_N N_E N_H],@sum,0);
        
        % Summing sums in full grid
        gridCount(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1,idx_H_start:idx_H_start+N_H-1) = ...
            gridCount(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1,idx_H_start:idx_H_start+N_H-1) + gridCountTemp;
        
        % Summing density in full grid
        gridSum(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1,idx_H_start:idx_H_start+N_H-1) = ...
            gridSum(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1,idx_H_start:idx_H_start+N_H-1) + gridSumTemp;
        
    end
    
    % average, and back in dB
    %gridMeanLevel = gridSum./gridCount;
    gridMeanLevel = 10.*log10(gridSum./gridCount);
    

    %% saving results
    fData.X_1E_gridEasting  = (0:numElemGridE-1) .*res + minGridE;
    fData.X_N1_gridNorthing = (0:numElemGridN-1)'.*res + minGridN;
    fData.X_11H_gridHeight  = permute((0:numElemGridH-1).*res + minGridH,[3,1,2]);
    fData.X_NEH_gridLevel   = gridMeanLevel;
    fData.X_NEH_gridDensity = gridCount;
    
    
end

