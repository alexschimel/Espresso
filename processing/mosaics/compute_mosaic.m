%% this_function_name.m
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
% * |input_variable_1|: Description (Information). XXX
% * |input_variable_2|: Description (Information). XXX
% * |input_variable_3|: Description (Information). XXX
%
% *OUTPUT VARIABLES*
%
% _This section contains bullet points of output variables with description
% and information. See input variables for template. Example below to
% replace. Delete these lines XXX._
%
% * |output_variable_1|: Description (Information). XXX
% * |output_variable_2|: Description (Information). XXX
%
% *DEVELOPMENT NOTES*
%
% _This section describes what features are temporary, needed future
% developments and paper references. Example below to replace. Delete these
% lines XXX._
%
% * research point 1. XXX
% * research point 2. XXX
%
% *NEW FEATURES*
%
% _This section contains dates and descriptions of major updates. Example
% below to replace. Delete these lines XXX._
%
% * YYYY-MM-DD: second version. Describes the update. XXX
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
% _This last section contains at least author name and affiliation. Delete
% these lines XXX._
%
% Yoann Ladroit, Alexandre Schimel, NIWA. XXX

%% Function
function mosaic = compute_mosaic(mosaic,fData_tot)

E_lim = mosaic.E_lim;
N_lim = mosaic.N_lim;
res   = mosaic.res;

if res<mosaic.best_res
    warning('Cannot mosaic data at higher resolution than coarsest constituent grid. Best resolution possible is %.2g m.', mosaic.best_res);
    return
end

%% initalize the grids:
% weighted sum and total sum of weights.
% in absence of weights, the total sum of weights is simply the count of
% points, and the weighted sum is simply the sum
[numElemGridN,numElemGridE] = size(mosaic.mosaic_level);
mosaicWeightedSum = zeros(numElemGridN,numElemGridE,'single');
mosaicTotalWeight = zeros(numElemGridN,numElemGridE,'single');

% Test if GPU is avaialble for computation and setup for it
gpu_comp = get_gpu_comp_stat();
if gpu_comp > 0
    mosaicWeightedSum = gpuArray(mosaicWeightedSum);
    mosaicTotalWeight = gpuArray(mosaicTotalWeight);
end

% loop over all files loaded
for iF = 1:numel(fData_tot)
    
    % get data
    fData = fData_tot{iF};
    E = fData.X_1E_gridEasting;
    N = fData.X_N1_gridNorthing;
    L = fData.X_NEH_gridLevel;
    W = fData.X_NEH_gridDensity;
    if ~gpu_comp
        if isa(L,'gpuArray')
            L = gather(L);
        end
        if isa(W,'gpuArray')
            W = gather(W);
        end
    else
        if ~isa(L,'gpuArray')
            L = gpuArray(L);
        end
        if ~isa(W,'gpuArray')
            W = gpuArray(W);
        end
    end
    
    % if L has a height dimension, average through the water-column
    if size(L,3) > 1
        L = nanmean(L,3);
    end
    if size(W,3) > 1
        W = nansum(W,3);
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
    
    % vectorize
    [numel_N, numel_E] = size(L);
    E = repmat(E,numel_N,1);
    N = repmat(N,1,numel_E);
    E = E(:);
    N = N(:);
    L = L(:);
    W = W(:);
    
    % remove nans
    indNan = isnan(L);
    E(indNan) = [];
    N(indNan) = [];
    L(indNan) = [];
    W(indNan) = [];
    
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
    subs    = single([N_idx E_idx]); % indices in the temp grid of each data point
    sz      = single([N_N N_E]);     % size of ouptut
    fillval = single(0);             % filling value in output if no data contributed
    
    % calculate the sum of weights per mosaic cell
    mosaicTotalWeightTemp = accumarray(subs,W',sz,@sum,fillval);
    
    % calculate the sum of weighted levels per mosaic cell
    mosaicWeightedSumTemp = accumarray(subs,W'.*L',sz,@sum,fillval);
    
    % Add the temp mosaic of weights sum to the full one
    mosaicTotalWeight(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1) = ...
        mosaicTotalWeight(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1) + mosaicTotalWeightTemp;
    
    % Add the temp mosaic of sum of weighted levels to the full one
    mosaicWeightedSum(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1) = ...
        mosaicWeightedSum(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1) + mosaicWeightedSumTemp;
        
end

% final calculations: average and back in dB
mosaic_level = 10.*log10(mosaicWeightedSum./mosaicTotalWeight);

if isa(mosaic_level,'gpuArray')
    mosaic_level = gather(mosaic_level);
end

% save
mosaic.mosaic_level = mosaic_level;

end



