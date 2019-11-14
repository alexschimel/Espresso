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
function [mosaic, fData_tot] = prep_mosaic(mosaic,fData_tot)

% mosaic boundaries
E_lim = mosaic.E_lim;
N_lim = mosaic.N_lim;

for iF = 1:numel(fData_tot)
    
    fData = fData_tot{iF};
    
    if ~isfield(fData,'X_1E_gridEasting')
        mosaic.Fdata_ID(iF) = 0;
        continue;
    end
    
    E = fData.X_1E_gridEasting;
    N = fData.X_N1_gridNorthing;
    
    % check if overlap between data grid boundaries and mosaic boundaries
    idx_keep_E = E>E_lim(1) & E<E_lim(2);
    idx_keep_N = N>N_lim(1) & N<N_lim(2);
    
    if ~any(idx_keep_E) || ~any(idx_keep_N)
        % no overlap
        mosaic.Fdata_ID(iF) = 0;
        continue;
    end
    
    % if still here, there is some overlap. But that overlap might not
    % actually contain data, so check for this too
    
    % grab data and format if necessary
    L = fData.X_NEH_gridLevel;
    
    if isa(L,'gpuArray')
        L = gather(L);
    end
    if size(L,3)>1
        L = nanmean(L,3);
    end
    
    % remove the data falling outside the mosaic
    L(~idx_keep_N,:) = [];
    L(:,~idx_keep_E) = [];
    
    % check if data remaining is all NaN
    if all(isnan(L(:)))
        % no data within requested mosaic bounds for that fData
        mosaic.Fdata_ID(iF) = 0;
        continue;
    end
    
    % if still here, this file can contribute to the mosaic
    mosaic.Fdata_ID(iF) = fData.ID;
    
    % is this file's resolution worst than what we have so far
    mosaic.res = nanmax(fData.X_1_gridHorizontalResolution,mosaic.res);
    
end

% remove from fData_tot those that are not necessary anymore
fData_tot(mosaic.Fdata_ID==0) = [];

% remove the blank IDs
mosaic.Fdata_ID(mosaic.Fdata_ID==0) = [];

% if any overlapping file has been found and coarsest resolution found,
% initialize the mosaic 
if mosaic.res>0
    numElemMosaicE = ceil((E_lim(2)-E_lim(1))./mosaic.res)+1;
    numElemMosaicN = ceil((N_lim(2)-N_lim(1))./mosaic.res)+1;
    mosaic.mosaic_level = zeros(numElemMosaicN,numElemMosaicE,'single');
else
    mosaic.mosaic_level = single([]);
end

mosaic.best_res = mosaic.res;



