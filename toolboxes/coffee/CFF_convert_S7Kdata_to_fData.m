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
    ping_number=S7Kdata.R7000_SonarSettings.PingNumber;
    ping_date=S7Kdata.R7000_SonarSettings.Date;
    ping_TSMIM=S7Kdata.R7000_SonarSettings.TimeSinceMidnightInMilliseconds;
    ping_time=cellfun(@(x) datenum(x,'yyyymmdd'),ping_date)+ping_TSMIM/(24*60*60*1e3);
    
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
            fData.He_1D_HeightCounter                   = 1:numel(S7Kdata.R1015_Navigation.Date);
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
        end
        
    elseif isfield(S7Kdata,'R1003_Position')
        
        
        if update_mode
            update_flag = 1;
        end
        
        % NumberOfDatagrams = length(S7Kdata.EM_Position.TypeOfDatagram);
        
        fData.Po_1D_Date                            = S7Kdata.R1003_Position.Date;
        fData.Po_1D_TimeSinceMidnightInMilliseconds = S7Kdata.R1003_Position.TimeSinceMidnightInMilliseconds;
        fData.Po_1D_PositionCounter                 = 1:numel(S7Kdata.R1003_Position.Date);
        
        if  S7Kdata.R1003_Position.Datum_id(i1003)==0
            fData.Po_1D_Latitude                        = S7Kdata.R1003_Position.Latitude;
            fData.Po_1D_Longitude                       = S7Kdata.R1003_Position.Longitude;
            nb_pt=numel(fData.Po_1D_Latitude);
            [dist_in_deg,head]=distance([fData.Po_1D_Latitude(1:nb_pt-1) fData.Po_1D_Longitude(1:nb_pt-1)],[fData.Po_1D_Latitude(2:nb_pt) fData.Po_1D_Longitude(2:nb_pt)]);
            d_dist=[0 deg2km(dist_in_deg)];
            t=cellfun(@(x) datenum(x,'yyyymmdd'),fData.Po_1D_Date)*24*60*60+fData.Po_1D_TimeSinceMidnightInMilliseconds/1e3;
            s=d_dist*1000/diff(t);
            fData.Po_1D_SpeedOfVesselOverGround =[s(1) s];
            fData.Po_1D_HeadingOfVessel =[head(1) head];
            
        else
            warning('Po_1D_Date:Could not find position data in the file');
        end
        
    else
        warning('Po_1D_Date:Could not find position data in the file');
    end
end




%% EM_XYZ88

