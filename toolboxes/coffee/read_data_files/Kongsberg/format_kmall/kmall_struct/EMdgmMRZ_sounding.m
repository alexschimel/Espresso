classdef EMdgmMRZ_sounding
    % #MRZ - Data for each sounding, e.g. XYZ, reflectivity, two way travel
    % time etc.
    %
    % Also contains information necessary to read seabed image following this
    % datablock (number of samples in SI etc.). To be entered in loop
    % (numSoundingsMaxMain + numExtraDetections) times.
    
    properties
        % Sounding index. Cross reference for seabed image. Valid range: 0 to
        % (numSoundingsMaxMain+numExtraDetections)-1, i.e. 0 - (Nrx+Nd)-1.
        soundingIndex uint16
        
        % Transmitting sector number. Valid range: 0-(Ntx-1), where Ntx is
        % numTxSectors.
        txSectorNumb uint8
        
        
        %% Detection info
        
        % Bottom detection type. Normal bottom detection, extra detection, or
        % rejected.
        % 0 = normal detection
        % 1 = extra detection
        % 2 = rejected detection
        % In case 2, the estimated range has been used to fill in amplitude samples
        % in the seabed image datagram.
        detectionType uint8
        
        % Method for determining bottom detection, e.g. amplitude or phase.
        % 0 = no valid detection
        % 1 = amplitude detection
        % 2 = phase detection
        % 3-15 for future use.
        detectionMethod uint8
        
        % For Kongsberg use.
        rejectionInfo1 uint8
        
        % For Kongsberg use.
        rejectionInfo2 uint8
        
        % For Kongsberg use.
        postProcessingInfo uint8
        
        % Only used by extra detections. Detection class based on detected range.
        % Detection class 1 to 7 corresponds to value 0 to 6. If the value is
        % between 100 and 106, the class is disabled by the operator. If the value
        % is 107, the detections are outside the treshhold limits.
        detectionClass uint8
        
        % Detection confidence level.
        detectionConfidenceLevel uint8
        
        % Byte alignment.
        padding uint16
        
        % Unit %. rangeFactor = 100 if main detection.
        rangeFactor float
        
        % Estimated standard deviation as % of the detected depth. Quality Factor
        % (QF) is calculated from IFREMER Quality Factor (IFQ):
        % QF=Est(dz)/z=100*10^-IQF
        qualityFactor float
        
        % Vertical uncertainty, based on quality factor (QF, qualityFactor).
        detectionUncertaintyVer_m float
        
        % Horizontal uncertainty, based on quality factor (QF, qualityFactor).
        detectionUncertaintyHor_m float
        
        % Detection window length. Unit second. Sample data range used in final
        % detection.
        detectionWindowLength_sec float
        
        % Measured echo length. Unit second.
        echoLength_sec float
        
        
        %% Water column parameters
        
        % Water column beam number. Info for plotting soundings together with water
        % column data.
        WCBeamNumb uint16
        
        % Water column range. Range of bottom detection, in samples.
        WCrange_samples uint16
        
        % Water column nominal beam angle across. Re vertical.
        WCNomBeamAngleAcross_deg float
        
        
        %% Reflectivity data (backscatter (BS) data)
        
        % Mean absorption coefficient, alfa. Used for TVG calculations. Value as
        % used. Unit dB/km.
        meanAbsCoeff_dBPerkm float
        
        % Beam intensity, using the traditional KM special TVG.
        reflectivity1_dB float
        
        % Beam intensity (BS), using TVG = X log(R) + 2 alpha R. X (operator
        % selected) is common to all beams in datagram. Alpha (variabel
        % meanAbsCoeff_dBPerkm) is given for each beam (current struct).
        % BS = EL - SL - M + TVG + BScorr,
        % where EL= detected echo level (not recorded in datagram), and the rest of
        % the parameters are found below.
        reflectivity2_dB float
        
        % Receiver sensitivity (M), in dB, compensated for RX beampattern at actual
        % transmit frequency at current vessel attitude.
        receiverSensitivityApplied_dB float
        
        % Source level (SL) applied (dB):
        % SL = SLnom + SLcorr
        % where SLnom = Nominal maximum SL, recorded per TX sector (variabel
        % txNominalSourceLevel_dB in struct EMdgmMRZ_txSectorInfo_def) and SLcorr =
        % SL correction relative to nominal TX power based on measured high voltage
        % power level and any use of digital power control. SL is corrected for TX
        % beampattern along and across at actual transmit frequency at current
        % vessel attitude.
        sourceLevelApplied_dB float
        
        % Backscatter (BScorr) calibration offset applied (default = 0 dB).
        BScalibration_dB float
        
        % Time Varying Gain (TVG) used when correcting reflectivity.
        TVG_dB float
        
        
        %% Range and angle data
        
        % Angle relative to the RX transducer array, except for ME70, where the
        % angles are relative to the horizontal plane.
        beamAngleReRx_deg float
        
        % Applied beam pointing angle correction.
        beamAngleCorrection_deg float
        
        % Two way travel time (also called range). Unit second.
        twoWayTravelTime_sec float
        
        % Applied two way travel time correction. Unit second.
        twoWayTravelTimeCorrection_sec float
        
        
        %% Georeferenced depth points
        
        % Distance from vessel reference point at time of first tx pulse in ping,
        % to depth point. Measured in the surface coordinate system (SCS), see
        % Coordinate systems for definition. Unit decimal degrees.
        deltaLatitude_deg float
        
        % Distance from vessel reference point at time of first tx pulse in ping,
        % to depth point. Measured in the surface coordinate system (SCS), see
        % Coordinate systems for definition. Unit decimal degree.
        deltaLongitude_deg float
        
        % Vertical distance z. Distance from vessel reference point at time of
        % first tx pulse in ping, to depth point. Measured in the surface
        % coordinate system (SCS), see Coordinate systems for definition.
        z_reRefPoint_m float
        
        % Horizontal distance y. Distance from vessel reference point at time of
        % first tx pulse in ping, to depth point. Measured in the surface
        % coordinate system (SCS), see Coordinate systems for definition.
        y_reRefPoint_m float
        
        % Horizontal distance x. Distance from vessel reference point at time of
        % first tx pulse in ping, to depth point. Measured in the surface
        % coordinate system (SCS), see Coordinate systems for definition.
        x_reRefPoint_m float
        
        % Beam incidence angle adjustment (IBA) unit degree.
        beamIncAngleAdj_deg float
        
        % For future use.
        realTimeCleanInfo uint16
        
        
        %% Seabed image
        
        % Seabed image start range, in sample number from transducer. Valid only
        % for the current beam.
        SIstartRange_samples uint16
        
        % Seabed image. Number of the centre seabed image sample for the current
        % beam.
        SIcentreSample uint16
        
        % Seabed image. Number of range samples from the current beam, used to form
        % the seabed image.
        SInumSamples uint16
    end
    
    methods
        function obj = EMdgmMRZ_sounding
            % Summary of constructor
        end
        function myMethod(obj)
            % Summary of myMethod
            disp(obj)
        end
    end
    
end