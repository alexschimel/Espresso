
%Based on CFF_convert_mat_to_fabc_v2
%% Function
function [FABCdata,up] = CFF_convert_struct_to_fabc_v2(varStruct,varargin)


%% input parsing

% init
p = inputParser;

% required
addRequired(p,'varStruct',@(x) isstruct(x) || iscell(x));
% optional
addOptional(p,'FABCdata',{},@(x) isstruct(x) || iscell(x));
addOptional(p,'dr_sub',1,@(x) isnumeric(x)&&x>0);
addOptional(p,'db_sub',1,@(x) isnumeric(x)&&x>0);

% parse
parse(p,varStruct,varargin{:})

% get results
varStruct = p.Results.varStruct;
FABCdata = p.Results.FABCdata;
dr_sub = p.Results.dr_sub;
db_sub = p.Results.db_sub;
clear p;

%% pre-processing


% turn varStruct to cell if string
if ischar(varStruct)
    varStruct = {varStruct};
end

% number of files
nFiles = length(varStruct);


% and the decimation factors
if isempty(FABCdata)
    FABCdata.dr_sub = dr_sub;
    FABCdata.db_sub = db_sub;
    FABCdata.ALLfilename=cell(1,nFiles);
   for iF = 1:nFiles
       FABCdata.ALLfilename{iF}=varStruct{iF}.ALLfilename;
   end
end
up=0;

%% loop through all files and aggregate the datagrams contents