if isfield(S7Kdata,'EM_XYZ88') %%%%TODO
    
    % only convert these datagrams if this type doesn't already exist in output
    if ~isfield(fData,'X8_1P_Date')
        
        if update_mode
            update_flag = 1;
        end
        
        NumberOfPings    = length(S7Kdata.EM_XYZ88.TypeOfDatagram); % total number of pings in file
        MaxNumberOfBeams = max(S7Kdata.EM_XYZ88.NumberOfBeamsInDatagram); % maximum beam number in file
        
        fData.X8_1P_Date                            = S7Kdata.EM_XYZ88.Date;
        fData.X8_1P_TimeSinceMidnightInMilliseconds = S7Kdata.EM_XYZ88.TimeSinceMidnightInMilliseconds;
        fData.X8_1P_PingCounter                     = S7Kdata.EM_XYZ88.PingCounter;
        fData.X8_1P_HeadingOfVessel                 = S7Kdata.EM_XYZ88.HeadingOfVessel;
        fData.X8_1P_SoundSpeedAtTransducer          = S7Kdata.EM_XYZ88.SoundSpeedAtTransducer;
        fData.X8_1P_TransmitTransducerDepth         = S7Kdata.EM_XYZ88.TransmitTransducerDepth;
        fData.X8_1P_NumberOfBeamsInDatagram         = S7Kdata.EM_XYZ88.NumberOfBeamsInDatagram;
        fData.X8_1P_NumberOfValidDetections         = S7Kdata.EM_XYZ88.NumberOfValidDetections;
        fData.X8_1P_SamplingFrequencyInHz           = S7Kdata.EM_XYZ88.SamplingFrequencyInHz;
        
        % initialize
        fData.X8_BP_DepthZ                       = nan(MaxNumberOfBeams,NumberOfPings);
        fData.X8_BP_AcrosstrackDistanceY         = nan(MaxNumberOfBeams,NumberOfPings);
        fData.X8_BP_AlongtrackDistanceX          = nan(MaxNumberOfBeams,NumberOfPings);
        fData.X8_BP_DetectionWindowLength        = nan(MaxNumberOfBeams,NumberOfPings);
        fData.X8_BP_QualityFactor                = nan(MaxNumberOfBeams,NumberOfPings);
        fData.X8_BP_BeamIncidenceAngleAdjustment = nan(MaxNumberOfBeams,NumberOfPings);
        fData.X8_BP_DetectionInformation         = nan(MaxNumberOfBeams,NumberOfPings);
        fData.X8_BP_RealTimeCleaningInformation  = nan(MaxNumberOfBeams,NumberOfPings);
        fData.X8_BP_ReflectivityBS               = nan(MaxNumberOfBeams,NumberOfPings);
        fData.X8_B1_BeamNumber                   = (1:MaxNumberOfBeams)';
        
        for iP = 1:NumberOfPings
            
            fData.X8_BP_DepthZ(1:MaxNumberOfBeams,iP)                       = cell2mat(S7Kdata.EM_XYZ88.DepthZ(iP));
            fData.X8_BP_AcrosstrackDistanceY(1:MaxNumberOfBeams,iP)         = cell2mat(S7Kdata.EM_XYZ88.AcrosstrackDistanceY(iP));
            fData.X8_BP_AlongtrackDistanceX(1:MaxNumberOfBeams,iP)          = cell2mat(S7Kdata.EM_XYZ88.AlongtrackDistanceX(iP));
            fData.X8_BP_DetectionWindowLength(1:MaxNumberOfBeams,iP)        = cell2mat(S7Kdata.EM_XYZ88.DetectionWindowLength(iP));
            fData.X8_BP_QualityFactor(1:MaxNumberOfBeams,iP)                = cell2mat(S7Kdata.EM_XYZ88.QualityFactor(iP));
            fData.X8_BP_BeamIncidenceAngleAdjustment(1:MaxNumberOfBeams,iP) = cell2mat(S7Kdata.EM_XYZ88.BeamIncidenceAngleAdjustment(iP));
            fData.X8_BP_DetectionInformation(1:MaxNumberOfBeams,iP)         = cell2mat(S7Kdata.EM_XYZ88.DetectionInformation(iP));
            fData.X8_BP_RealTimeCleaningInformation(1:MaxNumberOfBeams,iP)  = cell2mat(S7Kdata.EM_XYZ88.RealTimeCleaningInformation(iP));
            fData.X8_BP_ReflectivityBS(1:MaxNumberOfBeams,iP)               = cell2mat(S7Kdata.EM_XYZ88.ReflectivityBS(iP));
            
        end
        
    end
    
end



%% EM_WaterColumn (v2 verified)

