%% CFF_s7k_file_info.m
%
% Records basic info about the datagrams contained in one binary raw data
% file in the Teledyne-Reson format .s7k.
%
%% Help
%
% *USE*
%
% S7Kfileinfo = CFF_s7k_file_info(S7Kfilename) opens file S7Kfilename and
% reads through the start of each datagram to get basic information about
% it, and store it all in S7Kfileinfo.
%
% *INPUT VARIABLES*
%
% * |S7Kfilename|: Required. String filename to parse (extension in .s7k)
%
% *OUTPUT VARIABLES*
%
% * |S7Kfileinfo|: structure containing information about records in
% S7Kfilename, with fields:
%     * |S7Kfilename|: input file name
%     * |filesize|: file size in bytes
%     * |datagsizeformat|: endianness of the datagram size field. Always
%     'l' for .s7k files
%     * |datagramsformat|: endianness of the datagrams 'b' or 'l'. Always
%     'l' for .s7k files
%     * |recordNumberInFile|: number of record in file
%     * |recordTypeIdentifier|: record type in int (Reson .s7k format) 
%     * |recordTypeText|: record type description (Reson .s7k format)
%     * |recordTypeCounter|: counter of this type of record in the file (ie
%     first record of that type is 1 and last record is the total
%     number of record of that type)
%     * |recordStartPositionInFile|: position of beginning of record in
%     file 
%     * |record_size|: record size in bytes
%     * |DRF_size|: size of the "Data Record Frame" part of the record
%     (Reson .s7k format)
%     * |RTHandRD_size|: combined size of the "Record Type Header" and
%     "Record Data" parts of the record (Reson .s7k format)
%     * |OD_offset|: size of the Data Record Frame part of the record
%     (Reson .s7k format)
%     * |OD_size|: size of the "Optional Data" part of the record (Reson
%     .s7k format)
%     * |CS_size|: size of the "Checksum" part of the record (Reson .s7k
%     format)
%     * |syncCounter|: number of bytes found between this record and the
%     previous one (any number different than zero indicates a sync error)
%     * |date|: datagram date in YYYMMDD
%     * |timeSinceMidnightInMilliseconds|: time since midnight in
%     milliseconds
%     * |parsed|: flag for whether the record has been parsed. Initiated
%     at 0 at this stage. To be later turned to 1 for parsing.
%
% *DEVELOPMENT NOTES*
%
% * Check regularly with Reson doc to keep updated with new datagrams.
%
% *NEW FEATURES*
%
% * 2021-05-26: docstring updated
% * ????-??-??: first version, inspired from CFF_all_file_info.m
%
% *EXAMPLE*
%
% S7Kfilename = '.\data\EM2040c\0001_20140213_052736_Yolla.s7k';
% S7Kfileinfo = CFF_s7k_file_info(S7Kfilename);
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Alexandre Schimel (NGU, NIWA), Yoann Ladroit (NIWA). 
% Type |help CoFFee.m| for copyright information.

%% Function
function S7Kfileinfo = CFF_s7k_file_info(S7Kfilename)

%% Input arguments management using inputParser
p = inputParser;

% S7Kfilename to parse as only required argument. Test for file existence and
% extension.
argName = 'S7Kfilename';
argCheck = @(x) CFF_check_S7Kfilename(x);
addRequired(p,argName,argCheck);

% now parse inputs
parse(p,S7Kfilename)

% and get results
S7Kfilename = p.Results.S7Kfilename;

