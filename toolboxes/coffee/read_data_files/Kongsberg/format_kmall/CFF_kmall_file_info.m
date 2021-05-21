%% CFF_kmall_file_info.m
%
% Records basic info about the datagrams contained in one Kongsberg EM
% series binary .kmall or .kmwcd data file. 
%
%% Help
%
% *USE*
%
% KMALLfileinfo = CFF_kmall_file_info(KMALLfilename) opens KMALLfilename and reads
% through quickly to get information about each datagram, and store this
% info in KMALLfileinfo.
%
% *INPUT VARIABLES*
%
% * |KMALLfilename|: Required. String filename to parse (extension in .kmall or
% .kmwcd) 
%
% *OUTPUT VARIABLES*
%
% * |KMALLfileinfo|: structure containing information about datagrams in
% KMALLfilename, with fields:  
%     * |KMALLfilename|: input file name
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
% *DEVELOPMENT NOTES*
%
% * The code currently lists the EM model numbers supported as a test for
% sync. Add your model number in the list if it is not currently there (and
% if the parsing works). It would be better to remove this test and try to
% sync on ETX and Checksum instead.
% * Check regularly with Kongsberg doc to keep updated with new datagrams.
%
% *NEW FEATURES*
%
% * 2018-10-11: updated header before adding to Coffee v3
% * 2017-10-17: changed way filesize is calculated without it reading the
% entire file
% * 2017-06-29: header updated
% * 2015-09-30: first version taking from convert_kmall_to_mat
%
% *EXAMPLE*
%
% KMALLfilename = '.\data\EM2040c\0001_20140213_052736_Yolla.kmall';
% KMALLfileinfo = CFF_kmall_file_info(KMALLfilename);
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Alexandre Schimel, Waikato University, Deakin University, NIWA.

%% Function
function KMALLfileinfo = CFF_kmall_file_info(KMALLfilename)

%% Input arguments management using inputParser
p = inputParser;

% KMALLfilename to parse as only required argument. Test for file existence and
% extension.
argName = 'KMALLfilename';
argCheck = @(x) exist(x,'file') && any(strcmp(CFF_file_extension(x),{'.kmall','.KMALL','.kmwcd','.KMWCD'}));
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
filesize = ftell(fid);
fseek(fid,0,-1);

% create ouptut info file if required
if nargout
    KMALLfileinfo.KMALLfilename   = KMALLfilename;
    KMALLfileinfo.filesize        = filesize;
    KMALLfileinfo.datagsizeformat = 'l';
    KMALLfileinfo.datagramsformat = 'l';
end

% initialize list of datagram types
list_dgmTypeVer = {};

% intitializing the counter of datagrams in this file
kk = 0;

% initializing synchronization counter: the number of bytes that needed to
% be passed before this datagram appeared
syncCounter = 0;


%% Reading datagrams
pif_nextrecordstart = 0;
while pif_nextrecordstart < filesize
    
    % new record begins
    pif_recordstart = ftell(fid);
    
    
    %% reading record
    % A kmall datagram is organized as a sequence of:
    % * the general header, EMdgmHeader_def
    % * ...
    % * size of the datagram in bytes (uint32)
    
    % Parsing general header
    numBytesDgm   = fread(fid,1,'uint32'); % Datagram length in bytes
    dgmType       = fread(fid,4,'uchar');  % Datagram type definition, e.g. #AAA 
    dgmVersion    = fread(fid,1,'uint8');  % Datagram version
    systemID      = fread(fid,1,'uint8');  % System ID. Parameter used for separating datagrams from different echosounders
    echoSounderID = fread(fid,1,'uint16'); % Echo sounder identity, e.g. 124, 304, 712, 2040, 2045 (EM 2040C)
    time_sec      = fread(fid,1,'uint32'); % UTC time in seconds. Epoch 1970-01-01. time_nanosec part to be added for more exact time. 
    time_nanosec  = fread(fid,1,'uint32'); % Nano seconds remainder. time_nanosec part to be added to time_sec for more exact time. 
        

    %% process time
    datetime(time_sec, 'posixtime');

    
    %% write output KMALLfileinfo
    
    % record complete
    kk = kk+1;
    
    % Datagram number in file
    KMALLfileinfo.datagNumberInFile(kk,1) = kk;
    
    % Datagram info
    KMALLfileinfo.dgmSize(kk,1) = numBytesDgm;
    KMALLfileinfo.dgmType(kk,1) = dgmType;
    KMALLfileinfo.dgmVersion(kk,1) = dgmVersion;
    
    % System info
    KMALLfileinfo.systemID(kk,1) = systemID;
    KMALLfileinfo.echoSounderID(kk,1) = echoSounderID;
    
    % Time
    KMALLfileinfo.timeSinceMidnightInMilliseconds(kk,1) = timeSinceMidnightInMilliseconds;
    
    
    KMALLfileinfo.parsed(kk,1) = 0;
    
    %% datagram type counter
    
    % combine type and version
    dgmTypeVer = [dgmType ' v' num2str(dgmVersion)];
    
    % index of datagram type in the list
    dgmTypeVer_idx = find(dgmTypeVer == list_dgmTypeVer);
    
    if isempty(dgmTypeVer_idx)
        % new type, add it to the list
        dgmTypeVer_idx = length(list_dgmTypeVer) + 1;
    end
    
    % increment counter
    list_dgmTypeVerCounter{dgmTypeVer_idx} = list_dgmTypeVerCounter{dgmTypeVer_idx} + 1;
    dgmTypeVerCounter = list_dgmTypeVerCounter{dgmTypeVer_idx};
    
    
    
    
    
    % go to end of datagram
    fseek(fid,pif_recordstart+4+nbDatag,-1);
    
end



%% closing file
fclose(fid);


