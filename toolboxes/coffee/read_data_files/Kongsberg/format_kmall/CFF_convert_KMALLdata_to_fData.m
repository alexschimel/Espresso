%% CFF_convert_KMALLdata_to_fData.m
%
% Function description XXX
%
%% Help
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Alexandre Schimel (NGU), Yoann Ladroit (NIWA).
% Type |help Espresso.m| for copyright information.

%% Function
function fData = CFF_convert_KMALLdata_to_fData(KMALLdataGroup,varargin)


%% input parsing

% init
p = inputParser;

% required
addRequired(p,'KMALLdataGroup',@(x) isstruct(x) || iscell(x));

% optional
addOptional(p,'dr_sub',1,@(x) isnumeric(x)&&x>0);
addOptional(p,'db_sub',1,@(x) isnumeric(x)&&x>0);

% parse
parse(p,KMALLdataGroup,varargin{:})

% get results
KMALLdataGroup = p.Results.KMALLdataGroup;
dr_sub = p.Results.dr_sub;
db_sub = p.Results.db_sub;
clear p;

%% pre-processing

if isstruct(KMALLdataGroup)
    % single KMALLdata structure
    
    % check it's from Kongsberg and that source file exist
    has_KMALLfilename = isfield(KMALLdataGroup, 'KMALLfilename');
    if ~has_KMALLfilename || ~CFF_check_KMALLfilename(KMALLdataGroup.KMALLfilename)
        error('Invalid input');
    end
    
    % if clear, turn to cell before processing further
    KMALLdataGroup = {KMALLdataGroup};
    
elseif iscell(KMALLdataGroup) && numel(KMALLdataGroup)==2
    % pair of KMALLdata structures
    
    % check it's from a pair of Kongsberg kmall/kmwcd files and that source
    % files exist
    has_KMALLfilename = cell2mat(cellfun(@(x) isfield(x, 'KMALLfilename'), KMALLdataGroup, 'UniformOutput', false));
    rawfilenames = cellfun(@(x) x.KMALLfilename, KMALLdataGroup, 'UniformOutput', false);
    if ~all(has_KMALLfilename) || ~CFF_check_KMALLfilename(rawfilenames)
        error('Invalid input');
    end
    
else
    error('Invalid input');
end

% number of individual KMALLdata structures in input KMALLdataGroup
nStruct = length(KMALLdataGroup);

% initialize fData, with current version number
fData.MET_Fmt_version = CFF_get_current_fData_version();

% initialize source filenames
fData.ALLfilename = cell(1,nStruct);


