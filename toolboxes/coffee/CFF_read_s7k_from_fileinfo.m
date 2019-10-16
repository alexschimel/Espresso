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

% MATfilename output as only optional argument.
argName = 'S7Kfileinfo';
argCheck = @isstruct;
addRequired(p,argName,argCheck);

% MATfilename output as only optional argument.
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

tx_pulse_env_id={{'Tapered rectangular' 'Tukey' 'Hamming' 'Han' 'Rectangular'};{0 1 2 3 4}};
tx_pulse_modes={{'Single ping' 'Multi-ping 2' 'Multi-ping 3' 'Multi-ping 4'};{1 2 3 4}};
proj_beam_types={{'Rectangular' 'Chebychev' 'Gauss'};{0 1 2}};
rx_beam_win={{'Chebychev' 'Kaiser'};{0 1}};
height_source={{'None' 'RTK' 'Tide'};{0  1 2}};

%% Reading datagrams
for iDatag = datagToParse'
    
    % A full s7k record is organized as a sequence of:
    % * DRF - Data Record Frame (64 bytes, at least for protocol version 5)
    % * RTH - Record Type Header (variable size)
    % * RD - Record Data (optional, variable size)
    % * OD - Optional Data (optional, variable size)
    % * CS - Checksum (optional, 4 bytes)
    
    % DRF info was already read so get relevant parameters in fileinfo
    pif_recordstart = S7Kfileinfo.recordStartPositionInFile(iDatag);
    recordTypeIdentifier = S7Kfileinfo.recordTypeIdentifier(iDatag);
    
    DRF_size      = S7Kfileinfo.DRF_size(iDatag);
    RTHandRD_size = S7Kfileinfo.RTHandRD_size(iDatag);
    OD_size       = S7Kfileinfo.OD_size(iDatag);
    CS_size       = S7Kfileinfo.CS_size(iDatag);
    OD_offset = S7Kfileinfo.OD_offset(iDatag);
    % Go directly to the start of RTH
    pif_current = ftell(fid);
    fread(fid, pif_recordstart - pif_current + DRF_size);
    
    % reset the parsed switch
    parsed = 0;
    
    switch recordTypeIdentifier
        case 1003
            %% 1003  Position TODO
            fieldname='R1003_Position';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            try i1003=i1003+1; catch, i1003=1; end
            icurr_field=i1003;
            
            S7Kdata.R1003_Position.Datum_id(i1003)  = fread(fid,1,'uint32');
            
        case 1012
            %% 1012  Roll Pitch Heave
            fieldname='R1012_RollPitchHeave';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            try i1012=i1012+1; catch, i1012=1; end
            icurr_field=i1012;
            
            S7Kdata.R1012_RollPitchHeave.Roll(i1012)  = fread(fid,1,'float32');
            S7Kdata.R1012_RollPitchHeave.Pitch(i1012) = fread(fid,1,'float32');
            S7Kdata.R1012_RollPitchHeave.Heave(i1012) = fread(fid,1,'float32');
            parsed = 1;
        case 1015
            %% 1015  Navigation
            fieldname='R1015_Navigation';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            try i1015=i1015+1; catch, i1015=1; end
            icurr_field=i1015;
            S7Kdata.R1015_Navigation.VerticalReference(i1015)=fread(fid,1,'uint8');
            S7Kdata.R1015_Navigation.Latitude(i1015)=fread(fid,1,'float64')/pi*180;
            S7Kdata.R1015_Navigation.Longitude(i1015)=fread(fid,1,'float64')/pi*180;
            S7Kdata.R1015_Navigation.HorizontalPositionAccuracy(i1015)=fread(fid,1,'float32');
            S7Kdata.R1015_Navigation.VesselHeight(i1015)=fread(fid,1,'float32');
            S7Kdata.R1015_Navigation.HeightAccuracy(i1015)=fread(fid,1,'float32');
            S7Kdata.R1015_Navigation.CourseOverGround(i1015)=fread(fid,1,'float32');
            S7Kdata.R1015_Navigation.Heading(i1015)=fread(fid,1,'float32');
            parsed = 1;
        case 7000
            %% 7000  7k Sonar Settings
            fieldname='R7000_SonarSettings';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            try i7000=i7000+1; catch, i7000=1; end
            icurr_field=i7000;
            
            S7Kdata.R7000_SonarSettings.SonarID(i7000)=fread(fid,1,'uint64');
            S7Kdata.R7000_SonarSettings.PingNumber(i7000)=fread(fid,1,'uint32');
            S7Kdata.R7000_SonarSettings.MultiPingSequence(i7000)=fread(fid,1,'uint16');
            S7Kdata.R7000_SonarSettings.Frequency(i7000)=fread(fid,1,'float32');
            S7Kdata.R7000_SonarSettings.SampleRate(i7000)=fread(fid,1,'float32');
            S7Kdata.R7000_SonarSettings.ReceiverBandwidth(i7000)=fread(fid,1,'float32');
            S7Kdata.R7000_SonarSettings.TxPulseWidth(i7000)=fread(fid,1,'float32');
            S7Kdata.R7000_SonarSettings.TXPulseIdentifier(i7000)=fread(fid,1,'uint32');%0=CW, 1=FM
            t_temp=fread(fid,1,'uint32');
            S7Kdata.R7000_SonarSettings.TXPulseEnvelopeIdentifier{i7000}=get_param_val(tx_pulse_env_id,t_temp);%0=Tapered Rect, 1=Tukey, 2= Hamming, 3=Han, 4= Rectangular
            S7Kdata.R7000_SonarSettings.TXPulseEnvelopeParameter(i7000)=fread(fid,1,'float32');
            t_temp=fread(fid,1,'uint16');
            S7Kdata.R7000_SonarSettings.TXPulseMode{i7000}=get_param_val(tx_pulse_modes,t_temp);%1=Single Ping, 2= Multi-ping 2, 3=Multi-ping 3, 4= Multi-ping 4
            S7Kdata.R7000_SonarSettings.TXPulseReserved(i7000)=fread(fid,1,'uint16');
            S7Kdata.R7000_SonarSettings.MaxPingRate(i7000)=fread(fid,1,'float32');%in pings per seconds
            S7Kdata.R7000_SonarSettings.RangeSelection(i7000)=fread(fid,1,'float32');
            S7Kdata.R7000_SonarSettings.GainSelection(i7000)=fread(fid,1,'float32');
            S7Kdata.R7000_SonarSettings.ControlFlags(i7000)=fread(fid,1,'uint32');
            S7Kdata.R7000_SonarSettings.ProjectIdentifier(i7000)=fread(fid,1,'uint32');
            S7Kdata.R7000_SonarSettings.ProjectorBeamSteeringAngleVerticalRad(i7000)=fread(fid,1,'float32');
            S7Kdata.R7000_SonarSettings.ProjectorBeamSteeringAngleHorizontalRad(i7000)=fread(fid,1,'float32');
            S7Kdata.R7000_SonarSettings.ProjectorBeam3dBWidthVerticalRad(i7000)=fread(fid,1,'float32');
            S7Kdata.R7000_SonarSettings.ProjectorBeam3dBWidthHorizontalRad(i7000)=fread(fid,1,'float32');
            S7Kdata.R7000_SonarSettings.ProjectorBeamFocalPoint(i7000)=fread(fid,1,'float32');
            t_temp=fread(fid,1,'uint32');
            S7Kdata.R7000_SonarSettings.ProjectorBeamWeightingWindowType{i7000}=get_param_val(proj_beam_types,t_temp);
            S7Kdata.R7000_SonarSettings.ProjectorBeamWeightingWindowParameter(i7000)=fread(fid,1,'float32');
            S7Kdata.R7000_SonarSettings.TransmitFlags(i7000)=fread(fid,1,'uint32');
            S7Kdata.R7000_SonarSettings.HydrophoneIdentifier(i7000)=fread(fid,1,'uint32');
            t_temp=fread(fid,1,'uint32');
            S7Kdata.R7000_SonarSettings.ReceiveBeamWeightingWindowType{i7000}=get_param_val(rx_beam_win,t_temp);
            S7Kdata.R7000_SonarSettings.ReceiveBeamWeightingWindowParameter=fread(fid,1,'float32');
            S7Kdata.R7000_SonarSettings.ReceiveFlags(i7000)=fread(fid,1,'uint32');
            S7Kdata.R7000_SonarSettings.ReceiveBeamWidthRad(i7000)=fread(fid,1,'float32');
            S7Kdata.R7000_SonarSettings.BottomDetectFilter{i7000}=fread(fid,4,'float32');%[min_range max_range min_depth max_depth]
            S7Kdata.R7000_SonarSettings.Absorption(i7000)=fread(fid,1,'float32');
            S7Kdata.R7000_SonarSettings.SoundVelocity(i7000)=fread(fid,1,'float32');
            S7Kdata.R7000_SonarSettings.Spreading(i7000)=fread(fid,1,'float32');
            S7Kdata.R7000_SonarSettings.Reserved(i7000)=fread(fid,1,'uint16');
            parsed = 1;
        case 7001
            %% 7001  7k Configuration TODO
            fieldname='R7001_7kConfiguration';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            try i7001=i7001+1; catch, i7001=1; end
            icurr_field=i7001;
            
            S7Kdata.R7001_7kConfiguration.SonarId(i7001)      = fread(fid,1,'uint64');
            N_info                                            = fread(fid,1,'uint32');
            S7Kdata.R7001_7kConfiguration.N(i7001)            = N_info;
            
            S7Kdata.R7001_7kConfiguration.DeviceID{i7001}=nan(1,N_info);
            S7Kdata.R7001_7kConfiguration.DeviceDescription{i7001}=cell(1,N_info);
            S7Kdata.R7001_7kConfiguration.DeviceAlphaDataCard{i7001}=nan(1,N_info);
            S7Kdata.R7001_7kConfiguration.DeviceSerialNumber{i7001}=nan(1,N_info);
            S7Kdata.R7001_7kConfiguration.DeviceInfo{i7001}=cell(1,N_info);
            
            for i_inf=1:N_info
                S7Kdata.R7001_7kConfiguration.DeviceID{i7001}(i_inf)=fread(fid,1,'uint32');
                S7Kdata.R7001_7kConfiguration.DeviceDescription{i7001}{i_inf}=fread(fid,60,'*char')';
                S7Kdata.R7001_7kConfiguration.DeviceAlphaDataCard{i7001}(i_inf)=fread(fid,1,'uint32');
                S7Kdata.R7001_7kConfiguration.DeviceSerialNumber{i7001}(i_inf)=fread(fid,1,'uint32');
                l_tmp=fread(fid,1,'uint32');
                S7Kdata.R7001_7kConfiguration.DeviceInfo{i7001}{i_inf}=fread(fid,l_tmp,'*char')';
            end
            
            
        case 7002
            %% 7002  7k Match Filter TODO
            fieldname='R7001_7kMatchFilter';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            try i7002=i7002+1; catch, i7002=1; end
            icurr_field=i7002;
            
            parsed = 1;
        case 7004
            %% 7004  7k Beam Geometry TODO
            fieldname='R7004_7kBeamGeometry';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            try i7004=i7004+1; catch, i7004=1; end
            icurr_field=i7004;
            
            parsed = 1;
        case 7007
            %% 7007  7k Side Scan Data TODO
            fieldname='R7004_7kSideScanData';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            try i7007=i7007+1; catch, i7007=1; end
            icurr_field=i7007;
            
            parsed = 1;
        case 7012
            %% 7012  7k Ping Motion Data TODO
            fieldname='R7012_7kPingMotionData';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            try i7012=i7012+1; catch, i7012=1; end
            icurr_field=i7012;
            
            parsed = 1;
        case 7018
            %% 7018  7k Beamformed Data TODO
            fieldname='R7018_7kBeamformedData';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            try i7018=i7018+1; catch, i7018=1; end
            icurr_field=i7018;
            
            parsed = 1;
        case 7021
            %% 7021  7k Built-In Test Environment Data TODO
            fieldname='R7021_7kBuiltInTestEnvData';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            try i7021=i7021+1; catch, i7021=1; end
            icurr_field=i7021;
            
            parsed = 1;
        case 7022
            %% 7022  7kCenter Version TODO
            fieldname='R7022_7kCenterVersion';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            try i7022=i7022+1; catch, i7022=1; end
            icurr_field=i7022;
        case 7027
            %% 7027  7k RAW Detection Data
            fieldname='R7027_RAWdetection';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            try i7027=i7027+1; catch, i7027=1; end
            icurr_field=i7027;
            
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
            S7Kdata.R7027_RAWdetection.Date(i7027)                             = S7Kfileinfo.date(iDatag);
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
                tmp_pos=ftell(fid);
                % parsing OD
                fread(fid,OD_offset-(tmp_pos-pif_recordstart),'uint8');
            
                S7Kdata.R7027_RAWdetection.Frequency(i7027)       = fread(fid,1,'float32');
                S7Kdata.R7027_RAWdetection.Latitude(i7027)        = fread(fid,1,'float64')/pi*180;
                S7Kdata.R7027_RAWdetection.Longitude(i7027)       = fread(fid,1,'float64')/pi*180;
                S7Kdata.R7027_RAWdetection.Heading(i7027)         = fread(fid,1,'float32')/pi*180;
                t_temp                                            = fread(fid,1,'uint8');
                S7Kdata.R7027_RAWdetection.HeightSource{i7027}=get_param_val(height_source,t_temp);
                S7Kdata.R7027_RAWdetection.Tide(i7027)            = fread(fid,1,'float32');
                S7Kdata.R7027_RAWdetection.Roll(i7027)            = fread(fid,1,'float32')/pi*180;
                S7Kdata.R7027_RAWdetection.Pitch(i7027)            = fread(fid,1,'float32')/pi*180;
                S7Kdata.R7027_RAWdetection.Heave(i7027)            = fread(fid,1,'float32');
                S7Kdata.R7027_RAWdetection.VehicleDepth(i7027)     = fread(fid,1,'float32');
                
                tmp_beam_data = fread(fid,[5 N],'float32');

                S7Kdata.R7027_RAWdetection.Depth{i7027}               = tmp_beam_data(1,:);
                S7Kdata.R7027_RAWdetection.AlongTrackDistance{i7027}  = tmp_beam_data(2,:);
                S7Kdata.R7027_RAWdetection.AcrossTrackDistance{i7027} = tmp_beam_data(3,:);
                S7Kdata.R7027_RAWdetection.PointingAngle{i7027}       = tmp_beam_data(4,:);
                S7Kdata.R7027_RAWdetection.AzimuthAngle{i7027}        = tmp_beam_data(5,:);
 
            else
                S7Kdata.R7027_RAWdetection.Frequency(i7027)       = nan;
                S7Kdata.R7027_RAWdetection.Latitude(i7027)        = nan;
                S7Kdata.R7027_RAWdetection.Longitude(i7027)       = nan;
                S7Kdata.R7027_RAWdetection.Heading(i7027)         = nan;
                
                S7Kdata.R7027_RAWdetection.HeightSource{i7027 }    = '';
                S7Kdata.R7027_RAWdetection.Tide(i7027)            = nan;
                S7Kdata.R7027_RAWdetection.Roll(i7027)            = nan;
                S7Kdata.R7027_RAWdetection.Pitch(i7027)            = nan;
                S7Kdata.R7027_RAWdetection.Heave(i7027)            = nan;
                S7Kdata.R7027_RAWdetection.VehicleDepth(i7027)     = nan;
                                
                S7Kdata.R7027_RAWdetection.Depth{i7027}               = {};
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
            %% 7028  7k Snippet Data TODO
            fieldname='R7001_7k_configuration';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            try i7001=i7001+1; catch, i7001=1; end
            icurr_field=i7001;
            
            parsed = 1;
            
        case 7042
            %% 7042 Compressed Watercolumn Data
            fieldname='R7042_CompressedWaterColumn';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            
            % counter for this type of datagram
            try i7042=i7042+1; catch, i7042=1; end
            icurr_field=i7042;
            
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
            flag_bin = dec2bin(S7Kdata.R7042_CompressedWaterColumn.Flags(i7042), 32);
            
            % Bit 0 : Use maximum bottom detection point in each beam to
            % limit data. Data is included up to the bottom detection point
            % + 10%. This flag has no effect on systems which do not
            % perform bottom detection.
            flag_dataTruncatedBeyondBottom = bin2dec(flag_bin(32-0));
            
            % Bit 1 : Include magnitude data only (strip phase)
            flag_magnitudeOnly = bin2dec(flag_bin(32-1));
            
            % Bit 2 : Convert mag to dB, then compress from 16 bit to 8 bit
            % by truncation of 8 lower bits. Phase compression simply
            % truncates lower (least significant) byte of phase data.
            flag_8BitCompression = bin2dec(flag_bin(32-2));
            
            % Bit 3 : Reserved.
            
            % Bit 4-7 : Downsampling divisor. Value = (BITS >> 4). Only
            % values 2-16 are valid. This field is ignored if downsampling
            % is not enabled (type = none).
            flag_downsamplingDivisor = bin2dec(flag_bin(32-7:32-4));
            
            % Bit 8-11 : Downsampling type:
            %             0x000 = None
            %             0x100 = Middle value
            %             0x200 = Peak value
            %             0x300 = Average value
            flag_downsamplingType = bin2dec(flag_bin(32-11:32-8));
            
            % Bit 12: 32 Bits data
            flag_32BitsData = bin2dec(flag_bin(32-12));
            
            % Bit 13: Compression factor available
            flag_compressionFactorAvailable = bin2dec(flag_bin(32-13));
            
            % Bit 14: Segment numbers available
            flag_segmentNumbersAvailable = bin2dec(flag_bin(32-14));
            
            % figure the size of a "sample" in bytes based on those flags
            if flag_magnitudeOnly
                if flag_32BitsData && ~flag_8BitCompression
                    % F) 32 bit Mag (32 bits total, no phase)
                    sample_size = 4;
                elseif ~flag_32BitsData && flag_8BitCompression
                    % D) 8 bit Mag (8 bits total, no phase)
                    sample_size = 1;
                elseif ~flag_32BitsData && ~flag_8BitCompression
                    % B) 16 bit Mag (16 bits total, no phase)
                    sample_size = 2;
                else
                    % if both flag_32BitsData and flag_8BitCompression are
                    % =1, then I am not quite sure how it would work given
                    % how I understand the file format documentation.
                    % Throw error if you ever get this case and look for
                    % more information about data format...
                    warning('%s: WC compression flag issue',fieldname);
                end
            else
                if ~flag_32BitsData && flag_8BitCompression
                    % C) 8 bit Mag & 8 bit Phase (16 bits total)
                    sample_size = 2;
                elseif ~flag_32BitsData && ~flag_8BitCompression
                    % A) 16 bit Mag & 16bit Phase (32 bits total)
                    sample_size = 4;
                else
                    % Again, if both flag_32BitsData and
                    % flag_8BitCompression are = 1, I don't know what the
                    % result would be.
                    
                    % There is another weird case: if flag_32BitsData=1 and
                    % flag_8BitCompression=0, I would assume it would 32
                    % bit Mab & 32 bit Phase (64 bits total), but that case
                    % does not exist in the documentation. Instead you have
                    % a case E) 32 bit Mag & 8 bit Phase (40 bits total),
                    % which I don't understand could happen. Also, that
                    % would screw the code as we read the data in bytes,
                    % aka multiples of 8 bits. We would need to modify the
                    % code to work per bit if we ever had such a case.
                    
                    % Anyway, throw error if you ever get here and look for
                    % more information about data format...
                    warning('%s: WC flag combination non taken into account',fieldname);
                    i7042=i7042-1;
                    continue;
                end
            end
            
            % parsing RD
            % repeat cycle: B entries of a possibly variable number of
            % bits. Reading everything first and using a for loop to parse
            % the data in it
            pos_2 = ftell(fid); % position at start of data
            RTH_size = 44;
            RD_size = RTHandRD_size - RTH_size;
            tmp = fread(fid,RD_size,'int8'); % read all that data block
            tmp = int8(tmp');
            
            id  = 0; % offset for start of each Nrx block
            wc_parsing_error = 0; % initialize flag
            
            % initialize outputs
            B = S7Kdata.R7042_CompressedWaterColumn.Beams(i7042);
            S7Kdata.R7042_CompressedWaterColumn.BeamNumber{i7042}                = nan(1,B);
            S7Kdata.R7042_CompressedWaterColumn.SegmentNumber{i7042}             = nan(1,B);
            S7Kdata.R7042_CompressedWaterColumn.NumberOfSamples{i7042}           = nan(1,B);
            S7Kdata.R7042_CompressedWaterColumn.SampleStartPositionInFile{i7042} = nan(1,B);
            Ns = zeros(1,B); % Number of samples in matrix form
            
            % now parse the data
            if flag_segmentNumbersAvailable
                for jj = 1:B
                    try
                        S7Kdata.R7042_CompressedWaterColumn.BeamNumber{i7042}(jj)      = typecast(tmp(1+id:2+id),'uint16');
                        S7Kdata.R7042_CompressedWaterColumn.SegmentNumber{i7042}(jj)   = typecast(tmp(3+id),'uint8');
                        S7Kdata.R7042_CompressedWaterColumn.NumberOfSamples{i7042}(jj) = typecast(tmp(4+id:7+id),'uint32');
                        S7Kdata.R7042_CompressedWaterColumn.SampleStartPositionInFile{i7042}(jj) = pos_2 + id + 7;
                        Ns(jj) = S7Kdata.R7042_CompressedWaterColumn.NumberOfSamples{i7042}(jj);
                        id = 7*jj + sum(Ns).*sample_size;
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
                        S7Kdata.R7042_CompressedWaterColumn.BeamNumber{i7042}(jj)      = typecast(tmp(1+id:2+id),'uint16');
                        S7Kdata.R7042_CompressedWaterColumn.NumberOfSamples{i7042}(jj) = typecast(tmp(3+id:6+id),'uint32');
                        S7Kdata.R7042_CompressedWaterColumn.SampleStartPositionInFile{i7042}(jj) = pos_2 + id + 6;
                        Ns(jj) = S7Kdata.R7042_CompressedWaterColumn.NumberOfSamples{i7042}(jj);
                        id = 6*jj + sum(Ns).*sample_size;
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
            %% 7200  7k File Header'
            fieldname='R7200_FileHeader';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            % counter for this type of datagram
            try i7200=i7200+1; catch, i7200=1; end
            icurr_field=i7200;
            
            
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
                tmp_pos=ftell(fid);
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
            %% 7300  7k File Catalog Record TODO
            fieldname='R7200_FileCatalogRecord';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            % counter for this type of datagram
            try i7300=i7300+1; catch, i7300=1; end
            icurr_field=i7300;
            
        case 7503
            %% 7503  Remote Control Sonar Settings TODO
            fieldname='R7503_FileCatalogRecord';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            % counter for this type of datagram
            try i7503=i7503+1; catch, i7503=1; end
            icurr_field=i7503;
            
        case 7504
            %% 7504  7P Common System Settings TODO
            fieldname='R7504_7pCommonSystemSettings';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            % counter for this type of datagram
            try i7504=i7504+1; catch, i7504=1; end
            icurr_field=i7504;
            
        case 7610
            %% 7610  7k Sound Velocity TODO
            fieldname='R7610_7kSoundVelocity';
            if ~(isempty(p.Results.OutputFields)||any(strcmp(fieldname,p.Results.OutputFields)))
                continue;
            end
            % counter for this type of datagram
            try i7610=i7610+1; catch, i7610=1; end
            icurr_field=i7610;
        otherwise
            
            % datagTypeNumber is not recognized yet
            
    end
    
    % modify parsed status in info
    S7Kfileinfo.parsed(iDatag,1) = parsed;
    if parsed==1
        S7Kdata.(fieldname).TimeSinceMidnightInMilliseconds(icurr_field)  = S7Kfileinfo.timeSinceMidnightInMilliseconds(iDatag);
        S7Kdata.(fieldname).Date{icurr_field}                             = S7Kfileinfo.date{iDatag};
    end
    
end


%% close fid
fclose(fid);


%% add info to parsed data
S7Kdata.info = S7Kfileinfo;
end

function val=get_param_val(rx_beam_win,t_temp)
idx=[rx_beam_win{2}{:}]==double(t_temp);
if any(idx)
    val=rx_beam_win{1}{idx};
else
    val='';
end
end
