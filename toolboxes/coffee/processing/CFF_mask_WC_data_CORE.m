function data = CFF_mask_WC_data_CORE(data, fData, blockPings, varargin)
%CFF_MASK_WC_DATA_CORE  One-line description
%
%   See also ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

% input parsing
try mask_angle = varargin{1};
catch
    mask_angle = inf; % default
end
try mask_closerange = varargin{2};
catch
    mask_closerange = 0; % default
end
try mask_bottomrange = varargin{3};
catch
    mask_bottomrange = inf; % default
end
try mypolygon = varargin{4};
catch
    mypolygon = []; % default
end
try mask_ping = varargin{5};
catch
    mask_ping = 100; % default
end

% data size
[nSamples, nBeams, ~] = size(data);

nPings = numel(blockPings);

% source datagram
datagramSource = CFF_get_datagramSource(fData);

% calculate inter-sample distance
interSamplesDistance = CFF_inter_sample_distance(fData);
interSamplesDistance = interSamplesDistance(blockPings);

% MASK 1: OUTER BEAMS REMOVAL
if ~isinf(mask_angle)
    
    % extract needed data
    angles = fData.(sprintf('%s_BP_BeamPointingAngle',datagramSource))(:,blockPings);
    
    % build mask: 1: to conserve, 0: to remove
    X_BP_OuterBeamsMask = angles>=-abs(mask_angle) & angles<=abs(mask_angle);
    
    X_1BP_OuterBeamsMask = permute(X_BP_OuterBeamsMask ,[3,1,2]);
    
else
    
    % conserve all data
    X_1BP_OuterBeamsMask = true(1,nBeams,nPings);
    
end

