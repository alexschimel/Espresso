function [fData] = CFF_filter_WC_bottom_detect_v2(fData,varargin)
% [fData] = CFF_filter_WC_bottom_detect_v2(fData,varargin)
%
% DESCRIPTION
%
% Filter bottom detection in watercolumn data
%
% INPUT VARIABLES
%
% - varargin{1} "method": method for bottom filtering/processing
%   - noFilter: None
%   - alex: medfilt2 + inpaint_nans (default)
%   - amy: ...
%
% OUTPUT VARIABLES
%
% - fData
%
% RESEARCH NOTES
%
% NEW FEATURES
%
% * 2017-10-10: new v2 functions because of dimensions swap (Alex Schimel)
% - 2016-12-01: Using the new "X_PB_bottomSample" field in fData rather
% than "b1"
% - 2016-11-07: First version. Code taken from CFF_filter_watercolumn.m
%
%%%
% Alex Schimel, Deakin University
%%%



%% INPUT PARSER

% initialize input parser
p = inputParser;

% 'fData': The multibeam data structure.
% Required.
validate_fData = @isstruct;
addRequired(p,'fData',validate_fData);

% 'method': apply median filter to all bottom detects (filter), or find &
% delete bad bottom detects (flag).
% Optional -> Default: 'filter'.
validate_method = @(x) ismember(x,{'filter','flag'});
default_method = 'filter';
addOptional(p,'method',default_method,validate_method);

% 'pingBeamWindowSize': the number of pings and beams to define neighbours
% to each bottom detect. 1x2 int array, valid entries zero or positive.
% set 0 to use just current ping, inf for all pings (long computing time)
% set 0 to use just current beam, inf for all beams (long computing time)
% Optional -> Default: [5,5].
validate_pingBeamWindowSize = @(x) validateattributes(x,{'numeric'},{'size',[1,2],'integer','nonnegative'});
default_pingBeamWindowSize = [5,5];
addOptional(p,'pingBeamWindowSize',default_pingBeamWindowSize,validate_pingBeamWindowSize);

% 'maxHorizDist': maximum horizontal distance to consider neighbours. valid
% entries: numeric, non-zero, positive. Use inf to indicate NOT using a max 
% horizontal distance.
% Optional - Default: inf
validate_maxHorizDist = @(x) validateattributes(x,{'numeric'},{'scalar','positive'});
default_maxHorizDist = inf;
addOptional(p,'maxHorizDist',default_maxHorizDist,validate_maxHorizDist);

% 'interpolate': interpolate missing values or not. char, valid entries
% 'yes or 'no'. 
% Optional -> Default 'yes'
validate_interpolate = @(x) ismember(x,{'yes','no'});
default_interpolate = 'yes';
addOptional(p,'interpolate',default_interpolate,validate_interpolate);

% optional 'flagParams', struct with fields:
% * type, char, valid entries 'all' or 'median'
% * variable, char, valid entries 'slope', 'eucliDist' or 'vertDist'
% * threshold, num
validate_flagParams = @(x) isstruct(x);
default_flagParams = struct('type','all','variable','vertDist','threshold',1);
addOptional(p,'flagParams',default_flagParams,validate_flagParams);

% parsing actual inputs
parse(p,fData,varargin{:});

% saving results individually
flagParams = p.Results.flagParams;
interpolateFlag = p.Results.interpolate;
maxHorizDist = p.Results.maxHorizDist;
method = p.Results.method;
pingBeamWindowSize = p.Results.pingBeamWindowSize;
clear p

%% PRE-PROCESSING

% extract needed data
b0 = fData.X_BP_bottomSample;
bE = fData.X_BP_bottomEasting;
bN = fData.X_BP_bottomNorthing;
bH = fData.X_BP_bottomHeight;

b0(b0==0) = NaN; % repace no detects by NaNs

% dimensions
nBeams = size(b0,1);
nPings = size(b0,2);

% initialize results
b1 = b0;