if isfield(S7Kdata,'EM_WaterColumn') %%TODOOO
    
    % only convert these datagrams if this type doesn't already exist in output
    if ~isfield(fData,'WC_1P_Date') || fData.dr_sub~=dr_sub || fData.db_sub~=db_sub
        
        if update_mode
            update_flag = 1;
        end
        
        % get the number of heads
        headNumber = unique(S7Kdata.EM_WaterColumn.SystemSerialNumber,'stable');
        
        % get the list of pings and the index of first datagram for
        % each ping
        if length(headNumber) == 1
            % if only one head...
            [pingCounters, iFirstDatagram] = unique(S7Kdata.EM_WaterColumn.PingCounter,'stable');
        else
            % in case there's more than one head, we're going to only
            % keep pings for which we have data for all heads
            
            % pings for first head
            pingCounters = unique(S7Kdata.EM_WaterColumn.PingCounter(S7Kdata.EM_WaterColumn.SystemSerialNumber==headNumber(1)),'stable');
            
            % for each other head, get ping numbers and only keep
            % intersection
            for iH = 2:length(headNumber)
                pingCountersOtherHead = unique(S7Kdata.EM_WaterColumn.PingCounter(S7Kdata.EM_WaterColumn.SystemSerialNumber==headNumber(iH)),'stable');
                pingCounters = intersect(pingCounters, pingCountersOtherHead);
            end
            
            % get the index of first datagram for each ping and each
            % head
            for iH = 1:length(headNumber)
                iFirstDatagram(:,iH) = find( S7Kdata.EM_WaterColumn.SystemSerialNumber == headNumber(iH) & ...
                    ismember(S7Kdata.EM_WaterColumn.PingCounter,pingCounters) & ...
                    S7Kdata.EM_WaterColumn.DatagramNumbers == 1);
            end
        end
        
        % save ping numbers
        fData.WC_1P_PingCounter = pingCounters;
        
        % for the following fields, take value from first datagram in
        % first head
        fData.WC_1P_Date                            = S7Kdata.EM_WaterColumn.Date(iFirstDatagram(:,1));
        fData.WC_1P_TimeSinceMidnightInMilliseconds = S7Kdata.EM_WaterColumn.TimeSinceMidnightInMilliseconds(iFirstDatagram(:,1));
        fData.WC_1P_SoundSpeed                      = S7Kdata.EM_WaterColumn.SoundSpeed(iFirstDatagram(:,1));
        fData.WC_1P_OriginalSamplingFrequencyHz     = S7Kdata.EM_WaterColumn.SamplingFrequency(iFirstDatagram(:,1)).*0.01; % in Hz
        fData.WC_1P_SamplingFrequencyHz             = (S7Kdata.EM_WaterColumn.SamplingFrequency(iFirstDatagram(:,1)).*0.01)./dr_sub; % in Hz
        fData.WC_1P_TXTimeHeave                     = S7Kdata.EM_WaterColumn.TXTimeHeave(iFirstDatagram(:,1));
        fData.WC_1P_TVGFunctionApplied              = S7Kdata.EM_WaterColumn.TVGFunctionApplied(iFirstDatagram(:,1));
        fData.WC_1P_TVGOffset                       = S7Kdata.EM_WaterColumn.TVGOffset(iFirstDatagram(:,1));
        fData.WC_1P_ScanningInfo                    = S7Kdata.EM_WaterColumn.ScanningInfo(iFirstDatagram(:,1));
        
        % test for inconsistencies between heads and raise a warning if
        % one is detected
        if length(headNumber) > 1
            fields = {'Date','TimeSinceMidnightInMilliseconds','SoundSpeed','SamplingFrequency','TXTimeHeave','TVGFunctionApplied','TVGOffset','ScanningInfo'};
            for iF = 1:length(fields)
                if any(any(S7Kdata.EM_WaterColumn.(fields{iF})(iFirstDatagram(:,1))'.*ones(1,length(headNumber))~=S7Kdata.EM_WaterColumn.(fields{iF})(iFirstDatagram)))
                    warning(sprintf('System has more than one head and "%s" data are inconsistent between heads for at least one ping. Using information from first head anyway.',fields{iF}));
                end
            end
        end
        
        % for the other fields, sum the numbers from heads
        if length(headNumber) > 1
            fData.WC_1P_NumberOfDatagrams                  = sum(S7Kdata.EM_WaterColumn.NumberOfDatagrams(iFirstDatagram),2)';
            fData.WC_1P_NumberOfTransmitSectors            = sum(S7Kdata.EM_WaterColumn.NumberOfTransmitSectors(iFirstDatagram),2)';
            fData.WC_1P_OriginalTotalNumberOfReceiveBeams  = sum(S7Kdata.EM_WaterColumn.TotalNumberOfReceiveBeams(iFirstDatagram),2)';
            fData.WC_1P_TotalNumberOfReceiveBeams          = sum(ceil(S7Kdata.EM_WaterColumn.TotalNumberOfReceiveBeams(iFirstDatagram)/db_sub),2)'; % each head is decimated in beam individually
        else
            fData.WC_1P_NumberOfDatagrams                  = S7Kdata.EM_WaterColumn.NumberOfDatagrams(iFirstDatagram);
            fData.WC_1P_NumberOfTransmitSectors            = S7Kdata.EM_WaterColumn.NumberOfTransmitSectors(iFirstDatagram);
            fData.WC_1P_OriginalTotalNumberOfReceiveBeams  = S7Kdata.EM_WaterColumn.TotalNumberOfReceiveBeams(iFirstDatagram);
            fData.WC_1P_TotalNumberOfReceiveBeams          = ceil(S7Kdata.EM_WaterColumn.TotalNumberOfReceiveBeams(iFirstDatagram)/db_sub); % each head is decimated in beam individually
        end
        
        % get number of pings, maximum number of transmit sectors,
        % maximum number of receive beams and maximum number of samples
        % in any given ping to use as the output data dimensions
        nPings              = length(pingCounters);
        maxNTransmitSectors = max(fData.WC_1P_NumberOfTransmitSectors);
        maxNBeams           = max(fData.WC_1P_OriginalTotalNumberOfReceiveBeams);
        maxNBeams_sub       = max(fData.WC_1P_TotalNumberOfReceiveBeams); % number of beams to extract (decimated)
        maxNSamples         = max(cellfun(@(x) max(x), S7Kdata.EM_WaterColumn.NumberOfSamples(ismember(S7Kdata.EM_WaterColumn.PingCounter,pingCounters))));
        maxNSamples_sub     = ceil(maxNSamples/dr_sub); % number of samples to extract (decimated)
        
        % initialize data per transmit sector and ping
        fData.WC_TP_TiltAngle            = nan(maxNTransmitSectors,nPings);
        fData.WC_TP_CenterFrequency      = nan(maxNTransmitSectors,nPings);
        fData.WC_TP_TransmitSectorNumber = nan(maxNTransmitSectors,nPings);
        fData.WC_TP_SystemSerialNumber   = nan(maxNTransmitSectors,nPings);
        
        % initialize data per decimated beam and ping
        fData.WC_BP_BeamPointingAngle      = nan(maxNBeams_sub,nPings);
        fData.WC_BP_StartRangeSampleNumber = nan(maxNBeams_sub,nPings);
        fData.WC_BP_NumberOfSamples        = nan(maxNBeams_sub,nPings);
        fData.WC_BP_DetectedRangeInSamples = zeros(maxNBeams_sub,nPings);
        fData.WC_BP_TransmitSectorNumber   = nan(maxNBeams_sub,nPings);
        fData.WC_BP_BeamNumber             = nan(maxNBeams_sub,nPings);
        fData.WC_BP_SystemSerialNumber     = nan(maxNBeams_sub,nPings);
        
        % path to binary file for WC data
        file_binary = fullfile(wc_dir,'WC_SBP_SampleAmplitudes.dat');
        
        % if file does not exist or we're re-sampling it, create a new
        % one ready for writing
        if ~exist(file_binary,'file') || fData.dr_sub~=dr_sub || fData.db_sub~=db_sub
            fileID = fopen(file_binary,'w+');
        else
            % if we're here, it means the file already exists and
            % already contain the data at the proper sampling. So we
            % just need to store the metadata and link to it as
            % memmapfile.
            fileID = -1;
        end
        
        % now get data for each ping
        for iP = 1:nPings
            
            % ping number (ex: 50455)
            pingCounter = fData.WC_1P_PingCounter(1,iP);
            
            % initialize the water column data matrix for that ping.
            % Original data are in "int8" format, the NaN equivalent
            % will be -128
            if fileID >= 0
                SB_temp = zeros(maxNSamples_sub,maxNBeams_sub,'int8') - 128;
            end
            
            % intialize number of sectors and beams recorded so far for
            % that ping (needed for multiple heads)
            nTxSectTot = 0;
            nBeamTot = 0;
            
            for iH = 1:length(headNumber)
                
                headSSN = headNumber(iH);
                
                % index of the datagrams making up this ping/head in S7Kdata.EM_Watercolumn (ex: 58-59-61-64)
                iDatagrams  = find( S7Kdata.EM_WaterColumn.PingCounter == pingCounter & ...
                    S7Kdata.EM_WaterColumn.SystemSerialNumber == headSSN);
                
                % actual number of datagrams available (ex: 4)
                nDatagrams  = length(iDatagrams);
                
                % some datagrams may be missing. Need to detect and adjust.
                % order of the datagrams (ex: 4-3-6-2, the missing one is 1st, 5th and 7th)
                datagramOrder     = S7Kdata.EM_WaterColumn.DatagramNumbers(iDatagrams);
                [~,IX]            = sort(datagramOrder);
                iDatagrams        = iDatagrams(IX); % index of the datagrams making up this ping in S7Kdata.EM_Watercolumn, but in the right order (ex: 64-59-58-61, missing datagrams are still missing)
                nBeamsPerDatagram = S7Kdata.EM_WaterColumn.NumberOfBeamsInThisDatagram(iDatagrams); % number of beams in each datagram making up this ping (ex: 56-61-53-28)
                
                % number of transmit sectors to record
                nTxSect = S7Kdata.EM_WaterColumn.NumberOfTransmitSectors(iDatagrams(1));
                
                % indices of those sectors in output structure
                iTxSectDest = nTxSectTot + (1:nTxSect);
                
                % recording data per transmit sector
                fData.WC_TP_TiltAngle(iTxSectDest,iP)            = S7Kdata.EM_WaterColumn.TiltAngle{iDatagrams(1)};
                fData.WC_TP_CenterFrequency(iTxSectDest,iP)      = S7Kdata.EM_WaterColumn.CenterFrequency{iDatagrams(1)};
                fData.WC_TP_TransmitSectorNumber(iTxSectDest,iP) = S7Kdata.EM_WaterColumn.TransmitSectorNumber{iDatagrams(1)};
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
                        % if not first datagram, continue the
                        % decimation where we left it
                        nBeamsLastDatag = nBeamsPerDatagram(iD-1);
                        lastRecBeam  = iBeamSource(end);
                        iBeamStart = db_sub - (nBeamsLastDatag-lastRecBeam);
                    end
                    iBeamSource = iBeamStart:db_sub:nBeamsPerDatagram(iD);
                    
                    % number of beams to record
                    nBeam = length(iBeamSource);
                    
                    % indices of those beams in output structure
                    iBeamDest = nBeamTot + (1:nBeam);
                    
                    fData.WC_BP_BeamPointingAngle(iBeamDest,iP)      = S7Kdata.EM_WaterColumn.BeamPointingAngle{iDatagrams(iD)}(iBeamSource);
                    fData.WC_BP_StartRangeSampleNumber(iBeamDest,iP) = round(S7Kdata.EM_WaterColumn.StartRangeSampleNumber{iDatagrams(iD)}(iBeamSource)./dr_sub);
                    fData.WC_BP_NumberOfSamples(iBeamDest,iP)        = round(S7Kdata.EM_WaterColumn.NumberOfSamples{iDatagrams(iD)}(iBeamSource)./dr_sub);
                    fData.WC_BP_DetectedRangeInSamples(iBeamDest,iP) = round(S7Kdata.EM_WaterColumn.DetectedRangeInSamples{iDatagrams(iD)}(iBeamSource)./dr_sub);
                    fData.WC_BP_TransmitSectorNumber(iBeamDest,iP)   = S7Kdata.EM_WaterColumn.TransmitSectorNumber2{iDatagrams(iD)}(iBeamSource);
                    fData.WC_BP_BeamNumber(iBeamDest,iP)             = S7Kdata.EM_WaterColumn.BeamNumber{iDatagrams(iD)}(iBeamSource);
                    fData.WC_BP_SystemSerialNumber(iBeamDest,iP)     = headSSN;
                    
                    % now getting watercolumn data (beams x samples)
                    if fileID >= 0
                        
                        for iB = 1:nBeam
                            
                            % actual number of samples in that beam
                            nSamp = S7Kdata.EM_WaterColumn.NumberOfSamples{iDatagrams(iD)}(iBeamSource(iB));
                            
                            % number of samples we're going to record
                            nSamp_sub = ceil(nSamp/dr_sub);
                            
                            % read the data in original file and record
                            % water column data are recorded in "int8
                            % (-128 to 126) with -128 being the NaN
                            % value, and with a resolution of 0.5dB,
                            % aka it needs to be multiplied by a factor
                            % of 1/2 to retrieve the appropriate value,
                            % aka an int8 record of -41 is actually
                            % -20.5dB
                            pos = S7Kdata.EM_WaterColumn.SampleAmplitudePosition{iDatagrams(iD)}(iBeamSource(iB));
                            fseek(fid_all,pos,'bof');
                            SB_temp(1:nSamp_sub,nBeamTot+iB) = fread(fid_all,nSamp_sub,'int8',dr_sub-1);
                            
                        end
                        
                    end
                    
                    % updating total number of beams recorded so far
                    nBeamTot = nBeamTot + nBeam;
                    
                end
                
            end
            
            % store data on binary file
            if fileID >= 0
                fwrite(fileID,SB_temp,'int8');
            end
            
        end
        
        % close binary data file
        if fileID >= 0
            fclose(fileID);
        end
        
        % and link to it through memmapfile
        % remember data is in int8 format
        fData.WC_SBP_SampleAmplitudes = memmapfile(file_binary,'Format',{'int8' [maxNSamples_sub maxNBeams_sub nPings] 'val'},'repeat',1,'writable',true);
        
        % save info about data format for later access and conversion
        % to dB
        fData.WC_1_SampleAmplitudes_Class = 'int8';
        fData.WC_1_SampleAmplitudes_Nanval = -128;
        fData.WC_1_SampleAmplitudes_Factor = 1/2;
        
    end
end


%% EM_AmpPhase

if isfield(S7Kdata,'EM_AmpPhase') %%%TODOOOOO
    
    % only convert these datagrams if this type doesn't already exist in output
    if ~isfield(fData,'AP_1P_Date') || fData.dr_sub~=dr_sub || fData.db_sub~=db_sub
        
        if update_mode
            update_flag = 1;
        end
        
        % get indices of first datagram for each ping
        [pingCounters,iFirstDatagram] = unique(S7Kdata.EM_AmpPhase.PingCounter,'stable');
        
        % get data dimensions
        nPings              = length(pingCounters); % total number of pings in file
        maxNBeams           = max(S7Kdata.EM_AmpPhase.TotalNumberOfReceiveBeams); % maximum number of beams for a ping in file
        maxNTransmitSectors = max(S7Kdata.EM_AmpPhase.NumberOfTransmitSectors); % maximum number of transmit sectors for a ping in file
        maxNSamples         = max(cellfun(@(x) max(x),S7Kdata.EM_AmpPhase.NumberOfSamples)); % max number of samples for a beam in file
        
        % decimating beams and samples
        maxNBeams_sub       = ceil(maxNBeams/db_sub); % number of beams to extract
        maxNSamples_sub     = ceil(maxNSamples/dr_sub); % number of samples to extract
        
        % read data per ping from first datagram of each ping
        fData.AP_1P_Date                            = S7Kdata.EM_AmpPhase.Date(iFirstDatagram);
        fData.AP_1P_TimeSinceMidnightInMilliseconds = S7Kdata.EM_AmpPhase.TimeSinceMidnightInMilliseconds(iFirstDatagram);
        fData.AP_1P_PingCounter                     = S7Kdata.EM_AmpPhase.PingCounter(iFirstDatagram);
        fData.AP_1P_NumberOfDatagrams               = S7Kdata.EM_AmpPhase.NumberOfDatagrams(iFirstDatagram);
        fData.AP_1P_NumberOfTransmitSectors         = S7Kdata.EM_AmpPhase.NumberOfTransmitSectors(iFirstDatagram);
        fData.AP_1P_TotalNumberOfReceiveBeams       = S7Kdata.EM_AmpPhase.TotalNumberOfReceiveBeams(iFirstDatagram);
        fData.AP_1P_SoundSpeed                      = S7Kdata.EM_AmpPhase.SoundSpeed(iFirstDatagram);
        fData.AP_1P_SamplingFrequencyHz             = (S7Kdata.EM_AmpPhase.SamplingFrequency(iFirstDatagram).*0.01)./dr_sub; % in Hz
        fData.AP_1P_TXTimeHeave                     = S7Kdata.EM_AmpPhase.TXTimeHeave(iFirstDatagram);
        fData.AP_1P_TVGFunctionApplied              = S7Kdata.EM_AmpPhase.TVGFunctionApplied(iFirstDatagram);
        fData.AP_1P_TVGOffset                       = S7Kdata.EM_AmpPhase.TVGOffset(iFirstDatagram);
        fData.AP_1P_ScanningInfo                    = S7Kdata.EM_AmpPhase.ScanningInfo(iFirstDatagram);
        
        % initialize data per transmit sector and ping
        fData.AP_TP_TiltAngle            = nan(maxNTransmitSectors,nPings);
        fData.AP_TP_CenterFrequency      = nan(maxNTransmitSectors,nPings);
        fData.AP_TP_TransmitSectorNumber = nan(maxNTransmitSectors,nPings);
        
        % initialize data per decimated beam and ping
        fData.AP_BP_BeamPointingAngle      = nan(maxNBeams_sub,nPings);
        fData.AP_BP_StartRangeSampleNumber = nan(maxNBeams_sub,nPings);
        fData.AP_BP_NumberOfSamples        = nan(maxNBeams_sub,nPings);
        fData.AP_BP_DetectedRangeInSamples = zeros(maxNBeams_sub,nPings);
        fData.AP_BP_TransmitSectorNumber   = nan(maxNBeams_sub,nPings);
        fData.AP_BP_BeamNumber             = nan(maxNBeams_sub,nPings);
        
        % path to binary file for WC data
        file_amp_binary   = fullfile(wc_dir,'AP_SBP_SampleAmplitudes.dat');
        file_phase_binary = fullfile(wc_dir,'AP_SBP_SamplePhase.dat');
        
        % if file does not exist or we're re-sampling it, create a new
        % one ready for writing
        if exist(file_amp_binary,'file')==0 || fData.dr_sub~=dr_sub || fData.db_sub~=db_sub
            file_amp_id = fopen(file_amp_binary,'w+');
        else
            % if we're here, it means the file already exists and
            % already contain the data at the proper sampling. So we
            % just need to store the metadata and link to it as
            % memmapfile.
            file_amp_id = -1;
        end
        
        % repeat for phase file
        if exist(file_phase_binary,'file')==0 || fData.dr_sub~=dr_sub || fData.db_sub~=db_sub
            file_phase_id = fopen(file_phase_binary,'w+');
        else
            file_phase_id = -1;
        end
        
        % now get data for each ping
        for iP = 1:nPings
            
            % find datagrams composing this ping
            pingCounter = fData.AP_1P_PingCounter(1,iP); % ping number (ex: 50455)
            % nDatagrams  = fData.AP_1P_NumberOfDatagrams(1,iP); % theoretical number of datagrams for this ping (ex: 7)
            iDatagrams  = find(S7Kdata.EM_AmpPhase.PingCounter==pingCounter); % index of the datagrams making up this ping in S7Kdata.EM_AmpPhase (ex: 58-59-61-64)
            nDatagrams  = length(iDatagrams); % actual number of datagrams available (ex: 4)
            
            % some datagrams may be missing, like in the example. Detect and adjust...
            datagramOrder     = S7Kdata.EM_AmpPhase.DatagramNumbers(iDatagrams); % order of the datagrams (ex: 4-3-6-2, the missing one is 1st, 5th and 7th)
            [~,IX]            = sort(datagramOrder);
            iDatagrams        = iDatagrams(IX); % index of the datagrams making up this ping in S7Kdata.EM_AmpPhase, but in the right order (ex: 64-59-58-61, missing datagrams are still missing)
            nBeamsPerDatagram = S7Kdata.EM_AmpPhase.NumberOfBeamsInThisDatagram(iDatagrams); % number of beams in each datagram making up this ping (ex: 56-61-53-28)
            
            % assuming transmit sectors data are not split between several datagrams, get that data from the first datagram.
            nTransmitSectors = fData.AP_1P_NumberOfTransmitSectors(1,iP); % number of transmit sectors in this ping
            fData.AP_TP_TiltAngle(1:nTransmitSectors,iP)            = S7Kdata.EM_AmpPhase.TiltAngle{iDatagrams(1)};
            fData.AP_TP_CenterFrequency(1:nTransmitSectors,iP)      = S7Kdata.EM_AmpPhase.CenterFrequency{iDatagrams(1)};
            fData.AP_TP_TransmitSectorNumber(1:nTransmitSectors,iP) = S7Kdata.EM_AmpPhase.TransmitSectorNumber{iDatagrams(1)};
            
            % initialize the water column data matrix for that ping.
            if file_amp_id >= 0 || file_phase_id >= 0
                SB2_temp = zeros(maxNSamples_sub,maxNBeams_sub,'int16') - 2^15;
                Ph_temp = zeros(maxNSamples_sub,maxNBeams_sub,'int16');
            end
            
            % and then read the data in each datagram
            for iD = 1:nDatagrams
                
                % index of beams in output structure for this datagram
                [iBeams,idx_beams] = unique(ceil((sum(nBeamsPerDatagram(1:iD-1)) + (1:nBeamsPerDatagram(iD)))/db_sub));
                % old approach
                % iBeams = sum(nBeamsPerDatagram(1:iD-1)) + (1:nBeamsPerDatagram(iD));
                % idx_beams = (1:numel(iBeams));
                
                % ping x beam data
                fData.AP_BP_BeamPointingAngle(iBeams,iP)      = S7Kdata.EM_AmpPhase.BeamPointingAngle{iDatagrams(iD)}(idx_beams);
                fData.AP_BP_StartRangeSampleNumber(iBeams,iP) = round(S7Kdata.EM_AmpPhase.StartRangeSampleNumber{iDatagrams(iD)}(idx_beams)./dr_sub);
                fData.AP_BP_NumberOfSamples(iBeams,iP)        = round(S7Kdata.EM_AmpPhase.NumberOfSamples{iDatagrams(iD)}(idx_beams)./dr_sub);
                fData.AP_BP_DetectedRangeInSamples(iBeams,iP) = round(S7Kdata.EM_AmpPhase.DetectedRangeInSamples{iDatagrams(iD)}(idx_beams)./dr_sub);
                fData.AP_BP_TransmitSectorNumber(iBeams,iP)   = S7Kdata.EM_AmpPhase.TransmitSectorNumber2{iDatagrams(iD)}(idx_beams);
                fData.AP_BP_BeamNumber(iBeams,iP)             = S7Kdata.EM_AmpPhase.BeamNumber{iDatagrams(iD)}(idx_beams);
                
                % now getting watercolumn data (beams x samples)
                if file_amp_id >= 0 || file_phase_id >= 0
                    
                    for iB = 1:numel(iBeams)
                        
                        % actual number of samples in that beam
                        Ns = S7Kdata.EM_AmpPhase.NumberOfSamples{iDatagrams(iD)}(idx_beams(iB));
                        
                        % number of samples we're going to record:
                        Ns_sub = ceil(Ns/dr_sub);
                        
                        % get the data:
                        if Ns_sub > 0
                            
                            fseek(fid_all,S7Kdata.EM_AmpPhase.SamplePhaseAmplitudePosition{iDatagrams(iD)}(idx_beams(iB)),'bof');
                            tmp = fread(fid_all,Ns_sub,'uint16',2);
                            SB2_temp(1:Ns_sub,iBeams(iB)) = int16(20*log10(single(tmp)*0.0001)*40); % what is this transformation? XXX
                            
                            fseek(fid_all,S7Kdata.EM_AmpPhase.SamplePhaseAmplitudePosition{iDatagrams(iD)}(idx_beams(iB))+1,'bof');
                            tmp = fread(fid_all,Ns_sub,'int16',2);
                            Ph_temp(1:Ns_sub,iBeams(iB)) = -0.0001*single(tmp)*30/pi*180; % what is this transformation? XXX
                            
                        end
                    end
                end
            end
            
            % store amp data on binary file
            if file_amp_id >= 0
                fwrite(file_amp_id,SB2_temp,'int16');
            end
            
            % store phase data on binary file
            if file_phase_id>=0
                fwrite(file_phase_id,Ph_temp,'int16');
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
        
        % and link to them through memmapfile
        fData.AP_SBP_SampleAmplitudes = memmapfile(file_amp_binary,'Format',{'int16' [maxNSamples_sub maxNBeams_sub nPings] 'val'},'repeat',1,'writable',true);
        fData.AP_SBP_SamplePhase      = memmapfile(file_phase_binary,'Format',{'int16' [maxNSamples_sub maxNBeams_sub nPings] 'val'},'repeat',1,'writable',true);
        
        % save info about data format for later access
        fData.AP_1_SampleAmplitudes_Class  = 'int16';
        fData.AP_1_SampleAmplitudes_Nanval = int16(-inf);
        fData.AP_1_SampleAmplitudes_Factor = 1/40;
        fData.AP_1_SamplePhase_Class  = 'int16';
        fData.AP_1_SamplePhase_Nanval = 0;
        fData.AP_1_SamplePhase_Factor = 1/30;
        
    end
    
end

% close the original raw file
fclose(fid_all);

end