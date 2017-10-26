%% CFF_convert_mat_to_fabc_v2.m
%
% Converts the Kongsberg EM series data files in MAT format (containing the
% KONGSBERG datagrams) to the FABC format for use in processing.
%
% Note: v2 has a few major changes including change in order of dimensions
%
%% Help
%
% *USE*
%
% FABCdata = CFF_convert_mat_to_fabc_v2(MATfilename) converts the contents
% of MATfilename (string or cell of string) to a FABCdata structure.
%
% FABCdata = CFF_convert_mat_to_fabc_v2({MATfilename1,MATfilename2})
% converts the contents of strings MATfilename1 and MATfilename2 to a
% FABCdata structure, with the datagrams of MATfilename2 not being loaded
% if that datagram type existed in MATfilename1. AKA, use 1 for WCD data
% and 2 for ALL data.
%
% *INPUT VARIABLES*
%
% REQUIRED:
% * |MATfilename|: MAT file to convert either as a string of a single file,
% or cell of strings for several files to parse together.
%
% *OUTPUT VARIABLES*
%
% * |FABCdata|: structure for the storage of data in a format easier to use
% than the EM datagrams. The data is recorded as fields coded "a_b_c" of
% the structure "FABCdata", and accessible as FABCdata.a_b_c, where:
%     * a: code indicating data origin:
%         * IP: installation parameters
%         * De: depth datagram
%         * He: height datagram
%         * X8: XYZ88 datagram
%         * SI: seabed image datagram
%         * S8: seabed image data 89
%         * WC: watercolumn data
%         * Po: position datagram
%         * At: attitude datagram
%         * SS: sound speed profile datagram
%     More codes for the 'a' part will be created if more datagrams are
%     parsed. As further codes work with the data contained in FABC
%     structure, these derived data can be recorded back into the FABC,
%     with the 'a' code set to 'X'.
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
%     datagrams needs them. As subsequent functions work with the data
%     contained in FABC structure to generate derived data, these derived
%     data can be recorded with other dimensions types. They are not listed
%     fully here but they may include:
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
% *RESEARCH NOTES*
%
% * FOR NOW, PARSING DIFFERENT FILES DO NOT APPEND DATA TO EXISTING
% FIELDS. ONLY NEW DATAGRAMS ARE COPIED. So if file 1 has Depth datagrams,
% and file 2 has depth and watercolumn datagrams, the function will save
% all datagrams in file 1 first (aka, Depth), and then IGNORE THE DEPTH
% DATAGRAMS IN THE SECOND FILE, only recording the water-column one. This
% is because I could not be bothered having to test for redundant dagrams
% in both files. In theory, this code is to use on a single file only, with
% the option to load several files being only used to load data from a .raw
% file and its corresponding .wcd file.
%
% * Have not tested the loading of data from 'EM_Depth' and
% 'EM_SeabedImage' in the new version. Might need debugging.
%
% * Possible improvement: maybe the loading of the EM_* datagrams can
% probably be done on a matfile basis...
%
% *NEW FEATURES*
%
% * 2017-10-06: remove the possibility to load FABCdata as a matfile. Was
% too slow (Alex Schimel)
% * 2017-10-04: complete re-ordering of dimensions, no backward
% compatibility so saving as a new function (v2) (Alex Schimel).
% * 2017-09-28: revamped code to allow loading data in a matfile, rather
% than in memory, as possible fix for large-memory files. Still to be fully
% tested (see research notes) (Alex Schimel).
% * 2017-09-28: updated header to new format, and updated contents, in
% preparation for revamping to handle large water-column data (Alex
% Schimel).
% * 2014-04-28: Fixed watercolumn data parsing for when some
% datagrams are missing. height datagram supported (Alex Schimel).
% * ????-??-??: Added support for XYZ88, seabed image 89 and WC
% * ????-??-??: Splitted seabed image samples per beam. Still not sorted
% * ????-??-??: Made all types of datagram optional
% * ????-??-??: Improved comments and general code
% * ????-??-??: Changed data origin codes to two letters
% * ????-??-??: Recording ASCII parameters as well
% * ????-??-??: Reading sound speed profile
%
% % *EXAMPLE*
%
% ALLfilename = '.\data\EM2040c\0001_20140213_052736_Yolla.all';
% MATfilename = '0001_20140213_052736_Yolla.mat';
% info = CFF_all_file_info(ALLfilename);
% info.parsed(:)=1; % to save all the datagrams
% ALLdata = CFF_read_all_from_fileinfo(ALLfilename, info);
% ALLfileinfo = CFF_save_mat_from_all(ALLdata, MATfilename);
% FABCdata = CFF_convert_mat_to_fabc_v2(MATfilename);
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Alexandre Schimel,Deakin University, NIWA

