%THIS IS A PRELIMINARY VERSION THAT ONLY POPULATES STUFF ABSOLUTELY
%NECESSARY FOR ESPRESSO TO DISPLAY T50 DATA
function [fData,update_flag] = CFF_convert_S7Kdata_to_fData(S7KdataGroup,varargin)

%% input parsing

% init
p = inputParser;

% required
addRequired(p,'S7KdataGroup',@(x) isstruct(x) || iscell(x));

% optional
addOptional(p,'dr_sub',1,@(x) isnumeric(x)&&x>0);
addOptional(p,'db_sub',1,@(x) isnumeric(x)&&x>0);
addOptional(p,'fData',{},@(x) isstruct(x) || iscell(x));

% parse
parse(p,S7KdataGroup,varargin{:})

% get results
S7KdataGroup = p.Results.S7KdataGroup;
dr_sub = p.Results.dr_sub;
db_sub = p.Results.db_sub;
fData = p.Results.fData;
clear p;

%% pre-processing

if ~iscell(S7KdataGroup)
    S7KdataGroup = {S7KdataGroup};
end

% number of individual S7Kdata structures in input S7KdataGroup
nStruct = length(S7KdataGroup);

% initialize fData if one not given in input
if isempty(fData)
    
    update_mode = 0;
    
    % initialize FABC structure by writing in the raw data filenames to be
    % added here
    fData.ALLfilename = cell(1,nStruct);
    for iF = 1:nStruct
        fData.ALLfilename{iF} = S7KdataGroup{iF}.S7Kfilename;
    end
    % add the decimation factors given here in input
    fData.dr_sub = dr_sub;
    fData.db_sub = db_sub;
else
    
    update_mode = 1;
    
end

% initialize update_flag
update_flag = 0;

%% take one S7Kdata structure at a time and add its contents to fData