%% Records available according to documentation
% if this requires udpate, just modify list but ensure first four
% characters make up the record type identifier
list_recordTypeText = {...
    '1000 – Reference Point';...
    '1001 – Sensor Offset Position';...
    '1002 – Sensor Offset Position Calibrated';...
    '1003 – Position';...
    '1004 – Custom Attitude Information';...
    '1005 – Tide';...
    '1006 – Altitude';...
    '1007 – Motion Over Ground';...
    '1008 – Depth';...
    '1009 – Sound Velocity Profile';...
    '1010 – CTD';...
    '1011 – Geodesy';...
    '1012 – Roll Pitch Heave';...
    '1013 – Heading';...
    '1014 – Survey Line';...
    '1015 – Navigation';...
    '1016 – Attitude';...
    '1017 – Pan Tilt';...
    '1020 – Sonar Installation Identifiers';...
    '2004 – Sonar Pipe Environment';...
    '3001 – Contact Output';...
    '7000 – 7k Sonar Settings';...
    '7001 – 7k Configuration';...
    '7002 – 7k Match Filter';...
    '7003 – 7k Firmware and Hardware Configuration';...
    '7004 – 7k Beam Geometry';...
    '7006 – 7k Bathymetric Data';...
    '7007 – 7k Side Scan Data';...
    '7008 – 7k Generic Water Column Data';...
    '7010 – TVG Values';...
    '7011 – 7k Image Data';...
    '7012 – 7k Ping Motion Data';...
    '7017 – 7k Detection Data Setup';...
    '7018 – 7k Beamformed Data';...
    '7019 – Vernier Processing Data (Raw)';...
    '7021 – 7k Built-In Test Environment Data';...
    '7022 – 7kCenter Version';...
    '7023 – 8k Wet End Version';...
    '7027 – 7k RAW Detection Data';...
    '7028 – 7k Snippet Data';...
    '7029 – Vernier Processing Data (Filtered)';...
    '7030 – Sonar Installation Parameters';...
    '7031 – 7k Built-In Test Environment Data (Summary)';...
    '7041 – Compressed Beamformed Magnitude Data';...
    '7042 - Compressed Watercolumn Data';...
    '7048 – 7k Calibrated Beam Data';...
    '7050 – 7k System Events';...
    '7051 – 7k System Event Message';...
    '7052 – RDR Recording Status - Detailed';...
    '7053 – 7k Subscriptions';...
    '7054 – RDR Storage Recording – Short Update';...
    '7055 – Calibration Status';...
    '7057 – Calibrated Side-Scan Data';...
    '7058 – Snippet Backscattering Strength';...
    '7059 – MB2 specific status';...
    '7200 – 7k File Header';...
    '7300 – 7k File Catalog Record';...
    '7400 – 7k Time Message';...
    '7500 – 7k Remote Control';...
    '7501 – 7k Remote Control Acknowledge';...
    '7502 – 7k Remote Control Not Acknowledge';...
    '7503 – Remote Control Sonar Settings';...
    '7504 – 7P Common System Settings';...
    '7510 – SV Filtering';...
    '7511 – System Lock Status';...
    '7610 – 7k Sound Velocity';...
    '7611 – 7k Absorption Loss';...
    '7612 – 7k Spreading Loss' ...
    }; 

% identifiers
list_recordTypeIdentifier = cellfun(@(x) str2double(x(1:4)), list_recordTypeText);


%% Open file and initializing
% s7k files are in little Endian 'l', which is the default with fopen
[fid,~] = fopen(S7Kfilename, 'r');

% go to end of file to get number of bytes in file then rewind
fseek(fid,0,1);
filesize = ftell(fid);
fseek(fid,0,-1);

% create ouptut info file if required
if nargout
    S7Kfileinfo.S7Kfilename     = S7Kfilename;
    S7Kfileinfo.filesize        = filesize;
    S7Kfileinfo.datagsizeformat = 'l';
    S7Kfileinfo.datagramsformat = 'l';
end

% intitializing the counter of total records in this file, and records of
% given type
kk = 0;
list_recordTypeCounter = zeros(size(list_recordTypeIdentifier));

% initializing synchronization counter: the number of bytes that needed to
% be passed before this datagram appeared
syncCounter = 0;