%% Function
function [FABCdata] = CFF_convert_mat_to_fabc_v2(MATfilename,varargin)


%% input parsing

% init
p = inputParser;

% required
addRequired(p,'MATfilename',@(x) ischar(x) || iscell(x));

% optional
addOptional(p,'dr_sub',1,@(x) isnumeric(x)&&x>0);
addOptional(p,'db_sub',1,@(x) isnumeric(x)&&x>0);

% parse
parse(p,MATfilename,varargin{:})

% get results
MATfilename = p.Results.MATfilename;
dr_sub = p.Results.dr_sub;
db_sub = p.Results.db_sub;
clear p;

%% pre-processing

% turn MATfilename to cell if string
if ischar(MATfilename)
    MATfilename = {MATfilename};
end

% number of files
nFiles = length(MATfilename);

% initialize FABC structre by writing MATfilename in it as metadata
FABCdata.MET_MATfilename = MATfilename;

% and the decimation factors
FABCdata.dr_sub = dr_sub;
FABCdata.db_sub = db_sub;


%% loop through all files and aggregate the datagrams contents

for iF = 1:nFiles
    
    % clear previous datagrams
    clear -regexp EM\w*
    
    % OPENING MAT FILE
    % research note: maybe these could be loaded through matfile, rather
    % than loading it all...
    file = MATfilename{iF};
    load(file);
    
    [dir_data,fname,~]=fileparts(file);
    % EM_InstallationStart (v2 VERIFIED)
    if exist('EM_InstallationStart','var')
        
        % only do if data of that type has not been recorded yet, aka:
        if ~isfield(FABCdata,'IP_ASCIIparameters')
            
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
    if exist('EM_SoundSpeedProfile','var')
        
        % only do if data of that type has not been recorded yet, aka:
        if ~isfield(FABCdata,'SS_1D_Date')
            
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
    if exist('EM_Attitude','var')
        
        % only do if data of that type has not been recorded yet, aka:
        if ~isfield(FABCdata,'At_1D_Date')
            
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
    if exist('EM_Height','var')
        
        % only do if data of that type has not been recorded yet, aka:
        if ~isfield(FABCdata,'He_1D_Date')
            
            % NumberOfDatagrams = length(EM_Height.TypeOfDatagram);
            
            FABCdata.He_1D_Date                            = EM_Height.Date;
            FABCdata.He_1D_TimeSinceMidnightInMilliseconds = EM_Height.TimeSinceMidnightInMilliseconds;
            FABCdata.He_1D_HeightCounter                   = EM_Height.HeightCounter;
            FABCdata.He_1D_Height                          = EM_Height.Height;
            
        end
        
    end
    
    % EM_Position (v2 verified)
    if exist('EM_Position','var')
        
        % only do if data of that type has not been recorded yet, aka:
        if ~isfield(FABCdata,'Po_1D_Date')
            
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
    if exist('EM_Depth','var')
        
        % only do if data of that type has not been recorded yet, aka:
        if ~isfield(FABCdata,'De_1P_Date')
            
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
    if exist('EM_XYZ88','var')
        
        % only do if data of that type has not been recorded yet, aka:
        if ~isfield(FABCdata,'X8_1P_Date')
            
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
    if exist('EM_SeabedImage','var')
        
        % only do if data of that type has not been recorded yet, aka:
        if ~isfield(FABCdata,'SI_1P_Date')
            
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
    if exist('EM_SeabedImage89','var')
        
        % only do if data of that type has not been recorded yet, aka:
        if ~isfield(FABCdata,'S8_1D_Date')
            
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
    if exist('EM_WaterColumn','var')
        
        % only do if data of that type has not been recorded yet, aka:
        if ~isfield(FABCdata,'WC_1P_Date')
                        
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
            if nPings*maxNBeams_sub*maxNSamples_sub < 10^6
                
                % use simple 3D data array
                
                % initialize data per decimated samples, decimated beams,
                % and pings
                FABCdata.WC_SBP_SampleAmplitudes.Data.val = nan(maxNSamples_sub,maxNBeams_sub,nPings);
                
            else
                
                % use memmap file
                
                % initialize binary file for writing
                tmpdir=fullfile(dir_data,'temp',fname);
                if exist(tmpdir,'dir')==0
                    mkdir(tmpdir);
                end
                
                file_binary = fullfile(tmpdir,'WC_SBP_SampleAmplitudes.dat');
                fileID = fopen(file_binary,'w+');
                
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
                SB_temp = nan(maxNSamples_sub,maxNBeams_sub,'single');
                
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
                    
                    % now getting watercolumn data (beams x samples)
                    for iB = 1:numel(iBeams)
                        % actual number of samples in that beam
                        Ns = EM_WaterColumn.NumberOfSamples{iDatagrams(iD)}(idx_beams(iB));
                        % number of samples we're going to record:
                        Ns_sub = ceil(Ns/dr_sub);
                        % get the data:
                        SB_temp(1:Ns_sub,iBeams(iB)) = EM_WaterColumn.SampleAmplitude{iDatagrams(iD)}{idx_beams(iB)}(1:dr_sub:end)';
                    end
                    
                end
                
                % store data
                if exist('fileID','var')
                    % write on binary file
                    fwrite(fileID,SB_temp,'single');
                else
                    % store as data
                    FABCdata.WC_SBP_SampleAmplitudes.Data.val(1:maxNSamples_sub,1:maxNBeams_sub,iP) = SB_temp;
                end
                
            end
            
            % close binary file if in this case
            if exist('fileID','var')
                % close binary file
                fclose(fileID);
                % re-open as memmapfile
                FABCdata.WC_SBP_SampleAmplitudes = memmapfile(file_binary,'Format',{'single' [maxNSamples_sub maxNBeams_sub nPings] 'val'},'repeat',1,'writable',true);
            end
            
        end
        
    end
    
    
    % other types of datagrams not supported yet.
    