for iF = 1:nFiles
    
    if ~ismember(varStruct{iF}.ALLfilename,FABCdata.ALLfilename)
        disp('Cannot add different files to this structure.')
        continue;
    end
    
    
    % clear previous datagrams
    clear -regexp EM\w*
    
    % OPENING MAT FILE
    % research note: maybe these could be loaded through matfile, rather
    % than loading it all...
    varStructCurr = varStruct{iF};

    fid_all=fopen(FABCdata.ALLfilename{iF}, 'r',varStructCurr.datagramsformat);
    wc_dir=get_wc_dir(FABCdata.ALLfilename{iF});
    
    % EM_InstallationStart (v2 VERIFIED)
    if isfield(varStructCurr,'EM_InstallationStart')
        EM_InstallationStart=varStructCurr.EM_InstallationStart;
        % only do if data of that type has not been recorded yet, aka:
        if ~isfield(FABCdata,'IP_ASCIIparameters')
            up=1;
            % initialize struct
            IP_ASCIIparameters = struct;
            
            % read ASCIIdata
            ASCIIdata = char(EM_InstallationStart.ASCIIData(1));
            
            % remove carriage returns, tabs and linefeed
            ASCIIdata = regexprep(ASCIIdata,char(9),'');
            ASCIIdata = regexprep(ASCIIdata,char(10),'');
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
            
            % finally store in FABCdata
            FABCdata.IP_ASCIIparameters = IP_ASCIIparameters;
            
        end
        
    end
    
    % EM_SoundSpeedProfile (v2 VERIFIED)
    
    if isfield(varStructCurr,'EM_SoundSpeedProfile')
        EM_SoundSpeedProfile=varStructCurr.EM_SoundSpeedProfile;
        % only do if data of that type has not been recorded yet, aka:
        if ~isfield(FABCdata,'SS_1D_Date')
            up=1;
            NumberOfDatagrams  = length(EM_SoundSpeedProfile.TypeOfDatagram);
            MaxNumberOfEntries = max(EM_SoundSpeedProfile.NumberOfEntries);
            
            FABCdata.SS_1D_Date                                              = EM_SoundSpeedProfile.Date;
            FABCdata.SS_1D_TimeSinceMidnightInMilliseconds                   = EM_SoundSpeedProfile.TimeSinceMidnightInMilliseconds;
            FABCdata.SS_1D_ProfileCounter                                    = EM_SoundSpeedProfile.ProfileCounter;
            FABCdata.SS_1D_DateWhenProfileWasMade                            = EM_SoundSpeedProfile.DateWhenProfileWasMade;
            FABCdata.SS_1D_TimeSinceMidnightInMillisecondsWhenProfileWasMade = EM_SoundSpeedProfile.TimeSinceMidnightInMillisecondsWhenProfileWasMade;
            FABCdata.SS_1D_NumberOfEntries                                   = EM_SoundSpeedProfile.NumberOfEntries;
            FABCdata.SS_1D_DepthResolution                                   = EM_SoundSpeedProfile.DepthResolution;
            
            FABCdata.SS_ED_Depth      = nan(MaxNumberOfEntries,NumberOfDatagrams);
            FABCdata.SS_ED_SoundSpeed = nan(MaxNumberOfEntries,NumberOfDatagrams);
            
            for iD = 1:NumberOfDatagrams
                
                NumberOfEntries = EM_SoundSpeedProfile.NumberOfEntries(iD);
                
                FABCdata.SS_ED_Depth(1:NumberOfEntries,iD)      = cell2mat(EM_SoundSpeedProfile.Depth(iD));
                FABCdata.SS_ED_SoundSpeed(1:NumberOfEntries,iD) = cell2mat(EM_SoundSpeedProfile.SoundSpeed(iD));
                
            end
            
        end
        
    end
    
    % EM_Attitude
    if isfield(varStructCurr,'EM_Attitude')
        EM_Attitude=varStructCurr.EM_Attitude;
        % only do if data of that type has not been recorded yet, aka:
        if ~isfield(FABCdata,'At_1D_Date')
            up=1;
            NumberOfDatagrams  = length(EM_Attitude.TypeOfDatagram);
            MaxNumberOfEntries = max(EM_Attitude.NumberOfEntries);
            
            FABCdata.At_1D_Date                            = EM_Attitude.Date;
            FABCdata.At_1D_TimeSinceMidnightInMilliseconds = EM_Attitude.TimeSinceMidnightInMilliseconds;
            FABCdata.At_1D_AttitudeCounter                 = EM_Attitude.AttitudeCounter;
            FABCdata.At_1D_NumberOfEntries                 = EM_Attitude.NumberOfEntries;
            
            FABCdata.At_ED_TimeInMillisecondsSinceRecordStart = nan(MaxNumberOfEntries, NumberOfDatagrams);
            FABCdata.At_ED_SensorStatus                       = nan(MaxNumberOfEntries, NumberOfDatagrams);
            FABCdata.At_ED_Roll                               = nan(MaxNumberOfEntries, NumberOfDatagrams);
            FABCdata.At_ED_Pitch                              = nan(MaxNumberOfEntries, NumberOfDatagrams);
            FABCdata.At_ED_Heave                              = nan(MaxNumberOfEntries, NumberOfDatagrams);
            FABCdata.At_ED_Heading                            = nan(MaxNumberOfEntries, NumberOfDatagrams);
            
            for iD = 1:NumberOfDatagrams
                
                NumberOfEntries = EM_Attitude.NumberOfEntries(iD);
                
                FABCdata.At_ED_TimeInMillisecondsSinceRecordStart(1:NumberOfEntries, iD) = cell2mat(EM_Attitude.TimeInMillisecondsSinceRecordStart(iD));
                FABCdata.At_ED_SensorStatus(1:NumberOfEntries, iD)                       = cell2mat(EM_Attitude.SensorStatus(iD));
                FABCdata.At_ED_Roll(1:NumberOfEntries, iD)                               = cell2mat(EM_Attitude.Roll(iD));
                FABCdata.At_ED_Pitch(1:NumberOfEntries, iD)                              = cell2mat(EM_Attitude.Pitch(iD));
                FABCdata.At_ED_Heave(1:NumberOfEntries, iD)                              = cell2mat(EM_Attitude.Heave(iD));
                FABCdata.At_ED_Heading(1:NumberOfEntries, iD)                            = cell2mat(EM_Attitude.Heading(iD));
                
            end
            
        end
        
    end
    
    % EM_Height
    if isfield(varStructCurr,'EM_Height')
        EM_Height=varStructCurr.EM_Height;
        % only do if data of that type has not been recorded yet, aka:
        if ~isfield(FABCdata,'He_1D_Date')
            up=1;
            % NumberOfDatagrams = length(EM_Height.TypeOfDatagram);
            
            FABCdata.He_1D_Date                            = EM_Height.Date;
            FABCdata.He_1D_TimeSinceMidnightInMilliseconds = EM_Height.TimeSinceMidnightInMilliseconds;
            FABCdata.He_1D_HeightCounter                   = EM_Height.HeightCounter;
            FABCdata.He_1D_Height                          = EM_Height.Height;
            
        end
        
    end
    
    % EM_Position (v2 verified)
    if isfield(varStructCurr,'EM_Position')
        EM_Position=varStructCurr.EM_Position;
        % only do if data of that type has not been recorded yet, aka:
        if ~isfield(FABCdata,'Po_1D_Date')
            up=1;
            % NumberOfDatagrams = length(EM_Position.TypeOfDatagram);
            
            FABCdata.Po_1D_Date                            = EM_Position.Date;
            FABCdata.Po_1D_TimeSinceMidnightInMilliseconds = EM_Position.TimeSinceMidnightInMilliseconds;
            FABCdata.Po_1D_PositionCounter                 = EM_Position.PositionCounter;
            FABCdata.Po_1D_Latitude                        = EM_Position.Latitude;
            FABCdata.Po_1D_Longitude                       = EM_Position.Longitude;
            FABCdata.Po_1D_SpeedOfVesselOverGround         = EM_Position.SpeedOfVesselOverGround;
            FABCdata.Po_1D_HeadingOfVessel                 = EM_Position.HeadingOfVessel;
            
        end
        
    end
    
    % EM_Depth
    
    if isfield(varStructCurr,'EM_Depth')
        EM_Depth=varStructCurr.EM_Depth;
        
        % only do if data of that type has not been recorded yet, aka:
        if ~isfield(FABCdata,'De_1P_Date')
            up=1;
            NumberOfPings    = length(EM_Depth.TypeOfDatagram); % total number of pings in file
            MaxNumberOfBeams = max(cellfun(@(x) max(x),EM_Depth.BeamNumber)); % maximum beam number in file
            
            FABCdata.De_1P_Date                            = EM_Depth.Date;
            FABCdata.De_1P_TimeSinceMidnightInMilliseconds = EM_Depth.TimeSinceMidnightInMilliseconds;
            FABCdata.De_1P_PingCounter                     = EM_Depth.PingCounter;
            FABCdata.De_1P_HeadingOfVessel                 = EM_Depth.HeadingOfVessel;
            FABCdata.De_1P_SoundSpeedAtTransducer          = EM_Depth.SoundSpeedAtTransducer;
            FABCdata.De_1P_TransmitTransducerDepth         = EM_Depth.TransmitTransducerDepth + 65536.*EM_Depth.TransducerDepthOffsetMultiplier;
            FABCdata.De_1P_MaximumNumberOfBeamsPossible    = EM_Depth.MaximumNumberOfBeamsPossible;
            FABCdata.De_1P_NumberOfValidBeams              = EM_Depth.NumberOfValidBeams;
            FABCdata.De_1P_ZResolution                     = EM_Depth.ZResolution;
            FABCdata.De_1P_XAndYResolution                 = EM_Depth.XAndYResolution;
            FABCdata.De_1P_SamplingRate                    = EM_Depth.SamplingRate;
            
            % initialize
            FABCdata.De_BP_DepthZ                  = nan(MaxNumberOfBeams,NumberOfPings);
            FABCdata.De_BP_AcrosstrackDistanceY    = nan(MaxNumberOfBeams,NumberOfPings);
            FABCdata.De_BP_AlongtrackDistanceX     = nan(MaxNumberOfBeams,NumberOfPings);
            FABCdata.De_BP_BeamDepressionAngle     = nan(MaxNumberOfBeams,NumberOfPings);
            FABCdata.De_BP_BeamAzimuthAngle        = nan(MaxNumberOfBeams,NumberOfPings);
            FABCdata.De_BP_Range                   = nan(MaxNumberOfBeams,NumberOfPings);
            FABCdata.De_BP_QualityFactor           = nan(MaxNumberOfBeams,NumberOfPings);
            FABCdata.De_BP_LengthOfDetectionWindow = nan(MaxNumberOfBeams,NumberOfPings);
            FABCdata.De_BP_ReflectivityBS          = nan(MaxNumberOfBeams,NumberOfPings);
            FABCdata.De_B1_BeamNumber              = (1:MaxNumberOfBeams)';
            
            for iP = 1:NumberOfPings
                
                BeamNumber = cell2mat(EM_Depth.BeamNumber(iP));
                
                FABCdata.De_BP_DepthZ(BeamNumber,iP)                  = cell2mat(EM_Depth.DepthZ(iP));
                FABCdata.De_BP_AcrosstrackDistanceY(BeamNumber,iP)    = cell2mat(EM_Depth.AcrosstrackDistanceY(iP));
                FABCdata.De_BP_AlongtrackDistanceX(BeamNumber,iP)     = cell2mat(EM_Depth.AlongtrackDistanceX(iP));
                FABCdata.De_BP_BeamDepressionAngle(BeamNumber,iP)     = cell2mat(EM_Depth.BeamDepressionAngle(iP));
                FABCdata.De_BP_BeamAzimuthAngle(BeamNumber,iP)        = cell2mat(EM_Depth.BeamAzimuthAngle(iP));
                FABCdata.De_BP_Range(BeamNumber,iP)                   = cell2mat(EM_Depth.Range(iP));
                FABCdata.De_BP_QualityFactor(BeamNumber,iP)           = cell2mat(EM_Depth.QualityFactor(iP));
                FABCdata.De_BP_LengthOfDetectionWindow(BeamNumber,iP) = cell2mat(EM_Depth.LengthOfDetectionWindow(iP));
                FABCdata.De_BP_ReflectivityBS(BeamNumber,iP)          = cell2mat(EM_Depth.ReflectivityBS(iP));
                
            end
            
        end
        
    end
    
    % EM_XYZ88
    if isfield(varStructCurr,'EM_XYZ88')
        EM_XYZ88=varStructCurr.EM_XYZ88;
        
        % only do if data of that type has not been recorded yet, aka:
        if ~isfield(FABCdata,'X8_1P_Date')
            up=1;
            NumberOfPings    = length(EM_XYZ88.TypeOfDatagram); % total number of pings in file
            MaxNumberOfBeams = max(EM_XYZ88.NumberOfBeamsInDatagram); % maximum beam number in file
            
            FABCdata.X8_1P_Date                            = EM_XYZ88.Date;
            FABCdata.X8_1P_TimeSinceMidnightInMilliseconds = EM_XYZ88.TimeSinceMidnightInMilliseconds;
            FABCdata.X8_1P_PingCounter                     = EM_XYZ88.PingCounter;
            FABCdata.X8_1P_HeadingOfVessel                 = EM_XYZ88.HeadingOfVessel;
            FABCdata.X8_1P_SoundSpeedAtTransducer          = EM_XYZ88.SoundSpeedAtTransducer;
            FABCdata.X8_1P_TransmitTransducerDepth         = EM_XYZ88.TransmitTransducerDepth;
            FABCdata.X8_1P_NumberOfBeamsInDatagram         = EM_XYZ88.NumberOfBeamsInDatagram;
            FABCdata.X8_1P_NumberOfValidDetections         = EM_XYZ88.NumberOfValidDetections;
            FABCdata.X8_1P_SamplingFrequencyInHz           = EM_XYZ88.SamplingFrequencyInHz;
            
            % initialize
            FABCdata.X8_BP_DepthZ                       = nan(MaxNumberOfBeams,NumberOfPings);
            FABCdata.X8_BP_AcrosstrackDistanceY         = nan(MaxNumberOfBeams,NumberOfPings);
            FABCdata.X8_BP_AlongtrackDistanceX          = nan(MaxNumberOfBeams,NumberOfPings);
            FABCdata.X8_BP_DetectionWindowLength        = nan(MaxNumberOfBeams,NumberOfPings);
            FABCdata.X8_BP_QualityFactor                = nan(MaxNumberOfBeams,NumberOfPings);
            FABCdata.X8_BP_BeamIncidenceAngleAdjustment = nan(MaxNumberOfBeams,NumberOfPings);
            FABCdata.X8_BP_DetectionInformation         = nan(MaxNumberOfBeams,NumberOfPings);
            FABCdata.X8_BP_RealTimeCleaningInformation  = nan(MaxNumberOfBeams,NumberOfPings);
            FABCdata.X8_BP_ReflectivityBS               = nan(MaxNumberOfBeams,NumberOfPings);
            FABCdata.X8_B1_BeamNumber                   = (1:MaxNumberOfBeams)';
            
            for iP = 1:NumberOfPings
                
                FABCdata.X8_BP_DepthZ(1:MaxNumberOfBeams,iP)                       = cell2mat(EM_XYZ88.DepthZ(iP));
                FABCdata.X8_BP_AcrosstrackDistanceY(1:MaxNumberOfBeams,iP)         = cell2mat(EM_XYZ88.AcrosstrackDistanceY(iP));
                FABCdata.X8_BP_AlongtrackDistanceX(1:MaxNumberOfBeams,iP)          = cell2mat(EM_XYZ88.AlongtrackDistanceX(iP));
                FABCdata.X8_BP_DetectionWindowLength(1:MaxNumberOfBeams,iP)        = cell2mat(EM_XYZ88.DetectionWindowLength(iP));
                FABCdata.X8_BP_QualityFactor(1:MaxNumberOfBeams,iP)                = cell2mat(EM_XYZ88.QualityFactor(iP));
                FABCdata.X8_BP_BeamIncidenceAngleAdjustment(1:MaxNumberOfBeams,iP) = cell2mat(EM_XYZ88.BeamIncidenceAngleAdjustment(iP));
                FABCdata.X8_BP_DetectionInformation(1:MaxNumberOfBeams,iP)         = cell2mat(EM_XYZ88.DetectionInformation(iP));
                FABCdata.X8_BP_RealTimeCleaningInformation(1:MaxNumberOfBeams,iP)  = cell2mat(EM_XYZ88.RealTimeCleaningInformation(iP));
                FABCdata.X8_BP_ReflectivityBS(1:MaxNumberOfBeams,iP)               = cell2mat(EM_XYZ88.ReflectivityBS(iP));
                
            end
            
        end
        
    end
    
    % EM_SeabedImage
    if isfield(varStructCurr,'EM_SeabedImage')
        EM_SeabedImage=varStructCurr.EM_SeabedImage;
        % only do if data of that type has not been recorded yet, aka:
        if ~isfield(FABCdata,'SI_1P_Date')
            up=1;
            NumberOfPings      = length(EM_SeabedImage.TypeOfDatagram); % total number of pings in file
            MaxNumberOfBeams   = max(cellfun(@(x) max(x),EM_SeabedImage.BeamIndexNumber))+1; % maximum beam number (beam index number +1), in file
            MaxNumberOfSamples = max(cellfun(@(x) max(x),EM_SeabedImage.NumberOfSamplesPerBeam));
            
            FABCdata.SI_1P_Date                            = EM_SeabedImage.Date;
            FABCdata.SI_1P_TimeSinceMidnightInMilliseconds = EM_SeabedImage.TimeSinceMidnightInMilliseconds;
            FABCdata.SI_1P_PingCounter                     = EM_SeabedImage.PingCounter;
            FABCdata.SI_1P_MeanAbsorptionCoefficient       = EM_SeabedImage.MeanAbsorptionCoefficient;
            FABCdata.SI_1P_PulseLength                     = EM_SeabedImage.PulseLength;
            FABCdata.SI_1P_RangeToNormalIncidence          = EM_SeabedImage.RangeToNormalIncidence;
            FABCdata.SI_1P_StartRangeSampleOfTVGRamp       = EM_SeabedImage.StartRangeSampleOfTVGRamp;
            FABCdata.SI_1P_StopRangeSampleOfTVGRamp        = EM_SeabedImage.StopRangeSampleOfTVGRamp;
            FABCdata.SI_1P_NormalIncidenceBS               = EM_SeabedImage.NormalIncidenceBS;
            FABCdata.SI_1P_ObliqueBS                       = EM_SeabedImage.ObliqueBS;
            FABCdata.SI_1P_TxBeamwidth                     = EM_SeabedImage.TxBeamwidth;
            FABCdata.SI_1P_TVGLawCrossoverAngle            = EM_SeabedImage.TVGLawCrossoverAngle;
            FABCdata.SI_1P_NumberOfValidBeams              = EM_SeabedImage.NumberOfValidBeams;
            
            % initialize
            FABCdata.SI_BP_SortingDirection       = nan(MaxNumberOfBeams,NumberOfPings);
            FABCdata.SI_BP_NumberOfSamplesPerBeam = nan(MaxNumberOfBeams,NumberOfPings);
            FABCdata.SI_BP_CentreSampleNumber     = nan(MaxNumberOfBeams,NumberOfPings);
            FABCdata.SI_B1_BeamNumber             = (1:MaxNumberOfBeams)';
            FABCdata.SI_SBP_SampleAmplitudes      = cell(NumberOfPings,1); % saving as sparse
            
            for iP = 1:NumberOfPings
                
                % Get data from datagram
                BeamNumber             = cell2mat(EM_SeabedImage.BeamIndexNumber(iP))+1;
                NumberOfSamplesPerBeam = cell2mat(EM_SeabedImage.NumberOfSamplesPerBeam(iP));
                Samples                = cell2mat(EM_SeabedImage.SampleAmplitudes(iP).beam(:));
                
                % from number of samples per beam, get indices of first and last
                % sample for each beam in the Samples data vector
                iFirst = [1;cumsum(NumberOfSamplesPerBeam(1:end-1))+1];
                iLast  = iFirst+NumberOfSamplesPerBeam-1;
                
                % store
                FABCdata.SI_BP_SortingDirection(BeamNumber,iP)       = cell2mat(EM_SeabedImage.SortingDirection(iP));
                FABCdata.SI_BP_NumberOfSamplesPerBeam(BeamNumber,iP) = NumberOfSamplesPerBeam;
                FABCdata.SI_BP_CentreSampleNumber(BeamNumber,iP)     = cell2mat(EM_SeabedImage.CentreSampleNumber(iP));
                
                % initialize the beams/sample array (use zero instead of NaN to
                % allow turning it to sparse
                temp = zeros(MaxNumberOfSamples,length(BeamNumber));
                
                % fill in
                for iB = 1:length(BeamNumber)
                    temp(1:NumberOfSamplesPerBeam(iB),BeamNumber(iB)) = Samples(iFirst(iB):iLast(iB));
                end
                
                % and save the sparse version
                FABCdata.SI_SBP_SampleAmplitudes(iP,1) = {sparse(temp)}; % to use full matrices, FABCdata.SI_SBP_SampleAmplitudes(:,:,iP) = temp;
                
            end
            
        end
        
    end
    
    % EM_SeabedImage89
    if isfield(varStructCurr,'EM_SeabedImage89')
        EM_SeabedImage89=varStructCurr.EM_SeabedImage89;
        % only do if data of that type has not been recorded yet, aka:
        if ~isfield(FABCdata,'S8_1D_Date')
            up=1;
            NumberOfPings      = length(EM_SeabedImage89.TypeOfDatagram); % total number of pings in file
            MaxNumberOfBeams   = max(EM_SeabedImage89.NumberOfValidBeams);
            MaxNumberOfSamples = max(cellfun(@(x) max(x),EM_SeabedImage89.NumberOfSamplesPerBeam));
            
            FABCdata.S8_1P_Date                            = EM_SeabedImage89.Date;
            FABCdata.S8_1P_TimeSinceMidnightInMilliseconds = EM_SeabedImage89.TimeSinceMidnightInMilliseconds;
            FABCdata.S8_1P_PingCounter                     = EM_SeabedImage89.PingCounter;
            FABCdata.S8_1P_SamplingFrequencyInHz           = EM_SeabedImage89.SamplingFrequencyInHz;
            FABCdata.S8_1P_RangeToNormalIncidence          = EM_SeabedImage89.RangeToNormalIncidence;
            FABCdata.S8_1P_NormalIncidenceBS               = EM_SeabedImage89.NormalIncidenceBS;
            FABCdata.S8_1P_ObliqueBS                       = EM_SeabedImage89.ObliqueBS;
            FABCdata.S8_1P_TxBeamwidthAlong                = EM_SeabedImage89.TxBeamwidthAlong;
            FABCdata.S8_1P_TVGLawCrossoverAngle            = EM_SeabedImage89.TVGLawCrossoverAngle;
            FABCdata.S8_1P_NumberOfValidBeams              = EM_SeabedImage89.NumberOfValidBeams;
            
            % initialize
            FABCdata.S8_BP_SortingDirection       = nan(MaxNumberOfBeams,NumberOfPings);
            FABCdata.S8_BP_DetectionInfo          = nan(MaxNumberOfBeams,NumberOfPings);
            FABCdata.S8_BP_NumberOfSamplesPerBeam = nan(MaxNumberOfBeams,NumberOfPings);
            FABCdata.S8_BP_CentreSampleNumber     = nan(MaxNumberOfBeams,NumberOfPings);
            FABCdata.S8_B1_BeamNumber             = (1:MaxNumberOfBeams)';
            FABCdata.S8_SBP_SampleAmplitudes      = cell(NumberOfPings,1);
            
            % in this more recent datagram, all beams are in. No beamnumber anymore
            BeamNumber = FABCdata.S8_B1_BeamNumber;
            
            for iP = 1:NumberOfPings
                
                % Get data from datagram
                NumberOfSamplesPerBeam = cell2mat(EM_SeabedImage89.NumberOfSamplesPerBeam(iP));
                Samples                = cell2mat(EM_SeabedImage89.SampleAmplitudes(iP).beam(:));
                
                % from number of samples per beam, get indices of first and last
                % sample for each beam in the Samples data vector
                iFirst = [1;cumsum(NumberOfSamplesPerBeam(1:end-1))+1];
                iLast  = iFirst+NumberOfSamplesPerBeam-1;
                
                % store
                FABCdata.S8_BP_SortingDirection(BeamNumber,iP)       = cell2mat(EM_SeabedImage89.SortingDirection(iP));
                FABCdata.S8_BP_NumberOfSamplesPerBeam(BeamNumber,iP) = NumberOfSamplesPerBeam;
                FABCdata.S8_BP_CentreSampleNumber(BeamNumber,iP)     = cell2mat(EM_SeabedImage89.CentreSampleNumber(iP));
                
                % initialize the beams/sample array (use zero instead of NaN to
                % allow turning it to sparse
                temp = zeros(MaxNumberOfSamples,length(BeamNumber));
                
                % and fill in
                for iB = 1:length(BeamNumber)
                    temp(1:NumberOfSamplesPerBeam(iB),BeamNumber(iB)) = Samples(iFirst(iB):iLast(iB));
                end
                
                % and save the sparse version
                FABCdata.S8_SBP_SampleAmplitudes(iP,1) = {sparse(temp)}; % to use full matrices, FABCdata.S8_SBP_SampleAmplitudes(:,:,iP) = temp;
                
            end
            
        end
        
    end
    
    % EM_WaterColumn (v2 verified)
    if isfield(varStructCurr,'EM_WaterColumn')
        EM_WaterColumn=varStructCurr.EM_WaterColumn;
        % only do if data of that type has not been recorded yet, aka:
        if ~isfield(FABCdata,'WC_1P_Date')||FABCdata.dr_sub~=dr_sub||FABCdata.db_sub~=db_sub
            up=1;
            % get indices of first datagram for each ping
            [pingCounters,iFirstDatagram] = unique(EM_WaterColumn.PingCounter);
            
            % get data dimensions
            nPings              = length(pingCounters); % total number of pings in file
            maxNBeams           = max(EM_WaterColumn.TotalNumberOfReceiveBeams); % maximum number of beams for a ping in file
            maxNTransmitSectors = max(EM_WaterColumn.NumberOfTransmitSectors); % maximum number of transmit sectors for a ping in file
            maxNSamples         = max(cellfun(@(x) max(x),EM_WaterColumn.NumberOfSamples)); % max number of samples for a beam in file
            
            % decimating beams and samples
            maxNBeams_sub       = ceil(maxNBeams/db_sub); % number of beams to extract
            maxNSamples_sub     = ceil(maxNSamples/dr_sub); % number of samples to extract
            
            % read data per ping from first datagram of each ping
            FABCdata.WC_1P_Date                            = EM_WaterColumn.Date(iFirstDatagram);
            FABCdata.WC_1P_TimeSinceMidnightInMilliseconds = EM_WaterColumn.TimeSinceMidnightInMilliseconds(iFirstDatagram);
            FABCdata.WC_1P_PingCounter                     = EM_WaterColumn.PingCounter(iFirstDatagram);
            FABCdata.WC_1P_NumberOfDatagrams               = EM_WaterColumn.NumberOfDatagrams(iFirstDatagram);
            FABCdata.WC_1P_NumberOfTransmitSectors         = EM_WaterColumn.NumberOfTransmitSectors(iFirstDatagram);
            FABCdata.WC_1P_TotalNumberOfReceiveBeams       = EM_WaterColumn.TotalNumberOfReceiveBeams(iFirstDatagram);
            FABCdata.WC_1P_SoundSpeed                      = EM_WaterColumn.SoundSpeed(iFirstDatagram);
            FABCdata.WC_1P_SamplingFrequencyHz             = (EM_WaterColumn.SamplingFrequency(iFirstDatagram).*0.01)./dr_sub; % in Hz
            FABCdata.WC_1P_TXTimeHeave                     = EM_WaterColumn.TXTimeHeave(iFirstDatagram);
            FABCdata.WC_1P_TVGFunctionApplied              = EM_WaterColumn.TVGFunctionApplied(iFirstDatagram);
            FABCdata.WC_1P_TVGOffset                       = EM_WaterColumn.TVGOffset(iFirstDatagram);
            FABCdata.WC_1P_ScanningInfo                    = EM_WaterColumn.ScanningInfo(iFirstDatagram);
            
            % initialize data per transmit sector and ping
            FABCdata.WC_TP_TiltAngle            = nan(maxNTransmitSectors,nPings);
            FABCdata.WC_TP_CenterFrequency      = nan(maxNTransmitSectors,nPings);
            FABCdata.WC_TP_TransmitSectorNumber = nan(maxNTransmitSectors,nPings);
            
            % initialize data per decimated beam and ping
            FABCdata.WC_BP_BeamPointingAngle      = nan(maxNBeams_sub,nPings);
            FABCdata.WC_BP_StartRangeSampleNumber = nan(maxNBeams_sub,nPings);
            FABCdata.WC_BP_NumberOfSamples        = nan(maxNBeams_sub,nPings);
            FABCdata.WC_BP_DetectedRangeInSamples = zeros(maxNBeams_sub,nPings);
            FABCdata.WC_BP_TransmitSectorNumber   = nan(maxNBeams_sub,nPings);
            FABCdata.WC_BP_BeamNumber             = nan(maxNBeams_sub,nPings);
            
            % decide whether to save in memory or as memmapfile
            
            
            % use memmap file
            
            % initialize binary file for writing

            file_binary = fullfile(wc_dir,'WC_SBP_SampleAmplitudes.dat');
            
            if exist(file_binary,'file')==0||FABCdata.dr_sub~=dr_sub||FABCdata.db_sub~=db_sub
                fileID = fopen(file_binary,'w+');
            else
                fileID=-1;
            end
            
            
            % now get data for each ping
            for iP = 1:nPings
                
                % find datagrams composing this ping
                pingCounter = FABCdata.WC_1P_PingCounter(1,iP); % ping number (ex: 50455)
                % nDatagrams  = FABCdata.WC_1P_NumberOfDatagrams(1,iP); % theoretical number of datagrams for this ping (ex: 7)
                iDatagrams  = find(EM_WaterColumn.PingCounter==pingCounter); % index of the datagrams making up this ping in EM_Watercolumn (ex: 58-59-61-64)
                nDatagrams  = length(iDatagrams); % actual number of datagrams available (ex: 4)
                
                % some datagrams may be missing, like in the example. Detect and adjust...
                datagramOrder     = EM_WaterColumn.DatagramNumbers(iDatagrams); % order of the datagrams (ex: 4-3-6-2, the missing one is 1st, 5th and 7th)
                [~,IX]            = sort(datagramOrder);
                iDatagrams        = iDatagrams(IX); % index of the datagrams making up this ping in EM_Watercolumn, but in the right order (ex: 64-59-58-61, missing datagrams are still missing)
                nBeamsPerDatagram = EM_WaterColumn.NumberOfBeamsInThisDatagram(iDatagrams); % number of beams in each datagram making up this ping (ex: 56-61-53-28)
                
                % assuming transmit sectors data are not split between several datagrams, get that data from the first datagram.
                nTransmitSectors = FABCdata.WC_1P_NumberOfTransmitSectors(1,iP); % number of transmit sectors in this ping
                FABCdata.WC_TP_TiltAngle(1:nTransmitSectors,iP)            = EM_WaterColumn.TiltAngle{iDatagrams(1)};
                FABCdata.WC_TP_CenterFrequency(1:nTransmitSectors,iP)      = EM_WaterColumn.CenterFrequency{iDatagrams(1)};
                FABCdata.WC_TP_TransmitSectorNumber(1:nTransmitSectors,iP) = EM_WaterColumn.TransmitSectorNumber{iDatagrams(1)};
                
                % initialize the decimated samples / decimated beams matrix (Watercolumn data)
                SB_temp = zeros(maxNSamples_sub,maxNBeams_sub,'int8')-128;
                
                % and then read the data in each datagram
                for iD = 1:nDatagrams
                    
                    % index of beams in output structure for this datagram
                    [iBeams,idx_beams] = unique(ceil((sum(nBeamsPerDatagram(1:iD-1)) + (1:nBeamsPerDatagram(iD)))/db_sub));
                    % old approach
                    % iBeams = sum(nBeamsPerDatagram(1:iD-1)) + (1:nBeamsPerDatagram(iD));
                    % idx_beams = (1:numel(iBeams));
                    
                    % ping x beam data
                    FABCdata.WC_BP_BeamPointingAngle(iBeams,iP)      = EM_WaterColumn.BeamPointingAngle{iDatagrams(iD)}(idx_beams);
                    FABCdata.WC_BP_StartRangeSampleNumber(iBeams,iP) = round(EM_WaterColumn.StartRangeSampleNumber{iDatagrams(iD)}(idx_beams)./dr_sub);
                    FABCdata.WC_BP_NumberOfSamples(iBeams,iP)        = round(EM_WaterColumn.NumberOfSamples{iDatagrams(iD)}(idx_beams)./dr_sub);
                    FABCdata.WC_BP_DetectedRangeInSamples(iBeams,iP) = round(EM_WaterColumn.DetectedRangeInSamples{iDatagrams(iD)}(idx_beams)./dr_sub);
                    FABCdata.WC_BP_TransmitSectorNumber(iBeams,iP)   = EM_WaterColumn.TransmitSectorNumber2{iDatagrams(iD)}(idx_beams);
                    FABCdata.WC_BP_BeamNumber(iBeams,iP)             = EM_WaterColumn.BeamNumber{iDatagrams(iD)}(idx_beams);
                    if fileID>=0
                        % now getting watercolumn data (beams x samples)
                        for iB = 1:numel(iBeams)
                            % actual number of samples in that beam
                            Ns = EM_WaterColumn.NumberOfSamples{iDatagrams(iD)}(idx_beams(iB));
                            % number of samples we're going to record:
                            Ns_sub = ceil(Ns/dr_sub);
                            % get the data:
                            fseek(fid_all,EM_WaterColumn.SampleAmplitudePosition{iDatagrams(iD)}(idx_beams(iB)),'bof');
                            SB_temp(1:Ns_sub,iBeams(iB))=fread(fid_all,Ns_sub,'int8',dr_sub-1);
                            %SB_temp(1:Ns_sub,iBeams(iB)) = EM_WaterColumn.SampleAmplitude{iDatagrams(iD)}{idx_beams(iB)}(1:dr_sub:Ns_sub*dr_sub)';
                        end
                    end
                end
                
                % store data
                if fileID>=0
                    % write on binary file
                    fwrite(fileID,SB_temp,'int8');
                end
                
            end
            
            if fileID>=0
                fclose(fileID);
            end
            % re-open as memmapfile
            FABCdata.WC_SBP_SampleAmplitudes = memmapfile(file_binary,'Format',{'int8' [maxNSamples_sub maxNBeams_sub nPings] 'val'},'repeat',1,'writable',true);
            
            
        end
        
    end
    
    
    % other types of datagrams not supported yet.
    fclose(fid_all);
end
