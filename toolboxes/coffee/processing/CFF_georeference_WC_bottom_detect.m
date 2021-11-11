function [fData] = CFF_georeference_WC_bottom_detect(fData)
%CFF_GEOREFERENCE_WC_BOTTOM_DETECT  One-line description
%
%   Get range, swathe coordinates (across and upwards distance from sonar),
%   and projected coordinates (easting, northing, height) of the bottom
%   detect samples
%
%   *INPUT VARIABLES*
%   * |fData|: Required. Structure for the storage of kongsberg EM series
%   multibeam data in a format more convenient for processing. The data is
%   recorded as fields coded "a_b_c" where "a" is a code indicating data
%   origing, "b" is a code indicating data dimensions, and "c" is the data
%   name. See the help of function CFF_convert_ALLdata_to_fData.m for
%   description of codes.
%
%   *OUTPUT VARIABLES*
%   * |fData|: fData structure updated with bottom detect georeferencing
%   fields
%
%   See also ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 11-11-2021

%% info extraction

% Extract needed ping info
X_1P_sonarHeight          = fData.X_1P_pingH; %m
X_1P_sonarEasting         = fData.X_1P_pingE; %m
X_1P_sonarNorthing        = fData.X_1P_pingN; %m
X_1P_gridConvergenceDeg   = fData.X_1P_pingGridConv; %deg
X_1P_vesselHeadingDeg     = fData.X_1P_pingHeading; %deg
X_1_sonarHeadingOffsetDeg = fData.IP_ASCIIparameters.S1H; %deg

% Considering the swath frame Fs (origin: sonar face, Xs: across distance
% (positive ~starboard), Ys: along distance (positive ~forward), Zs: up
% distance (positive up)) and the projection frame Fp (origin: the (0,0)
% Easting/Northing projection reference and datum reference, Xp: Easting
% (positive East), Yp: Northing (grid North, positive North), Zp:
% Elevation/Height (positive up)), AND ASSUMING THERE WAS A REAL-TIME
% COMPENSATION OF ROLL AND PITCH SO THAT ZS=ZP, then to go from Fs to Fp,
% one simply needs to rotate along the Z axis, which includes the vessel
% heading, the sonar head heading offset, and the grid convergence (aka
% angle between true north and grid north).
X_1P_thetaDeg = - mod( X_1P_gridConvergenceDeg + X_1P_vesselHeadingDeg + X_1_sonarHeadingOffsetDeg, 360 );
X_1P_thetaRad = deg2rad(X_1P_thetaDeg);

% In practice, might want to check the vessel roll and pitch.

datagramSource = CFF_get_datagramSource(fData);
switch datagramSource
    
    case {'WC' 'AP'}
        
        % get the bottom samples in each ping/beam
        X_BP_bottomSample = CFF_get_bottom_sample(fData); % not precising wether raw or processed here, as this code is used both when loading the data and after filtering
        X_1BP_bottomSample = permute(X_BP_bottomSample,[3,1,2]);
        
        % X_BP_startRangeSampleNumber = fData.WC_BP_StartRangeSampleNumber; % not needed for bottom detect (I think)
        X_BP_beamPointingAngleDeg = fData.(sprintf('%s_BP_BeamPointingAngle',datagramSource));
        X_BP_beamPointingAngleRad = deg2rad(X_BP_beamPointingAngleDeg);

        % OWTT distance traveled in one sample
        X_1P_oneSampleDistance = CFF_inter_sample_distance(fData);
        
        % Georeference those samples
        [X_1BP_bottomEasting, X_1BP_bottomNorthing, X_1BP_bottomHeight, X_1BP_bottomAcrossDist, X_1BP_bottomUpDist, X_1BP_bottomRange] = CFF_georeference_sample(X_1BP_bottomSample, 0, X_1P_oneSampleDistance, X_BP_beamPointingAngleRad, X_1P_sonarEasting, X_1P_sonarNorthing, X_1P_sonarHeight, X_1P_thetaRad);
        
        % save info
        fData = CFF_set_bottom_sample(fData,X_BP_bottomSample);
        fData.X_PB_beamPointingAngleRad = X_BP_beamPointingAngleRad;
        fData.X_BP_bottomRange          = permute(X_1BP_bottomRange,[2,3,1]);
        
        % save data in the swath frame
        fData.X_BP_bottomUpDist     = permute(X_1BP_bottomUpDist,[2,3,1]);
        fData.X_BP_bottomAcrossDist = permute(X_1BP_bottomAcrossDist,[2,3,1]);
        
        % save data in the projected frame
        fData.X_BP_bottomEasting   = permute(X_1BP_bottomEasting,[2,3,1]);
        fData.X_BP_bottomNorthing  = permute(X_1BP_bottomNorthing,[2,3,1]);
        fData.X_BP_bottomHeight    = permute(X_1BP_bottomHeight,[2,3,1]);
        
    case 'X8'
        
        % get bottom detect's across-track distance and depth from BP to
        % SBP (1BP)
        X_BP_bottomAcrossDist = fData.X8_BP_AcrosstrackDistanceY;
        X_BP_bottomUpDist     = -fData.X8_BP_DepthZ;
        X_1BP_bottomAcrossDist = permute(X_BP_bottomAcrossDist,[3,1,2]);
        X_1BP_bottomUpDist     = permute(X_BP_bottomUpDist,[3,1,2]);
        
        % get Easting, NOrthing and Height of bottom detect
        [X_1BP_bottomEasting, X_1BP_bottomNorthing, X_1BP_bottomHeight] = CFF_get_samples_ENH(X_1P_sonarEasting,X_1P_sonarNorthing,X_1P_sonarHeight,X_1P_thetaRad,X_1BP_bottomAcrossDist,X_1BP_bottomUpDist);
        
        % save data in the swath frame
        fData.X_BP_bottomUpDist     = X_BP_bottomUpDist;
        fData.X_BP_bottomAcrossDist = X_BP_bottomAcrossDist;
       
        % save data in the projected frame
        fData.X_BP_bottomEasting    = permute(X_1BP_bottomEasting,[2,3,1]);
        fData.X_BP_bottomNorthing   = permute(X_1BP_bottomNorthing,[2,3,1]);
        fData.X_BP_bottomHeight     = permute(X_1BP_bottomHeight,[2,3,1]);
        
end

% sort fields by name
fData = orderfields(fData);