end


% OLD CODE TO POSITION SEABED IMAGE SAMPLES RELATIVE TO BOTTOM DETECTION
% SAMPLES
% % if seabed image datagrams:
% if exist('EM_SeabedImage')
%
%     NumberOfPings = length(EM_SeabedImage.TypeOfDatagram); % total number of pings in file
%     NumberOfBeams = max(cellfun(@(x) max(x),EM_SeabedImage.BeamIndexNumber))+1; % maximum beam number (beam index number +1), in file
%
%     FABCdata.SI_1P_Date = EM_SeabedImage.Date';
%     FABCdata.SI_1P_TimeSinceMidnightInMilliseconds = EM_SeabedImage.TimeSinceMidnightInMilliseconds';
%     FABCdata.SI_1P_PingCounter = EM_SeabedImage.PingCounter';
%     FABCdata.SI_1P_MeanAbsorptionCoefficient = EM_SeabedImage.MeanAbsorptionCoefficient';
%     FABCdata.SI_1P_PulseLength = EM_SeabedImage.PulseLength';
%     FABCdata.SI_1P_RangeToNormalIncidence = EM_SeabedImage.RangeToNormalIncidence';
%     FABCdata.SI_1P_StartRangeSampleOfTVGRamp = EM_SeabedImage.StartRangeSampleOfTVGRamp';
%     FABCdata.SI_1P_StopRangeSampleOfTVGRamp = EM_SeabedImage.StopRangeSampleOfTVGRamp';
%     FABCdata.SI_1P_NormalIncidenceBS = EM_SeabedImage.NormalIncidenceBS';
%     FABCdata.SI_1P_ObliqueBS = EM_SeabedImage.ObliqueBS';
%     FABCdata.SI_1P_TxBeamwidth = EM_SeabedImage.TxBeamwidth';
%     FABCdata.SI_1P_TVGLawCrossoverAngle = EM_SeabedImage.TVGLawCrossoverAngle';
%     FABCdata.SI_1P_NumberOfValidBeams = EM_SeabedImage.NumberOfValidBeams';
%
%     % initialize
%     FABCdata.SI_BP_SortingDirection = nan(NumberOfPings,NumberOfBeams);
%     FABCdata.SI_BP_NumberOfSamplesPerBeam = nan(NumberOfPings,NumberOfBeams);
%     FABCdata.SI_BP_CentreSampleNumber = nan(NumberOfPings,NumberOfBeams);
%     FABCdata.SI_B1_BeamNumber = 1:NumberOfBeams;
%     FABCdata.SI_SBP_SampleAmplitudes = cell(NumberOfPings,1);
%
%     for iP = 1:NumberOfPings
%
%         % Get data from datagram
%         BeamNumber = cell2mat(EM_SeabedImage.BeamIndexNumber(iP))+1;
%         SortingDirection = cell2mat(EM_SeabedImage.SortingDirection(iP));
%         NumberOfSamplesPerBeam = cell2mat(EM_SeabedImage.NumberOfSamplesPerBeam(iP));
%         CentreSampleNumber = cell2mat(EM_SeabedImage.CentreSampleNumber(iP));
%         Samples = cell2mat(EM_SeabedImage.SampleAmplitudes(iP).beam(:));
%
%         % Get bottom sample number from Depth datagram
%         % depth datagram says "OWTT = range / sampling rate / 4"
%         % since OWTT = bottomsample# / (2 * sampling rate), then bottomsample# = "range"/2
%         % problem, this means bottom sample number as a 0.5 resolution
%         % (???)
%         BottomSample = ceil( FABCdata.De_BP_Range(BeamNumber,iP)' ./ 2 );
%
%         % from BottomSample and CentreSampleNumber, deduce numbers of first
%         % and last of recorded samples.
%         firstSampleNumber = 1 - CentreSampleNumber + BottomSample;
%         lastSampleNumber  = NumberOfSamplesPerBeam - CentreSampleNumber + BottomSample;
%
%         % min, max and total sample range for this ping.
%         minSampleNumber = min(firstSampleNumber);
%         maxSampleNumber = max(lastSampleNumber);
%         NumberOfSamples = maxSampleNumber-minSampleNumber+1;
%
%         % from number of samples per beam, get indices of first and last
%         % sample for each beam in the Samples data vector
%         iFirst =  [1;cumsum(NumberOfSamplesPerBeam(1:end-1))+1];
%         iLast = iFirst+NumberOfSamplesPerBeam-1;
%
%         % initialize the beams/sample array (use zero instead of NaN to
%         % allow turning it to sparse
%         temp = zeros(length(BeamNumber),NumberOfSamples);
%
%         % and fill in
%         for iB = 1:length(BeamNumber)
%             temp(iB,firstSampleNumber(iB)-minSampleNumber+1:lastSampleNumber(iB)-minSampleNumber+1) = Samples(iFirst(iB):iLast(iB));
%         end
%
%         % store
%         FABCdata.SI_BP_SortingDirection(BeamNumber,iP) = SortingDirection;
%         FABCdata.SI_BP_NumberOfSamplesPerBeam(BeamNumber,iP) = NumberOfSamplesPerBeam;
%         FABCdata.SI_BP_CentreSampleNumber(BeamNumber,iP) = CentreSampleNumber;
%
%         % store additional stuff:
%         FABCdata.SI_BP_BottomSample(BeamNumber,iP) = BottomSample; % from Depth datagram, see above for calculation
%         FABCdata.SI_BP_firstSampleNumber(BeamNumber,iP) = firstSampleNumber; % firstSampleNumber = 1 - CentreSampleNumber + BottomSample;
%         FABCdata.SI_BP_lastSampleNumber(BeamNumber,iP) = lastSampleNumber; % lastSampleNumber  = NumberOfSamplesPerBeam - CentreSampleNumber + BottomSample;
%
%         % and the data:
%         FABCdata.SI_SBP_SampleAmplitudes{iP} = sparse(temp);
%
%     end
%
% end
