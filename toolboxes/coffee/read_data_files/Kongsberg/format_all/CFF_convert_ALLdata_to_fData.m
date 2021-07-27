function fData = CFF_convert_ALLdata_to_fData(ALLdataGroup,varargin)
%CFF_CONVERT_ALLDATA_TO_FDATA  Convert all data to the CoFFee format
%
%   Converts Kongsberg EM series data FROM the ALLdata format (read by
%   CFF_READ_ALL) TO the CoFFee fData format used in processing.
%
%   fData = CFF_CONVERT_ALLDATA_TO_FDATA(ALLdata) converts the contents of
%   one ALLdata structure to a structure in the fData format.
%
%   fData = CFF_CONVERT_ALLDATA_TO_FDATA(ALLdataGroup) converts an array of
%   two ALLdata structures into one fData sructure. The pair of structure
%   must correspond to an .all/.wcd pair of files. Do not try to use this
%   feature to convert ALLdata structures from different acquisition files.
%   It will not work. Convert each into its own fData structure.
%
%   Note that the ALLdata structures are converted to fData in the order
%   they are in input, and that the first ones take precedence. Aka in the
%   example above, if the second structure contains a type of datagram that
%   is already in the first, they will NOT be converted. This is to avoid
%   doubling up the data that may exist in duplicate in the pair of raw
%   files. You need to order the ALLdata structures in input in order of
%   desired precedence.
%
%   fData = CFF_CONVERT_ALLDATA_TO_FDATA(ALLdata,dr_sub,db_sub) operates
%   the conversion with a sub-sampling of the water-column data (either WC
%   or AP datagrams) in range and in beams. For example, to sub-sample
%   range by a factor of 10 and beams by a factor of 2, use:
%   fData = CFF_CONVERT_ALLDATA_TO_FDATA(ALLdata,10,2).
%
%   *INPUT VARIABLES*
%   * |ALLdataGroup|: Required. ALLdata structure or cells of ALLdata
%   structures.
%   * |dr_sub|: Optional. Scalar for decimation in range. Default: 1 (no
%   decimation).
%   * |db_sub|: Optional. Scalar for decimation in beams. Default: 1 (no
%   decimation).
%   * |fData|: Optional. Existing fData structure to add to.
%
%   *OUTPUT VARIABLES*
%   * |fData|: structure for the storage of kongsberg EM series multibeam
%   data in a format more convenient for processing. The data is recorded
%   as fields coded "a_b_c" where "a" is a code indicating data origing,
%   "b" is a code indicating data dimensions, and "c" is the data name.
%     * a: code indicating data origin:
%         * IP: installation parameters
%         * Ru: Runtime Parameters
%         * De: depth datagram
%         * He: height datagram
%         * X8: XYZ88 datagram
%         * SI: seabed image datagram
%         * S8: seabed image data 89
%         * WC: watercolumn data
%         * Po: position datagram
%         * At: attitude datagram
%         * SS: sound speed profile datagram
%         * AP: "Amplitude and phase" water-column data
%     More codes for the 'a' part will be created if more datagrams are
%     parsed. Data derived from computations can be recorded back into
%     fData using 'X' for the "a" code.
%     * b: code indicating data dimensions (rows/columns)
%         * 1P: ping-like single-row-vector
%         * B1: beam-like single-column-vector
%         * BP: beam/ping array
%         * TP: transmit-sector/ping array
%         * SP: samples/ping array (note: samples are not sorted, this is
%         not equivalent to range!)
%         * 1D: datagram-like single-row-vector (for attitude or
%         position data)
%         * ED: entries-per-datagram/datagram array (for attitude or
%         position data)
%         * SBP: sample/beam/ping array (water-column data)
%     More codes for the 'b' part will be created if the storage of other
%     datagrams needs them. Data derived from computations can be recorded
%     back into fData using appropriate "b" codes such as:
%         * RP: range (choose distance, time or sample) / ping
%         * SP: swathe (meters) / ping
%         * LL: lat/long (WGS84)
%         * N1: northing-like single-column-vector
%         * 1E: easting-like single-row-vector
%         * NE: northing/easting
%         * NEH: northing/easting/height
%     * c: data type, obtained from the original variable name in the
%     Kongsberg datagram, or from the user's imagination for derived data
%     obtained from subsequent functions.
%
%   *DEVELOPMENT NOTES*
%   * only water column data can be subsampled, all other datagrams are
%   converted in full. To be consistent, develop code to subsample all
%   datagrams as desired in parameters. Add a subsampling in pings while
%   you're at it.
%   * Have not tested the loading of data from 'EM_Depth' and
%   'EM_SeabedImage' in the new format version (v2). Might need debugging.
%
%   See also ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 21-07-2021


%% input parsing

% init
p = inputParser;

% required
addRequired(p,'ALLdataGroup',@(x) isstruct(x) || iscell(x));

% optional
addOptional(p,'dr_sub',1,@(x) isnumeric(x)&&x>0);
addOptional(p,'db_sub',1,@(x) isnumeric(x)&&x>0);

% parse
parse(p,ALLdataGroup,varargin{:})

% get results
ALLdataGroup = p.Results.ALLdataGroup;
dr_sub = p.Results.dr_sub;
db_sub = p.Results.db_sub;
clear p;


%% pre-processing

if isstruct(ALLdataGroup)
    % single ALLdata structure
    
    % check it's from Kongsberg and that source file exist
    has_ALLfilename = isfield(ALLdataGroup, 'ALLfilename');
    if ~has_ALLfilename || ~CFF_check_ALLfilename(ALLdataGroup.ALLfilename)
        error('Invalid input');
    end
    
    % if clear, turn to cell before processing further
    ALLdataGroup = {ALLdataGroup};
    
elseif iscell(ALLdataGroup) && numel(ALLdataGroup)==2
    % pair of ALLdata structures
    
    % check it's from a pair of Kongsberg all/wcd files and that source
    % files exist
    has_ALLfilename = cell2mat(cellfun(@(x) isfield(x, 'ALLfilename'), ALLdataGroup, 'UniformOutput', false));
    rawfilenames = cellfun(@(x) x.ALLfilename, ALLdataGroup, 'UniformOutput', false);
    if ~all(has_ALLfilename) || ~CFF_check_ALLfilename(rawfilenames)
        error('Invalid input');
    end
    
else
    error('Invalid input');
end

% number of individual ALLdata structures in input ALLdataGroup
nStruct = length(ALLdataGroup);

% initialize fData, with current version number
fData.MET_Fmt_version = CFF_get_current_fData_version();

% initialize source filenames
fData.ALLfilename = cell(1,nStruct);


