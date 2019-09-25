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
    OD_size       =  S7Kfileinfo.OD_size(iDatag);
    CS_size       = S7Kfileinfo.CS_size(iDatag);
    
    % Go directly to the start of RTH
    pif_current = ftell(fid);
    fread(fid, pif_recordstart - pif_current + DRF_size);
    
    % reset the parsed switch
    parsed = 0;
    
    switch recordTypeIdentifier
        
        case 7027 
            %% '7027 – 7k RAW Detection Data'
            if ~(isempty(p.Results.OutputFields)||any(strcmp('7027_RAWdetection',p.Results.OutputFields)))
                continue;
            end
            
            % counter for this type of datagram
            try i7027=i7027+1; catch, i7027=1; end
            
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
            
            % parsing OD
            % ... TO DO XXX
            if OD_size~=0
                tmp_OD = fread(fid,OD_size,'uint8');
            else
                tmp_OD = NaN;
            end
            
            % parsing CS
            if CS_size == 4
                S7Kdata.R7027_RAWdetection.Checksum(i7027) = fread(fid,1,'uint32');
            elseif CS_size == 0
                S7Kdata.R7027_RAWdetection.Checksum(i7027) = NaN;
            else
                error('unexpected CS size');
            end
            % check data integrity with checksum... TO DO XXX
            
            % confirm parsing
            parsed = 1;
            
        
        case 7042 
            %% 'Compressed Watercolumn Data'
            if ~(isempty(p.Results.OutputFields)||any(strcmp('7042_CompressedWaterColumn',p.Results.OutputFields)))
                continue;
            end
            
            % counter for this type of datagram
            try i7042=i7042+1; catch, i7042=1; end
            
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
            % is not enabled (type = “none”).  
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
                    error;
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
                    error;
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
                
                % parsing OD
                % ... TO DO XXX
                if OD_size~=0
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
                    error('unexpected CS size');
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
            %% '7200 – 7k File Header'
            if ~(isempty(p.Results.OutputFields)||any(strcmp('7200_FileHeader',p.Results.OutputFields)))
                continue;
            end
            
            % counter for this type of datagram
            try i7200=i7200+1; catch, i7200=1; end
            
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
            
            % parsing OD
            if OD_size == 12
                S7Kdata.R7200_FileHeader.Size(i7200)   = fread(fid,1,'uint32');
                S7Kdata.R7200_FileHeader.Offset(i7200) = fread(fid,1,'uint64');
            elseif OD_size == 0
                S7Kdata.R7200_FileHeader.Size(i7200)   = NaN;
                S7Kdata.R7200_FileHeader.Offset(i7200) = NaN;
            else
                error('unexpected OD size');
            end
            
            % parsing CS
            if CS_size == 4
                S7Kdata.R7200_FileHeader.Checksum(i7200) = fread(fid,1,'uint32');
            elseif CS_size == 0
                S7Kdata.R7200_FileHeader.Checksum(i7200) = NaN;
            else
                error('unexpected CS size');
            end
            % check data integrity with checksum... TO DO XXX
            
            % confirm parsing
            parsed = 1;
            
            
