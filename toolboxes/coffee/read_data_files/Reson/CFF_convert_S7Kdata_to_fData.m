function [fData,update_flag] = CFF_convert_S7Kdata_to_fData(S7KdataGroup,varargin)
%CFF_CONVERT_S7KDATA_TO_FDATA  Convert s7k data to the CoFFee format
%
%   Converts Teledyne-Reson data FROM the S7Kdata format (read by
%   CFF_READ_S7K) TO the CoFFee fData format used in processing. NOTE THIS
%   IS A PRELIMINARY VERSION THAT ONLY POPULATES STUFF ABSOLUTELY NECESSARY
%   FOR ESPRESSO TO DISPLAY T50 DATA.
%
%   fData = CFF_CONVERT_S7KDATA_TO_FDATA(S7Kdata) converts the contents of
%   one S7Kdata structure to a structure in the fData format.
%
%   fData = CFF_CONVERT_S7KDATA_TO_FDATA(S7KdataGroup) converts an array of
%   S7Kdata structures into one fData sructure. The structures must
%   correspond to the same raw data file.
%
%   fData = CFF_CONVERT_S7KDATA_TO_FDATA(S7Kdata,dr_sub,db_sub) operates
%   the conversion with a sub-sampling of the water-column data in range
%   and in beams. For example, to sub-sample range by a factor of 10 and
%   beams by a factor of 2, use: 
%   fData = CFF_CONVERT_S7KDATA_TO_FDATA(S7Kdata,10,2).
%
%   See also ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 21-07-2021

%% Input arguments management
p = inputParser;

% required
addRequired(p,'S7KdataGroup',@(x) isstruct(x) || iscell(x));

% decimation factor in range and beam
addOptional(p,'dr_sub',1,@(x) isnumeric(x)&&x>0);
addOptional(p,'db_sub',1,@(x) isnumeric(x)&&x>0);

% parse inputs
parse(p,S7KdataGroup,varargin{:})

% and get results
S7KdataGroup = p.Results.S7KdataGroup;
dr_sub = p.Results.dr_sub;
db_sub = p.Results.db_sub;
clear p;

if ~iscell(S7KdataGroup)
    S7KdataGroup = {S7KdataGroup};
end


%% Prep

% number of individual S7Kdata structures in input S7KdataGroup
nStruct = length(S7KdataGroup);

% initialize fData, with current version number
fData.MET_Fmt_version = CFF_get_current_fData_version();

% initialize source filenames
fData.ALLfilename = cell(1,nStruct);


for iF = 1:nStruct
    fData.ALLfilename{iF} = S7KdataGroup{iF}.S7Kfilename;
end

% add the decimation factors given here in input
fData.dr_sub = dr_sub;
fData.db_sub = db_sub;

% XXX1 this calls Matlab version. To fix quick
if ~strcmpi(ver,CFF_get_current_fData_version)
    f_reconvert = 1;
    update_mode = 0;
