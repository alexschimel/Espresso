function X_BP_bottomSample = CFF_get_bottom_sample(fData,varargin)
%
% Get the bottom sample (per ping and beam) in fData. Precise the
% 'datagramSource' as either 'WC', 'AP', 'De', 'X8'. By default using the
% fData datagramSource. Also precise 'which' as either 'raw' (raw bottom
% sample) or 'processed' (as recorded after georeferencing and possibly
% filtering) (default).
%
% Not precising anything returns as the original code did, aka, using the
% fData datagramsource, and the processed version if it exists, or else the
% raw one.

% initialize input parser
p = inputParser;

% Required.
validate_fData = @isstruct;
addRequired(p,'fData',validate_fData);

% 'datagramSource': 
validate_datagramSource = @(x) ismember(x,{'WC','AP','De','X8'});
default_datagramSource = CFF_get_datagramSource(fData);
addOptional(p,'datagramSource',default_datagramSource,validate_datagramSource);

% 'which':
validate_which = @(x) ismember(x,{'raw','processed'});
default_which = 'processed';
addOptional(p,'which',default_which,validate_which);

% parsing actual inputs
parse(p,fData,varargin{:});

% saving results individually
datagramSource = p.Results.datagramSource;
which          = p.Results.which;
clear p

if strcmp(which,'processed') && isfield(fData,sprintf('X_BP_bottomSample_%s',datagramSource))
    % extracting already processed (and possibly filtered) bottom sample
    X_BP_bottomSample = fData.(sprintf('X_BP_bottomSample_%s',datagramSource)); % in sample number
else
    % extracting raw bottom sample
    X_BP_bottomSample = fData.(sprintf('%s_BP_DetectedRangeInSamples',datagramSource)); % in sample number
    X_BP_bottomSample(X_BP_bottomSample==0) = NaN; 
end