%         case 65 % 'ATTITUDE (41H)'
%             if ~(isempty(p.Results.OutputFields)||any(strcmp('EM_Attitude',p.Results.OutputFields)))
%                 continue;
%             end
%             % counter for this type of datagram
%             try i65=i65+1; catch, i65=1; end
%             
%             % parsing
%             S7Kdata.EM_Attitude.NumberOfBytesInDatagram(i65)                = nbDatag;
%             S7Kdata.EM_Attitude.STX(i65)                                    = stxDatag;
%             S7Kdata.EM_Attitude.TypeOfDatagram(i65)                         = datagTypeNumber;
%             S7Kdata.EM_Attitude.EMModelNumber(i65)                          = emNumber;
%             S7Kdata.EM_Attitude.Date(i65)                                   = date;
%             S7Kdata.EM_Attitude.TimeSinceMidnightInMilliseconds(i65)        = timeSinceMidnightInMilliseconds;
%             S7Kdata.EM_Attitude.AttitudeCounter(i65)                        = number;
%             S7Kdata.EM_Attitude.SystemSerialNumber(i65)                     = systemSerialNumber;
%             
%             S7Kdata.EM_Attitude.NumberOfEntries(i65)                        = fread(fid,1,'uint16'); %N
%             
%             % repeat cycle: N entries of 12 bits
%             temp = ftell(fid);
%             N = S7Kdata.EM_Attitude.NumberOfEntries(i65) ;
%             S7Kdata.EM_Attitude.TimeInMillisecondsSinceRecordStart{i65} = fread(fid,N,'uint16',12-2);
%             fseek(fid,temp+2,'bof'); % to next data type
%             S7Kdata.EM_Attitude.SensorStatus{i65}                       = fread(fid,N,'uint16',12-2);
%             fseek(fid,temp+4,'bof'); % to next data type
%             S7Kdata.EM_Attitude.Roll{i65}                               = fread(fid,N,'int16',12-2);
%             fseek(fid,temp+6,'bof'); % to next data type
%             S7Kdata.EM_Attitude.Pitch{i65}                              = fread(fid,N,'int16',12-2);
%             fseek(fid,temp+8,'bof'); % to next data type
%             S7Kdata.EM_Attitude.Heave{i65}                              = fread(fid,N,'int16',12-2);
%             fseek(fid,temp+10,'bof'); % to next data type
%             S7Kdata.EM_Attitude.Heading{i65}                            = fread(fid,N,'uint16',12-2);
%             fseek(fid,2-12,'cof'); % we need to come back after last jump
%             
%             S7Kdata.EM_Attitude.SensorSystemDescriptor(i65)                 = fread(fid,1,'uint8');
%             S7Kdata.EM_Attitude.ETX(i65)                                    = fread(fid,1,'uint8');
%             S7Kdata.EM_Attitude.CheckSum(i65)                               = fread(fid,1,'uint16');
%             
%             % ETX check
%             if S7Kdata.EM_Attitude.ETX(i65)~=3
%                 error('wrong ETX value (S7Kdata.EM_Attitude)');
%             end
%             
%             % confirm parsing
%             parsed = 1;
%             
%         case 67 % 'CLOCK (43H)'
%             if ~(isempty(p.Results.OutputFields)||any(strcmp('EM_Clock',p.Results.OutputFields)))
%                 continue;
%             end
%             % counter for this type of datagram
%             try i67=i67+1; catch, i67=1; end
%             
%             % parsing
%             S7Kdata.EM_Clock.NumberOfBytesInDatagram(i67)                          = nbDatag;
%             S7Kdata.EM_Clock.STX(i67)                                              = stxDatag;
%             S7Kdata.EM_Clock.TypeOfDatagram(i67)                                   = datagTypeNumber;
%             S7Kdata.EM_Clock.EMModelNumber(i67)                                    = emNumber;
%             S7Kdata.EM_Clock.Date(i67)                                             = date;
%             S7Kdata.EM_Clock.TimeSinceMidnightInMilliseconds(i67)                  = timeSinceMidnightInMilliseconds;
%             S7Kdata.EM_Clock.ClockCounter(i67)                                     = number;
%             S7Kdata.EM_Clock.SystemSerialNumber(i67)                               = systemSerialNumber;
%             
%             S7Kdata.EM_Clock.DateFromExternalClock(i67)                            = fread(fid,1,'uint32');
%             S7Kdata.EM_Clock.TimeSinceMidnightInMillisecondsFromExternalClock(i67) = fread(fid,1,'uint32');
%             S7Kdata.EM_Clock.OnePPSUse(i67)                                        = fread(fid,1,'uint8');
%             S7Kdata.EM_Clock.ETX(i67)                                              = fread(fid,1,'uint8');
%             S7Kdata.EM_Clock.CheckSum(i67)                                         = fread(fid,1,'uint16');
%             
%             % ETX check
%             if S7Kdata.EM_Clock.ETX(i67)~=3
%                 error('wrong ETX value (S7Kdata.EM_Clock)');
%             end
%             
%             % confirm parsing
%             parsed = 1;
%             
%         case 68 % 'DEPTH DATAGRAM (44H)'
%             if ~(isempty(p.Results.OutputFields)||any(strcmp('EM_Depth',p.Results.OutputFields)))
%                 continue;
%             end
%             % counter for this type of datagram
%             try i68=i68+1; catch, i68=1; end
%             
%             % parsing
%             S7Kdata.EM_Depth.NumberOfBytesInDatagram(i68)           = nbDatag;
%             S7Kdata.EM_Depth.STX(i68)                               = stxDatag;
%             S7Kdata.EM_Depth.TypeOfDatagram(i68)                    = datagTypeNumber;
%             S7Kdata.EM_Depth.EMModelNumber(i68)                     = emNumber;
%             S7Kdata.EM_Depth.Date(i68)                              = date;
%             S7Kdata.EM_Depth.TimeSinceMidnightInMilliseconds(i68)   = timeSinceMidnightInMilliseconds;
%             S7Kdata.EM_Depth.PingCounter(i68)                       = number;
%             S7Kdata.EM_Depth.SystemSerialNumber(i68)                = systemSerialNumber;
%             
%             S7Kdata.EM_Depth.HeadingOfVessel(i68)                   = fread(fid,1,'uint16');
%             S7Kdata.EM_Depth.SoundSpeedAtTransducer(i68)            = fread(fid,1,'uint16');
%             S7Kdata.EM_Depth.TransmitTransducerDepth(i68)           = fread(fid,1,'uint16');
%             S7Kdata.EM_Depth.MaximumNumberOfBeamsPossible(i68)      = fread(fid,1,'uint8');
%             S7Kdata.EM_Depth.NumberOfValidBeams(i68)                = fread(fid,1,'uint8'); %N
%             S7Kdata.EM_Depth.ZResolution(i68)                       = fread(fid,1,'uint8');
%             S7Kdata.EM_Depth.XAndYResolution(i68)                   = fread(fid,1,'uint8');
%             S7Kdata.EM_Depth.SamplingRate(i68)                      = fread(fid,1,'uint16'); % OR: S7Kdata.EM_Depth.DepthDifferenceBetweenSonarHeadsInTheEM3000D(i68) = fread(fid,1,'int16');
%             
%             % repeat cycle: N entries of 16 bits
%             temp = ftell(fid);
%             N = S7Kdata.EM_Depth.NumberOfValidBeams(i68);
%             S7Kdata.EM_Depth.DepthZ{i68}                        = fread(fid,N,'int16',16-2); % OR 'uint16' for EM120 and EM300
%             fseek(fid,temp+2,'bof'); % to next data type
%             S7Kdata.EM_Depth.AcrosstrackDistanceY{i68}          = fread(fid,N,'int16',16-2);
%             fseek(fid,temp+4,'bof'); % to next data type
%             S7Kdata.EM_Depth.AlongtrackDistanceX{i68}           = fread(fid,N,'int16',16-2);
%             fseek(fid,temp+6,'bof'); % to next data type
%             S7Kdata.EM_Depth.BeamDepressionAngle{i68}           = fread(fid,N,'int16',16-2);
%             fseek(fid,temp+8,'bof'); % to next data type
%             S7Kdata.EM_Depth.BeamAzimuthAngle{i68}              = fread(fid,N,'uint16',16-2);
%             fseek(fid,temp+10,'bof'); % to next data type
%             S7Kdata.EM_Depth.Range{i68}                         = fread(fid,N,'uint16',16-2);
%             fseek(fid,temp+12,'bof'); % to next data type
%             S7Kdata.EM_Depth.QualityFactor{i68}                 = fread(fid,N,'uint8',16-1);
%             fseek(fid,temp+13,'bof'); % to next data type
%             S7Kdata.EM_Depth.LengthOfDetectionWindow{i68}       = fread(fid,N,'uint8',16-1);
%             fseek(fid,temp+14,'bof'); % to next data type
%             S7Kdata.EM_Depth.ReflectivityBS{i68}                = fread(fid,N,'int8',16-1);
%             fseek(fid,temp+15,'bof'); % to next data type
%             S7Kdata.EM_Depth.BeamNumber{i68}                    = fread(fid,N,'uint8',16-1);
%             fseek(fid,1-16,'cof'); % we need to come back after last jump
%             
%             S7Kdata.EM_Depth.TransducerDepthOffsetMultiplier(i68) = fread(fid,1,'int8');
%             S7Kdata.EM_Depth.ETX(i68)                             = fread(fid,1,'uint8');
%             S7Kdata.EM_Depth.CheckSum(i68)                        = fread(fid,1,'uint16');
%             
%             % ETX check
%             if S7Kdata.EM_Depth.ETX(i68)~=3
%                 error('wrong ETX value (S7Kdata.EM_Depth)');
%             end
%             
%             % confirm parsing
%             parsed = 1;
%             
%         case 70 % 'RAW RANGE AND BEAM ANGLE (F) (46H)'
%             if ~(isempty(p.Results.OutputFields)||any(strcmp('EM_RawRangeBeamAngle',p.Results.OutputFields)))
%                 continue;
%             end
%             % counter for this type of datagram
%             try i70=i70+1; catch, i70=1; end
%             
%             % parsing
%             % ...to write...
%             
%         case 71 % 'SURFACE SOUND SPEED (47H)'
%             if ~(isempty(p.Results.OutputFields)||any(strcmp('EM_SurfaceSoundSpeed',p.Results.OutputFields)))
%                 continue;
%             end
%             % counter for this type of datagram
%             try i71=i71+1; catch, i71=1; end
%             
%             % parsing
%             S7Kdata.EM_SurfaceSoundSpeed.NumberOfBytesInDatagram(i71)           = nbDatag;
%             S7Kdata.EM_SurfaceSoundSpeed.STX(i71)                               = stxDatag;
%             S7Kdata.EM_SurfaceSoundSpeed.TypeOfDatagram(i71)                    = datagTypeNumber;
%             S7Kdata.EM_SurfaceSoundSpeed.EMModelNumber(i71)                     = emNumber;
%             S7Kdata.EM_SurfaceSoundSpeed.Date(i71)                              = date;
%             S7Kdata.EM_SurfaceSoundSpeed.TimeSinceMidnightInMilliseconds(i71)   = timeSinceMidnightInMilliseconds;
%             S7Kdata.EM_SurfaceSoundSpeed.SoundSpeedCounter(i71)                 = number;
%             S7Kdata.EM_SurfaceSoundSpeed.SystemSerialNumber(i71)                = systemSerialNumber;
%             
%             S7Kdata.EM_SurfaceSoundSpeed.NumberOfEntries(i71)                   = fread(fid,1,'uint16'); %N
%             
%             % repeat cycle: N entries of 4 bits
%             temp = ftell(fid);
%             N = S7Kdata.EM_SurfaceSoundSpeed.NumberOfEntries(i71);
%             S7Kdata.EM_SurfaceSoundSpeed.TimeInSecondsSinceRecordStart{i71} = fread(fid,N,'uint16',4-2);
%             fseek(fid,temp+2,'bof'); % to next data type
%             S7Kdata.EM_SurfaceSoundSpeed.SoundSpeed{i71}                    = fread(fid,N,'uint16',4-2);
%             fseek(fid,2-4,'cof'); % we need to come back after last jump
%             
%             S7Kdata.EM_SurfaceSoundSpeed.Spare(i71)                             = fread(fid,1,'uint8');
%             S7Kdata.EM_SurfaceSoundSpeed.ETX(i71)                               = fread(fid,1,'uint8');
%             S7Kdata.EM_SurfaceSoundSpeed.CheckSum(i71)                          = fread(fid,1,'uint16');
%             
%             % ETX check
%             if S7Kdata.EM_SurfaceSoundSpeed.ETX(i71)~=3
%                 error('wrong ETX value (S7Kdata.EM_SurfaceSoundSpeed)');
%             end
%             
%             % confirm parsing
%             parsed = 1;
%             
%         case 72 % 'HEADING (48H)'
%             if ~(isempty(p.Results.OutputFields)||any(strcmp('EM_Heading',p.Results.OutputFields)))
%                 continue;
%             end
%             % counter for this type of datagram
%             try i72=i72+1; catch, i72=1; end
%             
%             % parsing
%             % ...to write...
%             
%         case 73 % 'INSTALLATION PARAMETERS - START (49H)'
%             if ~(isempty(p.Results.OutputFields)||any(strcmp('EM_InstallationStart',p.Results.OutputFields)))
%                 continue;
%             end
%             % counter for this type of datagram
%             try i73=i73+1; catch, i73=1; end
%             
%             % parsing
%             S7Kdata.EM_InstallationStart.NumberOfBytesInDatagram(i73)         = nbDatag;
%             S7Kdata.EM_InstallationStart.STX(i73)                             = stxDatag;
%             S7Kdata.EM_InstallationStart.TypeOfDatagram(i73)                  = datagTypeNumber;
%             S7Kdata.EM_InstallationStart.EMModelNumber(i73)                   = emNumber;
%             S7Kdata.EM_InstallationStart.Date(i73)                            = date;
%             S7Kdata.EM_InstallationStart.TimeSinceMidnightInMilliseconds(i73) = timeSinceMidnightInMilliseconds;
%             S7Kdata.EM_InstallationStart.SurveyLineNumber(i73)                = number;
%             S7Kdata.EM_InstallationStart.SystemSerialNumber(i73)              = systemSerialNumber;
%             
%             S7Kdata.EM_InstallationStart.SerialNumberOfSecondSonarHead(i73)   = fread(fid,1,'uint16');
%             
%             % 18 bytes of binary data already recorded and 3 more to come = 21.
%             % but nbDatag will always be even thanks to SpareByte. so
%             % nbDatag is 22 if there is no ASCII data and more if there is
%             % ASCII data. read the rest as ASCII (including SpareByte) with
%             % 1 byte for 1 character.
%             S7Kdata.EM_InstallationStart.ASCIIData{i73}                       = fscanf(fid, '%c', nbDatag-21);
%             
%             S7Kdata.EM_InstallationStart.ETX(i73)                             = fread(fid,1,'uint8');
%             S7Kdata.EM_InstallationStart.CheckSum(i73)                        = fread(fid,1,'uint16');
%             
%             % ETX check
%             if S7Kdata.EM_InstallationStart.ETX(i73)~=3
%                 error('wrong ETX value (S7Kdata.EM_InstallationStart)');
%             end
%             
%             % confirm parsing
%             parsed = 1;
%             
%         case 78 % 'RAW RANGE AND ANGLE 78 (4EH)'
%             if ~(isempty(p.Results.OutputFields)||any(strcmp('EM_RawRangeAngle78',p.Results.OutputFields)))
%                 continue;
%             end
%             % counter for this type of datagram
%             try i78=i78+1; catch, i78=1; end
%             
%             % parsing
%             S7Kdata.EM_RawRangeAngle78.NumberOfBytesInDatagram(i78)           = nbDatag;
%             S7Kdata.EM_RawRangeAngle78.STX(i78)                               = stxDatag;
%             S7Kdata.EM_RawRangeAngle78.TypeOfDatagram(i78)                    = datagTypeNumber;
%             S7Kdata.EM_RawRangeAngle78.EMModelNumber(i78)                     = emNumber;
%             S7Kdata.EM_RawRangeAngle78.Date(i78)                              = date;
%             S7Kdata.EM_RawRangeAngle78.TimeSinceMidnightInMilliseconds(i78)   = timeSinceMidnightInMilliseconds;
%             S7Kdata.EM_RawRangeAngle78.PingCounter(i78)                       = number;
%             S7Kdata.EM_RawRangeAngle78.SystemSerialNumber(i78)                = systemSerialNumber;
%             
%             S7Kdata.EM_RawRangeAngle78.SoundSpeedAtTransducer(i78)            = fread(fid,1,'uint16');
%             S7Kdata.EM_RawRangeAngle78.NumberOfTransmitSectors(i78)           = fread(fid,1,'uint16'); %Ntx
%             S7Kdata.EM_RawRangeAngle78.NumberOfReceiverBeamsInDatagram(i78)   = fread(fid,1,'uint16'); %B
%             S7Kdata.EM_RawRangeAngle78.NumberOfValidDetections(i78)           = fread(fid,1,'uint16');
%             S7Kdata.EM_RawRangeAngle78.SamplingFrequencyInHz(i78)             = fread(fid,1,'float32');
%             S7Kdata.EM_RawRangeAngle78.Dscale(i78)                            = fread(fid,1,'uint32');
%             
%             % repeat cycle #1: Ntx entries of 24 bits
%             temp = ftell(fid);
%             C = 24;
%             Ntx = S7Kdata.EM_RawRangeAngle78.NumberOfTransmitSectors(i78);
%             S7Kdata.EM_RawRangeAngle78.TiltAngle{i78}                     = fread(fid,Ntx,'int16',C-2);
%             fseek(fid,temp+2,'bof'); % to next data type
%             S7Kdata.EM_RawRangeAngle78.FocusRange{i78}                    = fread(fid,Ntx,'uint16',C-2);
%             fseek(fid,temp+4,'bof'); % to next data type
%             S7Kdata.EM_RawRangeAngle78.SignalLength{i78}                  = fread(fid,Ntx,'float32',C-4);
%             fseek(fid,temp+8,'bof'); % to next data type
%             S7Kdata.EM_RawRangeAngle78.SectorTransmitDelay{i78}           = fread(fid,Ntx,'float32',C-4);
%             fseek(fid,temp+12,'bof'); % to next data type
%             S7Kdata.EM_RawRangeAngle78.CentreFrequency{i78}               = fread(fid,Ntx,'float32',C-4);
%             fseek(fid,temp+16,'bof'); % to next data type
%             S7Kdata.EM_RawRangeAngle78.MeanAbsorptionCoeff{i78}           = fread(fid,Ntx,'uint16',C-2);
%             fseek(fid,temp+18,'bof'); % to next data type
%             S7Kdata.EM_RawRangeAngle78.SignalWaveformIdentifier{i78}      = fread(fid,Ntx,'uint8',C-1);
%             fseek(fid,temp+19,'bof'); % to next data type
%             S7Kdata.EM_RawRangeAngle78.TransmitSectorNumberTxArrayIndex{i78} = fread(fid,Ntx,'uint8',C-1);
%             fseek(fid,temp+20,'bof'); % to next data type
%             S7Kdata.EM_RawRangeAngle78.SignalBandwidth{i78}               = fread(fid,Ntx,'float32',C-4);
%             fseek(fid,4-C,'cof'); % we need to come back after last jump
%             
%             % repeat cycle #2: Nrx entries of 16 bits
%             temp = ftell(fid);
%             C = 16;
%             Nrx = S7Kdata.EM_RawRangeAngle78.NumberOfReceiverBeamsInDatagram(i78);
%             S7Kdata.EM_RawRangeAngle78.BeamPointingAngle{i78}             = fread(fid,Nrx,'int16',C-2);
%             fseek(fid,temp+2,'bof'); % to next data type
%             S7Kdata.EM_RawRangeAngle78.TransmitSectorNumber{i78}          = fread(fid,Nrx,'uint8',C-1);
%             fseek(fid,temp+3,'bof'); % to next data type
%             S7Kdata.EM_RawRangeAngle78.DetectionInfo{i78}                 = fread(fid,Nrx,'uint8',C-1);
%             fseek(fid,temp+4,'bof'); % to next data type
%             S7Kdata.EM_RawRangeAngle78.DetectionWindowLength{i78}         = fread(fid,Nrx,'uint16',C-2);
%             fseek(fid,temp+6,'bof'); % to next data type
%             S7Kdata.EM_RawRangeAngle78.QualityFactor{i78}                 = fread(fid,Nrx,'uint8',C-1);
%             fseek(fid,temp+7,'bof'); % to next data type
%             S7Kdata.EM_RawRangeAngle78.Dcorr{i78}                         = fread(fid,Nrx,'int8',C-1);
%             fseek(fid,temp+8,'bof'); % to next data type
%             S7Kdata.EM_RawRangeAngle78.TwoWayTravelTime{i78}              = fread(fid,Nrx,'float32',C-4);
%             fseek(fid,temp+12,'bof'); % to next data type
%             S7Kdata.EM_RawRangeAngle78.ReflectivityBS{i78}                = fread(fid,Nrx,'int16',C-2);
%             fseek(fid,temp+14,'bof'); % to next data type
%             S7Kdata.EM_RawRangeAngle78.RealTimeCleaningInfo{i78}          = fread(fid,Nrx,'int8',C-1);
%             fseek(fid,temp+15,'bof'); % to next data type
%             S7Kdata.EM_RawRangeAngle78.Spare{i78}                         = fread(fid,Nrx,'uint8',C-1);
%             fseek(fid,1-C,'cof'); % we need to come back after last jump
%             
%             S7Kdata.EM_RawRangeAngle78.Spare2(i78)                            = fread(fid,1,'uint8');
%             S7Kdata.EM_RawRangeAngle78.ETX(i78)                               = fread(fid,1,'uint8');
%             S7Kdata.EM_RawRangeAngle78.CheckSum(i78)                          = fread(fid,1,'uint16');
%             
%             % ETX check
%             if S7Kdata.EM_RawRangeAngle78.ETX(i78)~=3
%                 error('wrong ETX value (S7Kdata.EM_RawRangeAngle78)');
%             end
%             
%             % confirm parsing
%             parsed = 1;
%             
%         case 79 % 'QUALITY FACTOR DATAGRAM 79 (4FH)'
%             if ~(isempty(p.Results.OutputFields)||any(strcmp('EM_QF',p.Results.OutputFields)))
%                 continue;
%             end
%             % counter for this type of datagram
%             try i79=i79+1; catch, i79=1; end
%             
%             % parsing
%             % ...to write...
%             
%         case 80 % 'POSITION (50H)'
%             if ~(isempty(p.Results.OutputFields)||any(strcmp('EM_Position',p.Results.OutputFields)))
%                 continue;
%             end
%             % counter for this type of datagram
%             try i80=i80+1; catch, i80=1; end
%             
%             % parsing
%             S7Kdata.EM_Position.NumberOfBytesInDatagram(i80)         = nbDatag;
%             S7Kdata.EM_Position.STX(i80)                             = stxDatag;
%             S7Kdata.EM_Position.TypeOfDatagram(i80)                  = datagTypeNumber;
%             S7Kdata.EM_Position.EMModelNumber(i80)                   = emNumber;
%             S7Kdata.EM_Position.Date(i80)                            = date;
%             S7Kdata.EM_Position.TimeSinceMidnightInMilliseconds(i80) = timeSinceMidnightInMilliseconds;
%             S7Kdata.EM_Position.PositionCounter(i80)                 = number;
%             S7Kdata.EM_Position.SystemSerialNumber(i80)              = systemSerialNumber;
%             
%             S7Kdata.EM_Position.Latitude(i80)                        = fread(fid,1,'int32');
%             S7Kdata.EM_Position.Longitude(i80)                       = fread(fid,1,'int32');
%             S7Kdata.EM_Position.MeasureOfPositionFixQuality(i80)     = fread(fid,1,'uint16');
%             S7Kdata.EM_Position.SpeedOfVesselOverGround(i80)         = fread(fid,1,'uint16');
%             S7Kdata.EM_Position.CourseOfVesselOverGround(i80)        = fread(fid,1,'uint16');
%             S7Kdata.EM_Position.HeadingOfVessel(i80)                 = fread(fid,1,'uint16');
%             S7Kdata.EM_Position.PositionSystemDescriptor(i80)        = fread(fid,1,'uint8');
%             S7Kdata.EM_Position.NumberOfBytesInInputDatagram(i80)    = fread(fid,1,'uint8');
%             
%             % next data size is variable. 34 bits of binary data already
%             % recorded and 3 more to come = 37. read the rest as ASCII
%             % (including SpareByte)
%             S7Kdata.EM_Position.PositionInputDatagramAsReceived{i80} = fscanf(fid, '%c', nbDatag-37);
%             
%             S7Kdata.EM_Position.ETX(i80)                             = fread(fid,1,'uint8');
%             S7Kdata.EM_Position.CheckSum(i80)                        = fread(fid,1,'uint16');
%             
%             % ETX check
%             if S7Kdata.EM_Position.ETX(i80)~=3
%                 error('wrong ETX value (S7Kdata.EM_Position)');
%             end
%             
%             % confirm parsing
%             parsed = 1;
%             
%         case 82 % 'RUNTIME PARAMETERS (52H)'
%             if ~(isempty(p.Results.OutputFields)||any(strcmp('EM_Runtime',p.Results.OutputFields)))
%                 continue;
%             end
%             % counter for this type of datagram
%             try i82=i82+1; catch, i82=1; end
%             
%             % parsing
%             S7Kdata.EM_Runtime.NumberOfBytesInDatagram(i82)                 = nbDatag;
%             S7Kdata.EM_Runtime.STX(i82)                                     = stxDatag;
%             S7Kdata.EM_Runtime.TypeOfDatagram(i82)                          = datagTypeNumber;
%             S7Kdata.EM_Runtime.EMModelNumber(i82)                           = emNumber;
%             S7Kdata.EM_Runtime.Date(i82)                                    = date;
%             S7Kdata.EM_Runtime.TimeSinceMidnightInMilliseconds(i82)         = timeSinceMidnightInMilliseconds;
%             S7Kdata.EM_Runtime.PingCounter(i82)                             = number;
%             S7Kdata.EM_Runtime.SystemSerialNumber(i82)                      = systemSerialNumber;
%             
%             S7Kdata.EM_Runtime.OperatorStationStatus(i82)                   = fread(fid,1,'uint8');
%             S7Kdata.EM_Runtime.ProcessingUnitStatus(i82)                    = fread(fid,1,'uint8');
%             S7Kdata.EM_Runtime.BSPStatus(i82)                               = fread(fid,1,'uint8');
%             S7Kdata.EM_Runtime.SonarHeadStatus(i82)                         = fread(fid,1,'uint8');
%             S7Kdata.EM_Runtime.Mode(i82)                                    = fread(fid,1,'uint8');
%             S7Kdata.EM_Runtime.FilterIdentifier(i82)                        = fread(fid,1,'uint8');
%             S7Kdata.EM_Runtime.MinimumDepth(i82)                            = fread(fid,1,'uint16');
%             S7Kdata.EM_Runtime.MaximumDepth(i82)                            = fread(fid,1,'uint16');
%             S7Kdata.EM_Runtime.AbsorptionCoefficient(i82)                   = fread(fid,1,'uint16');
%             S7Kdata.EM_Runtime.TransmitPulseLength(i82)                     = fread(fid,1,'uint16');
%             S7Kdata.EM_Runtime.TransmitBeamwidth(i82)                       = fread(fid,1,'uint16');
%             S7Kdata.EM_Runtime.TransmitPowerReMaximum(i82)                  = fread(fid,1,'int8');
%             S7Kdata.EM_Runtime.ReceiveBeamwidth(i82)                        = fread(fid,1,'uint8');
%             S7Kdata.EM_Runtime.ReceiveBandwidth(i82)                        = fread(fid,1,'uint8');
%             S7Kdata.EM_Runtime.ReceiverFixedGainSetting(i82)                = fread(fid,1,'uint8'); % OR mode 2
%             S7Kdata.EM_Runtime.TVGLawCrossoverAngle(i82)                    = fread(fid,1,'uint8');
%             S7Kdata.EM_Runtime.SourceOfSoundSpeedAtTransducer(i82)          = fread(fid,1,'uint8');
%             S7Kdata.EM_Runtime.MaximumPortSwathWidth(i82)                   = fread(fid,1,'uint16');
%             S7Kdata.EM_Runtime.BeamSpacing(i82)                             = fread(fid,1,'uint8');
%             S7Kdata.EM_Runtime.MaximumPortCoverage(i82)                     = fread(fid,1,'uint8');
%             S7Kdata.EM_Runtime.YawAndPitchStabilizationMode(i82)            = fread(fid,1,'uint8');
%             S7Kdata.EM_Runtime.MaximumStarboardCoverage(i82)                = fread(fid,1,'uint8');
%             S7Kdata.EM_Runtime.MaximumStarboardSwathWidth(i82)              = fread(fid,1,'uint16');
%             S7Kdata.EM_Runtime.DurotongSpeed(i82)                           = fread(fid,1,'uint16'); % OR: S7Kdata.EM_Runtime.TransmitAlongTilt(i82) = fread(fid,1,'int16');
%             S7Kdata.EM_Runtime.HiLoFrequencyAbsorptionCoefficientRatio(i82) = fread(fid,1,'uint8'); % OR filter identifier 2
%             S7Kdata.EM_Runtime.ETX(i82)                                     = fread(fid,1,'uint8');
%             S7Kdata.EM_Runtime.CheckSum(i82)                                = fread(fid,1,'uint16');
%             
%             % ETX check
%             if S7Kdata.EM_Runtime.ETX(i82)~=3
%                 error('wrong ETX value (S7Kdata.EM_Runtime)');
%             end
%             
%             % confirm parsing
%             parsed = 1;
%             
%         case 83 % 'SEABED IMAGE DATAGRAM (53H)'
%             if ~(isempty(p.Results.OutputFields)||any(strcmp('EM_SeabedImage',p.Results.OutputFields)))
%                 continue;
%             end
%             % counter for this type of datagram
%             try i83=i83+1; catch, i83=1; end
%             
%             % parsing
%             S7Kdata.EM_SeabedImage.NumberOfBytesInDatagram(i83)         = nbDatag;
%             S7Kdata.EM_SeabedImage.STX(i83)                             = stxDatag;
%             S7Kdata.EM_SeabedImage.TypeOfDatagram(i83)                  = datagTypeNumber;
%             S7Kdata.EM_SeabedImage.EMModelNumber(i83)                   = emNumber;
%             S7Kdata.EM_SeabedImage.Date(i83)                            = date;
%             S7Kdata.EM_SeabedImage.TimeSinceMidnightInMilliseconds(i83) = timeSinceMidnightInMilliseconds;
%             S7Kdata.EM_SeabedImage.PingCounter(i83)                     = number;
%             S7Kdata.EM_SeabedImage.SystemSerialNumber(i83)              = systemSerialNumber;
%             
%             S7Kdata.EM_SeabedImage.MeanAbsorptionCoefficient(i83)       = fread(fid,1,'uint16'); % 'this field had earlier definition'
%             S7Kdata.EM_SeabedImage.PulseLength(i83)                     = fread(fid,1,'uint16'); % 'this field had earlier definition'
%             S7Kdata.EM_SeabedImage.RangeToNormalIncidence(i83)          = fread(fid,1,'uint16');
%             S7Kdata.EM_SeabedImage.StartRangeSampleOfTVGRamp(i83)       = fread(fid,1,'uint16');
%             S7Kdata.EM_SeabedImage.StopRangeSampleOfTVGRamp(i83)        = fread(fid,1,'uint16');
%             S7Kdata.EM_SeabedImage.NormalIncidenceBS(i83)               = fread(fid,1,'int8'); %BSN
%             S7Kdata.EM_SeabedImage.ObliqueBS(i83)                       = fread(fid,1,'int8'); %BSO
%             S7Kdata.EM_SeabedImage.TxBeamwidth(i83)                     = fread(fid,1,'uint16');
%             S7Kdata.EM_SeabedImage.TVGLawCrossoverAngle(i83)            = fread(fid,1,'uint8');
%             S7Kdata.EM_SeabedImage.NumberOfValidBeams(i83)              = fread(fid,1,'uint8'); %N
%             
%             % repeat cycle: N entries of 6 bits
%             temp = ftell(fid);
%             N = S7Kdata.EM_SeabedImage.NumberOfValidBeams(i83);
%             S7Kdata.EM_SeabedImage.BeamIndexNumber{i83}             = fread(fid,N,'uint8',6-1);
%             fseek(fid,temp+1,'bof'); % to next data type
%             S7Kdata.EM_SeabedImage.SortingDirection{i83}            = fread(fid,N,'int8',6-1);
%             fseek(fid,temp+2,'bof'); % to next data type
%             S7Kdata.EM_SeabedImage.NumberOfSamplesPerBeam{i83}      = fread(fid,N,'uint16',6-2); %Ns
%             fseek(fid,temp+4,'bof'); % to next data type
%             S7Kdata.EM_SeabedImage.CentreSampleNumber{i83}          = fread(fid,N,'uint16',6-2);
%             fseek(fid,2-6,'cof'); % we need to come back after last jump
%             
%             % reading image data
%             Ns = [S7Kdata.EM_SeabedImage.NumberOfSamplesPerBeam{i83}];
%             tmp = fread(fid,sum(Ns),'int8');
%             S7Kdata.EM_SeabedImage.SampleAmplitudes(i83).beam = mat2cell(tmp,Ns);
%             
%             % "spare byte if required to get even length (always 0 if used)"
%             if floor(sum(Ns)/2) == sum(Ns)/2
%                 % even so far, since ETX is 1 byte, add a spare here
%                 S7Kdata.EM_SeabedImage.Data.SpareByte(i83)              = fread(fid,1,'uint8');
%             else
%                 % odd so far, since ETX is 1 bytes, no spare
%                 S7Kdata.EM_SeabedImage.Data.SpareByte(i83) = NaN;
%             end
%             S7Kdata.EM_SeabedImage.ETX(i83)                             = fread(fid,1,'uint8');
%             S7Kdata.EM_SeabedImage.CheckSum(i83)                        = fread(fid,1,'uint16');
%             
%             % ETX check
%             if S7Kdata.EM_SeabedImage.ETX(i83)~=3
%                 error('wrong ETX value (S7Kdata.EM_SeabedImage)');
%             end
%             
%             % confirm parsing
%             parsed = 1;
%             
%         case 85 % 'SOUND SPEED PROFILE (55H)'
%             if ~(isempty(p.Results.OutputFields)||any(strcmp('EM_SoundSpeedProfile',p.Results.OutputFields)))
%                 continue;
%             end
%             % counter for this type of datagram
%             try i85=i85+1; catch, i85=1; end
%             
%             % parsing
%             S7Kdata.EM_SoundSpeedProfile.NumberOfBytesInDatagram(i85)                           = nbDatag;
%             S7Kdata.EM_SoundSpeedProfile.STX(i85)                                               = stxDatag;
%             S7Kdata.EM_SoundSpeedProfile.TypeOfDatagram(i85)                                    = datagTypeNumber;
%             S7Kdata.EM_SoundSpeedProfile.EMModelNumber(i85)                                     = emNumber;
%             S7Kdata.EM_SoundSpeedProfile.Date(i85)                                              = date;
%             S7Kdata.EM_SoundSpeedProfile.TimeSinceMidnightInMilliseconds(i85)                   = timeSinceMidnightInMilliseconds;
%             S7Kdata.EM_SoundSpeedProfile.ProfileCounter(i85)                                    = number;
%             S7Kdata.EM_SoundSpeedProfile.SystemSerialNumber(i85)                                = systemSerialNumber;
%             
%             S7Kdata.EM_SoundSpeedProfile.DateWhenProfileWasMade(i85)                            = fread(fid,1,'uint32');
%             S7Kdata.EM_SoundSpeedProfile.TimeSinceMidnightInMillisecondsWhenProfileWasMade(i85) = fread(fid,1,'uint32');
%             S7Kdata.EM_SoundSpeedProfile.NumberOfEntries(i85)                                   = fread(fid,1,'uint16'); %N
%             S7Kdata.EM_SoundSpeedProfile.DepthResolution(i85)                                   = fread(fid,1,'uint16');
%             
%             % repeat cycle: N entries of 8 bits
%             temp = ftell(fid);
%             N = S7Kdata.EM_SoundSpeedProfile.NumberOfEntries(i85);
%             S7Kdata.EM_SoundSpeedProfile.Depth{i85}                                         = fread(fid,N,'uint32',8-4);
%             fseek(fid,temp+4,'bof'); % to next data type
%             S7Kdata.EM_SoundSpeedProfile.SoundSpeed{i85}                                    = fread(fid,N,'uint32',8-4);
%             fseek(fid,4-8,'cof'); % we need to come back after last jump
%             
%             S7Kdata.EM_SoundSpeedProfile.SpareByte(i85)                                         = fread(fid,1,'uint8');
%             S7Kdata.EM_SoundSpeedProfile.ETX(i85)                                               = fread(fid,1,'uint8');
%             S7Kdata.EM_SoundSpeedProfile.CheckSum(i85)                                          = fread(fid,1,'uint16');
%             
%             % ETX check
%             if S7Kdata.EM_SoundSpeedProfile.ETX(i85)~=3
%                 error('wrong ETX value (S7Kdata.EM_SoundSpeedProfile)');
%             end
%             
%             % confirm parsing
%             parsed = 1;
%             
%         case 88 % 'XYZ 88 (58H)'
%             if ~(isempty(p.Results.OutputFields)||any(strcmp('EM_XYZ88',p.Results.OutputFields)))
%                 continue;
%             end
%             % counter for this type of datagram
%             try i88=i88+1; catch, i88=1; end
%             
%             % parsing
%             S7Kdata.EM_XYZ88.NumberOfBytesInDatagram(i88)           = nbDatag;
%             S7Kdata.EM_XYZ88.STX(i88)                               = stxDatag;
%             S7Kdata.EM_XYZ88.TypeOfDatagram(i88)                    = datagTypeNumber;
%             S7Kdata.EM_XYZ88.EMModelNumber(i88)                     = emNumber;
%             S7Kdata.EM_XYZ88.Date(i88)                              = date;
%             S7Kdata.EM_XYZ88.TimeSinceMidnightInMilliseconds(i88)   = timeSinceMidnightInMilliseconds;
%             S7Kdata.EM_XYZ88.PingCounter(i88)                       = number;
%             S7Kdata.EM_XYZ88.SystemSerialNumber(i88)                = systemSerialNumber;
%             
%             S7Kdata.EM_XYZ88.HeadingOfVessel(i88)                   = fread(fid,1,'uint16');
%             S7Kdata.EM_XYZ88.SoundSpeedAtTransducer(i88)            = fread(fid,1,'uint16');
%             S7Kdata.EM_XYZ88.TransmitTransducerDepth(i88)           = fread(fid,1,'float32');
%             S7Kdata.EM_XYZ88.NumberOfBeamsInDatagram(i88)           = fread(fid,1,'uint16');
%             S7Kdata.EM_XYZ88.NumberOfValidDetections(i88)           = fread(fid,1,'uint16');
%             S7Kdata.EM_XYZ88.SamplingFrequencyInHz(i88)             = fread(fid,1,'float32');
%             S7Kdata.EM_XYZ88.ScanningInfo(i88)                      = fread(fid,1,'uint8');
%             S7Kdata.EM_XYZ88.Spare1(i88)                            = fread(fid,1,'uint8');
%             S7Kdata.EM_XYZ88.Spare2(i88)                            = fread(fid,1,'uint8');
%             S7Kdata.EM_XYZ88.Spare3(i88)                            = fread(fid,1,'uint8');
%             
%             % repeat cycle: N entries of 20 bits
%             temp = ftell(fid);
%             C = 20;
%             N = S7Kdata.EM_XYZ88.NumberOfBeamsInDatagram(i88);
%             S7Kdata.EM_XYZ88.DepthZ{i88}                        = fread(fid,N,'float32',C-4);
%             fseek(fid,temp+4,'bof'); % to next data type
%             S7Kdata.EM_XYZ88.AcrosstrackDistanceY{i88}          = fread(fid,N,'float32',C-4);
%             fseek(fid,temp+8,'bof'); % to next data type
%             S7Kdata.EM_XYZ88.AlongtrackDistanceX{i88}           = fread(fid,N,'float32',C-4);
%             fseek(fid,temp+12,'bof'); % to next data type
%             S7Kdata.EM_XYZ88.DetectionWindowLength{i88}         = fread(fid,N,'uint16',C-2);
%             fseek(fid,temp+14,'bof'); % to next data type
%             S7Kdata.EM_XYZ88.QualityFactor{i88}                 = fread(fid,N,'uint8',C-1);
%             fseek(fid,temp+15,'bof'); % to next data type
%             S7Kdata.EM_XYZ88.BeamIncidenceAngleAdjustment{i88}  = fread(fid,N,'int8',C-1);
%             fseek(fid,temp+16,'bof'); % to next data type
%             S7Kdata.EM_XYZ88.DetectionInformation{i88}          = fread(fid,N,'uint8',C-1);
%             fseek(fid,temp+17,'bof'); % to next data type
%             S7Kdata.EM_XYZ88.RealTimeCleaningInformation{i88}   = fread(fid,N,'int8',C-1);
%             fseek(fid,temp+18,'bof'); % to next data type
%             S7Kdata.EM_XYZ88.ReflectivityBS{i88}                = fread(fid,N,'int16',C-2);
%             fseek(fid,2-C,'cof'); % we need to come back after last jump
%             
%             S7Kdata.EM_XYZ88.Spare4(i88)                            = fread(fid,1,'uint8');
%             S7Kdata.EM_XYZ88.ETX(i88)                               = fread(fid,1,'uint8');
%             S7Kdata.EM_XYZ88.CheckSum(i88)                          = fread(fid,1,'uint16');
%             
%             % ETX check
%             if S7Kdata.EM_XYZ88.ETX(i88)~=3
%                 warning('wrong ETX value (S7Kdata.EM_XYZ88)');
%                 fields_xyz=fieldnames(S7Kdata.EM_XYZ88);
%                 for ifi=1:numel(fields_xyz)
%                     if numel(S7Kdata.EM_XYZ88.(fields_xyz{ifi}))>=i88
%                         S7Kdata.EM_XYZ88.(fields_xyz{ifi})(i88)=[];
%                     end
%                 end
%                 i88=i88-1;
%                 parsed=0;
%             else
%                 
%                 % confirm parsing
%                 parsed = 1;
%             end
%         case 89 % 'SEABED IMAGE DATA 89 (59H)'
%             if ~(isempty(p.Results.OutputFields)||any(strcmp('EM_SeabedImage89',p.Results.OutputFields)))
%                 continue;
%             end
%             % counter for this type of datagram
%             try i89=i89+1; catch, i89=1; end
%             
%             % parsing
%             S7Kdata.EM_SeabedImage89.NumberOfBytesInDatagram(i89)         = nbDatag;
%             S7Kdata.EM_SeabedImage89.STX(i89)                             = stxDatag;
%             S7Kdata.EM_SeabedImage89.TypeOfDatagram(i89)                  = datagTypeNumber;
%             S7Kdata.EM_SeabedImage89.EMModelNumber(i89)                   = emNumber;
%             S7Kdata.EM_SeabedImage89.Date(i89)                            = date;
%             S7Kdata.EM_SeabedImage89.TimeSinceMidnightInMilliseconds(i89) = timeSinceMidnightInMilliseconds;
%             S7Kdata.EM_SeabedImage89.PingCounter(i89)                     = number;
%             S7Kdata.EM_SeabedImage89.SystemSerialNumber(i89)              = systemSerialNumber;
%             
%             S7Kdata.EM_SeabedImage89.SamplingFrequencyInHz(i89)           = fread(fid,1,'float32');
%             S7Kdata.EM_SeabedImage89.RangeToNormalIncidence(i89)          = fread(fid,1,'uint16');
%             S7Kdata.EM_SeabedImage89.NormalIncidenceBS(i89)               = fread(fid,1,'int16'); %BSN
%             S7Kdata.EM_SeabedImage89.ObliqueBS(i89)                       = fread(fid,1,'int16'); %BSO
%             S7Kdata.EM_SeabedImage89.TxBeamwidthAlong(i89)                = fread(fid,1,'uint16');
%             S7Kdata.EM_SeabedImage89.TVGLawCrossoverAngle(i89)            = fread(fid,1,'uint16');
%             S7Kdata.EM_SeabedImage89.NumberOfValidBeams(i89)              = fread(fid,1,'uint16');
%             
%             % repeat cycle: N entries of 6 bits
%             temp = ftell(fid);
%             C = 6;
%             N = S7Kdata.EM_SeabedImage89.NumberOfValidBeams(i89);
%             S7Kdata.EM_SeabedImage89.SortingDirection{i89}            = fread(fid,N,'int8',C-1);
%             fseek(fid,temp+1,'bof'); % to next data type
%             S7Kdata.EM_SeabedImage89.DetectionInfo{i89}               = fread(fid,N,'uint8',C-1);
%             fseek(fid,temp+2,'bof'); % to next data type
%             S7Kdata.EM_SeabedImage89.NumberOfSamplesPerBeam{i89}      = fread(fid,N,'uint16',C-2); %Ns
%             fseek(fid,temp+4,'bof'); % to next data type
%             S7Kdata.EM_SeabedImage89.CentreSampleNumber{i89}          = fread(fid,N,'uint16',C-2);
%             fseek(fid,2-C,'cof'); % we need to come back after last jump
%             
%             % reading image data
%             Ns = [S7Kdata.EM_SeabedImage89.NumberOfSamplesPerBeam{i89}];
%             tmp = fread(fid,sum(Ns),'int16');
%             S7Kdata.EM_SeabedImage89.SampleAmplitudes(i89).beam = mat2cell(tmp,Ns);
%             
%             S7Kdata.EM_SeabedImage89.Spare(i89)                           = fread(fid,1,'uint8');
%             S7Kdata.EM_SeabedImage89.ETX(i89)                             = fread(fid,1,'uint8');
%             S7Kdata.EM_SeabedImage89.CheckSum(i89)                        = fread(fid,1,'uint16');
%             
%             % ETX check
%             if S7Kdata.EM_SeabedImage89.ETX(i89)~=3
%                 error('wrong ETX value (S7Kdata.EM_SeabedImage89)');
%             end
%             
%             % confirm parsing
%             parsed = 1;
%             
%         case 102 % 'RAW RANGE AND BEAM ANGLE (f) (66H)'
%             if ~(isempty(p.Results.OutputFields)||any(strcmp('EM_RawBeamRangeAngle',p.Results.OutputFields)))
%                 continue;
%             end
%             % counter for this type of datagram
%             try i102=i102+1; catch, i102=1; end
%             
%             % parsing
%             % ...to write...
%             
%         case 104 % 'DEPTH (PRESSURE) OR HEIGHT DATAGRAM (68H)'
%             if ~(isempty(p.Results.OutputFields)||any(strcmp('EM_Height',p.Results.OutputFields)))
%                 continue;
%             end
%             % counter for this type of datagram
%             try i104=i104+1; catch, i104=1; end
%             
%             % parsing
%             S7Kdata.EM_Height.NumberOfBytesInDatagram(i104)         = nbDatag;
%             S7Kdata.EM_Height.STX(i104)                             = stxDatag;
%             S7Kdata.EM_Height.TypeOfDatagram(i104)                  = datagTypeNumber;
%             S7Kdata.EM_Height.EMModelNumber(i104)                   = emNumber;
%             S7Kdata.EM_Height.Date(i104)                            = date;
%             S7Kdata.EM_Height.TimeSinceMidnightInMilliseconds(i104) = timeSinceMidnightInMilliseconds;
%             S7Kdata.EM_Height.HeightCounter(i104)                   = number;
%             S7Kdata.EM_Height.SystemSerialNumber(i104)              = systemSerialNumber;
%             
%             S7Kdata.EM_Height.Height(i104)                          = fread(fid,1,'int32');
%             S7Kdata.EM_Height.HeigthType(i104)                      = fread(fid,1,'uint8');
%             S7Kdata.EM_Height.ETX(i104)                             = fread(fid,1,'uint8');
%             S7Kdata.EM_Height.CheckSum(i104)                        = fread(fid,1,'uint16');
%             
%             % ETX check
%             if S7Kdata.EM_Height.ETX(i104)~=3
%                 error('wrong ETX value (S7Kdata.EM_Height)');
%             end
%             
%             % confirm parsing
%             parsed = 1;
%             
%         case 105 % 'INSTS7KATION PARAMETERS -  STOP (69H)'
%             if ~(isempty(p.Results.OutputFields)||any(strcmp('EM_InstallationStop',p.Results.OutputFields)))
%                 continue;
%             end
%             % counter for this type of datagram
%             try i105=i105+1; catch, i105=1; end
%             
%             % parsing
%             S7Kdata.EM_InstallationStop.NumberOfBytesInDatagram(i105)         = nbDatag;
%             S7Kdata.EM_InstallationStop.STX(i105)                             = stxDatag;
%             S7Kdata.EM_InstallationStop.TypeOfDatagram(i105)                  = datagTypeNumber;
%             S7Kdata.EM_InstallationStop.EMModelNumber(i105)                   = emNumber;
%             S7Kdata.EM_InstallationStop.Date(i105)                            = date;
%             S7Kdata.EM_InstallationStop.TimeSinceMidnightInMilliseconds(i105) = timeSinceMidnightInMilliseconds;
%             S7Kdata.EM_InstallationStop.SurveyLineNumber(i105)                = number;
%             S7Kdata.EM_InstallationStop.SystemSerialNumber(i105)              = systemSerialNumber;
%             
%             S7Kdata.EM_InstallationStop.SerialNumberOfSecondSonarHead(i105)   = fread(fid,1,'uint16');
%             
%             % 18 bytes of binary data already recorded and 3 more to come = 21.
%             % but nbDatag will always be even thanks to SpareByte. so
%             % nbDatag is 22 if there is no ASCII data and more if there is
%             % ASCII data. read the rest as ASCII (including SpareByte) with
%             % 1 byte for 1 character.
%             S7Kdata.EM_InstallationStop.ASCIIData{i105}                       = fscanf(fid, '%c', nbDatag-21);
%             
%             S7Kdata.EM_InstallationStop.ETX(i105)                             = fread(fid,1,'uint8');
%             S7Kdata.EM_InstallationStop.CheckSum(i105)                        = fread(fid,1,'uint16');
%             
%             % ETX check
%             if S7Kdata.EM_InstallationStop.ETX(i105)~=3
%                 error('wrong ETX value (S7Kdata.EM_InstallationStop)');
%             end
%             
%             % confirm parsing
%             parsed = 1;
%             
%         case 107 % 'WATER COLUMN DATAGRAM (6BH)'
%             if ~(isempty(p.Results.OutputFields)||any(strcmp('EM_WaterColumn',p.Results.OutputFields)))
%                 continue;
%             end
%             % counter for this type of datagram
%             try i107=i107+1; catch, i107=1; end
%             
%             % ----- IMPORTANT NOTE ----------------------------------------
%             % This datagram's data is massive so we don't extract it from
%             % the files and store in memory as is. Instead, we record the
%             % metadata and the exact location of the data for later
%             % extraction. 
%             % -------------------------------------------------------------
%             
%             % parsing
%             S7Kdata.EM_WaterColumn.NumberOfBytesInDatagram(i107) = nbDatag;
%             
%             % position at start of datagram
%             pos_1 = ftell(fid); 
%             
%             S7Kdata.EM_WaterColumn.STX(i107)                               = stxDatag;
%             S7Kdata.EM_WaterColumn.TypeOfDatagram(i107)                    = datagTypeNumber;
%             S7Kdata.EM_WaterColumn.EMModelNumber(i107)                     = emNumber;
%             S7Kdata.EM_WaterColumn.Date(i107)                              = date;
%             S7Kdata.EM_WaterColumn.TimeSinceMidnightInMilliseconds(i107)   = timeSinceMidnightInMilliseconds;
%             S7Kdata.EM_WaterColumn.PingCounter(i107)                       = number;
%             S7Kdata.EM_WaterColumn.SystemSerialNumber(i107)                = systemSerialNumber;
%             
%             S7Kdata.EM_WaterColumn.NumberOfDatagrams(i107)                 = fread(fid,1,'uint16');
%             S7Kdata.EM_WaterColumn.DatagramNumbers(i107)                   = fread(fid,1,'uint16');
%             S7Kdata.EM_WaterColumn.NumberOfTransmitSectors(i107)           = fread(fid,1,'uint16'); %Ntx
%             S7Kdata.EM_WaterColumn.TotalNumberOfReceiveBeams(i107)         = fread(fid,1,'uint16');
%             S7Kdata.EM_WaterColumn.NumberOfBeamsInThisDatagram(i107)       = fread(fid,1,'uint16'); %Nrx
%             S7Kdata.EM_WaterColumn.SoundSpeed(i107)                        = fread(fid,1,'uint16'); %SS
%             S7Kdata.EM_WaterColumn.SamplingFrequency(i107)                 = fread(fid,1,'uint32'); %SF
%             S7Kdata.EM_WaterColumn.TXTimeHeave(i107)                       = fread(fid,1,'int16');
%             S7Kdata.EM_WaterColumn.TVGFunctionApplied(i107)                = fread(fid,1,'uint8'); %X
%             S7Kdata.EM_WaterColumn.TVGOffset(i107)                         = fread(fid,1,'int8'); %C
%             S7Kdata.EM_WaterColumn.ScanningInfo(i107)                      = fread(fid,1,'uint8');
%             S7Kdata.EM_WaterColumn.Spare1(i107)                            = fread(fid,1,'uint8');
%             S7Kdata.EM_WaterColumn.Spare2(i107)                            = fread(fid,1,'uint8');
%             S7Kdata.EM_WaterColumn.Spare3(i107)                            = fread(fid,1,'uint8');
%             
%             % repeat cycle #1: Ntx entries of 6 bits
%             temp = ftell(fid);
%             C = 6;
%             Ntx = S7Kdata.EM_WaterColumn.NumberOfTransmitSectors(i107);
%             S7Kdata.EM_WaterColumn.TiltAngle{i107}                     = fread(fid,Ntx,'int16',C-2);
%             fseek(fid,temp+2,'bof'); % to next data type
%             S7Kdata.EM_WaterColumn.CenterFrequency{i107}               = fread(fid,Ntx,'uint16',C-2);
%             fseek(fid,temp+4,'bof'); % to next data type
%             S7Kdata.EM_WaterColumn.TransmitSectorNumber{i107}          = fread(fid,Ntx,'uint8',C-1);
%             fseek(fid,temp+5,'bof'); % to next data type
%             S7Kdata.EM_WaterColumn.Spare{i107}                         = fread(fid,Ntx,'uint8',C-1);
%             fseek(fid,1-C,'cof'); % we need to come back after last jump
%             
%             % repeat cycle #2: Nrx entries of a possibly variable number of
%             % bits. Reading everything first and using a for loop to parse
%             % the data in it
%             Nrx = S7Kdata.EM_WaterColumn.NumberOfBeamsInThisDatagram(i107);
%             
%             pos_2 = ftell(fid); % position at start of data
%             tmp = fread(fid,nbDatag-(pos_2-pos_1+1)-15,'int8'); % read all that data block
%             tmp = int8(tmp');
%             id  = 0; % offset for start of each Nrx block
%             wc_parsing_error = 0; % initialize flag
%             
%             % initialize outputs
%             S7Kdata.EM_WaterColumn.BeamPointingAngle{i107}          = nan(1,Nrx);
%             S7Kdata.EM_WaterColumn.StartRangeSampleNumber{i107}     = nan(1,Nrx);
%             S7Kdata.EM_WaterColumn.NumberOfSamples{i107}            = nan(1,Nrx);
%             S7Kdata.EM_WaterColumn.DetectedRangeInSamples{i107}     = nan(1,Nrx);
%             S7Kdata.EM_WaterColumn.TransmitSectorNumber2{i107}      = nan(1,Nrx);
%             S7Kdata.EM_WaterColumn.BeamNumber{i107}                 = nan(1,Nrx);
%             S7Kdata.EM_WaterColumn.SampleAmplitudePosition{i107}    = nan(1,Nrx); 
%             Ns  = zeros(1,Nrx);
%             
%             % now parse the data
%             for jj = 1:Nrx
%                 
%                 try
%                     
%                     S7Kdata.EM_WaterColumn.BeamPointingAngle{i107}(jj)       = typecast(tmp(1+id:2+id),'int16');
%                     S7Kdata.EM_WaterColumn.StartRangeSampleNumber{i107}(jj)  = typecast(tmp(3+id:4+id),'uint16');
%                     S7Kdata.EM_WaterColumn.NumberOfSamples{i107}(jj)         = typecast(tmp(5+id:6+id),'uint16');
%                     S7Kdata.EM_WaterColumn.DetectedRangeInSamples{i107}(jj)  = typecast(tmp(7+id:8+id),'uint16');
%                     S7Kdata.EM_WaterColumn.TransmitSectorNumber2{i107}(jj)   = typecast(tmp(9+id),'uint8');
%                     S7Kdata.EM_WaterColumn.BeamNumber{i107}(jj)          	 = typecast(tmp(10+id),'uint8');
%                     
%                     % recording data position instead of data themselves
%                     S7Kdata.EM_WaterColumn.SampleAmplitudePosition{i107}(jj) = pos_2 + id + 10; 
%                     % actual data recording would be:
%                     % S7Kdata.EM_WaterColumn.SampleAmplitude{i107}{jj} = tmp((11+id):(11+id+Ns(jj)-1));
%                     
%                     Ns(jj) = S7Kdata.EM_WaterColumn.NumberOfSamples{i107}(jj);
%                     
%                     % offset to next jj block
%                     id = 10*jj + sum(Ns);
%                     
%                 catch
%                     
%                     % issue in the recording, flag and exit the loop
%                     S7Kdata.EM_WaterColumn.NumberOfSamples{i107}(jj) = 0;
%                     Ns(jj) = 0;
%                     wc_parsing_error = 1;
%                     continue;
%                     
%                 end
%                 
%             end
%             
%             if wc_parsing_error == 0
%                 % HERE if data parsing all went well
%                 
%                 % "spare byte if required to get even length (always 0 if used)"
%                 if floor((Nrx*10+sum(Ns))/2) == (Nrx*10+sum(Ns))/2
%                     % even so far, since ETX is 1 byte, add a spare here
%                     S7Kdata.EM_WaterColumn.Spare4(i107) = double(typecast(tmp(1+id),'uint8'));
%                     id = id+1;
%                 else
%                     % odd so far, since ETX is 1 bytes, no spare
%                     S7Kdata.EM_WaterColumn.Spare4(i107) = NaN;
%                 end
%                 
%                 % end of datagram
%                 S7Kdata.EM_WaterColumn.ETX(i107)      = typecast(tmp(id+1),'uint8');
%                 S7Kdata.EM_WaterColumn.CheckSum(i107) = typecast(tmp(2+id:3+id),'uint16');
%                 
%                 % ETX check
%                 if S7Kdata.EM_WaterColumn.ETX(i107)~=3
%                     error('wrong ETX value (S7Kdata.EM_WaterColumn)');
%                 end
%                 
%                 % confirm parsing
%                 parsed = 1;
%                 
%             else
%                 % HERE if data parsing failed, add a blank datagram in
%                 % output
%                 
%                 % copy field names of previous entries
%                 fields_wc = fieldnames(S7Kdata.EM_WaterColumn);
%                 
%                 % add blanks fields for those missing
%                 for ifi = 1:numel(fields_wc)
%                     if numel(S7Kdata.EM_WaterColumn.(fields_wc{ifi})) >= i107
%                         S7Kdata.EM_WaterColumn.(fields_wc{ifi})(i107) = [];
%                     end
%                 end
%                 
%                 i107 = i107-1; % XXX if we do that, then we'll rewrite over the blank record we just entered??
%                 parsed = 0;
%                 
%             end
%             
%         case 110 % 'NETWORK ATTITUDE VELOCITY DATAGRAM 110 (6EH)'
%             if ~(isempty(p.Results.OutputFields)||any(strcmp('EM_NetworkAttitude',p.Results.OutputFields)))
%                 continue;
%             end
%             % counter for this type of datagram
%             try i110=i110+1; catch, i110=1; end
%             
%             % parsing
%             S7Kdata.EM_NetworkAttitude.NumberOfBytesInDatagram(i110)                    = nbDatag;
%             S7Kdata.EM_NetworkAttitude.STX(i110)                                        = stxDatag;
%             S7Kdata.EM_NetworkAttitude.TypeOfDatagram(i110)                             = datagTypeNumber;
%             S7Kdata.EM_NetworkAttitude.EMModelNumber(i110)                              = emNumber;
%             S7Kdata.EM_NetworkAttitude.Date(i110)                                       = date;
%             S7Kdata.EM_NetworkAttitude.TimeSinceMidnightInMilliseconds(i110)            = timeSinceMidnightInMilliseconds;
%             S7Kdata.EM_NetworkAttitude.NetworkAttitudeCounter(i110)                     = number;
%             S7Kdata.EM_NetworkAttitude.SystemSerialNumber(i110)                         = systemSerialNumber;
%             
%             S7Kdata.EM_NetworkAttitude.NumberOfEntries(i110)                            = fread(fid,1,'uint16'); %N
%             S7Kdata.EM_NetworkAttitude.SensorSystemDescriptor(i110)                     = fread(fid,1,'int8');
%             S7Kdata.EM_NetworkAttitude.Spare(i110)                                      = fread(fid,1,'uint8');
%             
%             % repeat cycle: N entries of a variable number of bits. Using a for loop
%             N = S7Kdata.EM_NetworkAttitude.NumberOfEntries(i110);
%             Nx = nan(1,N);
%             for jj=1:N
%                 S7Kdata.EM_NetworkAttitude.TimeInMillisecondsSinceRecordStart{i110}(jj)     = fread(fid,1,'uint16');
%                 S7Kdata.EM_NetworkAttitude.Roll{i110}(jj)                                   = fread(fid,1,'int16');
%                 S7Kdata.EM_NetworkAttitude.Pitch{i110}(jj)                                  = fread(fid,1,'int16');
%                 S7Kdata.EM_NetworkAttitude.Heave{i110}(jj)                                  = fread(fid,1,'int16');
%                 S7Kdata.EM_NetworkAttitude.Heading{i110}(jj)                                = fread(fid,1,'uint16');
%                 S7Kdata.EM_NetworkAttitude.NumberOfBytesInInputDatagrams{i110}(jj)          = fread(fid,1,'uint8'); %Nx
%                 Nx(jj) = S7Kdata.EM_NetworkAttitude.NumberOfBytesInInputDatagrams{i110}(jj);
%                 S7Kdata.EM_NetworkAttitude.NetworkAttitudeInputDatagramAsReceived{i110}{jj} = fread(fid,Nx(jj),'uint8');
%             end
%             
%             % "spare byte if required to get even length (always 0 if used)"
%             if floor((N*11+sum(Nx))/2) == (N*11+sum(Nx))/2
%                 % even so far, since ETX is 1 byte, add a spare here
%                 S7Kdata.EM_NetworkAttitude.Spare2(i110)                                    = fread(fid,1,'uint8');
%             else
%                 % odd so far, since ETX is 1 bytes, no spare
%                 S7Kdata.EM_NetworkAttitude.Spare2(i110) = NaN;
%             end
%             
%             S7Kdata.EM_NetworkAttitude.ETX(i110)                                           = fread(fid,1,'uint8');
%             S7Kdata.EM_NetworkAttitude.CheckSum(i110)                                      = fread(fid,1,'uint16');
%             
%             % ETX check
%             if S7Kdata.EM_NetworkAttitude.ETX(i110)~=3
%                 error('wrong ETX value (S7Kdata.EM_NetworkAttitude)');
%             end
%             
%             % confirm parsing
%             parsed = 1;
%             
%         case 114 %'AMPLITUDE AND PHASE WC DATAGRAM 114 (72H)';
%             if ~(isempty(p.Results.OutputFields)||any(strcmp('EM_AmpPhase',p.Results.OutputFields)))
%                 continue;
%             end
%             % counter for this type of datagram
%             try i114=i114+1; catch, i114=1; end
%             
%             % ----- IMPORTANT NOTE ----------------------------------------
%             % This datagram's data is massive so we don't extract it from
%             % the files and store in memory as is. Instead, we record the
%             % metadata and the exact location of the data for later
%             % extraction. 
%             % -------------------------------------------------------------
%             
%             % parsing
%             S7Kdata.EM_AmpPhase.NumberOfBytesInDatagram(i114)           = nbDatag;
%             
%             % position at start of datagram
%             pos_1 = ftell(fid); 
%             
%             S7Kdata.EM_AmpPhase.STX(i114)                               = stxDatag;
%             S7Kdata.EM_AmpPhase.TypeOfDatagram(i114)                    = datagTypeNumber;
%             S7Kdata.EM_AmpPhase.EMModelNumber(i114)                     = emNumber;
%             S7Kdata.EM_AmpPhase.Date(i114)                              = date;
%             S7Kdata.EM_AmpPhase.TimeSinceMidnightInMilliseconds(i114)   = timeSinceMidnightInMilliseconds;
%             S7Kdata.EM_AmpPhase.PingCounter(i114)                       = number;
%             S7Kdata.EM_AmpPhase.SystemSerialNumber(i114)                = systemSerialNumber;
%             
%             S7Kdata.EM_AmpPhase.NumberOfDatagrams(i114)                 = fread(fid,1,'uint16');
%             S7Kdata.EM_AmpPhase.DatagramNumbers(i114)                   = fread(fid,1,'uint16');
%             S7Kdata.EM_AmpPhase.NumberOfTransmitSectors(i114)           = fread(fid,1,'uint16'); %Ntx
%             S7Kdata.EM_AmpPhase.TotalNumberOfReceiveBeams(i114)         = fread(fid,1,'uint16');
%             S7Kdata.EM_AmpPhase.NumberOfBeamsInThisDatagram(i114)       = fread(fid,1,'uint16'); %Nrx
%             S7Kdata.EM_AmpPhase.SoundSpeed(i114)                        = fread(fid,1,'uint16'); %SS
%             S7Kdata.EM_AmpPhase.SamplingFrequency(i114)                 = fread(fid,1,'uint32'); %SF
%             S7Kdata.EM_AmpPhase.TXTimeHeave(i114)                       = fread(fid,1,'int16');
%             S7Kdata.EM_AmpPhase.TVGFunctionApplied(i114)                = fread(fid,1,'uint8'); %X
%             S7Kdata.EM_AmpPhase.TVGOffset(i114)                         = fread(fid,1,'uint8'); %C
%             S7Kdata.EM_AmpPhase.ScanningInfo(i114)                      = fread(fid,1,'uint8');
%             S7Kdata.EM_AmpPhase.Spare1(i114)                            = fread(fid,1,'uint8');
%             S7Kdata.EM_AmpPhase.Spare2(i114)                            = fread(fid,1,'uint8');
%             S7Kdata.EM_AmpPhase.Spare3(i114)                            = fread(fid,1,'uint8');
%             
%             % repeat cycle #1: Ntx entries of 6 bits
%             temp = ftell(fid);
%             C = 6;
%             Ntx = S7Kdata.EM_AmpPhase.NumberOfTransmitSectors(i114);
%             S7Kdata.EM_AmpPhase.TiltAngle{i114}                     = fread(fid,Ntx,'int16',C-2);
%             fseek(fid,temp+2,'bof'); % to next data type
%             S7Kdata.EM_AmpPhase.CenterFrequency{i114}               = fread(fid,Ntx,'uint16',C-2);
%             fseek(fid,temp+4,'bof'); % to next data type
%             S7Kdata.EM_AmpPhase.TransmitSectorNumber{i114}          = fread(fid,Ntx,'uint8',C-1);
%             fseek(fid,temp+5,'bof'); % to next data type
%             S7Kdata.EM_AmpPhase.Spare{i114}                         = fread(fid,Ntx,'uint8',C-1);
%             fseek(fid,1-C,'cof'); % we need to come back after last jump
%             
%             % repeat cycle #2: Nrx entries of a possibly variable number of
%             % bits. Reading everything first and using a for loop to parse
%             % the data in it
%             Nrx = S7Kdata.EM_AmpPhase.NumberOfBeamsInThisDatagram(i114);
%             
%             pos_2 = ftell(fid); % position at start of data
%             tmp = fread(fid,nbDatag-(pos_2-pos_1+1)-15,'int8'); % read all that data block
%             tmp = int8(tmp');
%             id = 0; % offset for start of each Nrx block
%             wc_parsing_error = 0; % initialize flag
%             
%             % initialize outputs
%             S7Kdata.EM_AmpPhase.BeamPointingAngle{i114}             = nan(1,Nrx);
%             S7Kdata.EM_AmpPhase.StartRangeSampleNumber{i114}        = nan(1,Nrx);
%             S7Kdata.EM_AmpPhase.NumberOfSamples{i114}               = nan(1,Nrx);
%             S7Kdata.EM_AmpPhase.DetectedRangeInSamples{i114}        = nan(1,Nrx);
%             S7Kdata.EM_AmpPhase.TransmitSectorNumber2{i114}         = nan(1,Nrx);
%             S7Kdata.EM_AmpPhase.BeamNumber{i114}                    = nan(1,Nrx);
%             S7Kdata.EM_AmpPhase.SamplePhaseAmplitudePosition{i114}  = nan(1,Nrx);
%             Ns = zeros(1,Nrx);
%             
%             % now parse the data
%             for jj = 1:Nrx
%                 
%                 try
%                     
%                     S7Kdata.EM_AmpPhase.BeamPointingAngle{i114}(jj)             = typecast(tmp(1+id:2+id),'int16');
%                     S7Kdata.EM_AmpPhase.StartRangeSampleNumber{i114}(jj)        = typecast(tmp(3+id:4+id),'uint16');
%                     S7Kdata.EM_AmpPhase.NumberOfSamples{i114}(jj)               = typecast(tmp(5+id:6+id),'uint16');
%                     S7Kdata.EM_AmpPhase.DetectedRangeInSamples{i114}(jj)        = typecast(tmp(7+id:8+id),'uint16');
%                     S7Kdata.EM_AmpPhase.TransmitSectorNumber2{i114}(jj)         = typecast(tmp(9+id),'uint8');
%                     S7Kdata.EM_AmpPhase.BeamNumber{i114}(jj)                    = typecast(tmp(10+id),'uint8');
%                     
%                     % recording data position instead of data themselves
%                     S7Kdata.EM_AmpPhase.SamplePhaseAmplitudePosition{i114}(jj) = pos_2 + id + 10;
%                     % actual data recording would be:
%                     % S7Kdata.EM_AmpPhase.SampleAmplitude{i114}{jj} = tmp((11+id):(11+id+Ns(jj)-1));
%                     
%                     if S7Kdata.EM_AmpPhase.NumberOfSamples{i114}(jj) < 2^16/2
%                         Ns(jj) = S7Kdata.EM_AmpPhase.NumberOfSamples{i114}(jj);
%                     else
%                         % error in number of samples
%                         S7Kdata.EM_AmpPhase.NumberOfSamples{i114}(jj) = 0;
%                         Ns(jj) = 0;
%                     end
%                     
%                     % offset to next jj block
%                     id = 10*jj + 4*sum(Ns);
%                     
%                 catch
%                     
%                     % issue in the recording, flag and exit the loop
%                     S7Kdata.EM_WaterColumn.NumberOfSamples{i107}(jj) = 0;
%                     Ns(jj) = 0;
%                     wc_parsing_error = 1;
%                     continue;
%                     
%                 end
%                 
%             end
%             
%             if wc_parsing_error == 0
%                 % HERE if data parsing all went well
%                 
%                 % "spare byte if required to get even length (always 0 if used)"
%                 if floor((Nrx*10+4*sum(Ns))/2) == (Nrx*10+4*sum(Ns))/2
%                     % even so far, since ETX is 1 byte, add a spare here
%                     S7Kdata.EM_AmpPhase.Spare4(i114) = double(typecast(tmp(1+id),'uint8'));
%                     id = id+1;
%                 else
%                     % odd so far, since ETX is 1 bytes, no spare
%                     S7Kdata.EM_AmpPhase.Spare4(i114) = NaN;
%                 end
%                 
%                 % end of datagram
%                 S7Kdata.EM_AmpPhase.ETX(i114)      = typecast(tmp(id+1),'uint8');
%                 S7Kdata.EM_AmpPhase.CheckSum(i114) = typecast(tmp(2+id:3+id),'uint16');
%                 
%                 % ETX check
%                 if S7Kdata.EM_AmpPhase.ETX(i114)~=3
%                     error('wrong ETX value (S7Kdata.EM_AmpPhase)');
%                 end
%                 
%                 % confirm parsing
%                 parsed = 1;
%                 
%             else
%                 % HERE if data parsing failed, add a blank datagram in
%                 % output
%                 
%                 % copy field names of previous entries
%                 fields_ap = fieldnames(S7Kdata.EM_AmpPhase);
%                 
%                 % add blanks fields for those missing
%                 for ifi = 1:numel(fields_ap)
%                     if numel(S7Kdata.EM_AmpPhase.(fields_ap{ifi})) >= i114
%                         S7Kdata.EM_AmpPhase.(fields_ap{ifi})(i114) = [];
%                     end
%                 end
%                 
%                 i114 = i114-1; % XXX if we do that, then we'll rewrite over the blank record we just entered??
%                 parsed = 0;
%                 
%             end
            
        otherwise
            
            % datagTypeNumber is not recognized yet
            
    end
    
    % modify parsed status in info
    S7Kfileinfo.parsed(iDatag,1) = parsed;
    
end


%% close fid
fclose(fid);


%% add info to parsed data
S7Kdata.info = S7Kfileinfo;

