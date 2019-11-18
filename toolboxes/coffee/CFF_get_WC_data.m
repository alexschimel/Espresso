%% CFF_get_WC_data.m
%
% Function to grab water column data in a fData structure, possibly
% subsampled in range or beams, or any pings required, in raw format or
% true value.
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
% * |fieldN|: Required. Description (Information). XXX
% * |iPing|: Optional. Description (Information). Default []. XXX
% * |dr_sub|: Optional. Description (Information). Default 1. XXX
% * |db_sub|: Optional. Description (Information). Default 1. XXX
% * |output_format|: Optional. Description (Information). 'raw' or 'true'
% (default) XXX

% *OUTPUT VARIABLES*
%
% _This section contains bullet points of output variables with description
% and information. See input variables for template. Example below to
% replace. Delete these lines XXX._
%
% * |data|: Description (Information). XXX
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
% * 2018-10-11: header
% * 2018-10-08: introduced option to extract data as raw or true. Info for
% the conversion not hard-coded anymore but obtained from fData
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
% Yoann Ladroit, Alexandre Schimel, NIWA.

%% Function
function data_tot = CFF_get_WC_data(fData,fieldN,varargin)


%% input parsing

% init
p = inputParser;


addRequired(p,'fieldN',@ischar);

% optional
addOptional(p,'iPing',[],@(x) isnumeric(x) ||isempty(x));
addOptional(p,'dr_sub',1,@(x) isnumeric(x) && x>0);
addOptional(p,'db_sub',1,@(x) isnumeric(x) && x>0);
addOptional(p,'output_format','true',@(x) ischar(x) && ismember(x,{'raw' 'true'}));
addParameter(p,'iBeam',[],@(x) isnumeric(x) ||isempty(x));
addParameter(p,'iRange',[],@(x) isnumeric(x) ||isempty(x));
% parse
parse(p,fieldN,varargin{:})

% get results
iPing = round(p.Results.iPing);
iBeam = p.Results.iBeam;
iRange = p.Results.iRange;


%% get raw data
if isempty(iPing)
    iPing = 1:cellfun(@(x) nansum(size(x.Data.val,3)),fData.(fieldN));
end
if isfield(fData,'WC_n_start')
    ping_group_start=fData.WC_n_start;
    ping_group_end=fData.WC_n_end;
else
    ping_group_start=fData.AP_n_start;
    ping_group_end=fData.AP_n_end;
end
%maxNSamples_groups=fData.([fieldN(1:2) '_n_maxNSamples']);

istart=find(ping_group_start<=nanmin(iPing),1,'last');
iend=find(ping_group_end>=nanmax(iPing),1,'first');

if isempty(iBeam)
    iBeam = 1:cellfun(@(x) nanmax(size(x.Data.val,2)),fData.(fieldN));
end

if isempty(iRange)
    iRange = 1:cellfun(@(x) nanmax(size(x.Data.val,1)),fData.(fieldN));
end

data_tot=nan(ceil(numel(iRange)/p.Results.dr_sub),ceil(numel(iBeam)/p.Results.db_sub),numel(iPing),'single');
ip=0;
% f=figure();
% ax=axes(f);
for ig=istart:iend
    iRange_tmp=iRange;
    iBeam_tmp=iBeam;
    iPing_tmp=iPing;
    iPing_tmp_gr=intersect(iPing_tmp,ping_group_start(ig):ping_group_end(ig));
    iPing_tmp=iPing_tmp_gr-ping_group_start(ig)+1;
    iRange_tmp(iRange_tmp>size(fData.(fieldN){ig}.Data.val,1)) = [];
    iBeam_tmp(iBeam_tmp>size(fData.(fieldN){ig}.Data.val,2))   = [];
    iPing_tmp(iPing_tmp>size(fData.(fieldN){ig}.Data.val,3))   = [];
    
    if isempty(iRange_tmp)||isempty(iBeam_tmp)||isempty(iPing_tmp)
        data_tot = [];
        continue;
    end
    
    data = fData.(fieldN){ig}.Data.val(iRange_tmp(1):p.Results.dr_sub:iRange_tmp(end),iBeam_tmp(1):p.Results.db_sub:iBeam_tmp(end),iPing_tmp);
    
    %% transform to true values if required
    switch p.Results.output_format
        
        case 'true'
            
            % get info about data
            idx_undsc = regexp(fieldN,'_');
            fact    = fData.(sprintf('%s_1_%s_Factor',fieldN(1:idx_undsc(1)-1),fieldN(idx_undsc(2)+1:end)));
            nan_val = fData.(sprintf('%s_1_%s_Nanval',fieldN(1:idx_undsc(1)-1),fieldN(idx_undsc(2)+1:end)));
            
            % convert to single class
            data = single(data);
            
            % add nans
            data(data==single(nan_val)) = single(NaN);
            
            % factor top get true dB values
            data = data*fact;
            
    end
    
    %     for i=1:size(data_tot,3)
    %         imagesc(ax,squeeze(data(:,:,i)));
    %         drawnow;
    %     end
    
    data_tot(1:size(data,1),1:(size(data,2)),ip+(1:(size(data,3))))=data;
    ip=ip+(size(data,3));
end


