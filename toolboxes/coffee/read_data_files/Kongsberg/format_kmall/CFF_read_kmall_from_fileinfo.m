%% CFF_read_kmall_from_fileinfo.m
%
% XXX
%
%% Help
%
% *USE*
%
% XXX
%
% *INPUT VARIABLES*
%
% XXX
%
% *OUTPUT VARIABLES*
%
% XXX
%
% *DEVELOPMENT NOTES*
%
% XXX
%
% *NEW FEATURES*
%
% * 2021-05-26: first version (Alex)
%
% *EXAMPLE*
%
% XXX
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Alexandre Schimel (NGU), Yoann Ladroit (NIWA).
% Type |help CoFFee.m| for copyright information.

%% Function
function KMALLdata = CFF_read_kmall_from_fileinfo(KMALLfilename,KMALLfileinfo,varargin)

global DEBUG;

%% Input arguments management using inputParser
p = inputParser;

% KMALLfilename to parse
argName = 'KMALLfilename';
argCheck = @(x) CFF_check_KMALLfilename(x);
addRequired(p,argName,argCheck);

% KMALLfileinfo resulting from first pass reading
argName = 'KMALLfileinfo';
argCheck = @isstruct;
addRequired(p,argName,argCheck);

% MATfilename output as only optional argument.
argName = 'OutputFields';
argCheck = @iscell;
addParameter(p,argName,{},argCheck);

% now parse inputs
parse(p,KMALLfilename,KMALLfileinfo,varargin{:});

% and get results
KMALLfilename = p.Results.KMALLfilename;
KMALLfileinfo = p.Results.KMALLfileinfo;


%% Pre-reading

% store
KMALLdata.KMALLfilename = KMALLfilename;

% open file
[fid,~] = fopen(KMALLfilename, 'r');

% Parse only datagrams indicated in KMALLfileinfo
datagToParse = find(KMALLfileinfo.parsed==1);


