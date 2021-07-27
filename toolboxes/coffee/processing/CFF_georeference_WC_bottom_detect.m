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
%   2017-2021; Last revision: 27-07-2021

%% info extraction

% Extract needed ping info
X_1P_sonarHeight          = fData.X_1P_pingH; %m
X_1P_sonarEasting         = fData.X_1P_pingE; %m
X_1P_sonarNorthing        = fData.X_1P_pingN; %m
X_1P_gridConvergenceDeg   = fData.X_1P_pingGridConv; %deg
X_1P_vesselHeadingDeg     = fData.X_1P_pingHeading; %deg
X_1_sonarHeadingOffsetDeg = fData.IP_ASCIIparameters.S1H; %deg

% Compute the horizontal rotation angle between the swath frame (Ys forward
% and Yp northing)
%
% In THEORY, real-time compensation of roll and pitch means the Z for the
% swath frame is exactly the same as Z for elevation, so that we only need
% to rotate in the horizontal frame. In effect, we may want to recompute
% the true up pointing angle for the swath. For now, we'll make it simple:
X_1P_thetaDeg = - mod( X_1P_gridConvergenceDeg + X_1P_vesselHeadingDeg + X_1_sonarHeadingOffsetDeg, 360 );
X_1P_thetaRad = deg2rad(X_1P_thetaDeg);

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
        
        [X_1BP_bottomEasting, X_1BP_bottomNorthing, X_1BP_bottomHeight] = CFF_get_samples_ENH(X_1P_sonarEasting,X_1P_sonarNorthing,X_1P_sonarHeight,X_1P_thetaRad,fData.X8_BP_AcrosstrackDistanceY,fData.X8_BP_DepthZ);
        
        X_1BP_bottomAcrossDist = fData.X8_BP_AcrosstrackDistanceY;
        
        % save data in the swath frame
        fData.X_BP_bottomAcrossDist = permute(X_1BP_bottomAcrossDist,[2,3,1]);
        
        % save data in the projected frame
        fData.X_BP_bottomEasting    = permute(X_1BP_bottomEasting,[2,3,1]);
        fData.X_BP_bottomNorthing   = permute(X_1BP_bottomNorthing,[2,3,1]);
        fData.X_BP_bottomHeight     = permute(X_1BP_bottomHeight,[2,3,1]);
        
end