% MASK 2: CLOSE RANGE REMOVAL
if mask_closerange>0
    
    % extract needed data
    ranges = CFF_get_samples_range( (1:nSamples)', fData.(sprintf('%s_BP_StartRangeSampleNumber',datagramSource))(:,blockPings), interSamplesDistance);
    
    % build mask: 1: to conserve, 0: to remove
    X_SBP_CloseRangeMask = ranges>=mask_closerange;
    
else
    
    % conserve all data
    X_SBP_CloseRangeMask = true(nSamples,nBeams,nPings);
    
end

% MASK 3: BOTTOM RANGE REMOVAL
if ~isinf(mask_bottomrange)
    
    % beam pointing angle
    theta = deg2rad(fData.(sprintf('%s_BP_BeamPointingAngle',datagramSource))(:,blockPings));
    
    % beamwidth
    beamwidth = deg2rad(fData.Ru_1D_ReceiveBeamwidth(1));
    
    %% original version starts
    
    % beamwidth including beam steering
    psi = beamwidth./cos(abs(theta)).^2/2;
    
    % transition between normal and grazing incidence
    %         theta_lim = psi/2;
    %         idx_normal = abs(theta) < theta_lim;
    %         idx_grazing = ~idx_normal;
    %
    % length of bottom echo? XXX1
    % M = zeros(size(theta),'single');
    % M(idx_normal)  = ( 1./cos(theta(idx_normal)+psi(idx_normal)/2)   - 1./cos(theta(idx_normal)) ) .* fData.X_BP_bottomRange(idx_normal,blockPings);
    % M(idx_grazing) = 2*( sin(theta(idx_grazing)+psi(idx_grazing)/2) - sin(theta(idx_grazing)-psi(idx_grazing)/2) ) .* fData.X_BP_bottomRange(idx_grazing,blockPings);
    
    % Original equation looks like calculating horizontal distance of the
    % beam footprint assuming flat seafloor. But why the 2x?
    M_1 = abs( 2* (sin(abs(theta)+psi/2) - sin(abs(theta)-psi/2) ) ) .* fData.X_BP_bottomRange(:,blockPings);
    
    %% new version starts
    
    % actual beamwidth including beam steering
    psi = beamwidth./cos(abs(theta));
    
    % assuming flat seafloor, actual horizontal distance between start of
    % the beam footprint, and bottom.
    M_2 = ( sin(abs(theta)) - sin(abs(theta)-psi/2) ) .* fData.X_BP_bottomRange(:,blockPings);
    
    %% let's try another approach.
    % Let's approximate the range at which the beam footprint starts as the
    % minimum range within +-X beams around beam of interest
    M_3 = nan(size(fData.X_BP_bottomRange(:,blockPings)));
    for ip = 1:length(blockPings)
        
        bottomranges = fData.X_BP_bottomRange(:,blockPings(ip));
        nbeams = size(theta,1);
        X = 5;
        
        minrangefunc = @(ibeam) nanmin(bottomranges(max(1,ibeam-X):min(nbeams,ibeam+X)));
        M_3(:,ip) = bottomranges - arrayfun(minrangefunc,[1:nbeams]');
        
    end
    
    %% select method here for now
    M = M_3;
    
    % calculate max sample beyond which mask is to be applied
    X_BP_maxRange  = fData.X_BP_bottomRange(:,blockPings) + mask_bottomrange - M;
    X_BP_maxSample = bsxfun(@rdivide,X_BP_maxRange,interSamplesDistance);
    X_BP_maxSample = round(X_BP_maxSample);
    X_BP_maxSample(X_BP_maxSample>nSamples|isnan(X_BP_maxSample)) = nSamples;
    
    % build list of indices for each beam & ping
    [PP,BB] = meshgrid((1:nPings),(1:nBeams));
    maxSubs = [X_BP_maxSample(:),BB(:),PP(:)];
    
    % build mask: 1: to conserve, 0: to remove
    X_SBP_BottomRangeMask = false(nSamples,nBeams,nPings);
    for ii = 1:size(maxSubs,1)
        X_SBP_BottomRangeMask(1:maxSubs(ii,1),maxSubs(ii,2),maxSubs(ii,3)) = true;
    end
    
else
    
    % conserve all data
    X_SBP_BottomRangeMask = true(nSamples,nBeams,nPings);
    
end

% MASK 4: OUTSIDE POLYGON REMOVAL
if ~isempty(mypolygon)
    
    % build mask: 1: to conserve, 0: to remove
    X_SBP_PolygonMask = inpolygon( fData.X_SBP_sampleEasting.Data.val(:,:,blockPings), ...
        fData.X_SBP_sampleNorthing.Data.val(:,:,blockPings), ...
        mypolygon(:,1), ...
        mypolygon(:,2));
    
else
    
    % conserve all data
    X_SBP_PolygonMask = true(nSamples,nBeams,nPings);
    
end

% MASK 5: PINGS REMOVAL
if mask_ping<100
    
    % for now we will use the percentage of faulty bottom detects as a
    % threshold to mask the ping. Aka, if mask_ping=10, then we
    % will mask the  ping if 10% or more of its bottom detects are
    % faulty.
    % Quick data look up reveal show that good pings still misses up to 6%
    % of detects on the outer beams. A ping with some missing bottom
    % detects in the data is around 8-15%, so good rule of thumb would be
    % to use:
    % * mask_ping = 7 to remove all but perfect pings
    % * mask_ping between 10 and 20 to allow pings with a few missing detect
    % * mask_ping > 20 to remove only the most severly affected pings
    
    % extract needed data
    faulty_bottom = fData.(sprintf('%s_BP_DetectedRangeInSamples',datagramSource))(:,blockPings)==0;
    
    proportion_faulty_detect = 100.*sum(faulty_bottom)./nBeams;
    
    % build mask: 1: to conserve, 0: to remove
    X_1P_PingMask = proportion_faulty_detect<mask_ping;
    X_11P_PingMask = permute(X_1P_PingMask ,[3,1,2]);
    
else
    
    % conserve all data
    X_11P_PingMask = true(1,1,nPings);
    
end


% MULTIPLYING ALL MASKS
% for earlier versions of Matlab
% if verLessThan('matlab','9.1')
% mask_temp = X_SBP_CloseRangeMask & X_SBP_BottomRangeMask & X_SBP_PolygonMask;
% mask_temp = bsxfun(@and,X_1BP_OuterBeamsMask,mask_temp);
% mask = bsxfun(@and,X_11P_PingMask,mask_temp);

mask = X_11P_PingMask & X_1BP_OuterBeamsMask & X_SBP_CloseRangeMask & X_SBP_BottomRangeMask & X_SBP_PolygonMask;

% apply mask
data(~mask) = NaN;