%% take one ALLdata structure at a time and add its contents to fData
for iF = 1:nStruct
    
    % get current structure
    ALLdata = ALLdataGroup{iF};
    
    % add source filename
    fData.ALLfilename{iF} = ALLdata.ALLfilename;
    
    % now reading each type of datagram.
    % Note we only convert the datagrams if fData does not already contain
    % any.
    
    
    %% EM_InstallationStart
    if isfield(ALLdata,'EM_InstallationStart') && ~isfield(fData,'IP_ASCIIparameters')
        
        % initialize struct
        IP_ASCIIparameters = struct;
        
        % read ASCIIdata
        ASCIIdata = char(ALLdata.EM_InstallationStart.ASCIIData(1));
        
        % remove carriage returns, tabs and linefeed
        ASCIIdata = regexprep(ASCIIdata,char(9),'');
        ASCIIdata = regexprep(ASCIIdata,newline,'');
        ASCIIdata = regexprep(ASCIIdata,char(13),'');
        
        % read individual fields
        if ~isempty(ASCIIdata)
            
            yo = strfind(ASCIIdata,',')';
            yo(:,1) = [1; yo(1:end-1)+1];        % beginning of ASCII field name
            yo(:,2) = strfind(ASCIIdata,'=')'-1; % end of ASCII field name
            yo(:,3) = strfind(ASCIIdata,'=')'+1; % beginning of ASCII field value
            yo(:,4) = strfind(ASCIIdata,',')'-1; % end of ASCII field value
            
            for ii = 1:size(yo,1)
                
                % get field string
                field = ASCIIdata(yo(ii,1):yo(ii,2));
                
                % try turn value into numeric
                value = str2double(ASCIIdata(yo(ii,3):yo(ii,4)));
                if length(value)~=1
                    % looks like it cant. Keep as string
                    value = ASCIIdata(yo(ii,3):yo(ii,4));
                end
                
                % store field/value
                IP_ASCIIparameters.(field) = value;
                
            end
            
        end
        
        % finally store in fData
        fData.IP_ASCIIparameters = IP_ASCIIparameters;
        
    end
    
    
    %% EM_Runtime
    if isfield(ALLdata,'EM_Runtime') && ~isfield(fData,'Ru_1D_Date')
        
        % Here we only record the fields we need later. More fields are
        % available than those below.
        
        fData.Ru_1D_Date                            = ALLdata.EM_Runtime.Date;
        fData.Ru_1D_TimeSinceMidnightInMilliseconds = ALLdata.EM_Runtime.TimeSinceMidnightInMilliseconds;
        fData.Ru_1D_PingCounter                     = ALLdata.EM_Runtime.PingCounter;
        fData.Ru_1D_TransmitPowerReMaximum          = ALLdata.EM_Runtime.TransmitPowerReMaximum;
        fData.Ru_1D_ReceiveBeamwidth                = ALLdata.EM_Runtime.ReceiveBeamwidth./10; % now in degrees
        
    end
    
    
    %% EM_SoundSpeedProfile
    if isfield(ALLdata,'EM_SoundSpeedProfile') && ~isfield(fData,'SS_1D_Date')
        
        nDatagrams  = length(ALLdata.EM_SoundSpeedProfile.TypeOfDatagram);
        maxnEntries = max(ALLdata.EM_SoundSpeedProfile.NumberOfEntries);
        
        fData.SS_1D_Date                                              = ALLdata.EM_SoundSpeedProfile.Date;
        fData.SS_1D_TimeSinceMidnightInMilliseconds                   = ALLdata.EM_SoundSpeedProfile.TimeSinceMidnightInMilliseconds;
        fData.SS_1D_ProfileCounter                                    = ALLdata.EM_SoundSpeedProfile.ProfileCounter;
        fData.SS_1D_DateWhenProfileWasMade                            = ALLdata.EM_SoundSpeedProfile.DateWhenProfileWasMade;
        fData.SS_1D_TimeSinceMidnightInMillisecondsWhenProfileWasMade = ALLdata.EM_SoundSpeedProfile.TimeSinceMidnightInMillisecondsWhenProfileWasMade;
        fData.SS_1D_NumberOfEntries                                   = ALLdata.EM_SoundSpeedProfile.NumberOfEntries;
        fData.SS_1D_DepthResolution                                   = ALLdata.EM_SoundSpeedProfile.DepthResolution;
        
        fData.SS_ED_Depth      = nan(maxnEntries,nDatagrams);
        fData.SS_ED_SoundSpeed = nan(maxnEntries,nDatagrams);
        
        for iD = 1:nDatagrams
            
            nEntries = ALLdata.EM_SoundSpeedProfile.NumberOfEntries(iD);
            
            fData.SS_ED_Depth(1:nEntries,iD)      = cell2mat(ALLdata.EM_SoundSpeedProfile.Depth(iD));
            fData.SS_ED_SoundSpeed(1:nEntries,iD) = cell2mat(ALLdata.EM_SoundSpeedProfile.SoundSpeed(iD));
            
        end
        
    end
    
    %% EM_Attitude
    if isfield(ALLdata,'EM_Attitude') && ~isfield(fData,'At_1D_Date')
        
        nDatagrams  = length(ALLdata.EM_Attitude.TypeOfDatagram);
        maxnEntries = max(ALLdata.EM_Attitude.NumberOfEntries);
        
        fData.At_1D_Date                            = ALLdata.EM_Attitude.Date;
        fData.At_1D_TimeSinceMidnightInMilliseconds = ALLdata.EM_Attitude.TimeSinceMidnightInMilliseconds;
        fData.At_1D_AttitudeCounter                 = ALLdata.EM_Attitude.AttitudeCounter;
        fData.At_1D_NumberOfEntries                 = ALLdata.EM_Attitude.NumberOfEntries;
        
        fData.At_ED_TimeInMillisecondsSinceRecordStart = nan(maxnEntries, nDatagrams);
        fData.At_ED_SensorStatus                       = nan(maxnEntries, nDatagrams);
        fData.At_ED_Roll                               = nan(maxnEntries, nDatagrams);
        fData.At_ED_Pitch                              = nan(maxnEntries, nDatagrams);
        fData.At_ED_Heave                              = nan(maxnEntries, nDatagrams);
        fData.At_ED_Heading                            = nan(maxnEntries, nDatagrams);
        
        for iD = 1:nDatagrams
            
            nEntries = ALLdata.EM_Attitude.NumberOfEntries(iD);
            
            fData.At_ED_TimeInMillisecondsSinceRecordStart(1:nEntries, iD) = cell2mat(ALLdata.EM_Attitude.TimeInMillisecondsSinceRecordStart(iD));
            fData.At_ED_SensorStatus(1:nEntries, iD)                       = cell2mat(ALLdata.EM_Attitude.SensorStatus(iD));
            fData.At_ED_Roll(1:nEntries, iD)                               = cell2mat(ALLdata.EM_Attitude.Roll(iD));
            fData.At_ED_Pitch(1:nEntries, iD)                              = cell2mat(ALLdata.EM_Attitude.Pitch(iD));
            fData.At_ED_Heave(1:nEntries, iD)                              = cell2mat(ALLdata.EM_Attitude.Heave(iD));
            fData.At_ED_Heading(1:nEntries, iD)                            = cell2mat(ALLdata.EM_Attitude.Heading(iD));
            
        end
        
    end
    
    
    %% EM_Height
    if isfield(ALLdata,'EM_Height') && ~isfield(fData,'He_1D_Date')
        
        fData.He_1D_Date                            = ALLdata.EM_Height.Date;
        fData.He_1D_TimeSinceMidnightInMilliseconds = ALLdata.EM_Height.TimeSinceMidnightInMilliseconds;
        fData.He_1D_HeightCounter                   = ALLdata.EM_Height.HeightCounter;
        fData.He_1D_Height                          = ALLdata.EM_Height.Height/100;
        
    end
    
    
    %% EM_Position
    if isfield(ALLdata,'EM_Position') && ~isfield(fData,'Po_1D_Date')
        
        fData.Po_1D_Date                            = ALLdata.EM_Position.Date;
        fData.Po_1D_TimeSinceMidnightInMilliseconds = ALLdata.EM_Position.TimeSinceMidnightInMilliseconds;  % in ms
        fData.Po_1D_PositionCounter                 = ALLdata.EM_Position.PositionCounter;
        fData.Po_1D_Latitude                        = ALLdata.EM_Position.Latitude./20000000; % now in decimal degrees
        fData.Po_1D_Longitude                       = ALLdata.EM_Position.Longitude./10000000; % now in decimal degrees
        fData.Po_1D_SpeedOfVesselOverGround         = ALLdata.EM_Position.SpeedOfVesselOverGround./100;  % now in m/s
        fData.Po_1D_HeadingOfVessel                 = ALLdata.EM_Position.HeadingOfVessel./100;  % now in degrees relative to north
        fData.Po_1D_MeasureOfPositionFixQuality     = ALLdata.EM_Position.MeasureOfPositionFixQuality./100;  % in meters
        fData.Po_1D_PositionSystemDescriptor        = ALLdata.EM_Position.PositionSystemDescriptor;  % indicator if there are several GPS sources
        
    end
    
    
    %% EM_Depth
    if isfield(ALLdata,'EM_Depth') && ~isfield(fData,'De_1P_Date')
        
        nPings  = length(ALLdata.EM_Depth.TypeOfDatagram); % total number of pings in file
        maxnBeams = max(cellfun(@(x) max(x),ALLdata.EM_Depth.BeamNumber)); % maximum beam number in file
        
        fData.De_1P_Date                            = ALLdata.EM_Depth.Date;
        fData.De_1P_TimeSinceMidnightInMilliseconds = ALLdata.EM_Depth.TimeSinceMidnightInMilliseconds;
        fData.De_1P_PingCounter                     = ALLdata.EM_Depth.PingCounter;
        fData.De_1P_HeadingOfVessel                 = ALLdata.EM_Depth.HeadingOfVessel;
        fData.De_1P_SoundSpeedAtTransducer          = ALLdata.EM_Depth.SoundSpeedAtTransducer*0.1;
        fData.De_1P_TransmitTransducerDepth         = ALLdata.EM_Depth.TransmitTransducerDepth + 65536.*ALLdata.EM_Depth.TransducerDepthOffsetMultiplier;
        fData.De_1P_MaximumNumberOfBeamsPossible    = ALLdata.EM_Depth.MaximumNumberOfBeamsPossible;
        fData.De_1P_NumberOfValidBeams              = ALLdata.EM_Depth.NumberOfValidBeams;
        fData.De_1P_ZResolution                     = ALLdata.EM_Depth.ZResolution;
        fData.De_1P_XAndYResolution                 = ALLdata.EM_Depth.XAndYResolution;
        fData.De_1P_SamplingRate                    = ALLdata.EM_Depth.SamplingRate;
        
        % initialize
        fData.De_BP_DepthZ                  = nan(maxnBeams,nPings);
        fData.De_BP_AcrosstrackDistanceY    = nan(maxnBeams,nPings);
        fData.De_BP_AlongtrackDistanceX     = nan(maxnBeams,nPings);
        fData.De_BP_BeamDepressionAngle     = nan(maxnBeams,nPings);
        fData.De_BP_BeamAzimuthAngle        = nan(maxnBeams,nPings);
        fData.De_BP_Range                   = nan(maxnBeams,nPings);
        fData.De_BP_QualityFactor           = nan(maxnBeams,nPings);
        fData.De_BP_LengthOfDetectionWindow = nan(maxnBeams,nPings);
        fData.De_BP_ReflectivityBS          = nan(maxnBeams,nPings);
        fData.De_B1_BeamNumber              = (1:maxnBeams)';
        
        for iP = 1:nPings
            
            N = cell2mat(ALLdata.EM_Depth.BeamNumber(iP));
            
            fData.De_BP_DepthZ(N,iP)                  = cell2mat(ALLdata.EM_Depth.DepthZ(iP));
            fData.De_BP_AcrosstrackDistanceY(N,iP)    = cell2mat(ALLdata.EM_Depth.AcrosstrackDistanceY(iP));
            fData.De_BP_AlongtrackDistanceX(N,iP)     = cell2mat(ALLdata.EM_Depth.AlongtrackDistanceX(iP));
            fData.De_BP_BeamDepressionAngle(N,iP)     = cell2mat(ALLdata.EM_Depth.BeamDepressionAngle(iP));
            fData.De_BP_BeamAzimuthAngle(N,iP)        = cell2mat(ALLdata.EM_Depth.BeamAzimuthAngle(iP));
            fData.De_BP_Range(N,iP)                   = cell2mat(ALLdata.EM_Depth.Range(iP));
            fData.De_BP_QualityFactor(N,iP)           = cell2mat(ALLdata.EM_Depth.QualityFactor(iP));
            fData.De_BP_LengthOfDetectionWindow(N,iP) = cell2mat(ALLdata.EM_Depth.LengthOfDetectionWindow(iP));
            fData.De_BP_ReflectivityBS(N,iP)          = cell2mat(ALLdata.EM_Depth.ReflectivityBS(iP));
            
        end
        
    end
    
    
    %% EM_XYZ88
    if isfield(ALLdata,'EM_XYZ88') && ~isfield(fData,'X8_1P_Date')
        
        nPings  = length(ALLdata.EM_XYZ88.TypeOfDatagram); % total number of pings in file
        maxnBeams = max(ALLdata.EM_XYZ88.NumberOfBeamsInDatagram); % maximum beam number in file
        
        fData.X8_1P_Date                            = ALLdata.EM_XYZ88.Date;
        fData.X8_1P_TimeSinceMidnightInMilliseconds = ALLdata.EM_XYZ88.TimeSinceMidnightInMilliseconds;
        fData.X8_1P_PingCounter                     = ALLdata.EM_XYZ88.PingCounter;
        fData.X8_1P_HeadingOfVessel                 = ALLdata.EM_XYZ88.HeadingOfVessel;
        fData.X8_1P_SoundSpeedAtTransducer          = ALLdata.EM_XYZ88.SoundSpeedAtTransducer*0.1;
        fData.X8_1P_TransmitTransducerDepth         = ALLdata.EM_XYZ88.TransmitTransducerDepth;
        fData.X8_1P_NumberOfBeamsInDatagram         = ALLdata.EM_XYZ88.NumberOfBeamsInDatagram;
        fData.X8_1P_NumberOfValidDetections         = ALLdata.EM_XYZ88.NumberOfValidDetections;
        fData.X8_1P_SamplingFrequencyInHz           = ALLdata.EM_XYZ88.SamplingFrequencyInHz;
        
        % initialize
        fData.X8_BP_DepthZ                       = nan(maxnBeams,nPings);
        fData.X8_BP_AcrosstrackDistanceY         = nan(maxnBeams,nPings);
        fData.X8_BP_AlongtrackDistanceX          = nan(maxnBeams,nPings);
        fData.X8_BP_DetectionWindowLength        = nan(maxnBeams,nPings);
        fData.X8_BP_QualityFactor                = nan(maxnBeams,nPings);
        fData.X8_BP_BeamIncidenceAngleAdjustment = nan(maxnBeams,nPings);
        fData.X8_BP_DetectionInformation         = nan(maxnBeams,nPings);
        fData.X8_BP_RealTimeCleaningInformation  = nan(maxnBeams,nPings);
        fData.X8_BP_ReflectivityBS               = nan(maxnBeams,nPings);
        fData.X8_B1_BeamNumber                   = (1:maxnBeams)';
        
        for iP = 1:nPings
            
            nBeams = numel(cell2mat(ALLdata.EM_XYZ88.DepthZ(iP)));
            
            fData.X8_BP_DepthZ(1:nBeams,iP)                       = cell2mat(ALLdata.EM_XYZ88.DepthZ(iP));
            fData.X8_BP_AcrosstrackDistanceY(1:nBeams,iP)         = cell2mat(ALLdata.EM_XYZ88.AcrosstrackDistanceY(iP));
            fData.X8_BP_AlongtrackDistanceX(1:nBeams,iP)          = cell2mat(ALLdata.EM_XYZ88.AlongtrackDistanceX(iP));
            fData.X8_BP_DetectionWindowLength(1:nBeams,iP)        = cell2mat(ALLdata.EM_XYZ88.DetectionWindowLength(iP));
            fData.X8_BP_QualityFactor(1:nBeams,iP)                = cell2mat(ALLdata.EM_XYZ88.QualityFactor(iP));
            fData.X8_BP_BeamIncidenceAngleAdjustment(1:nBeams,iP) = cell2mat(ALLdata.EM_XYZ88.BeamIncidenceAngleAdjustment(iP));
            fData.X8_BP_DetectionInformation(1:nBeams,iP)         = cell2mat(ALLdata.EM_XYZ88.DetectionInformation(iP));
            fData.X8_BP_RealTimeCleaningInformation(1:nBeams,iP)  = cell2mat(ALLdata.EM_XYZ88.RealTimeCleaningInformation(iP));
            fData.X8_BP_ReflectivityBS(1:nBeams,iP)               = cell2mat(ALLdata.EM_XYZ88.ReflectivityBS(iP));
            
        end
        
    end
    
    
    %% EM_SeabedImage
    if isfield(ALLdata,'EM_SeabedImage') && ~isfield(fData,'SI_1P_Date')
        
        nPings  = length(ALLdata.EM_SeabedImage.TypeOfDatagram); % total number of pings in file
        maxnBeams = max(cellfun(@(x) max(x),ALLdata.EM_SeabedImage.BeamIndexNumber))+1; % maximum beam number (beam index number +1), in file
        maxnSamples = max(cellfun(@(x) max(x),ALLdata.EM_SeabedImage.NumberOfSamplesPerBeam)); % maximum number of samples for a beam, in file
        
        fData.SI_1P_Date                            = ALLdata.EM_SeabedImage.Date;
        fData.SI_1P_TimeSinceMidnightInMilliseconds = ALLdata.EM_SeabedImage.TimeSinceMidnightInMilliseconds;
        fData.SI_1P_PingCounter                     = ALLdata.EM_SeabedImage.PingCounter;
        fData.SI_1P_MeanAbsorptionCoefficient       = ALLdata.EM_SeabedImage.MeanAbsorptionCoefficient;
        fData.SI_1P_PulseLength                     = ALLdata.EM_SeabedImage.PulseLength;
        fData.SI_1P_RangeToNormalIncidence          = ALLdata.EM_SeabedImage.RangeToNormalIncidence;
        fData.SI_1P_StartRangeSampleOfTVGRamp       = ALLdata.EM_SeabedImage.StartRangeSampleOfTVGRamp;
        fData.SI_1P_StopRangeSampleOfTVGRamp        = ALLdata.EM_SeabedImage.StopRangeSampleOfTVGRamp;
        fData.SI_1P_NormalIncidenceBS               = ALLdata.EM_SeabedImage.NormalIncidenceBS;
        fData.SI_1P_ObliqueBS                       = ALLdata.EM_SeabedImage.ObliqueBS;
        fData.SI_1P_TxBeamwidth                     = ALLdata.EM_SeabedImage.TxBeamwidth;
        fData.SI_1P_TVGLawCrossoverAngle            = ALLdata.EM_SeabedImage.TVGLawCrossoverAngle;
        fData.SI_1P_NumberOfValidBeams              = ALLdata.EM_SeabedImage.NumberOfValidBeams;
        
        % initialize
        fData.SI_BP_SortingDirection       = nan(maxnBeams,nPings);
        fData.SI_BP_NumberOfSamplesPerBeam = nan(maxnBeams,nPings);
        fData.SI_BP_CentreSampleNumber     = nan(maxnBeams,nPings);
        fData.SI_B1_BeamNumber             = (1:maxnBeams)';
        fData.SI_SBP_SampleAmplitudes      = cell(nPings,1); % saving as a cell vector of sparse matrices, per ping
        
        for iP = 1:nPings
            
            % Get data from datagram
            BeamNumber             = cell2mat(ALLdata.EM_SeabedImage.BeamIndexNumber(iP))+1;
            NumberOfSamplesPerBeam = cell2mat(ALLdata.EM_SeabedImage.NumberOfSamplesPerBeam(iP));
            Samples                = cell2mat(ALLdata.EM_SeabedImage.SampleAmplitudes(iP).beam(:));
            
            % from number of samples per beam, get indices of first and last
            % sample for each beam in the Samples data vector
            iFirst = [1;cumsum(NumberOfSamplesPerBeam(1:end-1))+1];
            iLast  = iFirst+NumberOfSamplesPerBeam-1;
            
            % store
            fData.SI_BP_SortingDirection(BeamNumber,iP)       = cell2mat(ALLdata.EM_SeabedImage.SortingDirection(iP));
            fData.SI_BP_NumberOfSamplesPerBeam(BeamNumber,iP) = NumberOfSamplesPerBeam;
            fData.SI_BP_CentreSampleNumber(BeamNumber,iP)     = cell2mat(ALLdata.EM_SeabedImage.CentreSampleNumber(iP));
            
            % initialize the beams/sample array (use zero instead of NaN to
            % allow turning it to sparse
            temp = zeros(maxnSamples,length(BeamNumber));
            
            % fill in
            for iB = 1:length(BeamNumber)
                temp(1:NumberOfSamplesPerBeam(iB),BeamNumber(iB)) = Samples(iFirst(iB):iLast(iB));
            end
            
            % and save as sparse matrix, as sparse version
            % to use full matrices, fData.SI_SBP_SampleAmplitudes(:,:,iP) = temp;
            fData.SI_SBP_SampleAmplitudes(iP,1) = {sparse(temp)};
            
        end
        
    end
    
    
    %% EM_SeabedImage89
    if isfield(ALLdata,'EM_SeabedImage89') && ~isfield(fData,'S8_1P_Date')
        
        nPings  = length(ALLdata.EM_SeabedImage89.TypeOfDatagram); % total number of pings in file
        maxnBeams = max(ALLdata.EM_SeabedImage89.NumberOfValidBeams); % maximum beam number (beam index number +1), in file
        maxnSamples = max(cellfun(@(x) max(x),ALLdata.EM_SeabedImage89.NumberOfSamplesPerBeam)); % maximum number of samples for a beam, in file
        
        fData.S8_1P_Date                            = ALLdata.EM_SeabedImage89.Date;
        fData.S8_1P_TimeSinceMidnightInMilliseconds = ALLdata.EM_SeabedImage89.TimeSinceMidnightInMilliseconds;
        fData.S8_1P_PingCounter                     = ALLdata.EM_SeabedImage89.PingCounter;
        fData.S8_1P_SamplingFrequencyInHz           = ALLdata.EM_SeabedImage89.SamplingFrequencyInHz;
        fData.S8_1P_RangeToNormalIncidence          = ALLdata.EM_SeabedImage89.RangeToNormalIncidence;
        fData.S8_1P_NormalIncidenceBS               = ALLdata.EM_SeabedImage89.NormalIncidenceBS;
        fData.S8_1P_ObliqueBS                       = ALLdata.EM_SeabedImage89.ObliqueBS;
        fData.S8_1P_TxBeamwidthAlong                = ALLdata.EM_SeabedImage89.TxBeamwidthAlong;
        fData.S8_1P_TVGLawCrossoverAngle            = ALLdata.EM_SeabedImage89.TVGLawCrossoverAngle;
        fData.S8_1P_NumberOfValidBeams              = ALLdata.EM_SeabedImage89.NumberOfValidBeams;
        
        % initialize
        fData.S8_BP_SortingDirection       = nan(maxnBeams,nPings);
        fData.S8_BP_DetectionInfo          = nan(maxnBeams,nPings);
        fData.S8_BP_NumberOfSamplesPerBeam = nan(maxnBeams,nPings);
        fData.S8_BP_CentreSampleNumber     = nan(maxnBeams,nPings);
        fData.S8_B1_BeamNumber             = (1:maxnBeams)';
        fData.S8_SBP_SampleAmplitudes      = cell(nPings,1); % saving as a cell vector of sparse matrices, per ping
        
        % in this more recent datagram, all beams are in. No beamnumber anymore
        BeamNumber = fData.S8_B1_BeamNumber;
        
        for iP = 1:nPings
            
            % Get data from datagram
            NumberOfSamplesPerBeam = cell2mat(ALLdata.EM_SeabedImage89.NumberOfSamplesPerBeam(iP));
            Samples                = cell2mat(ALLdata.EM_SeabedImage89.SampleAmplitudes(iP).beam(:));
            
            % from number of samples per beam, get indices of first and last
            % sample for each beam in the Samples data vector
            iFirst = [1;cumsum(NumberOfSamplesPerBeam(1:end-1))+1];
            iLast  = iFirst+NumberOfSamplesPerBeam-1;
            
            % store
            fData.S8_BP_SortingDirection(BeamNumber,iP)       = cell2mat(ALLdata.EM_SeabedImage89.SortingDirection(iP));
            fData.S8_BP_NumberOfSamplesPerBeam(BeamNumber,iP) = NumberOfSamplesPerBeam;
            fData.S8_BP_CentreSampleNumber(BeamNumber,iP)     = cell2mat(ALLdata.EM_SeabedImage89.CentreSampleNumber(iP));
            
            % initialize the beams/sample array (use zero instead of NaN to
            % allow turning it to sparse
            temp = zeros(maxnSamples,length(BeamNumber));
            
            % and fill in
            for iB = 1:length(BeamNumber)
                temp(1:NumberOfSamplesPerBeam(iB),BeamNumber(iB)) = Samples(iFirst(iB):iLast(iB));
            end
            
            % and save as sparse matrix, as sparse version
            % to use full matrices, fData.S8_SBP_SampleAmplitudes(:,:,iP) = temp;
            fData.S8_SBP_SampleAmplitudes(iP,1) = {sparse(temp)};
            
        end
        
    end
    
    
    %% EM_WaterColumn
    if isfield(ALLdata,'EM_WaterColumn') && ~isfield(fData,'WC_1P_Date')
        
        % samples data from WC or AP datagrams were not recorded, so we
        % need to fopen the source file to grab the data
        fid_all = fopen(fData.ALLfilename{iF},'r',ALLdata.datagramsformat);
        
        % also, that data will not be saved in fData but in binary files.
        % Get the output directory to store those files 
        wc_dir = CFF_converted_data_folder(fData.ALLfilename{iF});
        
        % get the number of heads
        headNumber = unique(ALLdata.EM_WaterColumn.SystemSerialNumber,'stable');
        
        % There are multiple datagrams per ping. Get the list of pings, and
        % the index of the first datagram for each ping 
        if length(headNumber) == 1
            % if only one head, it's simple
            [pingCounters, iFirstDatagram] = unique(ALLdata.EM_WaterColumn.PingCounter,'stable');
        else
            % in case there's more than one head, we're going to only keep
            % pings for which we have data for all heads
            
            % pings for first head
            pingCounters = unique(ALLdata.EM_WaterColumn.PingCounter(ALLdata.EM_WaterColumn.SystemSerialNumber==headNumber(1)),'stable');
            
            % for each other head, get ping numbers and only keep
            % intersection 
            for iH = 2:length(headNumber)
                pingCountersOtherHead = unique(ALLdata.EM_WaterColumn.PingCounter(ALLdata.EM_WaterColumn.SystemSerialNumber==headNumber(iH)),'stable');
                pingCounters = intersect(pingCounters, pingCountersOtherHead);
            end
            
            % get the index of first datagram for each ping and each head
            for iH = 1:length(headNumber)
                
                iFirstDatagram(:,iH) = arrayfun(@(x) find(ALLdata.EM_WaterColumn.SystemSerialNumber==headNumber(iH) & ALLdata.EM_WaterColumn.PingCounter==x, 1),pingCounters);
                
                % Originally we would require datagram number 1, but it
                % turns out it doesn't always exist. Keep this code here
                % for now, but the replacement above to just find the first
                % datagram for each ping seems to work fine.
                %
                % iFirstDatagram(:,iH) = find( ALLdata.EM_WaterColumn.SystemSerialNumber == headNumber(iH) & ...
                %     ismember(ALLdata.EM_WaterColumn.PingCounter,pingCounters) & ...
                %     ALLdata.EM_WaterColumn.DatagramNumbers == 1);
            end
        end
        
        % add the WCD decimation factors given here in input
        fData.dr_sub = dr_sub;
        fData.db_sub = db_sub;
        
        % save ping numbers
        fData.WC_1P_PingCounter = pingCounters;
        
        % values for the following fields are constant for a ping, over all
        % datagrams and all heads. Simply take value from first datagram
        fData.WC_1P_Date                            = ALLdata.EM_WaterColumn.Date(iFirstDatagram(:,1));
        fData.WC_1P_TimeSinceMidnightInMilliseconds = ALLdata.EM_WaterColumn.TimeSinceMidnightInMilliseconds(iFirstDatagram(:,1));
        fData.WC_1P_SoundSpeed                      = ALLdata.EM_WaterColumn.SoundSpeed(iFirstDatagram(:,1))*0.1;
        fData.WC_1P_OriginalSamplingFrequencyHz     = ALLdata.EM_WaterColumn.SamplingFrequency(iFirstDatagram(:,1)).*0.01; % in Hz
        fData.WC_1P_SamplingFrequencyHz             = (ALLdata.EM_WaterColumn.SamplingFrequency(iFirstDatagram(:,1)).*0.01)./dr_sub; % in Hz
        fData.WC_1P_TXTimeHeave                     = ALLdata.EM_WaterColumn.TXTimeHeave(iFirstDatagram(:,1));
        fData.WC_1P_TVGFunctionApplied              = ALLdata.EM_WaterColumn.TVGFunctionApplied(iFirstDatagram(:,1));
        fData.WC_1P_TVGOffset                       = ALLdata.EM_WaterColumn.TVGOffset(iFirstDatagram(:,1));
        fData.WC_1P_ScanningInfo                    = ALLdata.EM_WaterColumn.ScanningInfo(iFirstDatagram(:,1));
        
        % Still, test for inconsistencies between heads and raise a warning
        % if we detect one. To be investigated if it every happens
        if length(headNumber) > 1
            fields = {'SoundSpeed','SamplingFrequency','TXTimeHeave','TVGFunctionApplied','TVGOffset','ScanningInfo'};
            for iFi = 1:length(fields)
                if any(any(ALLdata.EM_WaterColumn.(fields{iFi})(iFirstDatagram(:,1))'.*ones(1,length(headNumber))~=ALLdata.EM_WaterColumn.(fields{iFi})(iFirstDatagram)))
                    warning('System has more than one head and "%s" data are inconsistent between heads for at least one ping. Using information from first head anyway.',fields{iFi});
                end
            end
        end
        
        % for the following fields, values need need to be summed over all
        % heads
        if length(headNumber) > 1
            fData.WC_1P_NumberOfDatagrams         = sum(ALLdata.EM_WaterColumn.NumberOfDatagrams(iFirstDatagram),2)';
            fData.WC_1P_NumberOfTransmitSectors   = sum(ALLdata.EM_WaterColumn.NumberOfTransmitSectors(iFirstDatagram),2)';
            fData.WC_1P_TotalNumberOfReceiveBeams = sum(ALLdata.EM_WaterColumn.TotalNumberOfReceiveBeams(iFirstDatagram),2)';
            fData.WC_1P_NumberOfBeamsToRead       = sum(ceil(ALLdata.EM_WaterColumn.TotalNumberOfReceiveBeams(iFirstDatagram)/db_sub),2)'; % each head is decimated in beam individually
        else
            fData.WC_1P_NumberOfDatagrams         = ALLdata.EM_WaterColumn.NumberOfDatagrams(iFirstDatagram);
            fData.WC_1P_NumberOfTransmitSectors   = ALLdata.EM_WaterColumn.NumberOfTransmitSectors(iFirstDatagram);
            fData.WC_1P_TotalNumberOfReceiveBeams = ALLdata.EM_WaterColumn.TotalNumberOfReceiveBeams(iFirstDatagram);
            fData.WC_1P_NumberOfBeamsToRead       = ceil(ALLdata.EM_WaterColumn.TotalNumberOfReceiveBeams(iFirstDatagram)/db_sub);
        end
        
        % number of pings
        nPings = length(pingCounters); % total number of pings in file
        
        % number of Tx sectors
        maxnTxSectors = max(fData.WC_1P_NumberOfTransmitSectors); % maximum number of transmit sectors in a ping
        
        % number of beams
        % maxnBeams = max(fData.WC_1P_TotalNumberOfReceiveBeams); % maximum number of receive beams in a ping (not using it)
        maxnBeams_sub = max(fData.WC_1P_NumberOfBeamsToRead); % maximum number of receive beams TO READ
        
        % number of samples
        % maxnSamples = max(cellfun(@(x) max(x), ALLdata.EM_WaterColumn.NumberOfSamples(ismember(ALLdata.EM_WaterColumn.PingCounter,pingCounters)))); % maximum number of samples in a ping (not using it)
        % maxnSamples_sub  = ceil(maxnSamples/dr_sub); 
        [maxnSamples_groups, ping_group_start, ping_group_end] = CFF_group_pings(ALLdata.EM_WaterColumn.NumberOfSamples, pingCounters, ALLdata.EM_WaterColumn.PingCounter); % making groups of pings to limit size of memmaped files
        maxnSamples_groups = ceil(maxnSamples_groups/dr_sub); % maximum number of samples TO READ, per group.
         
        % initialize data per transmit sector and ping
        fData.WC_TP_TiltAngle            = nan(maxnTxSectors,nPings);
        fData.WC_TP_CenterFrequency      = nan(maxnTxSectors,nPings);
        fData.WC_TP_TransmitSectorNumber = nan(maxnTxSectors,nPings);
        fData.WC_TP_SystemSerialNumber   = nan(maxnTxSectors,nPings);
        
        % initialize data per decimated beam and ping
        fData.WC_BP_BeamPointingAngle      = nan(maxnBeams_sub,nPings);
        fData.WC_BP_StartRangeSampleNumber = nan(maxnBeams_sub,nPings);
        fData.WC_BP_NumberOfSamples        = nan(maxnBeams_sub,nPings);
        fData.WC_BP_DetectedRangeInSamples = zeros(maxnBeams_sub,nPings);
        fData.WC_BP_TransmitSectorNumber   = nan(maxnBeams_sub,nPings);
        fData.WC_BP_BeamNumber             = nan(maxnBeams_sub,nPings);
        fData.WC_BP_SystemSerialNumber     = nan(maxnBeams_sub,nPings);
        
        % Definition of Kongsberg's water-column data format. We keep it
        % exactly like this to save disk space.
        % The raw data are recorded in "int8" (signed integers from -128 to
        % 127) with -128 being the NaN value. It needs to be multiplied by
        % a factor of 1/2 to retrieve the true value, aka an int8 record of
        % -41 is actually -20.5dB.
        raw_WC_Class = 'int8';
        raw_WC_Factor = 1./2;
        raw_WC_Nanval = intmin(raw_WC_Class); % -128
        
        % precision source and output for fread
        precision = sprintf('%s=>%s', raw_WC_Class, raw_WC_Class);
        
        % initialize data-holding binary files
        fData = CFF_init_memmapfiles(fData, ...
            'field', 'WC_SBP_SampleAmplitudes', ...
            'wc_dir', wc_dir, ...
            'Class', raw_WC_Class, ...
            'Factor', raw_WC_Factor, ...
            'Nanval', raw_WC_Nanval, ...
            'Offset', 0, ...
            'MaxSamples', maxnSamples_groups, ...
            'MaxBeams', maxnBeams_sub, ...
            'ping_group_start', ping_group_start, ...
            'ping_group_end', ping_group_end);
        
        % initialize ping group counter, to use to specify which memmapfile
        % to fill. We start in the first.
        iG = 1;
        
        % now get data for each ping
        for iP = 1:nPings
            
            % ping number (ex: 50455)
            pingCounter = fData.WC_1P_PingCounter(1,iP);
            
            % update ping group counter if needed
            if pingCounter > fData.WC_1P_PingCounter(ping_group_end(iG))
                iG = iG+1;
            end
            
            % initialize amplitude matrix for that ping
            SB_temp = raw_WC_Nanval.*ones(maxnSamples_groups(iG),maxnBeams_sub,raw_WC_Class);
            
            % initialize number of sectors and beams recorded so far for
            % that ping (needed for multiple heads)
            nTxSectTot = 0;
            nBeamTot = 0;
            
            for iH = 1:length(headNumber)
                
                headSSN = headNumber(iH);
                
                % index of the datagrams making up this ping/head in ALLdata.EM_Watercolumn (ex: 58-59-61-64)
                iDatagrams = find( ALLdata.EM_WaterColumn.PingCounter == pingCounter & ...
                    ALLdata.EM_WaterColumn.SystemSerialNumber == headSSN);
                
                % actual number of datagrams available (ex: 4)
                nDatagrams = length(iDatagrams);
                
                % some datagrams may be missing. Need to detect and adjust.
                datagramOrder     = ALLdata.EM_WaterColumn.DatagramNumbers(iDatagrams); % order of the datagrams (ex: 4-3-6-2, the missing one is 1st, 5th and 7th)
                [~,IX]            = sort(datagramOrder);
                iDatagrams        = iDatagrams(IX); % index of the datagrams making up this ping in ALLdata.EM_Watercolumn, but in the right order (ex: 64-59-58-61, missing datagrams are still missing)
                nBeamsPerDatagram = ALLdata.EM_WaterColumn.NumberOfBeamsInThisDatagram(iDatagrams); % number of beams in each datagram making up this ping (ex: 56-61-53-28)
                
                % number of transmit sectors to record
                nTxSect = ALLdata.EM_WaterColumn.NumberOfTransmitSectors(iDatagrams(1));
                
                % indices of those sectors in output structure
                iTxSectDest = nTxSectTot + (1:nTxSect);
                
                % data per Tx sector
                fData.WC_TP_TiltAngle(iTxSectDest,iP)            = ALLdata.EM_WaterColumn.TiltAngle{iDatagrams(1)};
                fData.WC_TP_CenterFrequency(iTxSectDest,iP)      = ALLdata.EM_WaterColumn.CenterFrequency{iDatagrams(1)};
                fData.WC_TP_TransmitSectorNumber(iTxSectDest,iP) = ALLdata.EM_WaterColumn.TransmitSectorNumber{iDatagrams(1)};
                fData.WC_TP_SystemSerialNumber(iTxSectDest,iP)   = headSSN;
                
                % updating total number of sectors recorded so far
                nTxSectTot = nTxSectTot + nTxSect;
                
                % and then read the data in each datagram
                for iD = 1:nDatagrams
                    
                    % indices of desired beams in this head/datagram
                    if iD == 1
                        % if first datagram, start with first beam
                        iBeamStart = 1;
                    else
                        % if not first datagram, continue the decimation where we left it 
                        nBeamsLastDatag = nBeamsPerDatagram(iD-1);
                        lastRecBeam  = iBeamSource(end);
                        iBeamStart = db_sub - (nBeamsLastDatag-lastRecBeam);
                    end
                    
                    % select beams with decimation
                    iBeamSource = iBeamStart:db_sub:nBeamsPerDatagram(iD);
                    
                    % number of beams to record
                    nBeam = length(iBeamSource);
                    
                    % indices of those beams in output structure
                    iBeamDest = nBeamTot + (1:nBeam);
                    
                    % record those beams' data, applying decimation in range to the data that are samples numbers.
                    fData.WC_BP_BeamPointingAngle(iBeamDest,iP)      = ALLdata.EM_WaterColumn.BeamPointingAngle{iDatagrams(iD)}(iBeamSource)/100;
                    fData.WC_BP_StartRangeSampleNumber(iBeamDest,iP) = round(ALLdata.EM_WaterColumn.StartRangeSampleNumber{iDatagrams(iD)}(iBeamSource)./dr_sub);
                    fData.WC_BP_NumberOfSamples(iBeamDest,iP)        = round(ALLdata.EM_WaterColumn.NumberOfSamples{iDatagrams(iD)}(iBeamSource)./dr_sub);
                    fData.WC_BP_DetectedRangeInSamples(iBeamDest,iP) = round(ALLdata.EM_WaterColumn.DetectedRangeInSamples{iDatagrams(iD)}(iBeamSource)./dr_sub);
                    fData.WC_BP_TransmitSectorNumber(iBeamDest,iP)   = ALLdata.EM_WaterColumn.TransmitSectorNumber2{iDatagrams(iD)}(iBeamSource);
                    fData.WC_BP_BeamNumber(iBeamDest,iP)             = ALLdata.EM_WaterColumn.BeamNumber{iDatagrams(iD)}(iBeamSource);
                    fData.WC_BP_SystemSerialNumber(iBeamDest,iP)     = headSSN;
                    
                    % and then, in each beam...
                    for iB = 1:nBeam
                        
                        % get actual number of samples in that beam
                        nSamp = ALLdata.EM_WaterColumn.NumberOfSamples{iDatagrams(iD)}(iBeamSource(iB));
                        
                        % number of samples we're going to record
                        nSamp_sub = ceil(nSamp/dr_sub);
                        
                        % get to the start of the data in original file
                        pos = ALLdata.EM_WaterColumn.SampleAmplitudePosition{iDatagrams(iD)}(iBeamSource(iB));
                        curr_pos = ftell(fid_all);
                        fseek(fid_all,pos-curr_pos,'cof');
                        
                        % read raw data, with decimation in range
                        SB_temp(1:nSamp_sub,iBeamDest(iB)) = fread(fid_all, nSamp_sub, precision, dr_sub-1);
                        
                    end
                    
                    % updating total number of beams recorded so far
                    nBeamTot = nBeamTot + nBeam;
                    
                end
                
            end
            
            % finished reading this ping's WC data. Store the data in the
            % appropriate binary file, at the appropriate ping, through the
            % memory mapping 
            fData.WC_SBP_SampleAmplitudes{iG}.Data.val(:,:,iP-ping_group_start(iG)+1) = SB_temp;
            
        end
        
        % close the original raw file
        fclose(fid_all);
        
    end
    
    
    %% EM_AmpPhase
    if isfield(ALLdata,'EM_AmpPhase') && ~isfield(fData,'AP_1P_Date')
        
        % samples data from WC or AP datagrams were not recorded, so we
        % need to fopen the source file to grab the data
        fid_all = fopen(fData.ALLfilename{iF},'r',ALLdata.datagramsformat);
        
        % also, that data will not be saved in fData but in binary files.
        % Get the output directory to store those files 
        wc_dir = CFF_converted_data_folder(fData.ALLfilename{iF});
        
        % get the number of heads
        headNumber = unique(ALLdata.EM_AmpPhase.SystemSerialNumber,'stable');
        % note we don't support multiple-head data for AP as we do for WC.
        % To be coded if we ever come across it...
        
        % There are multiple datagrams per ping. Get the list of pings, and
        % the index of the first datagram for each ping 
        [pingCounters,iFirstDatagram] = unique(ALLdata.EM_AmpPhase.PingCounter,'stable');
        
        % add the WCD decimation factors given here in input
        fData.dr_sub = dr_sub;
        fData.db_sub = db_sub;
        
        % save ping numbers
        fData.AP_1P_PingCounter = ALLdata.EM_AmpPhase.PingCounter(iFirstDatagram);
        
        % values for the following fields are constant over all datagrams
        % making up a ping. Take value from first datagram 
        fData.AP_1P_Date                            = ALLdata.EM_AmpPhase.Date(iFirstDatagram);
        fData.AP_1P_TimeSinceMidnightInMilliseconds = ALLdata.EM_AmpPhase.TimeSinceMidnightInMilliseconds(iFirstDatagram);
        fData.AP_1P_SoundSpeed                      = ALLdata.EM_AmpPhase.SoundSpeed(iFirstDatagram)*0.1;
        fData.AP_1P_OriginalSamplingFrequencyHz     = ALLdata.EM_AmpPhase.SamplingFrequency(iFirstDatagram).*0.01; % in Hz
        fData.AP_1P_SamplingFrequencyHz             = (ALLdata.EM_AmpPhase.SamplingFrequency(iFirstDatagram).*0.01)./dr_sub; % in Hz
        fData.AP_1P_TXTimeHeave                     = ALLdata.EM_AmpPhase.TXTimeHeave(iFirstDatagram);
        fData.AP_1P_TVGFunctionApplied              = ALLdata.EM_AmpPhase.TVGFunctionApplied(iFirstDatagram);
        fData.AP_1P_TVGOffset                       = ALLdata.EM_AmpPhase.TVGOffset(iFirstDatagram);
        fData.AP_1P_ScanningInfo                    = ALLdata.EM_AmpPhase.ScanningInfo(iFirstDatagram);
        fData.AP_1P_NumberOfDatagrams               = ALLdata.EM_AmpPhase.NumberOfDatagrams(iFirstDatagram);
        fData.AP_1P_NumberOfTransmitSectors         = ALLdata.EM_AmpPhase.NumberOfTransmitSectors(iFirstDatagram);
        fData.AP_1P_TotalNumberOfReceiveBeams       = ALLdata.EM_AmpPhase.TotalNumberOfReceiveBeams(iFirstDatagram);
        fData.AP_1P_NumberOfBeamsToRead             = ceil(ALLdata.EM_AmpPhase.TotalNumberOfReceiveBeams(iFirstDatagram)/db_sub);
        
        % ----- get original data dimensions ------------------------------
        % total number of pings in file
        nPings = length(pingCounters); 
        
        % maximum number of transmit sectors in a ping
        maxnTxSectors = max(fData.AP_1P_NumberOfTransmitSectors); 
        
        % maximum number of receive beams in a ping (not using it)
        % maxnBeams = max(fData.AP_1P_TotalNumberOfReceiveBeams); 
        
        % max number of samples for a beam in file (not using it)
        % maxnSamples = max(cellfun(@(x) max(x), ALLdata.EM_AmpPhase.NumberOfSamples));
        % ----------------------------------------------------------------- 
        
        % ----- get dimensions of data to read after decimation -----------
        % maximum number of receive beams TO READ
        maxnBeams_sub = max(fData.AP_1P_NumberOfBeamsToRead);
        
        % maximum number of samples TO READ
        % maxnSamples_sub  = ceil(maxnSamples/dr_sub); 
        
        % make groups of pings, so that indiviudal binary files are not too
        % big
        [maxnSamples_groups, ping_group_start, ping_group_end] = CFF_group_pings(ALLdata.EM_AmpPhase.NumberOfSamples, pingCounters, ALLdata.EM_AmpPhase.PingCounter);
        
        % maximum number of samples TO READ, per group.
        maxnSamples_groups = ceil(maxnSamples_groups/dr_sub); 
        % ----------------------------------------------------------------- 
        
        % initialize data per transmit sector and ping
        fData.AP_TP_TiltAngle            = nan(maxnTxSectors,nPings);
        fData.AP_TP_CenterFrequency      = nan(maxnTxSectors,nPings);
        fData.AP_TP_TransmitSectorNumber = nan(maxnTxSectors,nPings);
        % fData.AP_TP_SystemSerialNumber   = nan(maxnTxSectors,nPings);
        
        % initialize data per decimated beam and ping
        fData.AP_BP_BeamPointingAngle      = nan(maxnBeams_sub,nPings);
        fData.AP_BP_StartRangeSampleNumber = nan(maxnBeams_sub,nPings);
        fData.AP_BP_NumberOfSamples        = nan(maxnBeams_sub,nPings);
        fData.AP_BP_DetectedRangeInSamples = zeros(maxnBeams_sub,nPings);
        fData.AP_BP_TransmitSectorNumber   = nan(maxnBeams_sub,nPings);
        fData.AP_BP_BeamNumber             = nan(maxnBeams_sub,nPings);
        % fData.AC_BP_SystemSerialNumber     = nan(maxnBeams_sub,nPings);
        
        % Definition of Kongsberg's amplitude-phase data format. We keep it
        % exactly like this to save disk space.
        raw_AP_Class = 'int16';
        raw_A_Factor = 1/200;
        raw_P_Factor = 1/30;
        raw_A_Nanval = intmin(raw_AP_Class); % -32768
        raw_P_Nanval = 200;
        
        % initialize data-holding binary files
        fData = CFF_init_memmapfiles(fData, ...
            'field', 'AP_SBP_SampleAmplitudes', ...
            'wc_dir', wc_dir, ...
            'Class', raw_AP_Class, ...
            'Factor', raw_A_Factor, ...
            'Nanval', raw_A_Nanval, ...
            'Offset', 0, ...
            'MaxSamples', maxnSamples_groups, ...
            'MaxBeams', maxnBeams_sub, ...
            'ping_group_start', ping_group_start, ...
            'ping_group_end', ping_group_end);
        
        fData = CFF_init_memmapfiles(fData, ...
            'field', 'AP_SBP_SamplePhase', ...
            'wc_dir', wc_dir, ...
            'Class', raw_AP_Class, ...
            'Factor', raw_P_Factor, ...
            'Nanval', raw_P_Nanval, ...
            'Offset', 0, ...
            'MaxSamples', maxnSamples_groups, ...
            'MaxBeams', maxnBeams_sub, ...
            'ping_group_start', ping_group_start, ...
            'ping_group_end', ping_group_end);
        
        % initialize ping group counter, to use to specify which memmapfile
        % to fill. We start in the first.
        iG = 1;
        
        % debug graph
        disp_wc = 0;
        if disp_wc
            f = figure();
            ax_mag = axes(f,'outerposition',[0 0.5 1 0.5]);
            ax_phase = axes(f,'outerposition',[0 0 1 0.5]);
        end
        
        % now get data for each ping
        for iP = 1:nPings
            
            % ping number (ex: 50455)
            pingCounter = fData.AP_1P_PingCounter(1,iP);
            
            % update ping group counter if needed
            if pingCounter > fData.AP_1P_PingCounter(ping_group_end(iG))
                iG = iG+1;
            end
            
            % initialize the water column data matrix for that ping.
            SB2_temp = raw_A_Nanval.*ones(maxnSamples_groups(iG),maxnBeams_sub,raw_AP_Class);
            Ph_temp  = raw_P_Nanval.*ones(maxnSamples_groups(iG),maxnBeams_sub,raw_AP_Class);
            
            % index of the datagrams making up this ping/head in ALLdata.EM_Watercolumn (ex: 58-59-61-64)
            iDatagrams  = find(ALLdata.EM_AmpPhase.PingCounter==pingCounter);
            
            % actual number of datagrams available (ex: 4)
            nDatagrams  = length(iDatagrams);
            
            % some datagrams may be missing. Need to detect and adjust.
            datagramOrder     = ALLdata.EM_AmpPhase.DatagramNumbers(iDatagrams); % order of the datagrams (ex: 4-3-6-2, the missing one is 1st, 5th and 7th)
            [~,IX]            = sort(datagramOrder);
            iDatagrams        = iDatagrams(IX); % index of the datagrams making up this ping in ALLdata.EM_AmpPhase, but in the right order (ex: 64-59-58-61, missing datagrams are still missing)
            nBeamsPerDatagram = ALLdata.EM_AmpPhase.NumberOfBeamsInThisDatagram(iDatagrams); % number of beams in each datagram making up this ping (ex: 56-61-53-28)
            
            % number of transmit sectors in this ping
            nTxSect = fData.AP_1P_NumberOfTransmitSectors(1,iP);
            
            % recording data per transmit sector
            fData.AP_TP_TiltAngle(1:nTxSect,iP)            = ALLdata.EM_AmpPhase.TiltAngle{iDatagrams(1)};
            fData.AP_TP_CenterFrequency(1:nTxSect,iP)      = ALLdata.EM_AmpPhase.CenterFrequency{iDatagrams(1)};
            fData.AP_TP_TransmitSectorNumber(1:nTxSect,iP) = ALLdata.EM_AmpPhase.TransmitSectorNumber{iDatagrams(1)};
            
            % and then read the data in each datagram
            for iD = 1:nDatagrams
                
                % index of beams in output structure for this datagram
                [iBeams,idx_beams] = unique(ceil((sum(nBeamsPerDatagram(1:iD-1)) + (1:nBeamsPerDatagram(iD)))/db_sub));
                % old approach
                % iBeams = sum(nBeamsPerDatagram(1:iD-1)) + (1:nBeamsPerDatagram(iD));
                % idx_beams = (1:numel(iBeams));
                
                % ping x beam data
                fData.AP_BP_BeamPointingAngle(iBeams,iP)      = ALLdata.EM_AmpPhase.BeamPointingAngle{iDatagrams(iD)}(idx_beams)/100;
                fData.AP_BP_StartRangeSampleNumber(iBeams,iP) = round(ALLdata.EM_AmpPhase.StartRangeSampleNumber{iDatagrams(iD)}(idx_beams)./dr_sub);
                fData.AP_BP_NumberOfSamples(iBeams,iP)        = round(ALLdata.EM_AmpPhase.NumberOfSamples{iDatagrams(iD)}(idx_beams)./dr_sub);
                fData.AP_BP_DetectedRangeInSamples(iBeams,iP) = round(ALLdata.EM_AmpPhase.DetectedRangeInSamples{iDatagrams(iD)}(idx_beams)./dr_sub);
                fData.AP_BP_TransmitSectorNumber(iBeams,iP)   = ALLdata.EM_AmpPhase.TransmitSectorNumber2{iDatagrams(iD)}(idx_beams);
                fData.AP_BP_BeamNumber(iBeams,iP)             = ALLdata.EM_AmpPhase.BeamNumber{iDatagrams(iD)}(idx_beams);
                
                % and then, in each beam...
                for iB = 1:numel(iBeams)
                    
                    % get actual number of samples in that beam
                    nSamp = ALLdata.EM_AmpPhase.NumberOfSamples{iDatagrams(iD)}(idx_beams(iB));
                    
                    % number of samples we're going to record:
                    nSamp_sub = ceil(nSamp/dr_sub);
                    
                    % get the data:
                    if nSamp_sub > 0
                        
                        % get to the start of amplitude data
                        pos = ALLdata.EM_AmpPhase.SamplePhaseAmplitudePosition{iDatagrams(iD)}(idx_beams(iB));
                        fseek(fid_all,pos,'bof');
                        
                        % read amplitude data
                        tmp = fread(fid_all,nSamp_sub,'uint16',2); % XXX1 it's missing dr_sub
                        
                        % transform amplitude data
                        SB2_temp((1:(nSamp_sub)),iBeams(iB)) = int16(20*log10(single(tmp)*0.0001)*200); % what is this transformation? XXX2
                        
                        % get to the start of phase data
                        pos = pos+2;
                        fseek(fid_all,pos,'bof');
                        
                        % read phase data
                        tmp = fread(fid_all,nSamp_sub,'int16',2);  % XXX1 it's missing dr_sub
                        
                        % transform phase data
                        Ph_temp((1:(nSamp_sub)),iBeams(iB)) = int16(-0.0001*single(tmp)*30/pi*180); % what is this transformation? XXX2
                        
                    end
                end
            end
            
            % finished reading this ping's WC data. Store the data in the
            % appropriate binary file, at the appropriate ping, through the
            % memory mapping
            fData.AP_SBP_SampleAmplitudes{iG}.Data.val(:,:,iP-ping_group_start(iG)+1) = SB2_temp;
            fData.AP_SBP_SamplePhase{iG}.Data.val(:,:,iP-ping_group_start(iG)+1)      = Ph_temp;
            
            % debug graph
            if disp_wc
                imagesc(ax_mag,single(SB2_temp)/200);
                hold(ax_mag,'on');plot(ax_mag,fData.AP_BP_DetectedRangeInSamples(:,iP));
                hold(ax_mag,'off');
                caxis(ax_mag,[-100 -20]);
                imagesc(ax_phase,single(Ph_temp)/30);
                hold(ax_phase,'on');plot(ax_phase,fData.AP_BP_DetectedRangeInSamples(:,iP));
                hold(ax_phase,'off');
                drawnow;
            end
            
        end
        
        % close the original raw file
        fclose(fid_all);
        
    end
    
end
