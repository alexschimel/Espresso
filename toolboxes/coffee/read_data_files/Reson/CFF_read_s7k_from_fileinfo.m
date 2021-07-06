%% CFF_read_s7k_from_fileinfo.m
%
% Reads contents of one Kongsberg EM series binary .s7k or .wcd data file,
% using S7Kfileinfo to indicate which datagrams to be parsed.
%
%% Help
%
% *USE*
%
% S7Kdata = CFF_read_s7k_from_fileinfo(S7Kfilename, S7Kfileinfo) reads s7k
% datagrams in S7Kfilename for which S7Kfileinfo.parsed equals 1, and store
% them in S7Kdata.
%
% *INPUT VARIABLES*
%
% * |S7Kfilename|: Required. String filename to parse (extension in .s7k or
% .wcd).
% * |S7Kfileinfo|: structure containing information about datagrams in
% S7Kfilename, with fields:
%     * |S7Kfilename|: input file name
%     * |filesize|: file size in bytes
%     * |datagsizeformat|: endianness of the datagram size field 'b' or 'l'
%     * |datagramsformat|: endianness of the datagrams 'b' or 'l'
%     * |datagNumberInFile|: number of datagram in file
%     * |datagPositionInFile|: position of beginning of datagram in file
%     * |datagTypeNumber|: for each datagram, SIMRAD datagram type in
%     decimal
%     * |datagTypeText|: for each datagram, SIMRAD datagram type
%     description
%     * |parsed|: 0 for each datagram at this stage. To be later turned to
%     1 for parsing
%     * |counter|: the counter of this type of datagram in the file (ie
%     first datagram of that type is 1 and last datagram is the total
%     number of datagrams of that type)
%     * |number|: the number/counter found in the datagram (usually
%     different to counter)
%     * |size|: for each datagram, datagram size in bytes
%     * |syncCounter|: for each datagram, the number of bytes founds
%     between this datagram and the previous one (any number different than
%     zero indicates a sync error)
%     * |emNumber|: EM Model number (eg 2045 for EM2040c)
%     * |date|: datagram date in YYYMMDD
%     * |timeSinceMidnightInMilliseconds|: time since midnight in msecs
%
% *OUTPUT VARIABLES*
%
% * |S7Kdata|: structure containing the data. Each field corresponds a
% different type of datagram. The field |S7Kdata.info| contains a copy of
% S7Kfileinfo described above.
%
% *DEVELOPMENT NOTES*
%
% * PU Status output datagram structure seems different to the datagram
% manual description. Find the good description.#edit 21aug2013: updated to
% Rev Q. Need to be checked though.
% * The parsing code for some datagrams still need to be coded. To update.
%
% *NEW FEATURES*
%
% * 2018-10-11: updated header before adding to Coffee v3
% * 2018: added amplitude and phase datagram
% * 2017-06-29: header cleaned up. Changed S7Kfile for S7Kdata internally
% for consistency with other functions
% * 2015-09-30: first version taking from last version of
% convert_s7k_to_mat
%
% *EXAMPLE*
%
% S7Kfilename = '.\data\EM2040c\0001_20140213_052736_Yolla.s7k';
% info = CFF_s7k_file_info(S7Kfilename);
% info.parsed(:)=1; % to save all the datagrams
% S7Kdata = CFF_read_s7k_from_fileinfo(S7Kfilename, info);
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Alexandre Schimel, Waikato University, Deakin University, NIWA.

%% Function
function S7Kdata = CFF_read_s7k_from_fileinfo(S7Kfilename, S7Kfileinfo,varargin)


%% inputparser
p = inputParser;

% S7Kfilename to parse as only required argument. Test for file existence and
% extension.
argName = 'S7Kfilename';
argCheck = @(x) exist(x,'file') && any(strcmp(CFF_file_extension(x),{'.s7k','.S7K'}));
addRequired(p,argName,argCheck);

argName = 'S7Kfileinfo';
argCheck = @isstruct;
addRequired(p,argName,argCheck);

argName = 'OutputFields';
argCheck = @iscell;
addParameter(p,argName,{},argCheck);

% now parse inputs
parse(p,S7Kfilename,S7Kfileinfo,varargin{:});

% and get results
S7Kfilename = p.Results.S7Kfilename;
S7Kfileinfo = p.Results.S7Kfileinfo;


%% Pre-reading

% info
filesize        = S7Kfileinfo.filesize;
datagsizeformat = S7Kfileinfo.datagsizeformat;
datagramsformat = S7Kfileinfo.datagramsformat;

% store
S7Kdata.S7Kfilename     = S7Kfilename;
S7Kdata.datagramsformat = datagramsformat;

% Open file
[fid,~] = fopen(S7Kfilename, 'r',datagramsformat);

% Parse only datagrams indicated in S7Kfileinfo
datagToParse = find(S7Kfileinfo.parsed==1);

tx_pulse_env_id = {{'Tapered rectangular' 'Tukey' 'Hamming' 'Han' 'Rectangular'};{0 1 2 3 4}};
tx_pulse_modes  = {{'Single ping' 'Multi-ping 2' 'Multi-ping 3' 'Multi-ping 4'};{1 2 3 4}};
proj_beam_types = {{'Rectangular' 'Chebychev' 'Gauss'};{0 1 2}};
rx_beam_win     = {{'Chebychev' 'Kaiser'};{0 1}};
height_source   = {{'None' 'RTK' 'Tide'};{0  1 2}};

