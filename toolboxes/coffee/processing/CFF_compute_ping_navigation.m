function [fData] = CFF_compute_ping_navigation(fData,varargin)
%CFF_COMPUTE_PING_NAVIGATION  Interpolates navigation data to ping time
%
%   Interpolates navigation data from ancillary sensors to ping time (i.e.
%   Easting, Northing, Height, Grid Convergence, Heading, Speed).
%
%   *INPUT VARIABLES
%   * |fData|: Required. Structure for the storage of kongsberg EM series
%   multibeam data in a format more convenient for processing. The data is
%   recorded as fields coded "a_b_c" where "a" is a code indicating data
%   origing, "b" is a code indicating data dimensions, and "c" is the data
%   name. See the help of function CFF_convert_ALLdata_to_fData.m for
%   description of codes.
%   * |datagramSource| (optional): 'De', 'SI', 'WC', etc... as the
%   source datagram to use for time/date/pingcounter. If not specified,
%   function will look in order for "De", "X8" or "WC". Returns error if
%   can't find any of these three.
%   * |ellips| (optional): see "CFF_ll2tm.m" for options. If not
%   specified, function will use 'wgs84'
%   * |tmproj| (optional): see "CFF_ll2tm.m" for options. If not
%   specified, function will use the UTM projection for the first position
%   fix location.
%   * |navLat| (optional): navigation latency to introduce, in
%   milliseconds. If not specified, function will use navLat = 0;
%
%   *OUTPUT VARIABLES*
%   * |fData|: fData structure updated with ping navigation fields
%
%   *DEVELOPMENT NOTES*
%   * new developments needed: this function is to obtain best info on
%   sonar location (E,N,H) and orientation (azimuth, depression, heading)
%   at time of ping. In the future, maybe develop here to accept SBET.
%   * function formerly named CFF_process_ping.m
%
%   See also ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 11-11-2021


%% INPUT PARSING

% initialize information communication object
comms = CFF_Comms();
comms.start('Computing ping navigation');

% varargin{1}, source datagram for ping info:
if nargin>1    
    datagramSource = varargin{1};
else 
    datagramSource = [];
end
datagramSource = CFF_get_datagramSource(fData,datagramSource);

% varargin{2}: ellipsoid for CFF_ll2tm conversion
if nargin>2
    ellips = varargin{2};
else
    ellips = 'wgs84';
    %fprintf('ellips not specified. Using ''wgs84''...\n');
end

% varargin{3}: TM projection for CFF_ll2tm conversion
if nargin>3
    tmproj = varargin{3};
else
    % to be specified from fir good lat/long value
    tmproj = '';
end

% varargin{?}: datum conversion?
...
    
% varargin{4}: navigation latency
if nargin == 5
    navLat = varargin{4};
else
    navLat = 0;
    comms.info('navLat not specified in input. Using 0.');
end


%% EXTRACT PING DATA
% create ping time vectors in serial date number (SDN, Matlab, the whole
% and fractional number of days from January 0, 0000) and Time Since
% Midnight In Milliseconds (TSMIM, Kongsberg).

pingTSMIM    = fData.([datagramSource '_1P_TimeSinceMidnightInMilliseconds']);
pingDate     = fData.([datagramSource '_1P_Date']);
pingCounter  = fData.([datagramSource '_1P_PingCounter']);
pingDate     = datenum(cellfun(@num2str,num2cell(pingDate),'un',0),'yyyymmdd');
pingSDN      = pingDate(:)'+ pingTSMIM/(24*60*60*1000) + navLat./(1000.*60.*60.*24); % apply navigation latency here


%% EXTRACT NAVIGATION DATA
% same for navigation. In the future, offer possibility to import
% position/orientation from other files, say SBET

