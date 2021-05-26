%% CFF_kmall_file_info.m
%
% Records basic info about the datagrams contained in one binary raw data
% file in the Kongsberg EM series format .kmall.
%
%% Help
%
% *USE*
%
% KMALLfileinfo = CFF_kmall_file_info(KMALLfilename) opens file
% KMALLfilename and reads through the start of each datagram to get basic
% information about it, and store it all in KMALLfileinfo.
%
% *INPUT VARIABLES*
%
% * |KMALLfilename|: Required. String filename to parse (extension in
% .kmall or .kmwcd) 
%
% *OUTPUT VARIABLES*
%
% * |KMALLfileinfo|: structure containing information about datagrams in
% KMALLfilename, with fields:
%     * |file_name|: input file name
%     * |file_size|: file size in bytes
%     * |dgm_num|: number of datagram in file
%     * |dgm_type_code|: datagram type as string, e.g. '#IIP' (Kongsberg .kmall
%     format)
%     * |dgm_type_text|: datagram type description (Kongsberg .kmall format)
%     * |dgm_type_version|: version for this type of datagram, as int (Kongsberg
%     .kmall format)
%     * |dgm_counter|: counter for this type and version of datagram
%     in the file. There should not be multiple versions of a same type in
%     a same file, but we never know...
%     * |dgm_start_pif|: position of beginning of datagram in
%     file 
%     * |dgm_size|: datagram size in bytes
%     * |dgm_sys_ID|: System ID. Parameter used for separating datagrams from
%     different echosounders.
%     * |dgm_EM_ID|: Echo sounder identity, e.g. 124, 304, 712, 2040,
%     2045 (EM 2040C)
%     * |sync_counter|: number of bytes found between this datagram and the
%     previous one (any number different than zero indicates a sync error)
%     * |date_time|: datagram date in datetime format
%     * |parsed|: flag for whether the datagram has been parsed. Initiated
%     at 0 at this stage. To be later turned to 1 for parsing.
%
% *DEVELOPMENT NOTES*
%
% * NA
%
% *NEW FEATURES*
%
% * 2021-05-26: first version, inspired from CFF_all_file_info.m and
% CFF_s7k_file_info.m. (Alex)
%
% *EXAMPLE*
%
% KMALLfilename = '.\data\EM304\0000_20200428_101105_ShipName.kmall';
% KMALLfileinfo = CFF_kmall_file_info(KMALLfilename);
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Alexandre Schimel (NGU), Yoann Ladroit (NIWA). 
% Type |help CoFFee.m| for copyright information.

%% Function
function KMALLfileinfo = CFF_kmall_file_info(KMALLfilename)

%% Input arguments management using inputParser
p = inputParser;

% KMALLfilename to parse as only required argument. Test for file existence and
% extension.
argName = 'KMALLfilename';
argCheck = @(x) CFF_check_KMALLfilename(x);
addRequired(p,argName,argCheck);

% now parse inputs
parse(p,KMALLfilename)

% and get results
KMALLfilename = p.Results.KMALLfilename;


%% Open file and initializing
% kmall files are in little Endian 'l', which is the default with fopen
[fid,~] = fopen(KMALLfilename, 'r');

% go to end of file to get number of bytes in file then rewind
fseek(fid,0,1);
file_size = ftell(fid);
fseek(fid,0,-1);

% create ouptut info file if required
if nargout
    KMALLfileinfo.file_name = KMALLfilename;
    KMALLfileinfo.file_size = file_size;
end

% initialize list of datagram types and counter
list_dgm_typeversion = {};
list_dgm_counter = [];

% intitializing the counter of datagrams in this file
kk = 0;

% initializing synchronization counter: the number of bytes that needed to
% be passed before this datagram appeared
sync_counter = 0;