%% Reading s7k records
pif_nextrecordstart = 0;
while pif_nextrecordstart < filesize
    
    % new record begins
    pif_recordstart = ftell(fid);
    
    %% reading record
    % A full s7k record is organized as a sequence of:
    % * DRF - Data Record Frame (64 bytes, at least for protocol version 5)
    % * RTH - Record Type Header (variable size)
    % * RD - Record Data (optional, variable size)
    % * OD - Optional Data (optional, variable size)
    % * CS - Checksum (optional, 4 bytes)
    
    % Starting parsing DRF
    protocolVersion = fread(fid,1,'uint16');
    DRF_offset      = fread(fid,1,'uint16'); % should be 60, for version 5
    syncPattern     = fread(fid,1,'uint32');
    
    % test for synchronization
    if protocolVersion~=5 || DRF_offset~=60 || syncPattern~=65535
        % NOT SYNCHRONIZED
        % go back to new record start, advance one byte, and restart
        % reading
        fseek(fid, pif_recordstart+1, -1);
        pif_nextrecordstart = 0;
        syncCounter = syncCounter+1; % update sync counter
        if syncCounter == 1
            warning('Lost sync while reading datagrams. A record may be corrupted. Trying to resync...');
        end
        continue;
    else
        % SYNCHRONIZED
        if syncCounter
            % if we had lost sync, warn here we're back
            warning('Back in sync (%i bytes later)',syncCounter);
            % reinitialize sync counter
            syncCounter = 0;
        end
    end
    
    % finish parsing DRF
    record_size            = fread(fid,1,'uint32');
    optionalDataOffset     = fread(fid,1,'uint32');
    optionalDataIdentifier = fread(fid,1,'uint32');
    sevenKTime_year        = fread(fid,1,'uint16');
    sevenKTime_day         = fread(fid,1,'uint16');
    sevenKTime_seconds     = fread(fid,1,'float32');
    sevenKTime_hours       = fread(fid,1,'uint8');
    sevenKTime_minutes     = fread(fid,1,'uint8');
    recordVersion          = fread(fid,1,'uint16');
    recordTypeIdentifier   = fread(fid,1,'uint32');
    deviceIdentifier       = fread(fid,1,'uint32');
    reserved1              = fread(fid,1,'uint16');
    systemEnumerator       = fread(fid,1,'uint16');
    reserved2              = fread(fid,1,'uint32');
    flags                  = fread(fid,1,'uint16');
    reserved3              = fread(fid,1,'uint16');
    reserved4              = fread(fid,1,'uint32');
    totalRecordsInFragmentedDataRecordSet = fread(fid,1,'uint32');
    fragmentNumber         = fread(fid,1,'uint32');
    
    % size of DRF in bytes
    DRF_size = DRF_offset + 4;
    
    % checksum size
    if mod(flags,2)
        % flag is an odd number, aka the last 4 bytes of the record are the checksum
        CS_size = 4;
    else
        % flag is an even number, aka no checksum
        CS_size = 0;
    end
    
    % position in file of start of RTH (this is where we should be now)
    % pif_RTHstart = pif_recordstart + DRF_size;
    
    % position in file of next record
    pif_nextrecordstart = pif_recordstart + record_size;
    
    % size of OD and position in file
    if optionalDataOffset == 0
        % no OD
        OD_size = 0;
        % pif_ODstart = NaN;
    else
        OD_size = record_size - ( optionalDataOffset + CS_size);
        % pif_ODstart = pif_recordstart + optionalDataOffset;
    end
    
    % size of the actual data section (RTH and RD)
    RTHandRD_size = record_size - ( DRF_size + OD_size + CS_size);
    
    
    %% record type text and counter
    
    % index of record type in the list
    recordType_idx = find(recordTypeIdentifier == list_recordTypeIdentifier);
    
    if isempty(recordType_idx)
        
        % this record type is not recognized
        recordTypeText = sprintf('%i - UNKNOWN RECORD TYPE',recordTypeIdentifier);
        recordTypeCounter = NaN;
        
    else
        
        % record type text
        recordTypeText = list_recordTypeText{recordType_idx};
        
        % increment counter for this record type
        list_recordTypeCounter(recordType_idx) = list_recordTypeCounter(recordType_idx) + 1;
        recordTypeCounter = list_recordTypeCounter(recordType_idx);
        
    end
   
    %% write output S7Kfileinfo
    
    % record complete
    kk = kk + 1;
    
    % record number in file
    S7Kfileinfo.recordNumberInFile(kk,1) = kk;
    
    % Type of record info
    S7Kfileinfo.recordTypeIdentifier(kk,1) = recordTypeIdentifier;
    S7Kfileinfo.recordTypeText{kk,1}       = recordTypeText;
    S7Kfileinfo.recordTypeCounter(kk,1)    = recordTypeCounter;
    
    % position of start of record in file
    S7Kfileinfo.recordStartPositionInFile(kk,1) = pif_recordstart;
    
    % size of record and its components
    S7Kfileinfo.record_size(kk,1)   = record_size;
    S7Kfileinfo.DRF_size(kk,1)      = DRF_size;
    S7Kfileinfo.RTHandRD_size(kk,1) = RTHandRD_size;
    
    S7Kfileinfo.OD_offset(kk,1)     = optionalDataOffset;
    S7Kfileinfo.OD_size(kk,1)       = OD_size;
    S7Kfileinfo.CS_size(kk,1)       = CS_size;
    
    % report sync issue if any
    S7Kfileinfo.syncCounter(kk,1) = syncCounter;
    
    % record time info
    S7Kfileinfo.date{kk,1} = datenum(sevenKTime_year,0, sevenKTime_day);
    S7Kfileinfo.timeSinceMidnightInMilliseconds(kk,1) = (sevenKTime_hours.*3600 + sevenKTime_minutes.*60 + sevenKTime_seconds).*1000;
    
    
    %% prepare for reloop
    
    % go to end of record
    fseek(fid, pif_nextrecordstart, -1);
    
end

% date as string
S7Kfileinfo.date = cellfun(@(x) datestr(x,'yyyymmdd'),S7Kfileinfo.date,'un',0);

% initialize parsing field
S7Kfileinfo.parsed = zeros(size(S7Kfileinfo.recordNumberInFile));

% close file
fclose(fid);