%% Reading datagrams
for iDatag = datagToParse'
    
    % A full s7k record is organized as a sequence of:
    % * DRF - Data Record Frame (64 bytes, at least for protocol version 5)
    % * RTH - Record Type Header (variable size)
    % * RD - Record Data (optional, variable size)
    % * OD - Optional Data (optional, variable size)
    % * CS - Checksum (optional, 4 bytes)
    
    % DRF info was already read so get relevant parameters in fileinfo
    pif_recordstart      = S7Kfileinfo.recordStartPositionInFile(iDatag);
    recordTypeIdentifier = S7Kfileinfo.recordTypeIdentifier(iDatag);
    DRF_size             = S7Kfileinfo.DRF_size(iDatag);
    RTHandRD_size        = S7Kfileinfo.RTHandRD_size(iDatag);
    OD_size              = S7Kfileinfo.OD_size(iDatag);
    CS_size              = S7Kfileinfo.CS_size(iDatag);
    OD_offset            = S7Kfileinfo.OD_offset(iDatag);
    
    % Go directly to the start of RTH
    pif_current = ftell(fid);
    fread(fid, pif_recordstart - pif_current + DRF_size);
    
    % reset the parsed switch
    parsed = 0;
    
    switch recordTypeIdentifier
        
        case 1003
            %% 1003 – Position
            fieldname = 'R1003_Position';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            try i1003 = i1003+1; catch, i1003 = 1; end
            icurr_field = i1003;
            
            S7Kdata.R1003_Position.Datum_id(i1003) = fread(fid,1,'uint32');
            S7Kdata.R1003_Position.Latency(i1003)  = fread(fid,1,'float32');
            
            if S7Kdata.R1003_Position.Datum_id(i1003)==0
                S7Kdata.R1003_Position.Latitude(i1003)  = fread(fid,1,'float64')/pi*180; % in radians if latitude (now degrees), or in meters if northing
                S7Kdata.R1003_Position.Longitude(i1003) = fread(fid,1,'float64')/pi*180; % in radians if longitude (now degrees), or in meters if easting
            else
                S7Kdata.R1003_Position.LatitudeRadOrNorthing(i1003) = fread(fid,1,'float64');
                S7Kdata.R1003_Position.LongitudeRadOrEasting(i1003) = fread(fid,1,'float64');
            end
            
            S7Kdata.R1003_Position.Height(i1003)             = fread(fid,1,'float64'); % in m
            S7Kdata.R1003_Position.PositionTypeFlag(i1003)   = fread(fid,1,'uint8');
            S7Kdata.R1003_Position.UTMZone(i1003)            = fread(fid,1,'uint8');
            S7Kdata.R1003_Position.QualityFlag(i1003)        = fread(fid,1,'uint8');
            S7Kdata.R1003_Position.PositioningMethod(i1003)  = fread(fid,1,'uint8');
            S7Kdata.R1003_Position.NumberOfSatellites(i1003) = fread(fid,1,'uint8');
            
            parsed = 1;
            
        case 1012
            %% 1012 – Roll Pitch Heave
            fieldname = 'R1012_RollPitchHeave';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            try i1012 = i1012+1; catch, i1012 = 1; end
            icurr_field = i1012;
            
            S7Kdata.R1012_RollPitchHeave.Roll(i1012)  = fread(fid,1,'float32');
            S7Kdata.R1012_RollPitchHeave.Pitch(i1012) = fread(fid,1,'float32');
            S7Kdata.R1012_RollPitchHeave.Heave(i1012) = fread(fid,1,'float32');
            
            parsed = 1;
            
        case 1015
            %% 1015 – Navigation
            fieldname = 'R1015_Navigation';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            try i1015 = i1015+1; catch, i1015 = 1; end
            icurr_field = i1015;
            
            S7Kdata.R1015_Navigation.VerticalReference(i1015)          = fread(fid,1,'uint8');
            S7Kdata.R1015_Navigation.Latitude(i1015)                   = fread(fid,1,'float64')/pi*180; % originally in rad, now in deg
            S7Kdata.R1015_Navigation.Longitude(i1015)                  = fread(fid,1,'float64')/pi*180; % originally in rad, now in deg
            S7Kdata.R1015_Navigation.HorizontalPositionAccuracy(i1015) = fread(fid,1,'float32');
            S7Kdata.R1015_Navigation.VesselHeight(i1015)               = fread(fid,1,'float32');
            S7Kdata.R1015_Navigation.HeightAccuracy(i1015)             = fread(fid,1,'float32'); % in m
            S7Kdata.R1015_Navigation.SpeedOverGround(i1015)            = fread(fid,1,'float32'); % in m/s
            S7Kdata.R1015_Navigation.CourseOverGround(i1015)           = fread(fid,1,'float32'); % in rad
            S7Kdata.R1015_Navigation.Heading(i1015)                    = fread(fid,1,'float32')/pi*180; % originally in rad, now in deg
            
            parsed = 1;
            
        case 7000
            %% 7000 – 7k Sonar Settings
            fieldname = 'R7000_SonarSettings';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            try i7000 = i7000+1; catch, i7000 = 1; end
            icurr_field = i7000;
            
            S7Kdata.R7000_SonarSettings.SonarID(i7000)           = fread(fid,1,'uint64');
            S7Kdata.R7000_SonarSettings.PingNumber(i7000)        = fread(fid,1,'uint32');
            S7Kdata.R7000_SonarSettings.MultiPingSequence(i7000) = fread(fid,1,'uint16');
            S7Kdata.R7000_SonarSettings.Frequency(i7000)         = fread(fid,1,'float32');
            S7Kdata.R7000_SonarSettings.SampleRate(i7000)        = fread(fid,1,'float32');
            S7Kdata.R7000_SonarSettings.ReceiverBandwidth(i7000) = fread(fid,1,'float32');
            S7Kdata.R7000_SonarSettings.TxPulseWidth(i7000)      = fread(fid,1,'float32');
            S7Kdata.R7000_SonarSettings.TXPulseIdentifier(i7000) = fread(fid,1,'uint32'); %0=CW, 1=FM
            
            t_temp = fread(fid,1,'uint32');
            S7Kdata.R7000_SonarSettings.TXPulseEnvelopeIdentifier{i7000} = get_param_val(tx_pulse_env_id,t_temp); % 0=Tapered Rect, 1=Tukey, 2= Hamming, 3=Han, 4= Rectangular
            
            S7Kdata.R7000_SonarSettings.TXPulseEnvelopeParameter(i7000)  = fread(fid,1,'float32');
            
            t_temp = fread(fid,1,'uint16');
            S7Kdata.R7000_SonarSettings.TXPulseMode{i7000} = get_param_val(tx_pulse_modes,t_temp); % 1=Single Ping, 2= Multi-ping 2, 3=Multi-ping 3, 4= Multi-ping 4
            
            S7Kdata.R7000_SonarSettings.TXPulseReserved(i7000)                         = fread(fid,1,'uint16');
            S7Kdata.R7000_SonarSettings.MaxPingRate(i7000)                             = fread(fid,1,'float32'); % in pings per seconds
            S7Kdata.R7000_SonarSettings.PingPeriod(i7000)                              = fread(fid,1,'float32'); % in pings per seconds
            S7Kdata.R7000_SonarSettings.RangeSelection(i7000)                          = fread(fid,1,'float32');
            S7Kdata.R7000_SonarSettings.PowerSelection(i7000)                          = fread(fid,1,'float32');
            S7Kdata.R7000_SonarSettings.GainSelection(i7000)                           = fread(fid,1,'float32');
            S7Kdata.R7000_SonarSettings.ControlFlags(i7000)                            = fread(fid,1,'uint32');
            S7Kdata.R7000_SonarSettings.ProjectIdentifier(i7000)                       = fread(fid,1,'uint32');
            S7Kdata.R7000_SonarSettings.ProjectorBeamSteeringAngleVerticalRad(i7000)   = fread(fid,1,'float32');
            S7Kdata.R7000_SonarSettings.ProjectorBeamSteeringAngleHorizontalRad(i7000) = fread(fid,1,'float32');
            S7Kdata.R7000_SonarSettings.ProjectorBeam3dBWidthVerticalRad(i7000)        = fread(fid,1,'float32');
            S7Kdata.R7000_SonarSettings.ProjectorBeam3dBWidthHorizontalRad(i7000)      = fread(fid,1,'float32');
            S7Kdata.R7000_SonarSettings.ProjectorBeamFocalPoint(i7000)                 = fread(fid,1,'float32');
            
            t_temp = fread(fid,1,'uint32');
            S7Kdata.R7000_SonarSettings.ProjectorBeamWeightingWindowType{i7000} = get_param_val(proj_beam_types,t_temp);
            
            S7Kdata.R7000_SonarSettings.ProjectorBeamWeightingWindowParameter(i7000) = fread(fid,1,'float32');
            S7Kdata.R7000_SonarSettings.TransmitFlags(i7000)                         = fread(fid,1,'uint32');
            S7Kdata.R7000_SonarSettings.HydrophoneIdentifier(i7000)                  = fread(fid,1,'uint32');
            
            t_temp = fread(fid,1,'uint32');
            S7Kdata.R7000_SonarSettings.ReceiveBeamWeightingWindowType{i7000} = get_param_val(rx_beam_win,t_temp);
            
            S7Kdata.R7000_SonarSettings.ReceiveBeamWeightingWindowParameter = fread(fid,1,'float32');
            S7Kdata.R7000_SonarSettings.ReceiveFlags(i7000)                 = fread(fid,1,'uint32');
            S7Kdata.R7000_SonarSettings.ReceiveBeamWidthRad(i7000)          = fread(fid,1,'float32');
            S7Kdata.R7000_SonarSettings.BottomDetectFilter{i7000}           = fread(fid,4,'float32'); % [min_range max_range min_depth max_depth]
            S7Kdata.R7000_SonarSettings.Absorption(i7000)                   = fread(fid,1,'float32');
            S7Kdata.R7000_SonarSettings.SoundVelocity(i7000)                = fread(fid,1,'float32');
            S7Kdata.R7000_SonarSettings.Spreading(i7000)                    = fread(fid,1,'float32');
            S7Kdata.R7000_SonarSettings.Reserved(i7000)                     = fread(fid,1,'uint16');
            
            parsed = 1;
            
        case 7001
            %% 7001 – 7k Configuration
            fieldname = 'R7001_7kConfiguration';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            try i7001=i7001+1; catch, i7001=1; end
            icurr_field = i7001;
            
            S7Kdata.R7001_7kConfiguration.SonarId(i7001) = fread(fid,1,'uint64');
            
            N_info = fread(fid,1,'uint32');
            S7Kdata.R7001_7kConfiguration.N(i7001) = N_info;
            
            S7Kdata.R7001_7kConfiguration.DeviceID{i7001}            = nan(1,N_info);
            S7Kdata.R7001_7kConfiguration.DeviceDescription{i7001}   = cell(1,N_info);
            S7Kdata.R7001_7kConfiguration.DeviceAlphaDataCard{i7001} = nan(1,N_info);
            S7Kdata.R7001_7kConfiguration.DeviceSerialNumber{i7001}  = nan(1,N_info);
            S7Kdata.R7001_7kConfiguration.DeviceInfo{i7001}          = cell(1,N_info);
            
            for i_inf = 1:N_info
                
                S7Kdata.R7001_7kConfiguration.DeviceID{i7001}(i_inf)            = fread(fid,1,'uint32');
                S7Kdata.R7001_7kConfiguration.DeviceDescription{i7001}{i_inf}   = fread(fid,60,'*char')';
                S7Kdata.R7001_7kConfiguration.DeviceAlphaDataCard{i7001}(i_inf) = fread(fid,1,'uint32');
                S7Kdata.R7001_7kConfiguration.DeviceSerialNumber{i7001}(i_inf)  = fread(fid,1,'uint32');
                
                l_tmp = fread(fid,1,'uint32');
                S7Kdata.R7001_7kConfiguration.DeviceInfo{i7001}{i_inf} = fread(fid,l_tmp,'*char')';
                
            end
            
            parsed = 1;
            
        case 7002
            %% 7002 – 7k Match Filter
            fieldname = 'R7001_7kMatchFilter';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            try i7002 = i7002+1; catch, i7002 = 1; end
            icurr_field = i7002;
            
            parsed = 1;
            
        case 7004
            %% 7004 – 7k Beam Geometry
            fieldname = 'R7004_7kBeamGeometry';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            try i7004 = i7004+1; catch, i7004 = 1; end
            icurr_field = i7004;
            
            S7Kdata.R7004_7kBeamGeometry.SonarID(i7004) = fread(fid,1,'uint64');
            S7Kdata.R7004_7kBeamGeometry.N(i7004) = fread(fid,1,'uint32');
            
            N = S7Kdata.R7004_7kBeamGeometry.N(i7004);
            S7Kdata.R7004_7kBeamGeometry.BeamVerticalDirectionAngleRad{i7004}   = fread(fid,N,'float32');
            S7Kdata.R7004_7kBeamGeometry.BeamHorizontalDirectionAngleRad{i7004} = fread(fid,N,'float32');
            S7Kdata.R7004_7kBeamGeometry.BeamWidth3dBAlongTrackRad{i7004}       = fread(fid,N,'float32');
            S7Kdata.R7004_7kBeamGeometry.BeamWidth3dBAcrossTrackRad{i7004}      = fread(fid,N,'float32');
            
            parsed = 1;
            
        case 7007
            %% 7007 – 7k Side Scan Data
            fieldname = 'R7004_7kSideScanData';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            try i7007 = i7007+1; catch, i7007 = 1; end
            icurr_field = i7007;
            
            parsed = 1;
            
        case 7012
            %% 7012 – 7k Ping Motion Data
            fieldname = 'R7012_7kPingMotionData';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            try i7012 = i7012+1; catch, i7012 = 1; end
            icurr_field = i7012;
            
            S7Kdata.R7012_7kPingMotionData.SonarID(i7012)           = fread(fid,1,'uint64');
            S7Kdata.R7012_7kPingMotionData.PingNumber(i7012)        = fread(fid,1,'uint32');
            S7Kdata.R7012_7kPingMotionData.PingNumber(i7012)        = fread(fid,1,'uint32');
            S7Kdata.R7012_7kPingMotionData.MultiPingSequence(i7012) = fread(fid,1,'uint16');
            S7Kdata.R7012_7kPingMotionData.NumberOfSamples(i7012)   = fread(fid,1,'uint32');
            S7Kdata.R7012_7kPingMotionData.Flags(i7012)             = fread(fid,1,'uint16');
            S7Kdata.R7012_7kPingMotionData.ErrorFlags(i7012)        = fread(fid,1,'uint32');
            S7Kdata.R7012_7kPingMotionData.SamplingRate(i7012)      = fread(fid,1,'float32');
            S7Kdata.R7012_7kPingMotionData.Pitch(i7012)             = fread(fid,1,'float32');
            
            N = S7Kdata.R7012_7kPingMotionData.NumberOfSamples(i7012);
            
            % read and parse flags
            flags = CFF_get_R7012_flags(S7Kdata.R7012_7kPingMotionData.Flags(i7012));
            if flags.pitchStab > 0
                S7Kdata.R7012_7kPingMotionData.Pitch{i7012}   = fread(fid,N,'float32');
            end
            if flags.rollStab > 0
                S7Kdata.R7012_7kPingMotionData.Roll{i7012}    = fread(fid,N,'float32');
            end
            if flags.yawStab > 0
                S7Kdata.R7012_7kPingMotionData.Heading{i7012} = fread(fid,N,'float32');
            end
            if flags.heaveStab > 0
                S7Kdata.R7012_7kPingMotionData.Heave{i7012}   = fread(fid,N,'float32');
            end
            
            parsed = 1;
            
        case 7018
            %% 7018 – 7k Beamformed Data
            fieldname = 'R7018_7kBeamformedData';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            try i7018 = i7018+1; catch, i7018 = 1; end
            icurr_field = i7018;
            
            S7Kdata.R7018_7kBeamformedData.SonarId(i7018)            = fread(fid,1,'uint64');
            S7Kdata.R7018_7kBeamformedData.PingNumber(i7018)         = fread(fid,1,'uint32');
            S7Kdata.R7018_7kBeamformedData.MultipingSequence(i7018)  = fread(fid,1,'uint16');
            S7Kdata.R7018_7kBeamformedData.N(i7018)                  = fread(fid,1,'uint16');
            S7Kdata.R7018_7kBeamformedData.S(i7018)                  = fread(fid,1,'uint32');
            S7Kdata.R7018_7kBeamformedData.Reserved{i7018}           = fread(fid,8,'uint32');
            S7Kdata.R7018_7kBeamformedData.BeamformedDataPos(i7018)  = ftell(fid);
            
            parsed = 1;
            
        case 7021
            %% 7021 – 7k Built-In Test Environment Data
            fieldname = 'R7021_7kBuiltInTestEnvData';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            try i7021 = i7021+1; catch, i7021 = 1; end
            icurr_field = i7021;
            
            parsed = 1;
            
        case 7022
            %% 7022 – 7kCenter Version
            fieldname = 'R7022_7kCenterVersion';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            try i7022 = i7022+1; catch, i7022 = 1; end
            icurr_field = i7022;
             
            parsed = 1;
            
        case 7027
            %% 7027 – 7k RAW Detection Data
            fieldname = 'R7027_RAWdetection';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            try i7027 = i7027+1; catch, i7027 = 1; end
            icurr_field = i7027;
            
            % parsing RTH
            S7Kdata.R7027_RAWdetection.SonarId(i7027)            = fread(fid,1,'uint64');
            S7Kdata.R7027_RAWdetection.PingNumber(i7027)         = fread(fid,1,'uint32');
            S7Kdata.R7027_RAWdetection.MultipingSequence(i7027)  = fread(fid,1,'uint16');
            S7Kdata.R7027_RAWdetection.N(i7027)                  = fread(fid,1,'uint32');
            S7Kdata.R7027_RAWdetection.DataFieldSize(i7027)      = fread(fid,1,'uint32');
            S7Kdata.R7027_RAWdetection.DetectionAlgorithm(i7027) = fread(fid,1,'uint8');
            S7Kdata.R7027_RAWdetection.Flags(i7027)              = fread(fid,1,'uint32');
            S7Kdata.R7027_RAWdetection.SamplingRate(i7027)       = fread(fid,1,'float32');
            S7Kdata.R7027_RAWdetection.TxAngle(i7027)            = fread(fid,1,'float32');
            S7Kdata.R7027_RAWdetection.AppliedRoll(i7027)        = fread(fid,1,'float32');
            S7Kdata.R7027_RAWdetection.Reserved{i7027}           = fread(fid,15,'uint32');
            
            S7Kdata.R7027_RAWdetection.TimeSinceMidnightInMilliseconds(i7027)  = S7Kfileinfo.timeSinceMidnightInMilliseconds(iDatag);
            
            % parsing RD
            % repeat cycle: N entries of S bytes
            temp = ftell(fid);
            N = S7Kdata.R7027_RAWdetection.N(i7027);
            S = S7Kdata.R7027_RAWdetection.DataFieldSize(i7027);
            S7Kdata.R7027_RAWdetection.BeamDescriptor{i7027} = fread(fid,N,'uint16',S-2);
            fseek(fid,temp+2,'bof'); % to next data type
            S7Kdata.R7027_RAWdetection.DetectionPoint{i7027} = fread(fid,N,'float32',S-4);
            fseek(fid,temp+6,'bof'); % to next data type
            S7Kdata.R7027_RAWdetection.RxAngle{i7027}        = fread(fid,N,'float32',S-4);
            fseek(fid,temp+10,'bof'); % to next data type
            S7Kdata.R7027_RAWdetection.Flags2{i7027}         = fread(fid,N,'uint32',S-4);
            fseek(fid,temp+14,'bof'); % to next data type
            S7Kdata.R7027_RAWdetection.Quality{i7027}        = fread(fid,N,'uint32',S-4);
            fseek(fid,temp+18,'bof'); % to next data type
            S7Kdata.R7027_RAWdetection.Uncertainty{i7027}    = fread(fid,N,'float32',S-4);
            fseek(fid,temp+22,'bof'); % to next data type
            S7Kdata.R7027_RAWdetection.SignalStrength{i7027} = fread(fid,N,'float32',S-4);
            fseek(fid,temp+26,'bof'); % to next data type
            S7Kdata.R7027_RAWdetection.MinLimit{i7027}       = fread(fid,N,'float32',S-4);
            fseek(fid,temp+30,'bof'); % to next data type
            S7Kdata.R7027_RAWdetection.MaxLimit{i7027}       = fread(fid,N,'float32',S-4);
            fseek(fid,4-S,'cof'); % we need to come back after last jump
            
            if OD_size~=0
                tmp_pos = ftell(fid);
                
                % parsing OD
                fread(fid,OD_offset-(tmp_pos-pif_recordstart),'uint8');
                
                S7Kdata.R7027_RAWdetection.Frequency(i7027) = fread(fid,1,'float32');
                S7Kdata.R7027_RAWdetection.Latitude(i7027)  = fread(fid,1,'float64')/pi*180;
                S7Kdata.R7027_RAWdetection.Longitude(i7027) = fread(fid,1,'float64')/pi*180;
                S7Kdata.R7027_RAWdetection.Heading(i7027)   = fread(fid,1,'float32')/pi*180;
                
                t_temp = fread(fid,1,'uint8');
                S7Kdata.R7027_RAWdetection.HeightSource{i7027} = get_param_val(height_source,t_temp);
                
                S7Kdata.R7027_RAWdetection.Tide(i7027)         = fread(fid,1,'float32');
                S7Kdata.R7027_RAWdetection.Roll(i7027)         = fread(fid,1,'float32')/pi*180;
                S7Kdata.R7027_RAWdetection.Pitch(i7027)        = fread(fid,1,'float32')/pi*180;
                S7Kdata.R7027_RAWdetection.Heave(i7027)        = fread(fid,1,'float32');
                S7Kdata.R7027_RAWdetection.VehicleDepth(i7027) = fread(fid,1,'float32');
                
                tmp_beam_data = fread(fid,[5 N],'float32');
                S7Kdata.R7027_RAWdetection.Depth{i7027}               = tmp_beam_data(1,:);
                S7Kdata.R7027_RAWdetection.AlongTrackDistance{i7027}  = tmp_beam_data(2,:);
                S7Kdata.R7027_RAWdetection.AcrossTrackDistance{i7027} = tmp_beam_data(3,:);
                S7Kdata.R7027_RAWdetection.PointingAngle{i7027}       = tmp_beam_data(4,:);
                S7Kdata.R7027_RAWdetection.AzimuthAngle{i7027}        = tmp_beam_data(5,:);
                
            else
                
                S7Kdata.R7027_RAWdetection.Frequency(i7027)           = nan;
                S7Kdata.R7027_RAWdetection.Latitude(i7027)            = nan;
                S7Kdata.R7027_RAWdetection.Longitude(i7027)           = nan;
                S7Kdata.R7027_RAWdetection.Heading(i7027)             = nan;
                S7Kdata.R7027_RAWdetection.HeightSource{i7027}        = '';
                S7Kdata.R7027_RAWdetection.Tide(i7027)                = nan;
                S7Kdata.R7027_RAWdetection.Roll(i7027)                = nan;
                S7Kdata.R7027_RAWdetection.Pitch(i7027)               = nan;
                S7Kdata.R7027_RAWdetection.Heave(i7027)               = nan;
                S7Kdata.R7027_RAWdetection.VehicleDepth(i7027)        = nan;
                S7Kdata.R7027_RAWdetection.Depth{i7027}               = nan(1,N);
                S7Kdata.R7027_RAWdetection.AlongTrackDistance{i7027}  = nan(1,N);
                S7Kdata.R7027_RAWdetection.AcrossTrackDistance{i7027} = nan(1,N);
                S7Kdata.R7027_RAWdetection.PointingAngle{i7027}       = nan(1,N);
                S7Kdata.R7027_RAWdetection.AzimuthAngle{i7027}        = nan(1,N);
                
            end
            
            % parsing CS
            if CS_size == 4
                S7Kdata.R7027_RAWdetection.Checksum(i7027) = fread(fid,1,'uint32');
            elseif CS_size == 0
                S7Kdata.R7027_RAWdetection.Checksum(i7027) = NaN;
            else
                warning('%s: unexpected CS size',fieldname);
            end
            % check data integrity with checksum... TO DO XXX
            
            % confirm parsing
            parsed = 1;
            
        case 7028
            %% 7028 – 7k Snippet Data
            fieldname = 'R7028_SnippetData';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            try i7001 = i7001+1; catch, i7001 = 1; end
            icurr_field = i7001;
            
            % confirm parsing
            parsed = 1;
            
        case 7042
            %% 7042 Compressed Watercolumn Data
            fieldname = 'R7042_CompressedWaterColumn';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            
            % counter for this type of datagram
            try i7042=i7042+1; catch, i7042=1; end
            icurr_field = i7042;
            
            % ----- IMPORTANT NOTE ----------------------------------------
            % This datagram's data is too to be stored in memory. Instead,
            % we record the metadata and the position-in-file location of
            % the data, which be extracted and stored in binary format at
            % the next stage of data conversion. 
            % -------------------------------------------------------------
            
            % parsing RTH
            S7Kdata.R7042_CompressedWaterColumn.SonarId(i7042)           = fread(fid,1,'uint64');
            S7Kdata.R7042_CompressedWaterColumn.PingNumber(i7042)        = fread(fid,1,'uint32');
            S7Kdata.R7042_CompressedWaterColumn.MultiPingSequence(i7042) = fread(fid,1,'uint16');
            S7Kdata.R7042_CompressedWaterColumn.Beams(i7042)             = fread(fid,1,'uint16');
            S7Kdata.R7042_CompressedWaterColumn.Samples(i7042)           = fread(fid,1,'uint32');
            S7Kdata.R7042_CompressedWaterColumn.CompressedSamples(i7042) = fread(fid,1,'uint32');
            S7Kdata.R7042_CompressedWaterColumn.Flags(i7042)             = fread(fid,1,'uint32');
            S7Kdata.R7042_CompressedWaterColumn.FirstSample(i7042)       = fread(fid,1,'uint32');
            S7Kdata.R7042_CompressedWaterColumn.SampleRate(i7042)        = fread(fid,1,'float32');
            S7Kdata.R7042_CompressedWaterColumn.CompressionFactor(i7042) = fread(fid,1,'float32');
            S7Kdata.R7042_CompressedWaterColumn.Reserved(i7042)          = fread(fid,1,'uint32');
            
            % flag processing
            [flags,sample_size,~,~] = CFF_get_R7042_flags(S7Kdata.R7042_CompressedWaterColumn.Flags(i7042));
            if sample_size == 0
                warning('%s: WC flag combination not taken into account',fieldname);
                fields_wc = fieldnames(S7Kdata.R7042_CompressedWaterColumn);
                
                % add blanks fields for those missing
                for ifi = 1:numel(fields_wc)
                    if numel(S7Kdata.R7042_CompressedWaterColumn.(fields_wc{ifi})) >= i7042
                        S7Kdata.R7042_CompressedWaterColumn.(fields_wc{ifi})(i7042) = [];
                    end
                end
                
                i7042 = i7042-1; % XXX if we do that, then we'll rewrite over the blank record we just entered??
                
                continue;
            end
            
            % parsing RD
            % repeat cycle: B entries of a possibly variable number of
            % bits. Reading everything first and using a for loop to parse
            % the data in it
            pos_2 = ftell(fid); % position at start of data
            RTH_size = 44;
            RD_size = RTHandRD_size - RTH_size;
            blocktmp = fread(fid,RD_size,'int8=>int8')'; % read all that data block
            
            wc_parsing_error = 0; % initialize flag
            
            % initialize outputs
            B = S7Kdata.R7042_CompressedWaterColumn.Beams(i7042);
            S7Kdata.R7042_CompressedWaterColumn.BeamNumber{i7042}                = nan(1,B);
            S7Kdata.R7042_CompressedWaterColumn.SegmentNumber{i7042}             = nan(1,B);
            S7Kdata.R7042_CompressedWaterColumn.NumberOfSamples{i7042}           = nan(1,B);
            S7Kdata.R7042_CompressedWaterColumn.SampleStartPositionInFile{i7042} = nan(1,B);
            
            Ns = zeros(1,B); % Number of samples in matrix form
            id  = zeros(1,B+1); % offset for start of each Nrx block
            % now parse the data
            if flags.segmentNumbersAvailable
                for jj = 1:B
                    try
                        S7Kdata.R7042_CompressedWaterColumn.BeamNumber{i7042}(jj)      = typecast(blocktmp(1+id(jj):2+id(jj)),'uint16');
                        S7Kdata.R7042_CompressedWaterColumn.SegmentNumber{i7042}(jj)   = typecast(blocktmp(3+id(jj)),'uint8');
                        S7Kdata.R7042_CompressedWaterColumn.NumberOfSamples{i7042}(jj) = typecast(blocktmp(4+id(jj):7+id(jj)),'uint32');
                        S7Kdata.R7042_CompressedWaterColumn.SampleStartPositionInFile{i7042}(jj) = pos_2 + id(jj) + 7;
                        Ns(jj) = S7Kdata.R7042_CompressedWaterColumn.NumberOfSamples{i7042}(jj);
                        id(jj) = 7*jj + sum(Ns)*sample_size;
                    catch
                        % if any issue in the recording, flag and exit the loop
                        S7Kdata.R7042_CompressedWaterColumn.NumberOfSamples{i7042}(jj) = 0;
                        Ns(jj) = 0;
                        wc_parsing_error = 1;
                        continue;
                    end
                end
            else
                % same process but without reading segment number
                for jj = 1:B
                    try
                        S7Kdata.R7042_CompressedWaterColumn.BeamNumber{i7042}(jj)      = typecast(blocktmp(1+id(jj):2+id(jj)),'uint16');
                        S7Kdata.R7042_CompressedWaterColumn.NumberOfSamples{i7042}(jj) = typecast(blocktmp(3+id(jj):6+id(jj)),'uint32');
                        S7Kdata.R7042_CompressedWaterColumn.SampleStartPositionInFile{i7042}(jj) = pos_2 + id(jj) + 6;
                        Ns(jj) = S7Kdata.R7042_CompressedWaterColumn.NumberOfSamples{i7042}(jj);
                        id(jj+1) = 6*jj + sum(Ns).*sample_size;
                    catch
                        % if any issue in the recording, flag and exit the loop
                        S7Kdata.R7042_CompressedWaterColumn.NumberOfSamples{i7042}(jj) = 0;
                        Ns(jj) = 0;
                        wc_parsing_error = 1;
                        continue;
                    end
                end
            end
            
            if wc_parsing_error == 0
                
                % HERE if data parsing all went well
                
                if OD_size~=0
                    tmp_pos=ftell(fid);
                    % parsing OD
                    fread(fid,OD_offset-(tmp_pos-pif_recordstart),'uint8');
                    
                    tmp_OD = fread(fid,OD_size,'uint8');
                else
                    tmp_OD = NaN;
                end
                
                % parsing CS
                if CS_size == 4
                    S7Kdata.R7042_CompressedWaterColumn.Checksum(i7042) = fread(fid,1,'uint32');
                elseif CS_size == 0
                    S7Kdata.R7042_CompressedWaterColumn.Checksum(i7042) = NaN;
                else
                    warning('%s: unexpected CS size',fieldname);
                end
                % check data integrity with checksum... TO DO XXX
                
                % confirm parsing
                parsed = 1;
                
            else
                % HERE if data parsing failed, add a blank datagram in
                % output
                warning('%s: error while parsing datagram',fieldname);
                % copy field names of previous entries
                fields_wc = fieldnames(S7Kdata.R7042_CompressedWaterColumn);
                
                % add blanks fields for those missing
                for ifi = 1:numel(fields_wc)
                    if numel(S7Kdata.R7042_CompressedWaterColumn.(fields_wc{ifi})) >= i7042
                        S7Kdata.R7042_CompressedWaterColumn.(fields_wc{ifi})(i7042) = [];
                    end
                end
                
                i7042 = i7042-1; % XXX if we do that, then we'll rewrite over the blank record we just entered??
                parsed = 0;
                
            end
            
            
        case 7200
            %% 7200 – 7k File Header'
            fieldname = 'R7200_FileHeader';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            % counter for this type of datagram
            try i7200 = i7200+1; catch, i7200 = 1; end
            icurr_field = i7200;
            
            % parsing RTH
            S7Kdata.R7200_FileHeader.FileIdentifier{i7200}                = fread(fid,2,'uint64'); % actually 128-bit unsigned integer but Matlab can't record that
            S7Kdata.R7200_FileHeader.VersionNumber(i7200)                 = fread(fid,1,'uint16');
            S7Kdata.R7200_FileHeader.Reserved(i7200)                      = fread(fid,1,'uint16');
            S7Kdata.R7200_FileHeader.SessionIdentifier{i7200}             = fread(fid,2,'uint64'); % actually 128-bit unsigned integer but Matlab can't record that
            S7Kdata.R7200_FileHeader.RecordDataSize(i7200)                = fread(fid,1,'uint32');
            S7Kdata.R7200_FileHeader.N(i7200)                             = fread(fid,1,'uint32');
            S7Kdata.R7200_FileHeader.RecordingName{i7200}                 = fread(fid,64,'uint8');
            S7Kdata.R7200_FileHeader.RecordingProgramVersionNumber{i7200} = fread(fid,16,'uint8');
            S7Kdata.R7200_FileHeader.UserDefinedName{i7200}               = fread(fid,64,'uint8');
            S7Kdata.R7200_FileHeader.Notes{i7200}                         = fread(fid,128,'uint8');
            
            % parsing RD
            % repeat cycle: N entries of 6 bytes
            temp = ftell(fid);
            N = S7Kdata.R7200_FileHeader.N(i7200);
            S7Kdata.R7200_FileHeader.DeviceIdentifier{i7200} = fread(fid,N,'uint32',6-4);
            fseek(fid,temp+4,'bof'); % to next data type
            S7Kdata.R7200_FileHeader.SystemEnumerator{i7200} = fread(fid,N,'uint16',6-2);
            fseek(fid,2-6,'cof'); % we need to come back after last jump
            
            if OD_size>= 12
                tmp_pos = ftell(fid);
                % parsing OD
                fread(fid,OD_offset-(tmp_pos-pif_recordstart),'uint8');
                
                fread(fid,1,'uint32');
                S7Kdata.R7200_FileHeader.Size(i7200)   = fread(fid,1,'uint32');
                S7Kdata.R7200_FileHeader.Offset(i7200) = fread(fid,1,'uint64');
            elseif OD_size == 0
                S7Kdata.R7200_FileHeader.Size(i7200)   = NaN;
                S7Kdata.R7200_FileHeader.Offset(i7200) = NaN;
            else
                warning('%s: unexpected OD size',fieldname);
            end
            
            % parsing CS
            if CS_size == 4
                S7Kdata.R7200_FileHeader.Checksum(i7200) = fread(fid,1,'uint32');
            elseif CS_size == 0
                S7Kdata.R7200_FileHeader.Checksum(i7200) = NaN;
            else
                warning('%s: unexpected CS size',fieldname);
            end
            % check data integrity with checksum... TO DO XXX
            
            % confirm parsing
            parsed = 1;
            
        case 7300
            %% 7300 – 7k File Catalog Record
            fieldname = 'R7200_FileCatalogRecord';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            % counter for this type of datagram
            try i7300 = i7300+1; catch, i7300 = 1; end
            icurr_field = i7300;
            
        case 7503
            %% 7503 – Remote Control Sonar Settings
            fieldname = 'R7503_FileCatalogRecord';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            % counter for this type of datagram
            try i7503 = i7503+1; catch, i7503 = 1; end
            icurr_field = i7503;
            
        case 7504
            %% 7504 – 7P Common System Settings
            fieldname = 'R7504_7pCommonSystemSettings';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            % counter for this type of datagram
            try i7504 = i7504+1; catch, i7504 = 1; end
            icurr_field = i7504;
            
        case 7610
            %% 7610 – 7k Sound Velocity
            fieldname = 'R7610_7kSoundVelocity';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            % counter for this type of datagram
            try i7610 = i7610+1; catch, i7610 = 1; end
            icurr_field = i7610;
            
        otherwise
            % datagTypeNumber is not recognized yet
            
    end
    
    % modify parsed status in info
    S7Kfileinfo.parsed(iDatag,1) = parsed;
    if parsed == 1
        S7Kdata.(fieldname).TimeSinceMidnightInMilliseconds(icurr_field)  = S7Kfileinfo.timeSinceMidnightInMilliseconds(iDatag);
        S7Kdata.(fieldname).Date(icurr_field)                             = str2double(S7Kfileinfo.date{iDatag});
    end
    
end


%% close fid
fclose(fid);


%% add info to parsed data
S7Kdata.info = S7Kfileinfo;

end

%% subfunction to read some parameters
function val = get_param_val(rx_beam_win,t_temp)

idx = [rx_beam_win{2}{:}] == double(t_temp);

if any(idx)
    val = rx_beam_win{1}{idx};
else
    val = '';
end

end
