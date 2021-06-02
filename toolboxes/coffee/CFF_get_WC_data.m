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
% XXX
%
% *INPUT VARIABLES*
%
% XXX
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
% XXX
%
% * |data|: Description (Information). XXX
%
% *DEVELOPMENT NOTES*
%
% XXX
%
% * research point 1. XXX
% * research point 2. XXX
%
% *NEW FEATURES*
%
% * 2018-10-11: header
% * 2018-10-08: introduced option to extract data as raw or true. Info for
% the conversion not hard-coded anymore but obtained from fData
% * YYYY-MM-DD: first version. XXX
%
% *EXAMPLE*
%
% XXX
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, Alexandre Schimel NIWA. Type |help Espresso.m| for
% copyright information.

%% Function
function data_tot = CFF_get_WC_data(fData,fieldN,varargin)

% input parsing
p = inputParser;
addRequired(p,'fieldN',@ischar);
addOptional(p,'iPing',[],@(x) isnumeric(x) ||isempty(x));
addOptional(p,'dr_sub',1,@(x) isnumeric(x) && x>0);
addOptional(p,'db_sub',1,@(x) isnumeric(x) && x>0);
addOptional(p,'output_format','true',@(x) ischar(x) && ismember(x,{'raw' 'true'}));
addParameter(p,'iBeam',[],@(x) isnumeric(x) ||isempty(x));
addParameter(p,'iRange',[],@(x) isnumeric(x) ||isempty(x));
parse(p,fieldN,varargin{:})
iPing  = round(p.Results.iPing);
iBeam  = p.Results.iBeam;
iRange = p.Results.iRange;

dg = CFF_get_datagramSource(fData);

if isempty(iPing)
    iPing = 1:cellfun(@(x) nansum(size(x.Data.val,3)),fData.(fieldN));
end

% exit clauses
if ~isfield(fData,fieldN)
    data_tot = [];
    return;
end
if ~ismember(dg,{'WC','AP'})
    data_tot = [];
    return;
end

p_end   =  fData.(sprintf('%s_n_end',dg));
p_start =  fData.(sprintf('%s_n_start',dg));

pingCounter = fData.(sprintf('%s_1P_PingCounter',dg));
p_end(p_end>numel(pingCounter))     = numel(pingCounter);
p_start(p_start>numel(pingCounter)) = numel(pingCounter);

ping_group_start = pingCounter(p_start);
ping_group_end = pingCounter(p_end);

istart = find( ping_group_start<=nanmin(pingCounter(iPing)), 1, 'last' );
iend   = find( ping_group_end>=nanmax(pingCounter(iPing)), 1, 'first' );

if isempty(iBeam)
    iBeam = 1:cellfun(@(x) nanmax(size(x.Data.val,2)),fData.(fieldN));
end

if isempty(iRange)
    iRange = 1:cellfun(@(x) nanmax(size(x.Data.val,1)),fData.(fieldN));
end

data_tot = nan(ceil(numel(iRange)/p.Results.dr_sub),ceil(numel(iBeam)/p.Results.db_sub),numel(iPing),'single');
ip = 0;
% f = figure();
% ax = axes(f);
for ig = istart:iend
    
    iRange_tmp = iRange;
    iBeam_tmp = iBeam;
    iPing_tmp = pingCounter(iPing);
    
    iPing_tmp_gr = intersect(iPing_tmp,ping_group_start(ig):ping_group_end(ig));
    
    iPing_tmp = iPing_tmp_gr-ping_group_start(ig)+1;
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
            dg = fieldN(1:idx_undsc(1)-1);
            fieldname = fieldN(idx_undsc(2)+1:end);
            
            % get NaN value (should be a single value)
            Nanval = fData.(sprintf('%s_1_%s_Nanval',dg,fieldname));
            
            % get factor (one per memmap file in the new format)
            Fact = fData.(sprintf('%s_1_%s_Factor',dg,fieldname));
            if numel(Fact)>1
                Fact = Fact(ig);
            end
                
            % get offset (doesn't exist for older format, one per memmap
            % file in the new format) 
            offset_fieldname = sprintf('%s_1_%s_Offset',dg,fieldname);
            if isfield(fData, offset_fieldname)
                Offset = fData.(offset_fieldname);
            else
                Offset = 0;
            end
            
            if numel(Offset)>1
                Offset = Offset(ig);
            end
            
            if ~isa(data,'single')
                
                % first, convert to single class
                data = single(data);
                
                % reset NaN value
                data(data==single(Nanval)) = single(NaN);
                
                % decode data, mnimizing calculation time
                if Fact~=1 && Offset~=0
                    data = data*Fact+Offset;
                elseif Fact~=1 && Offset==0
                    data = data*Fact;
                elseif Fact==1 && Offset~=0
                    data = data+Offset;
                end
                
            end
          
    end
    
    %     for i = 1:size(data_tot,3)
    %         imagesc(ax,squeeze(data(:,:,i)));
    %         drawnow;
    %     end
    
    data_tot(1:size(data,1),1:(size(data,2)),ip+(1:(size(data,3)))) = data;
    ip = ip + (size(data,3));
    
end