% test if there are several sources of GPS data
if isfield(fData,'Po_1D_PositionSystemDescriptor')
    ID = unique(fData.Po_1D_PositionSystemDescriptor);
    if numel(ID) > 1
        % several sources available
        % start by eliminating those that are obviously bad.
        % I have found data where one source had lat/long values that were
        % both constant and outside of normal values. You may want to
        % devise more tests if you ever come across different examples of
        % bad position data
        isLatAllConst = arrayfun(@(x) all(diff(fData.Po_1D_Latitude(fData.Po_1D_PositionSystemDescriptor==x))==0), ID); % check if all constant values
        isLonAllConst = arrayfun(@(x) all(diff(fData.Po_1D_Longitude(fData.Po_1D_PositionSystemDescriptor==x))==0), ID); % check if all constant values
        isLatAllBad = arrayfun(@(x) all(abs(fData.Po_1D_Latitude(fData.Po_1D_PositionSystemDescriptor==x))>90), ID); % check if all outside [-90:90]
        isLonAllBad = arrayfun(@(x) all(abs(fData.Po_1D_Longitude(fData.Po_1D_PositionSystemDescriptor==x))>180), ID); % check if all outside [-180:180]
        idxBadPos = isLatAllConst | isLonAllConst | isLatAllBad | isLonAllBad;
        % removing those bad sources
        ID = ID(~idxBadPos);
        if numel(ID)==1
            % only one good source left, just use that one
            pos_idx = fData.Po_1D_PositionSystemDescriptor==ID;
        else
            % still several sources available
            % find the one with the best fix quality
            meanFixQuality = arrayfun(@(x) nanmean(fData.Po_1D_MeasureOfPositionFixQuality(fData.Po_1D_PositionSystemDescriptor==x)), ID);
            [~,idx_keep] = min(meanFixQuality);
            pos_idx = fData.Po_1D_PositionSystemDescriptor==ID(idx_keep);
            comms.info(sprintf('Several sources of GPS data available. Using source with ID: %d',ID(idx_keep)));
        end
    else
        % single source. Use all datagrams.
        pos_idx = 1:numel(fData.Po_1D_Latitude);
    end
else
    % using older version of converted data, throw warning and continue
    comms.info('Navigation information in your converted data indicates it is not up to date with this version of Espresso. Consider reconverting this file, particularly if you see strange patterns in the navigation, or if two GPS sources have been logged in the file.');
    pos_idx = 1:numel(fData.Po_1D_Latitude);
end

% get data
posLatitude  = fData.Po_1D_Latitude(pos_idx); 
posLongitude = fData.Po_1D_Longitude(pos_idx);
posHeading   = fData.Po_1D_HeadingOfVessel(pos_idx);
posSpeed     = fData.Po_1D_SpeedOfVesselOverGround(pos_idx);
posTSMIM     = fData.Po_1D_TimeSinceMidnightInMilliseconds(pos_idx); % time since midnight in milliseconds
posDate      = datenum(cellfun(@num2str,num2cell(fData.Po_1D_Date(pos_idx)),'un',0),'yyyymmdd');
posSDN       = posDate(:)'+ posTSMIM/(24*60*60*1000); % serial date number

