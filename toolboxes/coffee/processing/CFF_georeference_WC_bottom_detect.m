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

datagramSource = CFF_get_datagramSource(fData);
switch datagramSource
    
    case {'WC' 'AP'}
        
        % For water-column data, we start from the number of the sample
        % corresponding to the bottom detect in each beam. 
        
        % Get it. Not precising wether raw or processed here, as this code
        % is used both when loading the data and after filtering, and
        % permute to get it as a 1BP array
        X_BP_bottomSample = CFF_get_bottom_sample(fData);
        X_1BP_bottomSample = permute(X_BP_bottomSample,[3,1,2]);
        
        % To get from sample number to range in meters, we need the OWTT
        % distance traveled in one sample 
        X_1P_oneSampleDistance = CFF_inter_sample_distance(fData);
        
        % To complete our coordinates, we need the beam pointing angle
        X_BP_beamPointingAngleDeg = fData.(sprintf('%s_BP_BeamPointingAngle',datagramSource));
        X_BP_beamPointingAngleRad = deg2rad(X_BP_beamPointingAngleDeg);
        
        % Range and angle will get us the coordinates of the bottom sample
        % in the swath frame. To get in a geographical frame, we also need
        % the heading angle, made up of the sonar heading offset, the
        % vessel heading, and the grid convergence
        X_1P_thetaDeg = - mod( X_1P_gridConvergenceDeg + X_1P_vesselHeadingDeg + X_1_sonarHeadingOffsetDeg, 360 );
        X_1P_thetaRad = deg2rad(X_1P_thetaDeg);
        
        % Use all of this to georeference those bottom samples
        [X_1BP_bottomEasting, X_1BP_bottomNorthing, X_1BP_bottomHeight, X_1BP_bottomAcrossDist, X_1BP_bottomUpDist, X_1BP_bottomRange] = CFF_georeference_sample(X_1BP_bottomSample, 0, X_1P_oneSampleDistance, X_BP_beamPointingAngleRad, X_1P_sonarEasting, X_1P_sonarNorthing, X_1P_sonarHeight, X_1P_thetaRad);
        
        % save info
        fData = CFF_set_bottom_sample(fData,X_BP_bottomSample);
        fData.X_BP_beamPointingAngleRad = X_BP_beamPointingAngleRad;
        fData.X_BP_bottomRange          = permute(X_1BP_bottomRange,[2,3,1]);
        
        % save data in the swath frame
        fData.X_BP_bottomUpDist     = permute(X_1BP_bottomUpDist,[2,3,1]);
        fData.X_BP_bottomAcrossDist = permute(X_1BP_bottomAcrossDist,[2,3,1]);
        
        % save data in the projected frame
        fData.X_BP_bottomEasting   = permute(X_1BP_bottomEasting,[2,3,1]);
        fData.X_BP_bottomNorthing  = permute(X_1BP_bottomNorthing,[2,3,1]);
        fData.X_BP_bottomHeight    = permute(X_1BP_bottomHeight,[2,3,1]);
        
    case 'X8'
        
        % For normal seafloor data, it's a bit simpler, as we start from
        % the (x:forward,y:starboard,z:depth) coordinates of each sounding.
        % We only need to rotate around the z/depth axis.
        
        % This time however, the data are already corrected for the sonar
        % heading offset, so the vessel azimuth is only the vessel heading
        % and the grid convergence
        X_1P_thetaDeg = mod(X_1P_gridConvergenceDeg+X_1P_vesselHeadingDeg,360);
        
        % apply rotation for the (x,y) -> (E,N) coordinates. (x,y) are
        % referenced to the horizontal position of the position system so
        % just add the values obtained before.
        fData.X_BP_bottomEasting  = fData.X_1P_pingE + fData.X8_BP_AcrosstrackDistanceY.*cosd(X_1P_thetaDeg) + fData.X8_BP_AlongtrackDistanceX.*sind(X_1P_thetaDeg);
        fData.X_BP_bottomNorthing = fData.X_1P_pingN - fData.X8_BP_AcrosstrackDistanceY.*sind(X_1P_thetaDeg) + fData.X8_BP_AlongtrackDistanceX.*cosd(X_1P_thetaDeg);
        
        % z values are referenced to the sonar head depth, so we need to
        % add the heave
        fData.X_BP_bottomHeight = - (fData.X8_1P_TransmitTransducerDepth + fData.X8_BP_DepthZ);
        
        % also save the across-track and depth in the swath frame
        fData.X_BP_bottomUpDist     = -fData.X8_BP_DepthZ;
        fData.X_BP_bottomAcrossDist = fData.X8_BP_AcrosstrackDistanceY;
       
end

% sort fields by name
fData = orderfields(fData);