%% take one KMALLdata structure at a time and add its contents to fData
for iF = 1:nStruct
    
    % get current structure
    KMALLdata = KMALLdataGroup{iF};
    
    % add source filename
    KMALLfilename = KMALLdata.KMALLfilename;
    fData.ALLfilename{iF} = KMALLfilename;
    
    % now reading each type of datagram.
    % Note we only convert the datagrams if fData does not already contain
    % any.
    
    
    %% '#IIP - Installation parameters and sensor setup'
    if isfield(KMALLdata,'EMdgmIIP') && ~isfield(fData,'IP_ASCIIparameters')
        
        % number of entries
        % nD = numel(KMALLdata.EMdgmIIP);
        
        % get date and time-since-midnight-in-milleseconds from header
        % [fData.IP_1D_Date, fData.IP_1D_TimeSinceMidnightInMilliseconds] = CFF_get_date_and_TSMIM_from_kmall(KMALLdata.EMdgmIIP(:));
        
        % DEV NOTES: Only value Espresso needs (to date) is the "sonar
        % heading offset". In installation parameters datagrams of .all
        % files, we only had one field "S1H" per head. Here we have heading
        % values for both the Tx and Rx antennae. So not sure which one we
        % should take, or the difference between the two... but for now,
        % take the value from Rx.
        
        % read ASCIIdata
        ASCIIdata = KMALLdata.EMdgmIIP(1).install_txt;
        
        % remove carriage returns, tabs and linefeed
        ASCIIdata = regexprep(ASCIIdata,char(9),'');
        ASCIIdata = regexprep(ASCIIdata,newline,'');
        ASCIIdata = regexprep(ASCIIdata,char(13),'');
        
        % read some fields and record value in old field for the software
        % to pick up
        try
            IP_ASCIIparameters.TRAI_RX1 = CFF_read_TRAI(ASCIIdata,'TRAI_RX1');
            IP_ASCIIparameters.S1H = IP_ASCIIparameters.TRAI_RX1.H;
        catch
            % at least in some EM2040C dual head data, I've found this
            % field missing and instead having TRAI_HD1
            IP_ASCIIparameters.TRAI_HD1 = CFF_read_TRAI(ASCIIdata,'TRAI_HD1');
            IP_ASCIIparameters.S1H = IP_ASCIIparameters.TRAI_HD1.H;
        end
        
        % finally store in fData
        fData.IP_ASCIIparameters = IP_ASCIIparameters;
        
    end
    
    %% '#IOP - Runtime parameters as chosen by operator'
    if isfield(KMALLdata,'EMdgmIOP') && ~isfield(fData,'Ru_1D_Date')
        
        % number of entries
        % nD = numel(KMALLdata.EMdgmIOP);
        
        % get date and time-since-midnight-in-milleseconds from header
        [fData.Ru_1D_Date, fData.Ru_1D_TimeSinceMidnightInMilliseconds] = CFF_get_date_and_TSMIM_from_kmall(KMALLdata.EMdgmIOP(:));
        
        % DEV NOTE: In the .all format, we only record two fields from the "Runtime
        % Parameters" datagram: "TransmitPowerReMaximum" for radiometric
        % corrections, and "ReceiveBeamwidth" for estimation of the bottom
        % echo for its removal. However these are absent from #IOP
        % datagrams in kmall.
        %
        % values below are set at some random value. to find and fix XXX
        fData.Ru_1D_TransmitPowerReMaximum = 0; % MRZ seem to have several values to do proper radiometric correction
        fData.Ru_1D_ReceiveBeamwidth       = 1; % 
        
        
    end
    
    %% '#MRZ - Multibeam (M) raw range (R) and depth(Z) datagram'
    if isfield(KMALLdata,'EMdgmMRZ') && ~isfield(fData,'X8_1D_Date')
        
        % number of entries
        nPings = numel(KMALLdata.EMdgmMRZ); % total number of pings in file
        maxnBeams = max(CFF_getfield([KMALLdata.EMdgmMRZ.rxInfo],'numSoundingsMaxMain') ... % maximum beam number in file
            + CFF_getfield([KMALLdata.EMdgmMRZ.rxInfo],'numExtraDetectionClasses'));        % (include extra detections)
        
        % get date and time-since-midnight-in-milleseconds from header
        [fData.X8_1P_Date, fData.X8_1P_TimeSinceMidnightInMilliseconds] = CFF_get_date_and_TSMIM_from_kmall(KMALLdata.EMdgmMRZ(:));
        
        % data per ping
        fData.X8_1P_PingCounter                     = CFF_getfield([KMALLdata.EMdgmMRZ.cmnPart],'pingCnt'); % unused anyway
        fData.X8_1P_HeadingOfVessel                 = CFF_getfield([KMALLdata.EMdgmMRZ.pingInfo],'headingVessel_deg'); % unused anyway
        fData.X8_1P_SoundSpeedAtTransducer          = CFF_getfield([KMALLdata.EMdgmMRZ.pingInfo],'soundSpeedAtTxDepth_mPerSec'); % unused anyway
        fData.X8_1P_TransmitTransducerDepth         = CFF_getfield([KMALLdata.EMdgmMRZ.pingInfo],'txTransducerDepth_m'); % unused anyway
        fData.X8_1P_NumberOfBeamsInDatagram         = NaN; % unused anyway
        fData.X8_1P_NumberOfValidDetections         = NaN; % unused anyway
        fData.X8_1P_SamplingFrequencyInHz           = NaN; % XXX in rxInfo unused anyway
        
        % data per beam and ping
        fData.X8_BP_DepthZ                       = reshape(CFF_getfield([KMALLdata.EMdgmMRZ.sounding],'z_reRefPoint_m'),maxnBeams,nPings);
        fData.X8_BP_AcrosstrackDistanceY         = reshape(CFF_getfield([KMALLdata.EMdgmMRZ.sounding],'y_reRefPoint_m'),maxnBeams,nPings);
        fData.X8_BP_AlongtrackDistanceX          = reshape(CFF_getfield([KMALLdata.EMdgmMRZ.sounding],'x_reRefPoint_m'),maxnBeams,nPings); % unused anyway
        fData.X8_BP_DetectionWindowLength        = NaN; % unused anyway
        fData.X8_BP_QualityFactor                = reshape(CFF_getfield([KMALLdata.EMdgmMRZ.sounding],'qualityFactor'),maxnBeams,nPings); % unused anyway
        fData.X8_BP_BeamIncidenceAngleAdjustment = NaN; % unused anyway
        fData.X8_BP_DetectionInformation         = NaN; % unused anyway
        fData.X8_BP_RealTimeCleaningInformation  = NaN; % unused anyway
        fData.X8_BP_ReflectivityBS               = reshape(CFF_getfield([KMALLdata.EMdgmMRZ.sounding],'reflectivity1_dB'),maxnBeams,nPings);
        fData.X8_B1_BeamNumber                   = NaN;        % unused anyway
        
    end
    
    %% '#MWC - Multibeam (M) water (W) column (C) datagram'
    if isfield(KMALLdata,'EMdgmMWC') && ~isfield(fData,'WC_1D_Date')
        
        % DEV NOTE: kmall format doesn't fit the fData structure to date
        % (13th July 2021). fData is based on three dimensions ping x beam
        % x sample, but the lowest-level unit in kmall is the "swath" to
        % accomodate dual- and multi-swath operating modes. For example, in
        % dual-swath mode, a single Tx transducer will transmit 2 pulses to
        % create two along-swathes, and in kmall those two swathes are
        % recorded with the same ping counter because they were produced at
        % about the same time.
        % To deal with this, we're going to create new "swath numbers"
        % based on the original ping number and swath counter for a ping.
        % For example a ping #832 made up of four swathes counted 0-3 will 
        % have new "swath numbers" of 832.00, 832.01, 832.02, and 832.03.
        % We will maintain the current "ping" nomenclature in fData, but
        % using those swath numbers. Note that if we have single-swath
        % data, then the swath number matches the ping number (832).
        % Note that this is made more complicated by the fact that an
        % individual swathe can have its data on multiple consecutive
        % datagrams, as different "Rx fans" (i.e multiple Rx heads) are
        % recorded on separate datagrams.
        
        % number of datagrams
        nDatag = numel(KMALLdata.EMdgmMWC);
        
        % number of pings
        pingCnt = CFF_getfield([KMALLdata.EMdgmMWC.cmnPart],'pingCnt'); % actual ping number for each datagram
        swathAlongPosition = CFF_getfield([KMALLdata.EMdgmMWC.cmnPart],'swathAlongPosition'); % swath number for a ping number
        dtg_swath_counter = pingCnt + 0.01.*swathAlongPosition; % "new ping number" for each datagram
        [swath_counter, iFirstDatagram] = unique(dtg_swath_counter,'stable'); % list of swath numbers
        nSwaths = numel(swath_counter); % total number of swaths in file
        
        % number of beams
        nBeams_per_dtg = CFF_getfield([KMALLdata.EMdgmMWC.rxInfo],'numBeams'); % number of beams per datagram
        nBeams = arrayfun(@(x) sum(nBeams_per_dtg(dtg_swath_counter==x)), swath_counter); % total number of beams per swath
        maxnBeams = nanmax(nBeams); % maximum number of beams per swath
        maxnBeams_sub = ceil(maxnBeams/db_sub); % maximum number of beams per swath TO READ
        
        % number of samples
        dtg_nSamples = arrayfun(@(idx) [KMALLdata.EMdgmMWC(idx).beamData_p(:).numSampleData], 1:nDatag, 'UniformOutput', false); % number of samples per datagram
        [maxnSamples_groups, ping_group_start, ping_group_end] = CFF_group_pings(dtg_nSamples, swath_counter, dtg_swath_counter); % making groups of pings to limit size of memmaped files
        maxnSamples_groups = ceil(maxnSamples_groups/dr_sub); % maximum number of samples TO READ, per group.
        
        % get date and time-since-midnight-in-milleseconds from header
        [fData.WC_1P_Date, fData.WC_1P_TimeSinceMidnightInMilliseconds] = CFF_get_date_and_TSMIM_from_kmall(KMALLdata.EMdgmMWC(:));
        
        % data per ping
        fData.WC_1P_PingCounter                     = swath_counter;
        fData.WC_1P_NumberOfDatagrams               = 0; % unused anyway
        fData.WC_1P_NumberOfTransmitSectors         = 0; % unused anyway
        fData.WC_1P_TotalNumberOfReceiveBeams       = 0; % unused anyway
        fData.WC_1P_SoundSpeed                      = CFF_getfield([KMALLdata.EMdgmMWC.rxInfo],'soundVelocity_mPerSec');
        fData.WC_1P_SamplingFrequencyHz             = CFF_getfield([KMALLdata.EMdgmMWC.rxInfo],'sampleFreq_Hz');
        fData.WC_1P_TXTimeHeave                     = 0; % unused anyway
        fData.WC_1P_TVGFunctionApplied              = CFF_getfield([KMALLdata.EMdgmMWC.rxInfo],'TVGfunctionApplied');
        fData.WC_1P_TVGOffset                       = CFF_getfield([KMALLdata.EMdgmMWC.rxInfo],'TVGoffset_dB');
        fData.WC_1P_ScanningInfo                    = 0; % unused anyway
        
        % data per transmit sector and ping
        fData.WC_TP_TiltAngle            = 0; % unused anyway
        fData.WC_TP_CenterFrequency      = 0; % unused anyway
        fData.WC_TP_TransmitSectorNumber = 0; % unused anyway
        
        % data per decimated beam and ping
        fData.WC_BP_BeamPointingAngle      = reshape(CFF_getfield([KMALLdata.EMdgmMWC.beamData_p],'beamPointAngReVertical_deg'),maxnBeams_sub,nSwaths);
        fData.WC_BP_StartRangeSampleNumber = reshape(CFF_getfield([KMALLdata.EMdgmMWC.beamData_p],'startRangeSampleNum'),maxnBeams_sub,nSwaths);
        fData.WC_BP_NumberOfSamples        = reshape(CFF_getfield([KMALLdata.EMdgmMWC.beamData_p],'numSampleData'),maxnBeams_sub,nSwaths);
        fData.WC_BP_DetectedRangeInSamples = reshape(CFF_getfield([KMALLdata.EMdgmMWC.beamData_p],'detectedRangeInSamplesHighResolution'),maxnBeams_sub,nSwaths);
        fData.WC_BP_TransmitSectorNumber   = 0; % unused anyway
        fData.WC_BP_BeamNumber             = 0; % unused anyway
        
        % Definition of Kongsberg's KMALL water-column data format. We keep
        % it exactly like this to save disk space.
        % The sample amplitude are recorded in "int8" (signed integers from
        % -128 to 127) with -128 being the NaN value. It needs to be
        % multiplied by a factor of 1/2 to retrieve the true value, aka an
        % int8 record of -41 is actually -20.5dB.
        raw_WCamp_Class = 'int8';
        raw_WCamp_Factor = 1./2;
        raw_WCamp_Nanval = intmin(raw_WCamp_Class); % -128
        
        % also, that data will not be saved in fData but in binary files.
        % Get the output directory to store memmaped files
        wc_dir = CFF_converted_data_folder(KMALLfilename);
        
        % initialize data-holding binary files for Amplitude
        fData = CFF_init_memmapfiles(fData, ...
            'field', 'WC_SBP_SampleAmplitudes', ...
            'wc_dir', wc_dir, ...
            'Class', raw_WCamp_Class, ...
            'Factor', raw_WCamp_Factor, ...
            'Nanval', raw_WCamp_Nanval, ...
            'Offset', 0, ...
            'MaxSamples', maxnSamples_groups, ...
            'MaxBeams', maxnBeams_sub, ...
            'ping_group_start', ping_group_start, ...
            'ping_group_end', ping_group_end);
        
        % was phase recorded?
        phaseFlags = CFF_getfield([KMALLdata.EMdgmMWC.rxInfo],'phaseFlag');
        if all(phaseFlags==1)
            phaseFlag = 1;
        elseif all(phaseFlags==2)
            phaseFlag = 2;
        else
            % also here if flag is not consistent between pings
            phaseFlag = 0;
        end
        
        % record phase data, if available
        if phaseFlag
            
            % raw Phase data format
            if phaseFlag==1
                raw_WCph_Class = 'int8';
                raw_WCph_Factor = 180/128;
            else
                raw_WCph_Class = 'int16';
                raw_WCph_Factor = 0.01;
            end
            raw_WCph_Nanval = intmin(raw_WCph_Class);
            
            % initialize data-holding binary files for Phase
            fData = CFF_init_memmapfiles(fData, ...
                'field', 'WC_SBP_SamplePhase', ...
                'wc_dir', wc_dir, ...
                'Class', raw_WCph_Class, ...
                'Factor', raw_WCph_Factor, ...
                'Nanval', raw_WCph_Nanval, ...
                'Offset', 0, ...
                'MaxSamples', maxnSamples_groups, ...
                'MaxBeams', maxnBeams_sub, ...
                'ping_group_start', ping_group_start, ...
                'ping_group_end', ping_group_end);
            
        end
        
        % samples data from WC or AP datagrams were not recorded, so we
        % need to fopen the source file to grab the data
        fid = fopen(KMALLfilename,'r','l');
        
        % initialize ping group counter, to use to specify which memmapfile
        % to fill. We start in the first.
        iG = 1;
        
        % debug graph
        disp_wc = 0;
        if disp_wc
            f = figure();
            if ~phaseFlag
                ax_mag = axes(f,'outerposition',[0 0 1 1]);
                title('WCD amplitude');
            else
                ax_mag = axes(f,'outerposition',[0 0.5 1 0.5]);
                title('WCD amplitude');
                ax_phase = axes(f,'outerposition',[0 0 1 0.5]);
                title('WCD phase');
            end
        end
        
        % position of start of data in each beam
        WC_BP_sampleDataPIF = reshape(CFF_getfield([KMALLdata.EMdgmMWC.beamData_p],'sampleDataPositionInFile'),maxnBeams_sub,nSwaths);
                
        % now get data for each ping
        for iP = 1:nSwaths
            
            % update ping group counter if needed
            if iP > ping_group_end(iG)
                iG = iG+1;
            end
            
            % initialize amplitude and phase matrices for that ping
            Mag_tmp = raw_WCamp_Nanval.*ones(maxnSamples_groups(iG),maxnBeams_sub,raw_WCamp_Class);
            if phaseFlag
                Ph_tmp = raw_WCph_Nanval.*ones(maxnSamples_groups(iG),maxnBeams_sub,raw_WCph_Class);
            end
            
            % in each beam
            for iB = 1:nBeams(iP)

                % get to start of record
                dpif = WC_BP_sampleDataPIF(iB,iP);
                fseek(fid,dpif,-1);
                
                % read data
                sR = fData.WC_BP_StartRangeSampleNumber(iB,iP);
                nS = fData.WC_BP_NumberOfSamples(iB,iP);
                if phaseFlags(iP) == 0
                    % Only nS records of amplitude of 1 byte
                    Mag_tmp(sR+1:sR+nS,iB) = fread(fid, nS, 'int8=>int8',0);
                elseif phaseFlags(iP) == 1
                    % XXX this case was not tested yet. Find data for it
                    % nS records of amplitude of 1 byte alternated with nS
                    % records of phase of 1 byte
                    Mag_tmp(sR+1:sR+nS,iB) = fread(fid, nS, 'int8=>int8',1);
                    fseek(fid,dpif+1,-1); % rewind to after the first amplitude record
                    Ph_tmp(sR+1:sR+nS,iB) = fread(fid, nS, 'int8=>int8',1);
                else
                    % XXX this case was not tested yet. Find data for it
                    % nS records of amplitude of 1 byte alternated with nS
                    % records of phase of 2 bytes
                    Mag_tmp(sR+1:sR+nS,iB) = fread(fid, nS, 'int8=>int8',2);
                    fseek(fid,dpif+1,-1); % rewind to after the first amplitude record
                    Ph_tmp(sR+1:sR+nS,iB) = fread(fid, nS, 'int16=>int16',1);
                end
            end

            % debug graph
            if disp_wc
                % display amplitude
                imagesc(ax_mag,double(Mag_tmp).*raw_WCamp_Factor);
                colorbar
                title(sprintf('Ping %i/%i, WCD amplitude',iP,nSwaths));
                % display phase
                if phaseFlag
                    imagesc(ax_phase,double(Ph_tmp).*raw_WCph_Factor);
                    colorbar
                end
                drawnow;
            end
            
            % finished reading this ping's WC data. Store the data in the
            % appropriate binary file, at the appropriate ping, through the
            % memory mapping 
            fData.WC_SBP_SampleAmplitudes{iG}.Data.val(:,:,iP-ping_group_start(iG)+1) = Mag_tmp;
            if phaseFlag
                fData.WC_SBP_SamplePhase{iG}.Data.val(:,:,iP-ping_group_start(iG)+1) = Ph_tmp;
            end
            
        end
        
        % close the original raw file
        fclose(fid);
        
    end
    
    %% '#SPO - Sensor (S) data for position (PO)'
    if isfield(KMALLdata,'EMdgmSPO') && ~isfield(fData,'Po_1D_Date')
        
        % DEV NOTE: There are many entries here but I found a lot of issues
        % in the heading. Digging in the data revealed that many successive
        % entries have same values of timeFromSensor_sec, latitude,
        % longitude, and other values. Yet speed and heading change with
        % every entry... and heading has errors. I suspect those two values
        % are (badly) calculated fromt the lat/long. So now we only record
        % one entry per unique time stamp. Note the time stamp is in
        % seconds so no more than one record per second. The nanosecond
        % field is wrong. Alex 12 july 2021
        
        % get unique time entries from sensorData
        SD = [KMALLdata.EMdgmSPO(:).sensorData];
        % idx_t = 1:numel(SD.timeFromSensor_sec); % for test to store all
        idx_t = [1, find([0, diff([SD.timeFromSensor_sec])]~=0)];
        
        % number of entries to record
        nD = numel(idx_t);
        
        % get date and time-since-midnight-in-milleseconds from header
        [fData.Po_1D_Date, fData.Po_1D_TimeSinceMidnightInMilliseconds] = CFF_get_date_and_TSMIM_from_kmall(KMALLdata.EMdgmSPO(idx_t));
        
        fData.Po_1D_Latitude                    = [SD(idx_t).correctedLat_deg]; % in decimal degrees
        fData.Po_1D_Longitude                   = [SD(idx_t).correctedLong_deg]; % in decimal degrees
        fData.Po_1D_SpeedOfVesselOverGround     = [SD(idx_t).speedOverGround_mPerSec]; % in m/s
        fData.Po_1D_HeadingOfVessel             = [SD(idx_t).courseOverGround_deg]; % in degrees relative to north
        fData.Po_1D_MeasureOfPositionFixQuality = [SD(idx_t).posFixQuality_m];
        fData.Po_1D_PositionSystemDescriptor    = zeros(1,nD); % dummy values
        
    end
    