% define tmproj at this stage, if it was not provided in input
if isempty(tmproj)
    [~,~,~,~,tmproj] = CFF_ll2tm(posLongitude(1),posLatitude(1),ellips,'utm');
    tmproj = ['utm' tmproj];
    comms.info(['tmproj not specified in input. Defining it from first position fix: ''' tmproj '''']);
end


%% EXTRACT HEIGHT DATA
if isfield(fData,'He_1D_Height')
    heiHeight = fData.He_1D_Height; % now m
    heiDate   = datenum(cellfun(@num2str,num2cell(fData.He_1D_Date),'un',0),'yyyymmdd');
    heiSDN    = heiDate(:)' + fData.He_1D_TimeSinceMidnightInMilliseconds/(24*60*60*1000);
else
    % no height datagrams, create fake variables
    heiHeight = zeros(size(pingTSMIM));
    heiSDN    = pingSDN;
end


%% PROCESS NAVIGATION AND HEADING
% Get position and heading for each ping. Position and heading were
% recorded at the sensor's time so we need to interpolate them at the same
% time to match ping time.

% convert posLatitude/posLongitude to easting/northing/grid convergence:
[posE, posN, posGridConv] = CFF_ll2tm(posLongitude, posLatitude, ellips, tmproj);

% convert heading to degrees and allow heading values superior to
% 360 or inferior to 0 (because every time the vessel crossed the NS
% line, the heading jumps from 0 to 360 (or from 360 to 0) and this
% causes a problem for following interpolation):

posJump = find(diff(posHeading)>300);
negJump = find(diff(posHeading)<-300);
jumps   = zeros(1,length(posHeading));

if ~isempty(posJump)
    for jj = 1:length(posJump)
        jumps(posJump(jj)+1:end) = jumps(posJump(jj)+1:end) - 1;
    end
end

if ~isempty(negJump)
    for jj = 1:length(negJump)
        jumps(negJump(jj)+1:end) = jumps(negJump(jj)+1:end) + 1;
    end
end

posHeading = posHeading + jumps.*360;

% initialize new vectors
pingE        = nan(size(pingTSMIM));
pingN        = nan(size(pingTSMIM));
pingGridConv = nan(size(pingTSMIM));
pingHeading  = nan(size(pingTSMIM));
pingSpeed    = nan(size(pingTSMIM));

% interpolate Easting, Northing, Grid Convergence and Heading at ping times
for jj = 1:length(pingTSMIM)
    A = posSDN-pingSDN(jj);
    iA = find (A == 0);
    if A > 0
        % the ping time is older than any navigation time, extrapolate from the first items in navigation array.
        pingE(jj) = posE(2) + (posE(2)-posE(1)).*(pingSDN(jj)-posSDN(2))./(posSDN(2)-posSDN(1));
        pingN(jj) = posN(2) + (posN(2)-posN(1)).*(pingSDN(jj)-posSDN(2))./(posSDN(2)-posSDN(1));
        pingGridConv(jj) = posGridConv(2) + (posGridConv(2)-posGridConv(1)).*(pingSDN(jj)-posSDN(2))./(posSDN(2)-posSDN(1));
        pingHeading(jj) = posHeading(2) + (posHeading(2)-posHeading(1)).*(pingSDN(jj)-posSDN(2))./(posSDN(2)-posSDN(1));
        pingSpeed(jj) = posSpeed(2) + (posSpeed(2)-posSpeed(1)).*(pingTSMIM(jj)-posTSMIM(2))./(posTSMIM(2)-posTSMIM(1));
    elseif A < 0
        % the ping time is more recent than any navigation time, extrapolate from the last items in navigation array.
        pingE(jj) = posE(end) + (posE(end)-posE(end-1)).*(pingSDN(jj)-posSDN(end))./(posSDN(end)-posSDN(end-1));
        pingN(jj) = posN(end) + (posN(end)-posN(end-1)).*(pingSDN(jj)-posSDN(end))./(posSDN(end)-posSDN(end-1));
        pingGridConv(jj) = posGridConv(end) + (posGridConv(end)-posGridConv(end-1)).*(pingSDN(jj)-posSDN(end))./(posSDN(end)-posSDN(end-1));
        pingHeading(jj) = posHeading(end) + (posHeading(end)-posHeading(end-1)).*(pingSDN(jj)-posSDN(end))./(posSDN(end)-posSDN(end-1));
        pingSpeed(jj) = posSpeed(end) + (posSpeed(end)-posSpeed(end-1)).*(pingTSMIM(jj)-posTSMIM(end))./(posTSMIM(end)-posTSMIM(end-1));
    elseif ~isempty(iA)
        % the ping time corresponds to an existing navigation time, get easting and northing from it.
        pingE(jj) = posE(iA);
        pingN(jj) = posN(iA);
        pingGridConv(jj) = posGridConv(iA);
        pingHeading(jj) = posHeading(iA);
        pingSpeed(jj) = posSpeed(iA);
    else
        % the ping time is within the limits of the navigation time array but doesn't correspond to any value in it, interpolate from nearest values
        iNegA = find(A<0);
        [~,iMax] = max(A(iNegA));
        iA(1) = iNegA(iMax); % index of navigation time just older than ping time
        iPosA = find(A>0);
        [~,iMin] = min(A(iPosA));
        iA(2) = iPosA(iMin); % index of navigation time just more recent ping time
        % now extrapolate easting, northing, grid convergence and heading
        pingE(jj) = posE(iA(2)) + (posE(iA(2))-posE(iA(1))).*(pingSDN(jj)-posSDN(iA(2)))./(posSDN(iA(2))-posSDN(iA(1)));
        pingN(jj) = posN(iA(2)) + (posN(iA(2))-posN(iA(1))).*(pingSDN(jj)-posSDN(iA(2)))./(posSDN(iA(2))-posSDN(iA(1)));
        pingGridConv(jj) = posGridConv(iA(2)) + (posGridConv(iA(2))-posGridConv(iA(1))).*(pingSDN(jj)-posSDN(iA(2)))./(posSDN(iA(2))-posSDN(iA(1)));
        pingHeading(jj) = posHeading(iA(2)) + (posHeading(iA(2))-posHeading(iA(1))).*(pingSDN(jj)-posSDN(iA(2)))./(posSDN(iA(2))-posSDN(iA(1)));
        pingSpeed(jj) = posSpeed(iA(2)) + (posSpeed(iA(2))-posSpeed(iA(1))).*(pingTSMIM(jj)-posTSMIM(iA(2)))./(posTSMIM(iA(2))-posTSMIM(iA(1)));
    end
end

% bring heading back into the interval [0 360]
posHeading  = posHeading - jumps.*360;
pingHeading = mod(pingHeading,360);


%% PROCESS HEIGHT
% Get height for each ping. Height were recorded at the sensor's time so we
% need to interpolate them at the same time to match ping time.

% initialize new vectors
pingH = nan(size(pingSDN));

% interpolate Height at ping times
for jj = 1:length(pingSDN)
    A = heiSDN-pingSDN(jj);
    iA = find (A == 0,1);
    if A > 0
        % the ping time is older than any height time, extrapolate from the first items in height array.
        pingH(jj) = heiHeight(2) + (heiHeight(2)-heiHeight(1)).*(pingSDN(jj)-heiSDN(2))./(heiSDN(2)-heiSDN(1));
    elseif A < 0
        % the ping time is more recent than any height time, extrapolate from the last items in height array.
        pingH(jj) = heiHeight(end) + (heiHeight(end)-heiHeight(end-1)).*(pingSDN(jj)-heiSDN(end))./(heiSDN(end)-heiSDN(end-1));
    elseif ~isempty(iA)
        % the ping time corresponds to an existing height time, get height
        % from it
        pingH(jj) = heiHeight(iA);
    else
        % the ping time is within the limits of the height time array but doesn't correspond to any value in it, interpolate from nearest values
        iNegA = find(A<0);
        [~,iMax] = max(A(iNegA));
        iA(1) = iNegA(iMax); % index of height time just older than ping time
        iPosA = find(A>0);
        [~,iMin] = min(A(iPosA));
        iA(2) = iPosA(iMin); % index of height time just more recent ping time
        % now extrapolate height
        pingH(jj) = heiHeight(iA(2)) + (heiHeight(iA(2))-heiHeight(iA(1))).*(pingSDN(jj)-heiSDN(iA(2)))./(heiSDN(iA(2))-heiSDN(iA(1)));
    end
end


%% SAVE RESULTS

% save processed results
fData.X_1P_pingCounter  = pingCounter;
fData.X_1P_pingTSMIM    = pingTSMIM;
fData.X_1P_pingSDN      = pingSDN;
fData.X_1P_pingE        = pingE;
fData.X_1P_pingN        = pingN;
fData.X_1P_pingH        = pingH;
fData.X_1P_pingGridConv = pingGridConv;
fData.X_1P_pingHeading  = pingHeading;
fData.X_1P_pingSpeed    = pingSpeed;

% metadata. 
% Datagram source is the datagram at the origin of the time vector, to
% which all the "X_1P" fields above correspond.
fData.MET_datagramSource                  = datagramSource;
fData.MET_navigationLatencyInMilliseconds = navLat;
fData.MET_ellips                          = ellips;
fData.MET_tmproj                          = tmproj;

% sort fields by name
fData = orderfields(fData);
