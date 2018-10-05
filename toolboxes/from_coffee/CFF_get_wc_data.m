%
% Function to grab water column data in a fData structure, possibly
% subsampled in range or beams, or any pings required, in raw format or
% true value.

%% Function
function [data,nan_val] = CFF_get_wc_data(fData,fieldN,varargin)


%% input parsing

% init
p = inputParser;

% required
addRequired(p,'fData',@isstruct);
addRequired(p,'fieldN',@ischar);

% optional
addOptional(p,'iPing',[],@(x) isnumeric(x) ||isempty(x));
addOptional(p,'dr_sub',1,@(x) isnumeric(x) && x>0);
addOptional(p,'db_sub',1,@(x) isnumeric(x) && x>0);
addOptional(p,'fmt','true',@(x) ischar(x) && ismember(x,{'raw' 'true'}));

% parse
parse(p,fData,fieldN,varargin{:})

% get results
iPing = p.Results.iPing;
dr_sub = p.Results.dr_sub;
db_sub = p.Results.db_sub;
fmt = p.Results.fmt;
clear p


%% get proper info depending on field required

switch fieldN
    case 'WCAP_SBP_SampleAmplitudes'
        fact = 1/40;
        nan_val = -2^15;
    case 'WCAP_SBP_SamplePhase'
        fact = 1/30;
        nan_val = 0;
    case 'WC_SBP_SampleAmplitudes'
        fact = 1/2;
        nan_val = -128;
    case 'X_SBP_WaterColumnProcessed'
        fact = 1/2;
        nan_val = -128;
    otherwise
        fact = 1;
        nan_val = [];
end

%% get raw data
if ~isempty(iPing)
    data = fData.(fieldN).Data.val(1:dr_sub:end,1:db_sub:end,iPing);
else
    data = fData.(fieldN).Data.val(1:dr_sub:end,1:db_sub:end,:);
end

%% transform to true values if required
switch fmt
    case 'true'
        data = single(data)*fact;
        if ~isempty(nan_val)
            data(data==nan_val) = NaN;
        end
end



