%% PROCESSSING
switch method
    
    case 'filter'
        
        if isinf(maxHorizDist)
            
            % filter method, no limit on horiz distance
            for pp = 1:nPings
                for bb = 1:nBeams
                    % find the subset of all bottom detects within set interval in pings and beams
                    pmin = max(1,pp-pingBeamWindowSize(1));
                    pmax = min(nPings,pp+pingBeamWindowSize(1));
                    bmin = max(1,bb-pingBeamWindowSize(2));
                    bmax = min(nBeams,bb+pingBeamWindowSize(2));
                    % get bottom for subset
                    subBottom = b0(bmin:bmax,pmin:pmax);
                    % compute median value
                    b1(bb,pp) = median(subBottom(:),'omitnan');
                end
            end
            
        else
            
            % filter method, with limit on horiz distance
            for pp = 1:nPings
                for bb = 1:nBeams
                    % find the subset of all bottom detects within set interval in pings and beams
                    pmin = max(1,pp-pingBeamWindowSize(1));
                    pmax = min(nPings,pp+pingBeamWindowSize(1));
                    bmin = max(1,bb-pingBeamWindowSize(2));
                    bmax = min(nBeams,bb+pingBeamWindowSize(2));
                    % get bottom for subset
                    subBottom = b0(bmin:bmax,pmin:pmax);
                    % get easting and northing
                    subEasting = bE(bmin:bmax,pmin:pmax);
                    subNorthing = bN(bmin:bmax,pmin:pmax);
                    % compute horizontal distance in m
                    subHzDist = sqrt( (bE(bb,pp)-subEasting).^2 + (bN(bb,pp)-subNorthing).^2 );
                    % keep only subset within desired horizontal distance
                    subBottom(subHzDist>maxHorizDist) = NaN;
                    % compute median value
                    b1(bb,pp) = median(subBottom(:),'omitnan');
                end
            end
            
        end
        
    case 'flag'
        
        % get flagging type first
        switch flagParams.type
            case 'all'
                f = @(x)all(x);
            case 'median'
                f = @(x)median(x);
            case 'any'
                f = @(x)any(x);
            otherwise
                error('flagParams.type not recognized')
        end
        
        % next, processing for each bottom detect (BT)
        for pp = 1:nPings
            for bb = 1:nBeams
                % first off, flag method is inapplicable if BT doesn't exist.
                if isnan(b0(bb,pp))
                    % keep b1(bb,pp) as Nan.
                    continue
                end
                % find the subset of all bottom detects within set interval in pings and beams
                pmin = max(1,pp-pingBeamWindowSize(1));
                pmax = min(nPings,pp+pingBeamWindowSize(1));
                bmin = max(1,bb-pingBeamWindowSize(2));
                bmax = min(nBeams,bb+pingBeamWindowSize(2));
                % index of BT in the subset
                pid = find(pp==pmin:pmax);
                bid = find(bb==bmin:bmax);
                % get easting, northing and height
                subEasting = bE(bmin:bmax,pmin:pmax);
                subNorthing = bN(bmin:bmax,pmin:pmax);
                subHeight = bH(bmin:bmax,pmin:pmax);
                % remove the BT itself from the subset
                subEasting(bid,pid) = NaN;
                subNorthing(bid,pid) = NaN;
                subHeight(bid,pid) = NaN;
                % compute horizontal distance in m
                subHzDist = sqrt( (bE(bb,pp)-subEasting).^2 + (bN(bb,pp)-subNorthing).^2 );
                % keep only subset within desired horizontal distance
                subEasting(subHzDist>maxHorizDist) = NaN;
                subNorthing(subHzDist>maxHorizDist) = NaN;
                subHeight(subHzDist>maxHorizDist) = NaN;
                subHzDist(subHzDist>maxHorizDist) = NaN;
                % if there are no subset left, flag that bottom anyway
                if all(isnan(subHzDist(:)))
                    b1(bb,pp) = NaN;
                    continue
                end
                % compute vertical distance in m
                subVertDist = subHeight-bH(bb,pp);
                % now switch on the flagging variable
                switch flagParams.variable
                    case 'vert'
                        v = subVertDist(:);
                    case 'eucl'
                        % compute euclidian distance in m
                        subEucliDist = sqrt( subHzDist.^2 + subVertDist.^2);
                        v = subEucliDist(:);
                    case 'slope'
                        % compute slope in degrees
                        subSlope = atan2(subVertDist,subHzDist) .*pi/180;
                        v = subSlope(:);
                    otherwise
                        error('flagParams.variable not recognized')
                end
                % finally, apply flagging decision
                if f(abs(v)) > flagParams.threshold
                    b1(bb,pp) = NaN;
                end
            end
        end
        
    otherwise
        
        error('method not recognized');
end



% NOTE: OLD METHOD:
% % apply a median filter (medfilt1 should do about the same)
% % fS = ceil((p.Results.beamFilterLength-1)./2);
% fS = pingBeamWindowSize(2);
% for ii = 1+fS:nBeams-fS
%   for jj=1:nPings
%         tmp = b0(ii,jj-fS:jj+fS);
%         tmp = tmp(~isnan(tmp(:)));
%         if ~isempty(tmp)
%             b2(ii,jj) = median(tmp);
%         end
%     end
% end


%% INTERPOLATE
switch interpolateFlag
    
    case 'yes'
        
        b1 = round(CFF_inpaint_nans(b1));
        
        % safeguard against inpaint_nans occasionally yielding numbers
        % below zeros in areas where there are a lot of nans:
        b1(b1<1)=2;
        
end



%% TEST DISPLAY
% figure;
% minb = min([b0(:);b1(:)]); maxb= max([b0(:);b1(:)]);
% subplot(221); imagesc(b0); colorbar; title('range of raw bottom'); caxis([minb maxb])
% subplot(222); imagesc(b1); colorbar; title('range of filtered bottom'); caxis([minb maxb])
% subplot(223); imagesc(b1-b0); colorbar; title('filtered minus raw')

%% SAVING RESULTS
fData.X_BP_bottomSample = b1;

%% RE-PROCESSING BOTTOM FROM RESULTS
fData = CFF_process_WC_bottom_detect_v2(fData);






