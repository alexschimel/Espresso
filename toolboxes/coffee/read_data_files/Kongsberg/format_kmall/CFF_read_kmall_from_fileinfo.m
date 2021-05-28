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
    
    % Go to start of dgm
    fseek(fid, dgm_start_pif, -1);
    
    % reset the parsed switch
    parsed = 0;
    
    switch dgm_type_code
        
        
        %% --------- INSTALLATION AND RUNTIME DATAGRAMS (I..) -------------
        
        case 'IIP'
            % '#IIP - Installation parameters and sensor setup'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iIIP=iIIP+1; catch, iIIP=1; end
             
            KMALLdata.EMdgmIIP(iIIP) = CFF_read_EMdgmIIP(fid);
            
            % extract kmall version
            kmall_version = CFF_get_kmall_version(KMALLdata.EMdgmIIP(iIIP));
            if ~strcmp(kmall_version, 'H')
                warning('This kmall format version (%s) is different to the one used to develop the raw data reading code (H). This may lead to issues.');
            end
            
            parsed = 1;
            
        case 'IOP'
            % '#IOP - Runtime parameters as chosen by operator'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iIOP=iIOP+1; catch, iIOP=1; end
            
            KMALLdata.EMdgmIOP(iIOP) = CFF_read_EMdgmIOP(fid);
            
            parsed = 1;
            
        case 'IBE'
            % '#IBE - Built in test (BIST) error report'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iIBE=iIBE+1; catch, iIBE=1; end
            
            % in progress...
            % KMALLdata.EMdgmIBE(iIBE) = CFF_read_EMdgmIBE(fid);
            
            parsed = 0;
            
        case 'IBR'
            % '#IBR - Built in test (BIST) reply'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iIBR=iIBR+1; catch, iIBR=1; end
            
            % in progress...
            % KMALLdata.EMdgmIBR(iIBR) = CFF_read_EMdgmIBR(fid);
            
            parsed = 0;
            
        case 'IBS' 
            % '#IBS - Built in test (BIST) short reply'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iIBS=iIBS+1; catch, iIBS=1; end
            
            % in progress...
            % KMALLdata.EMdgmIBS(iIBS) = CFF_read_EMdgmIBS(fid);
            
            parsed = 0;
            
          
        %% ------------------ MULTIBEAM DATAGRAMS (M..) -------------------
      
        case 'MRZ'
            % '#MRZ - Multibeam (M) raw range (R) and depth(Z) datagram'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iMRZ=iMRZ+1; catch, iMRZ=1; end
            
            % in progress...
            % KMALLdata.EMdgmMRZ(iMRZ) = CFF_read_EMdgmMRZ(fid);
            
            parsed = 0;
            
        case 'MWC'
            % '#MWC - Multibeam (M) water (W) column (C) datagram'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iMWC=iMWC+1; catch, iMWC=1; end
            
            % in progress...
            % KMALLdata.EMdgmMWC(iMWC) = CFF_read_EMdgmMWC(fid);
            
            parsed = 0;

        %% ------------------- SENSOR DATAGRAMS (S..) ---------------------

        case 'SPO'
            % '#SPO - Sensor (S) data for position (PO)'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iSPO=iSPO+1; catch, iSPO=1; end
            
            KMALLdata.EMdgmSPO(iSPO) = CFF_read_EMdgmSPO(fid);
            
            parsed = 1;
            
        case 'SKM'
            % '#SKM - Sensor (S) KM binary sensor format'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iSKM=iSKM+1; catch, iSKM=1; end
            
            KMALLdata.EMdgmSKM(iSKM) = CFF_read_EMdgmSKM(fid);
            
            parsed = 1;
            
        case 'SVP'
            % '#SVP - Sensor (S) data from sound velocity (V) profile (P) or CTD'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iSVP=iSVP+1; catch, iSVP=1; end
            
            KMALLdata.EMdgmSVP(iSVP) = CFF_read_EMdgmSVP(fid);
            
            parsed = 1;
            
            if DEBUG
                depth    = [KMALLdata.EMdgmSVP(iSVP).sensorData.depth_m];
                velocity = [KMALLdata.EMdgmSVP(iSVP).sensorData.soundVelocity_mPerSec];
                temp     = [KMALLdata.EMdgmSVP(iSVP).sensorData.temp_C];
                salinity = [KMALLdata.EMdgmSVP(iSVP).sensorData.salinity];
                figure;
                subplot(131); plot(velocity,-depth,'.-');
                ylabel('depth (m)'); xlabel('sound velocity (m/s)'); grid on
                subplot(132); plot(temp,-depth,'.-');
                ylabel('depth (m)'); xlabel('temperature (C)'); grid on
                title('KMALL Sound Velocity Profile datagram contents')
                subplot(133); plot(salinity,-depth,'.-');
                ylabel('depth (m)'); xlabel('salinity'); grid on
            end
            
        case 'SVT'
            % '#SVT - Sensor (S) data for sound velocity (V) at transducer (T)'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iSVT=iSVT+1; catch, iSVT=1; end
            
            % in progress...
            % KMALLdata.EMdgmSVT(iSVT) = CFF_read_EMdgmSVT(fid);
            
            parsed = 0;
            
        case 'SCL'
            % '#SCL - Sensor (S) data from clock (CL)'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iSCL=iSCL+1; catch, iSCL=1; end
            
            KMALLdata.EMdgmSCL(iSCL) = CFF_read_EMdgmSCL(fid);
            
            parsed = 1;
            
        case 'SDE'
            % '#SDE - Sensor (S) data from depth (DE) sensor'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iSDE=iSDE+1; catch, iSDE=1; end
            
            % in progress...
            % KMALLdata.EMdgmSDE(iSDE) = CFF_read_EMdgmSDE(fid);
            
            parsed = 0;
            
        case 'SHI'
            % '#SHI - Sensor (S) data for height (HI)'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iSHI=iSHI+1; catch, iSHI=1; end
            
            % in progress...
            % KMALLdata.EMdgmSHI(iSHI) = CFF_read_EMdgmSHI(fid);
            
            parsed = 0;
            
            
        %% --------------- COMPATIBILITY DATAGRAMS (C..) ------------------
                    
        case 'CPO'
            % '#CPO - Compatibility (C) data for position (PO)'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iCPO=iCPO+1; catch, iCPO=1; end
            
            KMALLdata.EMdgmCPO(iCPO) = CFF_read_EMdgmCPO(fid);
            
            parsed = 1;
            
        case 'CHE'
            % '#CHE - Compatibility (C) data for heave (HE)'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iCHE=iCHE+1; catch, iCHE=1; end
           
            KMALLdata.EMdgmCHE(iCHE) = CFF_read_EMdgmCHE(fid);
            
            parsed = 1;
            
 
        %% --------------------- FILE DATAGRAMS (F..) ---------------------
                                           
        case '#FCF - Backscatter calibration (C) file (F) datagram'
            % 'YYY'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iFCF=iFCF+1; catch, iFCF=1; end
            
            % in progress...
            % KMALLdata.EMdgmFCF(iFCF) = CFF_read_EMdgmFCF(fid);
            
            parsed = 0;
            
        otherwise
            % dgm_type_code not recognized. Skip.
            
            parsed = 0;
            
    end
    
    % modify parsed status in info
    KMALLfileinfo.parsed(iDatag,1) = parsed;
    
end


%% close fid
fclose(fid);

%% add info to parsed data
KMALLdata.info = KMALLfileinfo;

end


