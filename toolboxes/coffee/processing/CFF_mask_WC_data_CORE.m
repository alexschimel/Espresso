function data = CFF_mask_WC_data_CORE(data, fData, blockPings, varargin)
%CFF_MASK_WC_DATA_CORE  One-line description
%
%   See also ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

global DEBUG;

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
try mask_minslantrange = varargin{6};
catch
    mask_minslantrange = 0; % default
end

% data size
[nSamples, nBeams, ~] = size(data);

nPings = numel(blockPings);

% source datagram
datagramSource = CFF_get_datagramSource(fData);

% calculate inter-sample distance
interSamplesDistance = CFF_inter_sample_distance(fData);
interSamplesDistance = interSamplesDistance(blockPings);


%% MASK 1: OUTER BEAMS REMOVAL
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


%% MASK 2: CLOSE RANGE REMOVAL
if mask_closerange>0
    
    % extract needed data
    ranges = CFF_get_samples_range( (1:nSamples)', fData.(sprintf('%s_BP_StartRangeSampleNumber',datagramSource))(:,blockPings), interSamplesDistance);
    
    % build mask: 1: to conserve, 0: to remove
    X_SBP_CloseRangeMask = ranges>=mask_closerange;
    
else
    
    % conserve all data
    X_SBP_CloseRangeMask = true(nSamples,nBeams,nPings);
    
end


%% MASK 3: BOTTOM RANGE REMOVAL
if ~isinf(mask_bottomrange)
    
    % some data needed
    
    % beam pointing angle
    theta = deg2rad(fData.(sprintf('%s_BP_BeamPointingAngle',datagramSource))(:,blockPings));
    
    % beamwidth
    beamwidth = deg2rad(fData.Ru_1D_ReceiveBeamwidth(1));
    
    % Some development still needed here, so for now doing a switch. Best
    % method so far is 3. Debug display after the switch.
    method = 3;
    
    switch method
        
        case 1
            % first developped version, from Yoann
            
            % beamwidth including increase with beam steering
            psi = beamwidth./cos(abs(theta)).^2/2;
            
            % transition between normal and grazing incidence
            theta_lim = psi/2;
            idx_normal = abs(theta) < theta_lim;
            idx_grazing = ~idx_normal;
            
            % prep
            R = fData.X_BP_bottomRange(:,blockPings); % range of bottom detect
            R1 = zeros(size(theta),'single');   % range of echo start
            
            % compute range for each regime
            R1(idx_normal)  = ( 1./cos(theta(idx_normal)+psi(idx_normal)/2)   - 1./cos(theta(idx_normal)) ) .* R(idx_normal);
            R1(idx_grazing) = 2*( sin(theta(idx_grazing)+psi(idx_grazing)/2) - sin(theta(idx_grazing)-psi(idx_grazing)/2) ) .* R(idx_grazing);
            
            % Alex comments: First, the equation for beamwidth increase
            % with beam steering is bizarre. I think it should be
            % psi/cos(theta)... Next, I don't get the equation for the
            % normal regime, but I can see the equation for the second
            % regime is meant to be the horizontal  distance of the
            % intercept of the beam on a flat seafloor... except I think
            % it's missing the abs() function to deal with negative
            % steering angles, and it's multiplied by two for some
            % reason...
            %
            % The main issue is: why the horizontal distance? We want the
            % RANGE at which the beam FIRST intercepts the seafloor.
            %
            % So let's not use that one, but keeping it because I don't
            % fully understand this and I want to keep it until I'm 100%
            % sure it is not correct
            
        case 2
            % second version, from Alex
            
            % first, what I think is the actual beamwidth including beam
            % steering:
            psi = beamwidth./cos(abs(theta));
            
            % recalculating the normal/grazing incidence regimes
            theta_lim = psi/2;
            idx_normal = abs(theta) < theta_lim;
            idx_grazing = ~idx_normal;
            
            % prep
            R = fData.X_BP_bottomRange(:,blockPings); % range of bottom detect
            R1 = zeros(size(theta),'single');   % range of echo start
            
            % in the grazing regime, assuming a depth D, the range at which
            % the echo starts is R1 obtained from:
            % cos(theta) = D/R and cos(theta-0.5*psi) = D/R1
            % Aka: R1 = R*(cos(theta)/cos(theta-0.5*psi))
            % Since we here want R-R1, then:
            % R1 = R( 1 - (cos(theta)/cos(theta-0.5*psi)) )
            R1(idx_grazing) = R(idx_grazing) .* ( 1 - (cos(abs(theta(idx_grazing)))./cos(abs(theta(idx_grazing))-0.5.*psi(idx_grazing))) );
            
            % in the normal regime, we just apply the value at the
            % regime-transition aka: R1 = R( 1 - cos(theta) )
            R1(idx_normal) = R(idx_normal) .* ( 1 - cos(abs(theta(idx_normal))) );
            
            % Alex comments: it's closer to the bottom echo, but on our
            % test data, it looks like the bottom detection is not always
            % at the same place in the bottom echo... did we forget some
            % angular correction for the placement of the bottom??
            
        case 3
            % third version, empirical
            
            % Since none of the two first versions work too well on our
            % test data, we try an empirical approach: We try to
            % approximate the range at which the beam footprint starts as
            % the minimum range within +-X beams around beam of interest
            X = 5;
            nbeams = size(theta,1);
            R1 = zeros(size(theta),'single');
            for ip = 1:length(blockPings)
                bottomranges = fData.X_BP_bottomRange(:,blockPings(ip));
                minrangefunc = @(ibeam) nanmin(bottomranges(max(1,ibeam-X):min(nbeams,ibeam+X)));
                R1(:,ip) = bottomranges - arrayfun(minrangefunc,[1:nbeams]');
            end
            
    end
    
    % DEBUG display...
    DEBUG = 0;
    if DEBUG
    	WCD = CFF_get_WC_data(fData,'WC_SBP_SampleAmplitudes',blockPings);
        WCD_x = 1:size(WCD,2);
        WCD_y = interSamplesDistance(1).*[1:size(WCD,1)];
        figure;imagesc(WCD_x,WCD_y,WCD(:,:,1)); colormap('jet'); grid on; hold on
        plot(fData.X_BP_bottomRange(:,1),'k.-')
        plot(fData.X_BP_bottomRange(:,1) - R1(:,1),'ko-');
    end
    
    % continuing with the value found 
    
    % calculate max sample beyond which mask is to be applied
    X_BP_maxRange  = fData.X_BP_bottomRange(:,blockPings) + mask_bottomrange - R1;
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


%% MASK 4: OUTSIDE POLYGON REMOVAL
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


%% MASK 5: PINGS REMOVAL
if mask_ping<100
    
    % for now we will use the percentage of faulty bottom detects as a
    % threshold to mask the ping. Aka, if mask_ping=10, then we
    % will mask the ping if 10% or more of its bottom detects are
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


%% MASK 6: REMOVE DATA BEYOND MIN SLANT RANGE
if mask_minslantrange
   
    % get range (in m) for all samples
    samplesRange = CFF_get_samples_range( (1:nSamples)', fData.(sprintf('%s_BP_StartRangeSampleNumber',datagramSource))(:,blockPings), interSamplesDistance);
    
    % get bottom range (in m)
    bottomRange = fData.X_BP_bottomRange(:,blockPings);
    
    % min slant range per ping
    bottomRange(bottomRange==0) = NaN;
    P1_minSlantRange = nanmin(bottomRange)';
    SBP_minSlantRange = repmat( permute(P1_minSlantRange,[3,2,1]),nSamples,nBeams);
    
    % build mask: 1: to conserve, 0: to remove
    X_SBP_MinSlantRangeMask = samplesRange < SBP_minSlantRange;
    
else 
    % conserve all data
    X_SBP_MinSlantRangeMask = true(nSamples,nBeams,nPings);
end



%% MULTIPLYING ALL MASKS
% for earlier versions of Matlab
% if verLessThan('matlab','9.1')
% mask_temp = X_SBP_CloseRangeMask & X_SBP_BottomRangeMask & X_SBP_PolygonMask;
% mask_temp = bsxfun(@and,X_1BP_OuterBeamsMask,mask_temp);
% mask = bsxfun(@and,X_11P_PingMask,mask_temp);

mask = X_11P_PingMask & X_1BP_OuterBeamsMask & X_SBP_CloseRangeMask & X_SBP_BottomRangeMask & X_SBP_PolygonMask & X_SBP_MinSlantRangeMask;

% apply mask
data(~mask) = NaN;






