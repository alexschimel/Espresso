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

% initialize Sum and Count grids
[numElemGridN,numElemGridE] = size(mosaic.mosaic_level);
mosaicSum   = zeros(numElemGridN,numElemGridE,'single');
mosaicCount = zeros(numElemGridN,numElemGridE,'single');

% loop over all files loaded
for iF = 1:numel(fData_tot)
    
    % get data and add tag mosaic
    fData = fData_tot{iF};
    mosaic.Fdata_ID(iF) = fData.ID;
    
    if ~isfield(fData,'X_1E_gridEasting')
        continue;
    end
    
    % get data
    E = fData.X_1E_gridEasting;
    N = fData.X_N1_gridNorthing;
    L = fData.X_NEH_gridLevel;
    if isa(L,'gpuArray')
        L = gather(L);
    end
    
    % if L has a height dimension, average through the water-column here
    % first (in natural values, then convert result back to dB).
    if size(L,3) > 1
        data = pow2db_perso(nanmean(10.^(L/10),3));
    else
        data = L;
    end
    
    % remove all data outside of mosaic boundaries
    idx_keep_E = E>E_lim(1) & E<E_lim(2);
    idx_keep_N = N>N_lim(1) & N<N_lim(2);
    E(~idx_keep_E) = [];
    N(~idx_keep_N) = [];
    data(~idx_keep_N,:) = [];
    data(:,~idx_keep_E) = [];
    
    % remove nans
    idx_nan = isnan(data);
    data(idx_nan) = [];
    
    % if no data within mosaic bounds, continue to next file
    if isempty(data)
        continue;
    end
    
    E_mat = repmat(E,numel(N),1);
    N_mat = repmat(N,1,numel(E));
    N_mat(idx_nan) = [];
    E_mat(idx_nan) = [];
    
    % turn data from dB to natural before mosaicking
    data = (10.^(data./10));
    
    E_idx = round((E_mat-E_lim(1))/res+1);
    N_idx = round((N_mat-N_lim(1))/res+1);
    
    idx_E_start = min(E_idx);
    idx_N_start = min(N_idx);
    
    E_idx = E_idx - min(E_idx) + 1;
    N_idx = N_idx - min(N_idx) + 1;
    
    N_E = max(E_idx);
    N_N = max(N_idx);
    
    subs = single([N_idx(:) E_idx(:)]);
    
    mosaicCountTemp = accumarray(subs, ones(size(data(:)'),'single'), single([N_N N_E]), @sum, single(0));
    
    mosaicSumTemp = accumarray(subs,data(:)',single([N_N N_E]),@sum,single(0));
    
    mosaicCount(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1) = mosaicCount(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1) + mosaicCountTemp;
    
    mosaicSum(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1) = mosaicSum(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1) + mosaicSumTemp;
    
    mosaic.Fdata_ID = [mosaic.Fdata_ID fData.ID];
    
end

mosaic.mosaic_level = single(10.*log10(mosaicSum./mosaicCount));

end

%% subfunctions

function db = pow2db_perso(pow)

pow(pow<0) = nan;
db = 10*log10(pow);

end