%% Reading datagrams
next_dgm_start_pif = 0;
while next_dgm_start_pif < file_size
    
    % new record begins
    dgm_start_pif = ftell(fid);
    
    
    %% test for synchronization and datagram completeness
    %
    % A kmall datagram starts with the general header (EMdgmHeader_def),
    % which starts with datagram size (uint32) and datagram type definition
    % (e.g. #AAA). Then comes the rest of the datagram, depending on its
    % type. Finally, the datagram ends with a repeat of its size in bytes
    % (uint32). 
    %
    % We will test for both datagram completeness and sync by matching the
    % datagram size fields, and checking for the hash symbol at the
    % beggining of the datagram type definition.
    
    % Starting parsing general header
    numBytesDgm_start = fread(fid,1,'uint32'); % Datagram length in bytes
    dgmType           = char(fread(fid,4,'uchar')'); % Datagram type definition, e.g. #AAA
    
    % pif of presumed end of datagram
    dgm_end_pif = dgm_start_pif + numBytesDgm_start - 4;
    
    % get the repeat file_size at the end of the datagram
    if dgm_end_pif < file_size
        pif_temp = ftell(fid);
        fseek(fid, dgm_end_pif, -1);
        numBytesDgm_end  = fread(fid,1,'uint32'); % Datagram length in bytes
        next_dgm_start_pif = ftell(fid);
        fseek(fid, pif_temp, -1); % rewind
    else
        % Being here can be due to two things: either 1) we are in sync but
        % this datagram is incomplete, or 2) we are out of syn.
        numBytesDgm_end = [];
    end
    
    flag_numBytesDgm_match = numBytesDgm_start == numBytesDgm_end;
    flag_hash = strcmp(dgmType(1), '#');
    
    if ~flag_numBytesDgm_match || ~flag_hash
        % We've either lost sync, or the last datagram is incomplete
        % go back to new record start, advance one byte, and restart
        % reading
        fseek(fid, dgm_start_pif+1, -1);
        next_dgm_start_pif = -1;
        sync_counter = sync_counter+1; % update sync counter
        if sync_counter == 1
            % just lost sync, throw a message just now
            warning('Lost sync while reading datagrams. A record may be corrupted. Trying to resync...');
        end
        continue;
    else
        % In sync, and datagram complete
        if sync_counter
            % if we had lost sync, warn here we're back
            warning('Back in sync (%i bytes later)',sync_counter);
            % reinitialize sync counter
            sync_counter = 0;
        end
    end
    
    % finish parsing general header
    dgmVersion    = fread(fid,1,'uint8');  % Datagram version
    systemID      = fread(fid,1,'uint8');  % System ID. Parameter used for separating datagrams from different echosounders
    echoSounderID = fread(fid,1,'uint16'); % Echo sounder identity, e.g. 124, 304, 712, 2040, 2045 (EM 2040C)
    time_sec      = fread(fid,1,'uint32'); % UTC time in seconds. Epoch 1970-01-01. time_nanosec part to be added for more exact time. 
    time_nanosec  = fread(fid,1,'uint32'); % Nano seconds remainder. time_nanosec part to be added to time_sec for more exact time. 
        

    %% process time
    dgm_date_time = datetime(time_sec + time_nanosec.*10^-9,'ConvertFrom','posixtime');
    
    
    %% datagram type counter
    
    % combine type and version
    dgm_typeversion = [dgmType '_v' num2str(dgmVersion)];
    
    % index of datagram type in the list
    idx_dgmType = find(cellfun(@(x) strcmp(dgm_typeversion,x), list_dgm_typeversion));
    
    if isempty(idx_dgmType)
        % new type, add it to the list
        idx_dgmType = numel(list_dgm_typeversion) + 1;
        list_dgm_typeversion{idx_dgmType,1} = dgm_typeversion;
        list_dgm_counter(idx_dgmType,1) = 0;
    end
    
    % increment counter
    list_dgm_counter(idx_dgmType) = list_dgm_counter(idx_dgmType) + 1;
    dgm_counter = list_dgm_counter(idx_dgmType);
    
    
    %% write output KMALLfileinfo
    
    % record complete
    kk = kk+1;
    
    % Datagram number in file
    KMALLfileinfo.dgm_num(kk,1) = kk;
    
    % Datagram info
    KMALLfileinfo.dgm_type_code{kk,1}    = dgmType;
    KMALLfileinfo.dgm_type_text{kk,1}    = get_dgm_type_txt(dgmType);
    KMALLfileinfo.dgm_type_version(kk,1) = dgmVersion;
    KMALLfileinfo.dgm_counter(kk,1)      = dgm_counter;
    KMALLfileinfo.dgm_start_pif(kk,1)    = dgm_start_pif;
    KMALLfileinfo.dgm_size(kk,1)         = numBytesDgm_start;
    
    % System info
    KMALLfileinfo.dgm_sys_ID(kk,1) = systemID;
    KMALLfileinfo.dgm_EM_ID(kk,1)  = echoSounderID;
    
    % report sync issues in reading, if any
    KMALLfileinfo.sync_counter(kk,1) = sync_counter;
    
    % Time info
    KMALLfileinfo.date_time(kk,1) = dgm_date_time;

    %% prepare for reloop
    
    % go to end of datagram
    fseek(fid, next_dgm_start_pif, -1);
    
end


%% finalizing

% adding lists
KMALLfileinfo.list_dgm_typeversion = list_dgm_typeversion;
KMALLfileinfo.list_dgm_counter = list_dgm_counter;

% initialize parsing field
KMALLfileinfo.parsed = zeros(size(KMALLfileinfo.dgm_num));

% closing file
fclose(fid);

end

%% subfunctions
function dgm_type_text = get_dgm_type_txt(dgm_type_code)

list_dgm_type_text = {...
    '#IIP - Installation parameters and sensor setup';...
    '#IOP - Runtime parameters as chosen by operator';...
    '#IBE - Built in test (BIST) error report';...
    '#IBR - Built in test (BIST) reply';...
    '#IBS - Built in test (BIST) short reply';...
    '#MRZ - Multibeam (M) raw range (R) and depth(Z) datagram';...
    '#MWC - Multibeam (M) water (W) column (C) datagram';...
    '#SPO - Sensor (S) data for position (PO)';...
    '#SKM - Sensor (S) KM binary sensor format';...
    '#SVP - Sensor (S) data from sound velocity (V) profile (P) or CTD';...
    '#SVT - Sensor (S) data for sound velocity (V) at transducer (T)';...
    '#SCL - Sensor (S) data from clock (CL)';...
    '#SDE - Sensor (S) data from depth (DE) sensor';...
    '#SHI - Sensor (S) data for height (HI)';...
    '#CPO - Compatibility (C) data for position (PO)';...
    '#CHE - Compatibility (C) data for heave (HE)';...
    '#FCF - Backscatter calibration (C) file (F) datagram' ...
    };

idx = find(cellfun(@(x) strcmp(x(1:4),dgm_type_code), list_dgm_type_text));

if ~isempty(idx)
    dgm_type_text = list_dgm_type_text{idx};
else
    dgm_type_text = sprintf('%i - UNKNOWN RECORD TYPE',dgm_type_code);
end

end