%% Reading datagrams
for iDatag = datagToParse'
    
    % A full kmall datagram is organized as a sequence of:
    % * GH - General Header EMdgmHeader (20 bytes, at least for Rev H)
    % * DB - Datagram Body (variable size)
    % * DS - Datagram size (uint32, aka 4 bytes)
    %
    % The General Header was read and stored in fileinfo. Here we read the
    % datagram body only
    %
    % Relevant info from the general header
    dgm_type_code = KMALLfileinfo.dgm_type_code{iDatag}(2:end);
    dgm_start_pif = KMALLfileinfo.dgm_start_pif(iDatag);
    dgm_size      = KMALLfileinfo.dgm_size(iDatag);
    
    % size of datagram body
    GH_size = 20;
    DS_size = 4;
    dgm_body_size = dgm_size - GH_size - DS_size;
    
    % Go directly to the start of datagram body, after the general header
    fseek(fid, dgm_start_pif + GH_size, -1);
    
    % reset the parsed switch
    parsed = 0;
    
    switch dgm_type_code
        
        case 'IIP'
            %% '#IIP - Installation parameters and sensor setup'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iIIP=iIIP+1; catch, iIIP=1; end
            
            KMALLdata.IIP.numBytesCmnPart(iIIP) = fread(fid,1,'uint16');
            KMALLdata.IIP.info(iIIP)            = fread(fid,1,'uint16');
            KMALLdata.IIP.status(iIIP)          = fread(fid,1,'uint16');
            KMALLdata.IIP.install_txt{iIIP}     = fscanf(fid, '%c',dgm_body_size-6); % rest of the datagram is text info
            
            parsed = 1;
            
        case 'IOP'
            %% '#IOP - Runtime parameters as chosen by operator'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iIOP=iIOP+1; catch, iIOP=1; end
            
            KMALLdata.IOP.numBytesCmnPart(iIOP) = fread(fid,1,'uint16');
            KMALLdata.IOP.info(iIOP)            = fread(fid,1,'uint16');
            KMALLdata.IOP.status(iIOP)          = fread(fid,1,'uint16');
            KMALLdata.IOP.runtime_txt{iIOP}     = fscanf(fid, '%c',dgm_body_size-6); % rest of the datagram is text info
            
            parsed = 1;
            
        case 'IBE'
            %% '#IBE - Built in test (BIST) error report'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iIBE=iIBE+1; catch, iIBE=1; end
            
        case 'IBR'
            %% '#IBR - Built in test (BIST) reply'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iIBR=iIBR+1; catch, iIBR=1; end
            
        case 'IBS'
            %% '#IBS - Built in test (BIST) short reply'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iIBS=iIBS+1; catch, iIBS=1; end
            
        case 'MRZ'
            %% '#MRZ - Multibeam (M) raw range (R) and depth(Z) datagram'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iMRZ=iMRZ+1; catch, iMRZ=1; end
            
        case 'MWC'
            %% '#MWC - Multibeam (M) water (W) column (C) datagram'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iMWC=iMWC+1; catch, iMWC=1; end
            
        case 'SPO'
            %% '#SPO - Sensor (S) data for position (PO)'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iSPO=iSPO+1; catch, iSPO=1; end
            
        case 'SKM'
            %% '#SKM - Sensor (S) KM binary sensor format'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iSKM=iSKM+1; catch, iSKM=1; end
            
        case 'SVP'
            %% '#SVP - Sensor (S) data from sound velocity (V) profile (P) or CTD'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iSVP=iSVP+1; catch, iSVP=1; end
            
            KMALLdata.SVP.numBytesCmnPart(iSVP) = fread(fid,1,'uint16');
            
            N = fread(fid,1,'uint16');
            KMALLdata.SVP.numSamples(iSVP) = N;
            
            KMALLdata.SVP.sensorFormat{iSVP}    = fscanf(fid,'%c',4);
            KMALLdata.SVP.time_sec(iSVP)        = fread(fid,1,'uint32');
            KMALLdata.SVP.latitude_deg(iSVP)    = fread(fid,1,'double');
            KMALLdata.SVP.longitude_deg(iSVP)   = fread(fid,1,'double');
            
            % repeat cycles: N entries of S bytes
            % sensorData struct EMdgmSVPpoint_def
            temp = ftell(fid);
            S = 20; 
            KMALLdata.SVP.depth_m{iSVP}               = fread(fid,N,'float',S-4);
            fseek(fid,temp+4,'bof'); % to next data type
            KMALLdata.SVP.soundVelocity_mPerSec{iSVP} = fread(fid,N,'float',S-4);
            fseek(fid,temp+8,'bof'); % to next data type
            KMALLdata.SVP.padding{iSVP}               = fread(fid,N,'uint32',S-4);
            fseek(fid,temp+12,'bof'); % to next data type
            KMALLdata.SVP.temp_C{iSVP}                = fread(fid,N,'float',S-4);
            fseek(fid,temp+16,'bof'); % to next data type
            KMALLdata.SVP.salinity{iSVP}              = fread(fid,N,'float',S-4);
            fseek(fid,4-S,'cof'); % we need to come back after last jump
            
            parsed = 1;
            
            if DEBUG
                figure;
                subplot(131)
                plot(KMALLdata.SVP.soundVelocity_mPerSec{iSVP},-KMALLdata.SVP.depth_m{iSVP},'.-');
                ylabel('depth (m)')
                xlabel('sound velocity (m/s)')
                grid on
                subplot(132)
                plot(KMALLdata.SVP.temp_C{iSVP},-KMALLdata.SVP.depth_m{iSVP},'.-');
                ylabel('depth (m)')
                xlabel('temperature (C)')
                grid on
                title('KMALL Sound Velocity Profile datagram contents')
                subplot(133)
                plot(KMALLdata.SVP.salinity{iSVP},-KMALLdata.SVP.depth_m{iSVP},'.-');
                ylabel('depth (m)')
                xlabel('salinity')
                grid on
            end
            
        case 'SVT'
            %% '#SVT - Sensor (S) data for sound velocity (V) at transducer (T)'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iSVT=iSVT+1; catch, iSVT=1; end
            
        case 'SCL'
            %% '#SCL - Sensor (S) data from clock (CL)'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iSCL=iSCL+1; catch, iSCL=1; end
        case 'SDE'
            %% '#SDE - Sensor (S) data from depth (DE) sensor'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iSDE=iSDE+1; catch, iSDE=1; end
            
        case 'SHI'
            %% '#SHI - Sensor (S) data for height (HI)'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iSHI=iSHI+1; catch, iSHI=1; end
            
        case 'CPO'
            %% '#CPO - Compatibility (C) data for position (PO)'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iCPO=iCPO+1; catch, iCPO=1; end
            
        case 'CHE'
            %% '#CHE - Compatibility (C) data for heave (HE)'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iCHE=iCHE+1; catch, iCHE=1; end
            
        case '#FCF - Backscatter calibration (C) file (F) datagram'
            %% 'YYY'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iFCF=iFCF+1; catch, iFCF=1; end
            
        otherwise
            % dgm_type_code not recognized yet. Skip for now.
            
    end
    
    % modify parsed status in info
    KMALLfileinfo.parsed(iDatag,1) = parsed;
    
end


%% close fid
fclose(fid);

%% add info to parsed data
KMALLdata.info = KMALLfileinfo;