end

end

function out_struct = CFF_read_TRAI(ASCIIdata, TRAI_code)

out_struct = struct;

[iS,iE] = regexp(ASCIIdata,[TRAI_code ':.+?,']);

if isempty(iS)
    % no match, exit
    return
end

TRAI_TX1_ASCII = ASCIIdata(iS+9:iE-1);

yo(:,1) = [1; strfind(TRAI_TX1_ASCII,';')'+1]; % beginning of ASCII field name
yo(:,2) = strfind(TRAI_TX1_ASCII,'=')'-1; % end of ASCII field name
yo(:,3) = strfind(TRAI_TX1_ASCII,'=')'+1; % beginning of ASCII field value
yo(:,4) = [strfind(TRAI_TX1_ASCII,';')'-1;length(TRAI_TX1_ASCII)]; % end of ASCII field value

for ii = 1:size(yo,1)
    
    % get field string
    field = TRAI_TX1_ASCII(yo(ii,1):yo(ii,2));
    
    % try turn value into numeric
    value = str2double(TRAI_TX1_ASCII(yo(ii,3):yo(ii,4)));
    if length(value)~=1
        % looks like it cant. Keep as string
        value = TRAI_TX1_ASCII(yo(ii,3):yo(ii,4));
    end
    
    % store field/value
    out_struct.(field) = value;
    
end

end

function values = CFF_getfield(S, fieldname)
values = [S(:).(fieldname)];
end

function [KM_date, TSMIM] = CFF_get_date_and_TSMIM_from_kmall(S)

% get values
time_sec = CFF_getfield([S(:).header], 'time_sec');
time_nanosec = CFF_getfield([S(:).header], 'time_nanosec');

% convert raw to datetime
dt = datetime(time_sec + time_nanosec.*10^-9,'ConvertFrom','posixtime');

% convert datetime to date and TSMIM
KM_date = convertTo(dt, 'yyyymmdd');
TSMIM = milliseconds(timeofday(dt));

end