else
    f_reconvert = 0;
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
    % XXX3 clean up that display later
    if ~ismember(S7Kdata.S7Kfilename,fData.ALLfilename)
        fprintf('Cannot add different files to this structure.\n')
        continue;
    end
    
    % now reading each type of datagram...
    
    fData.IP_ASCIIparameters.S1H=0; %deg (sonarHeadingOffsetDeg, to check where we can find it...)
    %ping_number=S7Kdata.R7000_SonarSettings.PingNumber;
    ping_date=S7Kdata.R7000_SonarSettings.Date;
    ping_TSMIM=S7Kdata.R7000_SonarSettings.TimeSinceMidnightInMilliseconds;
    %ping_time=cellfun(@(x) datenum(x,'yyyymmdd'),ping_date)+ping_TSMIM/(24*60*60*1e3);
    
    
    %% S7K_Height
    
    % only convert these datagrams if this type doesn't already exist in output
    if f_reconvert || ~isfield(fData,'He_1D_Date')
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
    if f_reconvert || ~isfield(fData,'Po_1D_Date')
        
        if update_mode
            update_flag = 1;
        end
        
        if isfield(S7Kdata,'R1015_Navigation')
            
            fData.Po_1D_Date                            = S7Kdata.R1015_Navigation.Date;
            fData.Po_1D_TimeSinceMidnightInMilliseconds = S7Kdata.R1015_Navigation.TimeSinceMidnightInMilliseconds;
            fData.Po_1D_PositionCounter                 = S7Kdata.R1015_Navigation.PositionCounter;
            fData.Po_1D_Latitude                        = S7Kdata.R1015_Navigation.Latitude;
            fData.Po_1D_Longitude                       = S7Kdata.R1015_Navigation.Longitude;
            fData.Po_1D_SpeedOfVesselOverGround         = S7Kdata.R1015_Navigation.SpeedOfVesselOverGround;
            fData.Po_1D_HeadingOfVessel                 = S7Kdata.R1015_Navigation.Heading;
            fData.Po_1D_MeasureOfPositionFixQuality     = S7Kdata.R1015_Navigation.HorizontalPositionAccuracy;
            fData.Po_1D_PositionSystemDescriptor        = ones(size(S7Kdata.R1015_Navigation.Date)); % dummy values to match needed field for Kongsberg
            
        elseif isfield(S7Kdata,'R1003_Position')
            
            fData.Po_1D_Date                            = S7Kdata.R1003_Position.Date;
            fData.Po_1D_TimeSinceMidnightInMilliseconds = S7Kdata.R1003_Position.TimeSinceMidnightInMilliseconds;
            fData.Po_1D_PositionCounter                 = 1:numel(S7Kdata.R1003_Position.Date);    % dummy values
            fData.Po_1D_MeasureOfPositionFixQuality     = ones(size(S7Kdata.R1003_Position.Date)); % dummy values
            fData.Po_1D_PositionSystemDescriptor        = S7Kdata.R1003_Position.PositioningMethod;
            
            if  S7Kdata.R1003_Position.Datum_id(1) == 0
                
                % lat and long
                fData.Po_1D_Latitude  = S7Kdata.R1003_Position.Latitude;
                fData.Po_1D_Longitude = S7Kdata.R1003_Position.Longitude;
                
                % calculating speed of vessel, and heading based on lat/long
                nb_pt = numel(fData.Po_1D_Latitude);
                [dist_in_deg,head] = distance([fData.Po_1D_Latitude(1:nb_pt-1)' fData.Po_1D_Longitude(1:nb_pt-1)'],[fData.Po_1D_Latitude(2:nb_pt)' fData.Po_1D_Longitude(2:nb_pt)']);
                d_dist = deg2km(dist_in_deg');
                t = datenum(cellfun(@num2str,num2cell(fData.Po_1D_Date),'un',0),'yyyymmdd')'*24*60*60+fData.Po_1D_TimeSinceMidnightInMilliseconds/1e3;
                s = d_dist*1000./diff(t);
                fData.Po_1D_SpeedOfVesselOverGround = [s(1) s];
                fData.Po_1D_HeadingOfVessel         = [head(1) head'];
                
            else
                warning('Po_1D_Date: Could not find position data in the file');
            end
            
        else
            warning('Po_1D_Date: Could not find position data in the file');
        end
        
        %% EM_XYZ88
        
        if isfield(S7Kdata,'R7027_RAWdetection') %%%%TODO
            
            % only convert these datagrams if this type doesn't already exist in output
            if f_reconvert || ~isfield(fData,'X8_1P_Date')
                
                if update_mode
                    update_flag = 1;
                end
                
                nPings    = numel(S7Kdata.R7027_RAWdetection.PingNumber); % total number of pings in file
                maxnBeams=nanmax(cellfun(@nanmax,S7Kdata.R7027_RAWdetection.BeamDescriptor));
                maxnBeams = maxnBeams+1;
                
                fData.X8_1P_Date                            = S7Kdata.R7027_RAWdetection.Date;
                fData.X8_1P_TimeSinceMidnightInMilliseconds = S7Kdata.R7027_RAWdetection.TimeSinceMidnightInMilliseconds;
                fData.X8_1P_PingCounter                     = 1:nPings;
                fData.X8_1P_HeadingOfVessel                 = S7Kdata.R7027_RAWdetection.Heading;
                fData.X8_1P_SoundSpeedAtTransducer          = nan(size(fData.X8_1P_Date));
                fData.X8_1P_TransmitTransducerDepth         = nan(size(fData.X8_1P_Date));
                fData.X8_1P_NumberOfBeamsInDatagram         = S7Kdata.R7027_RAWdetection.N;
                fData.X8_1P_NumberOfValidDetections         = S7Kdata.R7027_RAWdetection.N;
                fData.X8_1P_SamplingFrequencyInHz           = S7Kdata.R7027_RAWdetection.SamplingRate;
                
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
                    iBeam = S7Kdata.R7027_RAWdetection.BeamDescriptor{iP}+1;
                    fData.X8_BP_DepthZ(iBeam,iP)                       = S7Kdata.R7027_RAWdetection.Depth{iP};
                    fData.X8_BP_AcrosstrackDistanceY(iBeam,iP)         = S7Kdata.R7027_RAWdetection.AcrossTrackDistance{iP};
                    fData.X8_BP_AlongtrackDistanceX(iBeam,iP)          = S7Kdata.R7027_RAWdetection.AlongTrackDistance{iP};
                    fData.X8_BP_DetectionWindowLength(iBeam,iP)        = NaN;
                    fData.X8_BP_QualityFactor(iBeam,iP)                = S7Kdata.R7027_RAWdetection.Quality{iP} ;
                    fData.X8_BP_BeamIncidenceAngleAdjustment(iBeam,iP) = nan;
                    fData.X8_BP_DetectionInformation(iBeam,iP)         = nan;
                    fData.X8_BP_RealTimeCleaningInformation(iBeam,iP)  = nan;
                    fData.X8_BP_ReflectivityBS(iBeam,iP)               = S7Kdata.R7027_RAWdetection.SignalStrength{iP};
                end
                fData.X8_BP_ReflectivityBS = 20*log10(fData.X8_BP_ReflectivityBS/65535);
            end
            
        end
        %% R7000_SonarSettings TODO
        
        if isfield(S7Kdata,'R7000_SonarSettings')
            if f_reconvert || ~isfield(fData,'Ru_1D_Date')
                
                if update_mode
                    update_flag = 1;
                end
                
                fData.Ru_1D_Date                            = S7Kdata.R7000_SonarSettings.Date;
                fData.Ru_1D_TimeSinceMidnightInMilliseconds = S7Kdata.R7000_SonarSettings.TimeSinceMidnightInMilliseconds;
                fData.Ru_1D_PingCounter                     = S7Kdata.R7000_SonarSettings.PingNumber;
                % the rest to code... XXX2
                fData.Ru_1D_TransmitPowerReMaximum          = pow2db(S7Kdata.R7000_SonarSettings.PowerSelection);
                fData.Ru_1D_ReceiveBeamwidth                = S7Kdata.R7000_SonarSettings.ReceiveBeamWidthRad/pi*180;
                % the rest to code... XXX2
                
            end
        end
        
        
        %% R7018_7kBeamformedData TODO
        
        if isfield(S7Kdata,'R7018_7kBeamformedData')
            if f_reconvert || ~isfield(fData,'WC_1P_Date')
                if update_mode
                    update_flag = 1;
                end
                
                % get indices of first datagram for each ping
                pingNumber=1:numel(S7Kdata.R7018_7kBeamformedData.SonarId);
                maxnBeams=nanmax(S7Kdata.R7018_7kBeamformedData.N);
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
                fData.WC_1P_TVGOffset                       = zeros(size(pingNumber));
                fData.WC_1P_ScanningInfo                    = nan(size(pingNumber));
                
                % initialize data per transmit sector and ping
                fData.WC_TP_TiltAngle            = nan(maxNTransmitSectors,nPings);
                fData.WC_TP_CenterFrequency      = S7Kdata.R7000_SonarSettings.Frequency;
                fData.WC_TP_TransmitSectorNumber = nan(maxNTransmitSectors,nPings);
                
                % initialize data per decimated beam and ping
                fData.WC_BP_BeamPointingAngle      = nan(maxnBeams,nPings);
                fData.WC_BP_StartRangeSampleNumber = nan(maxnBeams,nPings);
                fData.WC_BP_NumberOfSamples        = nan(maxnBeams,nPings);
                fData.WC_BP_DetectedRangeInSamples = zeros(maxnBeams,nPings);
                fData.WC_BP_TransmitSectorNumber   = ones(maxnBeams,nPings);
                fData.WC_BP_BeamNumber             = nan(maxnBeams,nPings);
                
                
                [maxNSamples_groups,ping_group_start,ping_group_end]=CFF_group_pings(S7Kdata.R7018_7kBeamformedData.S,pingNumber,pingNumber);
                
                % The actual water-column data will not be saved in fData
                % but in binary files. Get the output directory to store
                % those files 
                wc_dir = CFF_converted_data_folder(fData.ALLfilename{iF});
                
                % Clean up that folder first before adding anything to it
                CFF_clean_delete_fdata(wc_dir);
                
                % save info about data format for later access
                fData.WC_1_SampleAmplitudes_Class  = 'int16';
                fData.WC_1_SampleAmplitudes_Nanval = intmin('int16');
                fData.WC_1_SampleAmplitudes_Factor = 1/200;
                fData.WC_1_SamplePhase_Class  = 'int16';
                fData.WC_1_SamplePhase_Nanval = 200;
                fData.WC_1_SamplePhase_Factor = 1;
                
                % initialize data-holding binary files
                fData = CFF_init_memmapfiles(fData, ...
                    'field', 'WC_SBP_SampleAmplitudes', ...
                    'wc_dir', wc_dir, ...
                    'Class', 'int16', ...
                    'Factor', 1/200, ...
                    'Nanval', intmin('int16'), ...
                    'Offset', 0, ...
                    'MaxSamples', maxNSamples_groups, ...
                    'MaxBeams', maxnBeams, ...
                    'ping_group_start', ping_group_start, ...
                    'ping_group_end', ping_group_end);
                
                fData = CFF_init_memmapfiles(fData, ...
                    'field', 'WC_SBP_SamplePhase', ...
                    'wc_dir', wc_dir, ...
                    'Class', 'int16', ...
                    'Factor', 1/10430/pi*180, ...
                    'Nanval', 200, ...
                    'Offset', 0, ...
                    'MaxSamples', maxNSamples_groups, ...
                    'MaxBeams', maxnBeams, ...
                    'ping_group_start', ping_group_start, ...
                    'ping_group_end', ping_group_end);
                
                % Also the samples data were not recorded in ALLdata, only
                % their location in the source file, so we need to fopen
                % the source file to grab the data.
                fid = fopen(fData.ALLfilename{iF},'r',S7Kdata.datagramsformat);
                
                % initialize ping group counter, to use to specify which memmapfile
                % to fill. We start in the first.
                iG=1;
                
                % now get data for each ping
                
                mag_fmt='uint16';
                
                % now get data for each ping
                for iP = 1:nPings
                    if iP>ping_group_end(iG)
                        iG=iG+1;
                    end
                    
                    fseek(fid,S7Kdata.R7018_7kBeamformedData.BeamformedDataPos(iP),'bof');
                    Mag_tmp=(fread(fid,[S7Kdata.R7018_7kBeamformedData.N(iP) S7Kdata.R7018_7kBeamformedData.S(iP)],'uint16',2))';
                    fseek(fid,S7Kdata.R7018_7kBeamformedData.BeamformedDataPos(iP)+2,'bof');
                    Ph_tmp=(fread(fid,[S7Kdata.R7018_7kBeamformedData.N(iP) S7Kdata.R7018_7kBeamformedData.S(iP)],'int16=>int16',2))';
                    
                    Mag_tmp(Mag_tmp==eval([mag_fmt '(-inf)']))=eval([mag_fmt '(-inf)']);
                    Mag_tmp=20*log10(Mag_tmp/double(intmax('uint16')))/fData.WC_1_SampleAmplitudes_Factor;
                    
                    fData.WC_SBP_SampleAmplitudes{iG}.Data.val(:,:,iP-ping_group_start(iG)+1)=int16(Mag_tmp);
                    fData.WC_SBP_SamplePhase{iG}.Data.val(:,:,iP-ping_group_start(iG)+1)=Ph_temp;
                    
                end
                
                % close the original raw file
                fclose(fid);
                
            end
        end
        
        
        %% R7042_CompressedWaterColumn
        
        if isfield(S7Kdata,'R7042_CompressedWaterColumn')
            
            % only convert these datagrams if this type doesn't already exist in output
            if f_reconvert || ~isfield(fData,'AP_1P_Date')
                
                if update_mode
                    update_flag = 1;
                end
                
                % number of pings
                nPings = numel(S7Kdata.R7042_CompressedWaterColumn.SonarId); % number of datagrams/pings
                pingNumber = 1:nPings; % ping counter
                
                % number of Tx sectors
                maxNTransmitSectors = 1;
                
                % number of beams
                nBeams = cellfun(@numel,S7Kdata.R7042_CompressedWaterColumn.BeamNumber); % number of beams per ping
                maxnBeams = nanmax(nBeams); % maximum number of beams in file
                
                % number of samples
                % maxNSamples = nanmax(S7Kdata.R7042_CompressedWaterColumn.FirstSample+cellfun(@nanmax,S7Kdata.R7042_CompressedWaterColumn.NumberOfSamples));
                dtg_nSamples = S7Kdata.R7042_CompressedWaterColumn.NumberOfSamples; % number of samples per datagram and beam
                [maxNSamples_groups, ping_group_start, ping_group_end] = CFF_group_pings(dtg_nSamples,pingNumber,pingNumber); % making groups of pings to limit size of memmaped files
                
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
                fData.AP_1P_TVGOffset                       = zeros(size(pingNumber));
                fData.AP_1P_ScanningInfo                    = nan(size(pingNumber));
                
                % initialize data per transmit sector and ping
                fData.AP_TP_TiltAngle            = nan(maxNTransmitSectors,nPings);
                fData.AP_TP_CenterFrequency      = S7Kdata.R7000_SonarSettings.Frequency;
                fData.AP_TP_TransmitSectorNumber = nan(maxNTransmitSectors,nPings);
                
                % initialize data per decimated beam and ping
                fData.AP_BP_BeamPointingAngle      = nan(maxnBeams,nPings);
                fData.AP_BP_StartRangeSampleNumber = nan(maxnBeams,nPings);
                fData.AP_BP_NumberOfSamples        = nan(maxnBeams,nPings);
                fData.AP_BP_DetectedRangeInSamples = zeros(maxnBeams,nPings);
                fData.AP_BP_TransmitSectorNumber   = nan(maxnBeams,nPings);
                fData.AP_BP_BeamNumber             = nan(maxnBeams,nPings);
                
                % flags indicating what data are available
                [flags,sample_size,mag_fmt,phase_fmt] = CFF_get_R7042_flags(S7Kdata.R7042_CompressedWaterColumn.Flags(1));
                
                % The actual water-column data will not be saved in fData
                % but in binary files. Get the output directory to store
                % those files 
                wc_dir = CFF_converted_data_folder(fData.ALLfilename{iF});
                
                % Clean up that folder first before adding anything to it
                CFF_clean_delete_fdata(wc_dir);
                
                % amplitude format
                switch mag_fmt
                    case 'int8'
                        mag_file_fmt = 'int8';
                        mag_fact = 1;
                    case {'uint16', 'float32'}
                        mag_file_fmt = 'int16';
                        mag_fact = 1/200;
                end
                
                % initialize data-holding binary files for Amplitude
                fData = CFF_init_memmapfiles(fData,...
                    'field', 'AP_SBP_SampleAmplitudes', ...
                    'wc_dir', wc_dir, ...
                    'Class', mag_file_fmt, ...
                    'Factor', mag_fact, ...
                    'Nanval', intmin(mag_file_fmt), ...
                    'Offset', 0, ...
                    'MaxSamples', maxNSamples_groups, ...
                    'MaxBeams', maxnBeams, ...
                    'ping_group_start', ping_group_start, ...
                    'ping_group_end', ping_group_end);
                

                % do the same for phase if it's available
                if ~flags.magnitudeOnly
                    
                    % phase format
                    switch phase_fmt
                        case 'int8'
                            phase_fact = 360/256;
                        case 'int16'
                            phase_fact = 180/pi/10430;
                    end
                    
                    % initialize data-holding binary files for Phase
                    fData = CFF_init_memmapfiles(fData, ...
                        'field', 'AP_SBP_SamplePhase', ...
                        'wc_dir', wc_dir, ...
                        'Class', phase_fmt, ...
                        'Factor', phase_fact, ...
                        'Nanval', 200, ...
                        'Offset', 0, ...
                        'MaxSamples', maxNSamples_groups, ...
                        'MaxBeams', maxnBeams, ...
                        'ping_group_start', ping_group_start, ...
                        'ping_group_end', ping_group_end);
                    
                end
                
                % Also the samples data were not recorded in ALLdata, only
                % their location in the source file, so we need to fopen
                % the source file to grab the data.
                fid = fopen(fData.ALLfilename{iF},'r',S7Kdata.datagramsformat);

                % correct sampling frequency record
                if flags.downsamplingType > 0
                    fData.AP_1P_SamplingFrequencyHz = fData.AP_1P_SamplingFrequencyHz./flags.downsamplingDivisor;
                end
                
                % initialize ping group counter, to use to specify which memmapfile
                % to fill. We start in the first.
                iG = 1;
                
                % debug graph
                disp_wc = 0;
                if disp_wc
                    f = figure();
                    if flags.magnitudeOnly
                        ax_mag = axes(f,'outerposition',[0 0 1 1]);
                    else
                        ax_mag = axes(f,'outerposition',[0 0.5 1 0.5]);
                        ax_phase = axes(f,'outerposition',[0 0 1 0.5]);
                    end
                end
                
                % now get data for each ping
                for iP = 1:nPings
                    
                    % update ping group counter if needed
                    if iP > ping_group_end(iG)
                        iG = iG+1;
                    end
                    
                    % data per Tx sector
                    nTransmitSectors = fData.AP_1P_NumberOfTransmitSectors(1,iP); % number of transmit sectors in this ping
                    fData.AP_TP_TiltAngle(1:nTransmitSectors,iP)            = zeros(nTransmitSectors,1);
                    fData.AP_TP_CenterFrequency(1:nTransmitSectors,iP)      = S7Kdata.R7000_SonarSettings.Frequency(iP)*ones(nTransmitSectors,1);
                    fData.AP_TP_TransmitSectorNumber(1:nTransmitSectors,iP) = 1:nTransmitSectors;
                    
                    % data per beam
                    iBeam = S7Kdata.R7042_CompressedWaterColumn.BeamNumber{iP}+1; % beam numbers in this ping
                    fData.AP_BP_BeamPointingAngle(iBeam,iP)      = S7Kdata.R7004_7kBeamGeometry.BeamHorizontalDirectionAngleRad{iP}/pi*180;
                    fData.AP_BP_StartRangeSampleNumber(iBeam,iP) = round(S7Kdata.R7042_CompressedWaterColumn.FirstSample(iP));
                    fData.AP_BP_NumberOfSamples(iBeam,iP)        = round(S7Kdata.R7042_CompressedWaterColumn.NumberOfSamples{iP});
                    fData.AP_BP_DetectedRangeInSamples(S7Kdata.R7027_RAWdetection.BeamDescriptor{iP}+1,iP) = round(S7Kdata.R7027_RAWdetection.DetectionPoint{iP}/flags.downsamplingDivisor);
                    fData.AP_BP_TransmitSectorNumber(iBeam,iP)   = 1;
                    fData.AP_BP_BeamNumber(iBeam,iP)             = S7Kdata.R7004_7kBeamGeometry.N(iP); % from R7004??? XXX1
                    
                    % initialize amplitude and phase matrices
                    Mag_tmp = ones(maxNSamples_groups(iG),maxnBeams,mag_fmt)*eval([mag_fmt '(-inf)']);
                    if ~flags.magnitudeOnly
                        Ph_tmp = zeros(maxNSamples_groups(iG),maxnBeams,phase_fmt);
                    end
                    
                    % number of samples for each beam in this ping
                    nSamples = S7Kdata.R7042_CompressedWaterColumn.NumberOfSamples{iP};
                    
                    % got to start of data in raw file, from here
                    pos = ftell(fid);
                    fseek(fid,S7Kdata.R7042_CompressedWaterColumn.SampleStartPositionInFile{iP}(1)-pos,'cof');
                    
                    % read the ping's data as int8, between the start
                    % position for the first beam's data and the end
                    % position of the last beam's data
                    pos_start_ping = S7Kdata.R7042_CompressedWaterColumn.SampleStartPositionInFile{iP}(1);
                    pos_end_ping = S7Kdata.R7042_CompressedWaterColumn.SampleStartPositionInFile{iP}(end)+nSamples(end)*sample_size;
                    DataSamples_tot = fread(fid,pos_end_ping-pos_start_ping+1,'int8=>int8');
                    
                    % index of first sample
                    start_sample = S7Kdata.R7042_CompressedWaterColumn.FirstSample(iP)+1;
                    
                    % read beam by beam
                    for jj = 1:S7Kdata.R7004_7kBeamGeometry.N(iP)  % from R7004??? XXX1
                        
                        % get data for that beam
                        idx_pp = S7Kdata.R7042_CompressedWaterColumn.SampleStartPositionInFile{iP}(jj):(S7Kdata.R7042_CompressedWaterColumn.SampleStartPositionInFile{iP}(jj)+nSamples(jj)*sample_size-1);
                        idx_pp = idx_pp-pos_start_ping+1;
                        DataSamples_tmp = DataSamples_tot(idx_pp);
                        
                        if flags.magnitudeOnly
                            % data are amplitude only
                            switch mag_fmt
                                % read amplitude data
                                case 'int8'
                                    Mag_tmp((start_sample:start_sample+nSamples(jj)-1),jj) = DataSamples_tmp;
                                case 'uint16'
                                    Mag_tmp((start_sample:start_sample+nSamples(jj)-1),jj) = typecast(DataSamples_tmp,mag_fmt);
                                case 'float32'
                                    Mag_tmp((start_sample:start_sample+nSamples(jj)-1),jj) = 10*log10(typecast(DataSamples_tmp,mag_fmt));
                                otherwise
                                    warning('WC compression flag issue');
                            end
                        else
                            % data are amplitude AND phase
                            switch mag_fmt
                                % read amplitude data
                                case 'int8'
                                    Mag_tmp((start_sample:start_sample+nSamples(jj)-1),jj) = DataSamples_tmp(1:2:end,:);
                                case 'uint16'
                                    idx_tot = rem(1:numel(DataSamples_tmp),4);
                                    idx_mag = idx_tot==1 | idx_tot==2;
                                    Mag_tmp((start_sample:start_sample+nSamples(jj)-1),jj) = typecast(DataSamples_tmp(idx_mag,:),mag_fmt);
                                otherwise
                                    warning('WC compression flag issue');
                            end
                            switch phase_fmt
                                % read phase data
                                case'int8'
                                    Ph_tmp((start_sample:start_sample+nSamples(jj)-1),jj) = DataSamples_tmp(2:2:end,:);
                                case 'int16'
                                    idx_tot = rem(1:numel(DataSamples_tmp),4);
                                    idx_phase = idx_tot==3 | idx_tot==0;
                                    Ph_tmp((start_sample:start_sample+nSamples(jj)-1),jj) = typecast(DataSamples_tmp(idx_phase,:),phase_fmt);
                                otherwise
                                    warning('WC compression flag issue');
                            end
                        end
                        
                    end
                    
                    % debug graph
                    if disp_wc
                        % display amplitude
                        switch mag_fmt
                            case 'int8'
                                imagesc(ax_mag,double(Mag_tmp)-128);
                            case 'uint16'
                                imagesc(ax_mag,10*log10(double(Mag_tmp)/double(intmax('int16'))));
                        end
                        caxis(ax_mag,[-100 -20]);
                        colorbar
                        title(sprintf('ping %i/%i',iP,nPings));
                        % display phase
                        if ~flags.magnitudeOnly
                            imagesc(ax_phase,Ph_tmp*phase_fact);
                            colorbar
                        end
                        drawnow;
                    end
                    
                    % reformat amplitude data for storing
                    switch mag_fmt
                        case 'int8'
                            Mag_tmp = Mag_tmp - int8(128);
                        case 'uint16'
                            idx0 = Mag_tmp==0;
                            Mag_tmp = (10*log10(double(Mag_tmp)/double(intmax('uint16')))/mag_fact);
                            Mag_tmp(idx0) = -inf;
                            Mag_tmp = int16(Mag_tmp);
                        case 'float32'
                            Mag_tmp = int16(Mag_tmp/mag_fact);
                    end
                    
                    % finished reading this ping's WC data. Store the data in the
                    % appropriate binary file, at the appropriate ping, through the
                    % memory mapping
                    fData.AP_SBP_SampleAmplitudes{iG}.Data.val(:,:,iP-ping_group_start(iG)+1) = Mag_tmp;
                    if ~flags.magnitudeOnly
                        fData.AP_SBP_SamplePhase{iG}.Data.val(:,:,iP-ping_group_start(iG)+1) = Ph_tmp;
                    end
                    
                end
                
                                
                % close the original raw file
                fclose(fid);
                
            end
            
        end
        
    end
    
end