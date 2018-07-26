%% CFF_process_WC_bottom_detect_v2.m
%
% Calculates the XY position in the swathe frame and the XYZ position in
% the geographical frame of each WC bottom detect.
%
% Important Note: this code executes the same calculations on the WC
% bottom detect as CFF_process_watercolumn_v2.m executes on the WC samples.
% (The reason they're separated is to allow reprocessing bottom detect
% after filtering, without reprocessing the samples).
% If an improvement is made to one of these two functions, do it on the
% other as well.
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |input_variable_1|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% * |output_variable_1|: TODO: write description and info on variable
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-10-10: removed the saving of beampointinganglerad (Alex Schimel)
% * 2017-10-10: New function recorded as v2 because of the changes in
% dimensions. Also, changed to match the latest changes in
% CFF_process_watercolumn_v2.m including the use of bsxfun to avoid repmat.
% Also updated the header (Alex Schimel).
% * 2016-12-01: First version. Code taken from CFF_process_watercolumn.m
% (Alex Schimel)
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Alexandre Schimel, NIWA.

%% Function
function [fData] = CFF_process_WC_bottom_detect_v2(fData)

if isfield(fData,'WC_SBP_SampleAmplitudes')
    start_fmt='WC_';
elseif isfield(fData,'WCAP_SBP_SampleAmplitudes')
    start_fmt='WCAP_';
end

% Extract needed ping info
X_1P_soundSpeed           = fData.(sprintf('%s1P_SoundSpeed',start_fmt)).*0.1; %m/s
X_1P_samplingFrequencyHz  = fData.(sprintf('%s1P_SamplingFrequencyHz',start_fmt)); %Hz
X_1P_sonarHeight          = fData.X_1P_pingH; %m
X_1P_sonarEasting         = fData.X_1P_pingE; %m
X_1P_sonarNorthing        = fData.X_1P_pingN; %m
X_1P_gridConvergenceDeg   = fData.X_1P_pingGridConv; %deg
X_1P_vesselHeadingDeg     = fData.X_1P_pingHeading; %deg
X_1_sonarHeadingOffsetDeg = fData.IP_ASCIIparameters.S1H; %deg

% Extract needed beam info
% X_BP_startRangeSampleNumber = fData.WC_BP_StartRangeSampleNumber; % not needed for bottom detect (I think)
X_BP_beamPointingAngleDeg   = fData.(sprintf('%sBP_BeamPointingAngle',start_fmt)).*0.01; %deg
X_BP_beamPointingAngleRad   = deg2rad(X_BP_beamPointingAngleDeg);

% Grab sample corresponding to bottom:
% - if fData contains a 'X_BP_bottomSample' field already, it means we are
% requesting all other bottom values to be recalculated from this (probably
% filtered) value. If the field doesn't exist, then this is the first
% calculation requested on the original bottom detect.
if ~isfield(fData, 'X_BP_bottomSample')
    fData.X_BP_bottomSample = fData.(sprintf('%sBP_DetectedRangeInSamples',start_fmt)); %in sample number
    fData.X_BP_bottomSample(fData.X_BP_bottomSample==0) = NaN;
end



%% Computations

% OWTT distance traveled in one sample
X_1P_oneSampleDistance = X_1P_soundSpeed./(X_1P_samplingFrequencyHz.*2);

% Compute the horizontal rotation angle between the swath frame (Ys forward
% and Yp northing)
% In THEORY, real-time compensation of roll and pitch means the Z for the
% swath frame is exactly the same as Z for elevation, so that we only need
% to rotate in the horizontal frame. In effect, we may want to recompute
% the true up pointing angle for the swath. For now, we'll make it simple:
X_1P_thetaDeg = - mod( X_1P_gridConvergenceDeg + X_1P_vesselHeadingDeg + X_1_sonarHeadingOffsetDeg, 360 );
X_1P_thetaRad = deg2rad(X_1P_thetaDeg);

% range. Not sure here. For water column, you need to take into account the
% startRangeSampleNumber to compute range as:
% range = oneSampleDistance*(sampleIndex+startRangeSampleNumber)
% But I don't think it applies to the bottom detect. No reason why it
% would, so here and only here, range would be computed as:
% range = oneSampleDistance*bottomSample
fData.X_BP_bottomRange = bsxfun(@times,fData.X_BP_bottomSample,X_1P_oneSampleDistance);

% Cartesian coordinates in the swath frame:
% - origin: sonar face
% - Xs: across distance (positive ~starboard) = -range*sin(pointingAngle)
% - Ys: along distance (positive ~forward) = 0
% - Zs: up distance (positive up) = -range*cos(pointingAngle)
fData.X_BP_bottomUpDist     = -fData.X_BP_bottomRange .* cos(X_BP_beamPointingAngleRad);
fData.X_BP_bottomAcrossDist = -fData.X_BP_bottomRange .* sin(X_BP_beamPointingAngleRad);

% Projected coordinates:
% - origin: the (0,0) Easting/Northing projection reference and datum reference
% - Xp: Easting (positive East) = sonarEasting + sampleAcrossDist*cos(heading)
% - Yp: Northing (grid North, positive North) = sonarNorthing + sampleAcrossDist*sin(heading)
% - Zp: Elevation/Height (positive up) = sonarHeight + sampleUpDist
fData.X_BP_bottomEasting  = bsxfun(@plus,X_1P_sonarEasting,bsxfun(@times,fData.X_BP_bottomAcrossDist,cos(X_1P_thetaRad)));
fData.X_BP_bottomNorthing = bsxfun(@plus,X_1P_sonarNorthing,bsxfun(@times,fData.X_BP_bottomAcrossDist,sin(X_1P_thetaRad)));
fData.X_BP_bottomHeight   = bsxfun(@plus,X_1P_sonarHeight,fData.X_BP_bottomUpDist);