for iF = 1:nStruct
    
    %% pre processing
    
    % get current structure
    S7Kdata = S7KdataGroup{iF};
    
    % Make sure we don't update fData with datagrams from different
    % sources
    % XXX clean up that display later
    if ~ismember(S7Kdata.S7Kfilename,fData.ALLfilename)
        fprintf('Cannot add different files to this structure.\n')
        continue;
    end
    
    % open the original raw file in case we need to grab WC data from it
    fid_all = fopen(fData.ALLfilename{iF},'r',S7Kdata.datagramsformat);
    
    % get folder for converted data
    wc_dir = CFF_converted_data_folder(fData.ALLfilename{iF});
    
    % now reading each type of datagram...
    
    fData.IP_ASCIIparameters.S1H=0; %deg (sonarHeadingOffsetDeg, to check where we can find it...)
    %ping_number=S7Kdata.R7000_SonarSettings.PingNumber;
    ping_date=S7Kdata.R7000_SonarSettings.Date;
    ping_TSMIM=S7Kdata.R7000_SonarSettings.TimeSinceMidnightInMilliseconds;
    %ping_time=cellfun(@(x) datenum(x,'yyyymmdd'),ping_date)+ping_TSMIM/(24*60*60*1e3);
    
    
    %% S7K_Height
    
    % only convert these datagrams if this type doesn't already exist in output
    if ~isfield(fData,'He_1D_Date')
        if update_mode
            update_flag = 1;
        end
        if isfield(S7Kdata,'R1015_Navigation')
            fData.He_1D_Date                            = S7Kdata.R1015_Navigation.Date;
            fData.He_1D_TimeSinceMidnightInMilliseconds = S7Kdata.R1015_Navigation.TimeSinceMidnightInMilliseconds;
            fData.He_1D_HeightCounter                   = 1:numel(S7Kdata.R1015_Navigation.Date);
            fData.He_1D_Height                          = S7Kdata.R1015_Navigation.VesselHeigh;
        else
            fData.He_1D_Date                            = ping_date;
            fData.He_1D_TimeSinceMidnightInMilliseconds = ping_TSMIM;
            fData.He_1D_HeightCounter                   = 1:numel(ping_TSMIM);
            fData.He_1D_Height                          = zeros(size(ping_date));
        end
    end
    
    
    %% S7K_Position
    if ~isfield(fData,'Po_1D_Date')
        
        if update_mode
            update_flag = 1;
        end
        
        if isfield(S7Kdata,'R1015_Navigation')
            
            % only convert these datagrams if this type doesn't already exist in output
            
            % NumberOfDatagrams = length(S7Kdata.EM_Position.TypeOfDatagram);
            
            fData.Po_1D_Date                            = S7Kdata.R1015_Navigation.Date;
            fData.Po_1D_TimeSinceMidnightInMilliseconds = S7Kdata.R1015_Navigation.TimeSinceMidnightInMilliseconds;
            fData.Po_1D_PositionCounter                 = S7Kdata.R1015_Navigation.PositionCounter;
            fData.Po_1D_Latitude                        = S7Kdata.R1015_Navigation.Latitude;
            fData.Po_1D_Longitude                       = S7Kdata.R1015_Navigation.Longitude;
            fData.Po_1D_SpeedOfVesselOverGround         = S7Kdata.R1015_Navigation.SpeedOfVesselOverGround;
            fData.Po_1D_HeadingOfVessel                 = S7Kdata.R1015_Navigation.Heading;
            nb_pt=numel(fData.Po_1D_Latitude);
            [dist_in_deg,~]=distance([fData.Po_1D_Latitude(1:nb_pt-1) fData.Po_1D_Longitude(1:nb_pt-1)],[fData.Po_1D_Latitude(2:nb_pt) fData.Po_1D_Longitude(2:nb_pt)]);
            d_dist=[0 deg2km(dist_in_deg)];
            t=cellfun(@(x) datenum(x,'yyyymmdd'),fData.Po_1D_Date)*24*60*60+fData.Po_1D_TimeSinceMidnightInMilliseconds/1e3;
            s=d_dist*1000/diff(t);
            fData.Po_1D_SpeedOfVesselOverGround =[s(1) s];
            
            
        elseif isfield(S7Kdata,'R1003_Position')
            
            
            if update_mode
                update_flag = 1;
            end
            
            % NumberOfDatagrams = length(S7Kdata.EM_Position.TypeOfDatagram);
            
            fData.Po_1D_Date                            = S7Kdata.R1003_Position.Date;
            fData.Po_1D_TimeSinceMidnightInMilliseconds = S7Kdata.R1003_Position.TimeSinceMidnightInMilliseconds;
            fData.Po_1D_PositionCounter                 = 1:numel(S7Kdata.R1003_Position.Date);
            
            if  S7Kdata.R1003_Position.Datum_id(1)==0
                fData.Po_1D_Latitude                        = S7Kdata.R1003_Position.Latitude;
                fData.Po_1D_Longitude                       = S7Kdata.R1003_Position.Longitude;
                nb_pt=numel(fData.Po_1D_Latitude);
                [dist_in_deg,head]=distance([fData.Po_1D_Latitude(1:nb_pt-1)' fData.Po_1D_Longitude(1:nb_pt-1)'],[fData.Po_1D_Latitude(2:nb_pt)' fData.Po_1D_Longitude(2:nb_pt)']);
                d_dist=deg2km(dist_in_deg');
                t=datenum(cellfun(@num2str,num2cell(fData.Po_1D_Date),'un',0),'yyyymmdd')'*24*60*60+fData.Po_1D_TimeSinceMidnightInMilliseconds/1e3;
                s=d_dist*1000./diff(t);
                fData.Po_1D_SpeedOfVesselOverGround =[s(1) s];
                fData.Po_1D_HeadingOfVessel =[head(1) head'];
                
            else
                warning('Po_1D_Date:Could not find position data in the file');
            end
            
        else
            warning('Po_1D_Date:Could not find position data in the file');
        end
        
        %% EM_XYZ88
        
        if isfield(S7Kdata,'R7027_RAWdetection') %%%%TODO
            
            % only convert these datagrams if this type doesn't already exist in output
            if ~isfield(fData,'X8_1P_Date')
                
                if update_mode
                    update_flag = 1;
                end
                
                nPings    = numel(S7Kdata.R7042_CompressedWaterColumn.BeamNumber); % total number of pings in file
                maxNBeams=nanmax(cellfun(@numel,S7Kdata.R7042_CompressedWaterColumn.BeamNumber));
                
                fData.X8_1P_Date                            = S7Kdata.R7027_RAWdetection.Date;
                fData.X8_1P_TimeSinceMidnightInMilliseconds = S7Kdata.R7027_RAWdetection.TimeSinceMidnightInMilliseconds;
                fData.X8_1P_PingCounter                     = 1:nPings;
                fData.X8_1P_HeadingOfVessel                 = nan(size(fData.X8_1P_Date));
                fData.X8_1P_SoundSpeedAtTransducer          = nan(size(fData.X8_1P_Date));
                fData.X8_1P_TransmitTransducerDepth         = nan(size(fData.X8_1P_Date));
                fData.X8_1P_NumberOfBeamsInDatagram         = S7Kdata.R7027_RAWdetection.N;
                fData.X8_1P_NumberOfValidDetections         = S7Kdata.R7027_RAWdetection.N;
                fData.X8_1P_SamplingFrequencyInHz           = S7Kdata.R7027_RAWdetection.SamplingRate;
                
                % initialize
                fData.X8_BP_DepthZ                       = nan(maxNBeams,nPings);
                fData.X8_BP_AcrosstrackDistanceY         = nan(maxNBeams,nPings);
                fData.X8_BP_AlongtrackDistanceX          = nan(maxNBeams,nPings);
                fData.X8_BP_DetectionWindowLength        = nan(maxNBeams,nPings);
                fData.X8_BP_QualityFactor                = nan(maxNBeams,nPings);
                fData.X8_BP_BeamIncidenceAngleAdjustment = nan(maxNBeams,nPings);
                fData.X8_BP_DetectionInformation         = nan(maxNBeams,nPings);
                fData.X8_BP_RealTimeCleaningInformation  = nan(maxNBeams,nPings);
                fData.X8_BP_ReflectivityBS               = nan(maxNBeams,nPings);
                fData.X8_B1_BeamNumber                   = (1:maxNBeams)';
                
                for iP = 1:nPings
                    iBeam=S7Kdata.R7027_RAWdetection.BeamDescriptor{iP}+1;
                    fData.X8_BP_DepthZ(iBeam,iP)                       = S7Kdata.R7027_RAWdetection.Depth{iP};
                    fData.X8_BP_AcrosstrackDistanceY(iBeam,iP)         = S7Kdata.R7027_RAWdetection.AcrossTrackDistance{iP};
                    fData.X8_BP_AlongtrackDistanceX(iBeam,iP)          = S7Kdata.R7027_RAWdetection.AlongTrackDistance{iP};
                    fData.X8_BP_DetectionWindowLength(iBeam,iP)        = nan;
                    fData.X8_BP_QualityFactor(iBeam,iP)                = S7Kdata.R7027_RAWdetection.Quality{iP} ;
                    fData.X8_BP_BeamIncidenceAngleAdjustment(iBeam,iP) = nan;
                    fData.X8_BP_DetectionInformation(iBeam,iP)         = nan;
                    fData.X8_BP_RealTimeCleaningInformation(iBeam,iP)  = nan;
                    fData.X8_BP_ReflectivityBS(iBeam,iP)               = S7Kdata.R7027_RAWdetection.SignalStrength{iP};
                end
                
            end
            
        end
        
        
        %% R7018_7kBeamformedData TODO
        
        if isfield(S7Kdata,'R7018_7kBeamformedData')
            if ~isfield(fData,'WC_1P_Date')
                if update_mode
                    update_flag = 1;
                end
                % get indices of first datagram for each ping
                pingNumber=1:numel(S7Kdata.R7018_7kBeamformedData.SonarId);
                maxNBeams=nanmax(numel,S7Kdata.R7018_7kBeamformedData.N);
                nPings=numel(S7Kdata.R7018_7kBeamformedData.N);
                maxNSamples=nanmax(S7Kdata.R7018_7kBeamformedData.S);
                maxNTransmitSectors = 1;
                
                
                % read data per ping from first datagram of each ping
                fData.WC_1P_Date                            = S7Kdata.R7018_7kBeamformedData.Date;
                fData.WC_1P_TimeSinceMidnightInMilliseconds = S7Kdata.R7018_7kBeamformedData.TimeSinceMidnightInMilliseconds;
                fData.WC_1P_PingCounter                     = pingNumber;
                fData.WC_1P_NumberOfDatagrams               = ones(size(pingNumber));
                fData.WC_1P_NumberOfTransmitSectors         = ones(size(pingNumber));
                fData.WC_1P_TotalNumberOfReceiveBeams       = S7Kdata.R7018_7kBeamformedData.N;
                fData.WC_1P_SoundSpeed                      = S7Kdata.R7000_SonarSettings.SoundVelocity;
                fData.WC_1P_SamplingFrequencyHz             = S7Kdata.R7000_SonarSettings.SampleRate; % in Hz
                fData.WC_1P_TXTimeHeave                     = nan(ones(size(pingNumber)));
                fData.WC_1P_TVGFunctionApplied              = nan(size(pingNumber));
                fData.WC_1P_TVGOffset                       = nan(size(pingNumber));
                fData.WC_1P_ScanningInfo                    = nan(size(pingNumber));
                
                % initialize data per transmit sector and ping
                fData.WC_TP_TiltAngle            = nan(maxNTransmitSectors,nPings);
                fData.WC_TP_CenterFrequency      = S7Kdata.R7000_SonarSettings.Frequency;
                fData.WC_TP_TransmitSectorNumber = nan(maxNTransmitSectors,nPings);
                
                % initialize data per decimated beam and ping
                fData.WC_BP_BeamPointingAngle      = nan(maxNBeams,nPings);
                fData.WC_BP_StartRangeSampleNumber = nan(maxNBeams,nPings);
                fData.WC_BP_NumberOfSamples        = nan(maxNBeams,nPings);
                fData.WC_BP_DetectedRangeInSamples = zeros(maxNBeams,nPings);
                fData.WC_BP_TransmitSectorNumber   = nan(maxNBeams,nPings);
                fData.WC_BP_BeamNumber             = nan(maxNBeams,nPings);
                
                % path to binary file for WC data
                file_amp_binary   = fullfile(wc_dir,'WC_SBP_SampleAmplitudes.dat');
                file_phase_binary = fullfile(wc_dir,'WC_SBP_SamplePhase.dat');
                
                % if file does not exist or we're re-sampling it, create a new
                % one ready for writing
                if exist(file_amp_binary,'file')==0
                    file_amp_id = fopen(file_amp_binary,'w+');
                else
                    % if we're here, it means the file already exists and
                    % already contain the data at the proper sampling. So we
                    % just need to store the metadata and link to it as
                    % memmapfile.
                    file_amp_id = -1;
                end
                
                % repeat for phase file
                if exist(file_phase_binary,'file')==0
                    file_phase_id = fopen(file_phase_binary,'w+');
                else
                    file_phase_id = -1;
                end
                mag_fmt='uint16';
                phase_fmt='int16';
                
                % now get data for each ping
                for iP = 1:nPings
                    fseek(fid_all,S7Kdata.R7018_7kBeamformedData.BeamformedDataPos(iP),'bof');
                    Mag_tmp=(fread(fid_all,[S7Kdata.R7018_7kBeamformedData.N(iP) S7Kdata.R7018_7kBeamformedData.S(iP)],mag_fmt,1))';
                    fseek(fid_all,S7Kdata.R7018_7kBeamformedData.BeamformedDataPos(iP)+1,'bof');
                    Ph_tmp=(fread(fid_all,[S7Kdata.R7018_7kBeamformedData.N(iP) S7Kdata.R7018_7kBeamformedData.S(iP)],phase_fmt,1))';
                    
                    Ph_tmp=Ph_tmp/10430/pi*180;
                    
                    Mag_tmp(Mag_tmp==eval([mag_fmt '(-inf)']))=eval([mag_fmt '(-inf)']);
                    % store amp data on binary file
                    if file_amp_id >= 0
                        fwrite(file_amp_id,Mag_tmp,mag_fmt);
                    end
                    
                    % store phase data on binary file
                    if file_phase_id>=0
                        fwrite(file_phase_id,Ph_tmp,phase_fmt);
                    end
                end
                
            end
        end
        
        %% R7042_CompressedWaterColumn
        
        if isfield(S7Kdata,'R7042_CompressedWaterColumn')
            
            % only convert these datagrams if this type doesn't already exist in output
            if ~isfield(fData,'AP_1P_Date')
                
                if update_mode
                    update_flag = 1;
                end
                
                % get indices of first datagram for each ping
                pingNumber=1:numel(S7Kdata.R7042_CompressedWaterColumn.SonarId);
                maxNBeams=nanmax(cellfun(@numel,S7Kdata.R7042_CompressedWaterColumn.BeamNumber));
                nPings=numel(S7Kdata.R7042_CompressedWaterColumn.BeamNumber);
                maxNSamples=nanmax(S7Kdata.R7042_CompressedWaterColumn.FirstSample+cellfun(@nanmax,S7Kdata.R7042_CompressedWaterColumn.NumberOfSamples));
                maxNTransmitSectors = 1;
                
                
                % read data per ping from first datagram of each ping
                fData.AP_1P_Date                            = S7Kdata.R7042_CompressedWaterColumn.Date;
                fData.AP_1P_TimeSinceMidnightInMilliseconds = S7Kdata.R7042_CompressedWaterColumn.TimeSinceMidnightInMilliseconds;
                fData.AP_1P_PingCounter                     = pingNumber;
                fData.AP_1P_NumberOfDatagrams               = ones(size(pingNumber));
                fData.AP_1P_NumberOfTransmitSectors         = ones(size(pingNumber));
                fData.AP_1P_TotalNumberOfReceiveBeams       = cellfun(@numel,S7Kdata.R7042_CompressedWaterColumn.BeamNumber);
                fData.AP_1P_SoundSpeed                      = S7Kdata.R7000_SonarSettings.SoundVelocity;
                fData.AP_1P_SamplingFrequencyHz             = S7Kdata.R7042_CompressedWaterColumn.SampleRate; % in Hz
                fData.AP_1P_TXTimeHeave                     = nan(ones(size(pingNumber)));
                fData.AP_1P_TVGFunctionApplied              = nan(size(pingNumber));
                fData.AP_1P_TVGOffset                       = nan(size(pingNumber));
                fData.AP_1P_ScanningInfo                    = nan(size(pingNumber));
                
                % initialize data per transmit sector and ping
                fData.AP_TP_TiltAngle            = nan(maxNTransmitSectors,nPings);
                fData.AP_TP_CenterFrequency      = S7Kdata.R7000_SonarSettings.Frequency;
                fData.AP_TP_TransmitSectorNumber = nan(maxNTransmitSectors,nPings);
                
                % initialize data per decimated beam and ping
                fData.AP_BP_BeamPointingAngle      = nan(maxNBeams,nPings);
                fData.AP_BP_StartRangeSampleNumber = nan(maxNBeams,nPings);
                fData.AP_BP_NumberOfSamples        = nan(maxNBeams,nPings);
                fData.AP_BP_DetectedRangeInSamples = zeros(maxNBeams,nPings);
                fData.AP_BP_TransmitSectorNumber   = nan(maxNBeams,nPings);
                fData.AP_BP_BeamNumber             = nan(maxNBeams,nPings);
                
                % path to binary file for WC data
                file_amp_binary   = fullfile(wc_dir,'AP_SBP_SampleAmplitudes.dat');
                file_phase_binary = fullfile(wc_dir,'AP_SBP_SamplePhase.dat');
                
                % if file does not exist or we're re-sampling it, create a new
                % one ready for writing
                if exist(file_amp_binary,'file')==0
                    file_amp_id = fopen(file_amp_binary,'w+');
                else
                    % if we're here, it means the file already exists and
                    % already contain the data at the proper sampling. So we
                    % just need to store the metadata and link to it as
                    % memmapfile.
                    file_amp_id = -1;
                end
                
                % repeat for phase file
                if exist(file_phase_binary,'file')==0
                    file_phase_id = fopen(file_phase_binary,'w+');
                else
                    file_phase_id = -1;
                end
                
                
                % now get data for each ping
                for iP = 1:nPings
                    
                    % find datagrams composing this ping
                    %pingCounter = fData.AP_1P_PingCounter(1,iP); % ping number (ex: 50455)
                    iBeam=S7Kdata.R7042_CompressedWaterColumn.BeamNumber{iP}+1;
                    [flags,sample_size,mag_fmt,phase_fmt]=CFF_get_R7042_flags(S7Kdata.R7042_CompressedWaterColumn.Flags(iP));
                    if flags.downsamplingType>0
                        fData.AP_1P_SamplingFrequencyHz(iP)=fData.AP_1P_SamplingFrequencyHz(iP)/flags.downsamplingDivisor;
                    end
                    % assuming transmit sectors data are not split between several datagrams, get that data from the first datagram.
                    nTransmitSectors = fData.AP_1P_NumberOfTransmitSectors(1,iP); % number of transmit sectors in this ping
                    fData.AP_TP_TiltAngle(1:nTransmitSectors,iP)            = zeros(nTransmitSectors,1);
                    fData.AP_TP_CenterFrequency(1:nTransmitSectors,iP)      = S7Kdata.R7000_SonarSettings.Frequency(iP)*ones(nTransmitSectors,1);
                    fData.AP_TP_TransmitSectorNumber(1:nTransmitSectors,iP) = 1:nTransmitSectors;
                    
                    % ping x beam data
                    fData.AP_BP_BeamPointingAngle(iBeam,iP)      = S7Kdata.R7004_7kBeamGeometry.BeamHorizontalDirectionAngleRad{iP}/pi*180;
                    fData.AP_BP_StartRangeSampleNumber(iBeam,iP) = round(S7Kdata.R7042_CompressedWaterColumn.FirstSample(iP));
                    fData.AP_BP_NumberOfSamples(iBeam,iP)        = round(S7Kdata.R7042_CompressedWaterColumn.NumberOfSamples{iP});
                    fData.AP_BP_DetectedRangeInSamples(S7Kdata.R7027_RAWdetection.BeamDescriptor{iP}+1,iP) = round(S7Kdata.R7027_RAWdetection.DetectionPoint{iP}/flags.downsamplingDivisor);
                    fData.AP_BP_TransmitSectorNumber(iBeam,iP)   = 1;
                    fData.AP_BP_BeamNumber(iBeam,iP)             = S7Kdata.R7004_7kBeamGeometry.N(iP);
                    
                    
                    % now getting watercolumn data (beams x samples)
                    if file_amp_id >= 0 || file_phase_id >= 0
                        
                        if flags.magnitudeOnly
                            Mag_tmp=ones(maxNSamples,maxNBeams,mag_fmt)*eval([mag_fmt '(-inf)']);
                        else
                            Mag_tmp=ones(maxNSamples,maxNBeams,mag_fmt)*eval([mag_fmt '(-inf)']);
                            Ph_tmp=zeros(maxNSamples,maxNBeams,phase_fmt);
                        end
                        start_sample=S7Kdata.R7042_CompressedWaterColumn.FirstSample(iP)+1;
                        Ns=S7Kdata.R7042_CompressedWaterColumn.NumberOfSamples{iP};
                        for jj=1:S7Kdata.R7004_7kBeamGeometry.N(iP)
                            fseek(fid_all,S7Kdata.R7042_CompressedWaterColumn.SampleStartPositionInFile{iP}(jj),'bof');
                            DataSamples_tmp=int8(fread(fid_all,Ns(jj)*sample_size,'int8'));
                            
                            if flags.magnitudeOnly
                                if flags.int32BitsData && ~flags.int8BitCompression
                                    % F) 32 bit Mag (32 bits total, no phase)
                                    Mag_tmp((start_sample:start_sample+Ns(jj)-1),jj)=pow2db(typecast(DataSamples_tmp,mag_fmt));
                                elseif ~flags.int32BitsData && flags.int8BitCompression
                                    % D) 8 bit Mag (8 bits total, no phase)
                                    Mag_tmp((start_sample:start_sample+Ns(jj)-1),jj)=DataSamples_tmp;
                                elseif ~flags.int32BitsData && ~flags.int8BitCompression
                                    % B) 16 bit Mag (16 bits total, no phase)
                                    Mag_tmp((start_sample:start_sample+Ns(jj)-1),jj)=typecast(DataSamples_tmp,mag_fmt);
                                else
                                    warning('WC compression flag issue');
                                end
                            else
                                if ~flags.int32BitsData && flags.int8BitCompression
                                    % C) 8 bit Mag & 8 bit Phase (16 bits total)
                                    
                                    Ph_tmp((start_sample:start_sample+Ns(jj)-1),jj)=DataSamples_tmp(2:2:end,:);
                                    Mag_tmp((start_sample:start_sample+Ns(jj)-1),jj)=DataSamples_tmp(1:2:end,:)-128;
                                elseif ~flags.int32BitsData && ~flags.int8BitCompression
                                    % A) 16 bit Mag & 16bit Phase (32 bits total)
                                    idx_tot=rem(1:numel(DataSamples_tmp),4);
                                    idx_phase=idx_tot==1|idx_tot==2;
                                    idx_mag=idx_tot==3|idx_tot==0;
                                    
                                    Ph_tmp((start_sample:start_sample+Ns(jj)-1),jj)=pow2db(typecast(DataSamples_tmp(idx_mag,:),mag_fmt));
                                    Mag_tmp((start_sample:start_sample+Ns(jj)-1),jj)=typecast(DataSamples_tmp(idx_phase,:),phase_fmt);
                                else
                                    warning('WC flag combination non taken into account');
                                end
                            end
                            
                        end
                        Mag_tmp(Mag_tmp==eval([mag_fmt '(-inf)']))=eval([mag_fmt '(-inf)']);
                        % store amp data on binary file
                        if file_amp_id >= 0
                            fwrite(file_amp_id,Mag_tmp,mag_fmt);
                        end
                        
                        % store phase data on binary file
                        if file_phase_id>=0
                            fwrite(file_phase_id,Ph_tmp,phase_fmt);
                        end
                        
                        if 0
                            f = figure();
                            ax_mag = axes(f,'outerposition',[0 0.5 1 0.5]);
                            imagesc(ax_mag,Mag_tmp);
                            ax_phase = axes(f,'outerposition',[0 0 1 0.5]);
                            imagesc(ax_phase,Ph_tmp);
                        end
                        
                        
                    end
                    
                end
                
                % close binary data file
                if file_amp_id >= 0
                    fclose(file_amp_id);
                end
                
                % close binary data file
                if file_phase_id >= 0
                    fclose(file_phase_id);
                end
                
                fData.AP_SBP_SampleAmplitudes = memmapfile(file_amp_binary,'Format',{mag_fmt [maxNSamples maxNBeams nPings] 'val'},'repeat',1,'writable',true);
                fData.AP_SBP_SamplePhase      = memmapfile(file_phase_binary,'Format',{phase_fmt [maxNSamples maxNBeams nPings] 'val'},'repeat',1,'writable',true);
                
                % save info about data format for later access
                fData.AP_1_SampleAmplitudes_Class  = mag_fmt;
                fData.AP_1_SampleAmplitudes_Nanval = eval([mag_fmt '(-inf)']);
                fData.AP_1_SampleAmplitudes_Factor = 1;
                fData.AP_1_SamplePhase_Class  = phase_fmt;
                fData.AP_1_SamplePhase_Nanval = 200;
                fData.AP_1_SamplePhase_Factor = 180/128;
                
            end
            
        end
        
        % close the original raw file
        fclose(fid_all);
        
    end
    
end