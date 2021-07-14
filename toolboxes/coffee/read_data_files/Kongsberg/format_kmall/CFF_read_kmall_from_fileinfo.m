%% CFF_read_kmall_from_fileinfo.m
%
% Reads contents of one Kongsberg EM series binary data file in .kmall
% format (.kmall or .kmwcd), using KMALLfileinfo to indicate which
% datagrams to be parsed. 
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
% * 2021-06-01: added MRZ and MWC parsing (Alex)
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

% This code was developped around the following kmall format versions.
kmall_versions_supported = 'H,I';

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

% flag so kmall version warning only goes off once
kmall_version_warning_flag = 0;

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
    
    % set/reset the parsed switch
    parsed = 0;
    
    % set/reset the datagram version warning flag
    dtg_warn_flag = 0;
    
    switch dgm_type_code
        
        
        %% --------- INSTALLATION AND RUNTIME DATAGRAMS (I..) -------------
        
        case 'IIP'
            % '#IIP - Installation parameters and sensor setup'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iIIP=iIIP+1; catch, iIIP=1; dtg_warn_flag = 1; end
             
            KMALLdata.EMdgmIIP(iIIP) = CFF_read_EMdgmIIP(fid, dtg_warn_flag);
            
            % extract kmall version
            kmall_version = CFF_get_kmall_version(KMALLdata.EMdgmIIP(iIIP));
            
            if ~ismember(kmall_version, kmall_versions_supported) && ~kmall_version_warning_flag
                warning('The kmall format version (%s) of this file is different to that used to develop the raw data reading code (%s). Data will be read anyway, but there may be issues.',kmall_version,kmall_versions_supported);
                kmall_version_warning_flag = 1;
            end
            
            parsed = 1;
            
        case 'IOP'
            % '#IOP - Runtime parameters as chosen by operator'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iIOP=iIOP+1; catch, iIOP=1; dtg_warn_flag = 1; end
            
            KMALLdata.EMdgmIOP(iIOP) = CFF_read_EMdgmIOP(fid, dtg_warn_flag);
            
            parsed = 1;
            
        case 'IBE'
            % '#IBE - Built in test (BIST) error report'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iIBE=iIBE+1; catch, iIBE=1; dtg_warn_flag = 1; end
            
            % in progress...
            % KMALLdata.EMdgmIBE(iIBE) = CFF_read_EMdgmIBE(fid, dtg_warn_flag);
            
            parsed = 0;
            
        case 'IBR'
            % '#IBR - Built in test (BIST) reply'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iIBR=iIBR+1; catch, iIBR=1; dtg_warn_flag = 1; end
            
            % in progress...
            % KMALLdata.EMdgmIBR(iIBR) = CFF_read_EMdgmIBR(fid, dtg_warn_flag);
            
            parsed = 0;
            
        case 'IBS' 
            % '#IBS - Built in test (BIST) short reply'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iIBS=iIBS+1; catch, iIBS=1; dtg_warn_flag = 1; end
            
            % in progress...
            % KMALLdata.EMdgmIBS(iIBS) = CFF_read_EMdgmIBS(fid, dtg_warn_flag);
            
            parsed = 0;
            
          
        %% ------------------ MULTIBEAM DATAGRAMS (M..) -------------------
      
        case 'MRZ'
            % '#MRZ - Multibeam (M) raw range (R) and depth(Z) datagram'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iMRZ=iMRZ+1; catch, iMRZ=1; dtg_warn_flag = 1; end
            
            KMALLdata.EMdgmMRZ(iMRZ) = CFF_read_EMdgmMRZ(fid, dtg_warn_flag);
            
            parsed = 1;
            
            if DEBUG
                figure;
                
                num_beams = KMALLdata.EMdgmMRZ(iMRZ).rxInfo.numSoundingsMaxMain ...
                    +  KMALLdata.EMdgmMRZ(iMRZ).rxInfo.numExtraDetectionClasses;
                
                % detection info
                subplot(221);
                plot([KMALLdata.EMdgmMRZ(iMRZ).sounding.qualityFactor]);
                hold on
                plot([KMALLdata.EMdgmMRZ(iMRZ).sounding.detectionUncertaintyVer_m]);
                plot([KMALLdata.EMdgmMRZ(iMRZ).sounding.detectionUncertaintyHor_m]);
                xlabel('beam number')
                legend('Ifremer quality fact.', 'Vert. uncert. (m)', 'Horz. uncert. (m)');
                title('Detection info')
                grid on
                xlim([1 num_beams])
                
                % reflectivity data
                subplot(222);
                plot([KMALLdata.EMdgmMRZ(iMRZ).sounding.reflectivity1_dB]);
                hold on
                plot([KMALLdata.EMdgmMRZ(iMRZ).sounding.reflectivity2_dB]);
                xlabel('beam number')
                legend('Refl. 1 (dB)', 'Refl. 2 (dB)');
                title('Reflectivity data')
                grid on
                xlim([1 num_beams])
                
                % range and angle
                subplot(223);
                plot([KMALLdata.EMdgmMRZ(iMRZ).sounding.beamAngleReRx_deg], ...
                    [KMALLdata.EMdgmMRZ(iMRZ).sounding.twoWayTravelTime_sec]);
                xlabel('beam angle re. Rx (deg)')
                ylabel('two-way travel time (s)')
                title('Range and angle')
                grid on
                
                % georeferenced depth points
                subplot(224);
                plot([KMALLdata.EMdgmMRZ(iMRZ).sounding.y_reRefPoint_m], ...
                    [KMALLdata.EMdgmMRZ(iMRZ).sounding.z_reRefPoint_m]);
                xlabel('Horz. dist y (m)')
                ylabel('Vert. dist z (m)')
                title('Georeferenced depth points')
                grid on
            end
            
        case 'MWC'
            % '#MWC - Multibeam (M) water (W) column (C) datagram'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iMWC=iMWC+1; catch, iMWC=1; dtg_warn_flag = 1; end
            
            KMALLdata.EMdgmMWC(iMWC) = CFF_read_EMdgmMWC(fid, dtg_warn_flag);
            
            parsed = 1;
            
            if DEBUG
                
                % save pif
                pif_save = ftell(fid);
                
                % get water-column amplitude for this ping and phase if it
                % exists)
                max_samples = max([KMALLdata.EMdgmMWC(iMWC).beamData_p.startRangeSampleNum] ...
                    + [KMALLdata.EMdgmMWC(iMWC).beamData_p.numSampleData]);
                nBeams = KMALLdata.EMdgmMWC(iMWC).rxInfo.numBeams;
                Mag_tmp = nan(max_samples, nBeams);
                Ph_tmp = nan(max_samples, nBeams);
                phaseFlag = KMALLdata.EMdgmMWC(iMWC).rxInfo.phaseFlag;
                for iB = 1:nBeams
                    dpif = KMALLdata.EMdgmMWC(iMWC).beamData_p.sampleDataPositionInFile(iB);
                    fseek(fid,dpif,-1);
                    sR = KMALLdata.EMdgmMWC(iMWC).beamData_p.startRangeSampleNum(iB);
                    nS = KMALLdata.EMdgmMWC(iMWC).beamData_p.numSampleData(iB);
                    if phaseFlag == 0
                        % Only nS records of amplitude of 1 byte
                        Mag_tmp(sR+1:sR+nS,iB) = fread(fid, nS, 'int8=>int8',0);
                    elseif phaseFlag == 1
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
                
                % reset pif
                fseek(fid, pif_save,-1);
                
                % plot
                figure;
                if ~phaseFlag
                    % amplitude only
                    imagesc(WC);
                    xlabel('beam number');
                    ylabel('sample number');
                    grid on; colorbar
                    title('KMALL Multibeam Water Column datagram contents: amplitude only');
                else
                    % amplitude
                    subplot(121); imagesc(WC);
                    xlabel('beam number');
                    ylabel('sample number');
                    grid on; colorbar
                    title('KMALL Multibeam Water Column datagram contents: amplitude');
                    % phase
                    subplot(121); imagesc(Ph);
                    xlabel('beam number');
                    ylabel('sample number');
                    grid on; colorbar
                    title('KMALL Multibeam Water Column datagram contents: phase');
                end
               
            end
            

        %% ------------------- SENSOR DATAGRAMS (S..) ---------------------

        case 'SPO'
            % '#SPO - Sensor (S) data for position (PO)'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iSPO=iSPO+1; catch, iSPO=1; dtg_warn_flag = 1; end
            
            KMALLdata.EMdgmSPO(iSPO) = CFF_read_EMdgmSPO(fid, dtg_warn_flag);
            
            parsed = 1;
            
        case 'SKM'
            % '#SKM - Sensor (S) KM binary sensor format'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iSKM=iSKM+1; catch, iSKM=1; dtg_warn_flag = 1; end
            
            KMALLdata.EMdgmSKM(iSKM) = CFF_read_EMdgmSKM(fid, dtg_warn_flag);
            
            parsed = 1;
            
        case 'SVP'
            % '#SVP - Sensor (S) data from sound velocity (V) profile (P) or CTD'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iSVP=iSVP+1; catch, iSVP=1; dtg_warn_flag = 1; end
            
            KMALLdata.EMdgmSVP(iSVP) = CFF_read_EMdgmSVP(fid, dtg_warn_flag);
            
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
                title(sprintf('%s\nSound Velocity Profile datagram contents',KMALLdata.KMALLfilename));
                subplot(133); plot(salinity,-depth,'.-');
                ylabel('depth (m)'); xlabel('salinity'); grid on
            end
            
        case 'SVT'
            % '#SVT - Sensor (S) data for sound velocity (V) at transducer (T)'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iSVT=iSVT+1; catch, iSVT=1; dtg_warn_flag = 1; end
            
            % in progress...
            % KMALLdata.EMdgmSVT(iSVT) = CFF_read_EMdgmSVT(fid, dtg_warn_flag);
            
            parsed = 0;
            
        case 'SCL'
            % '#SCL - Sensor (S) data from clock (CL)'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iSCL=iSCL+1; catch, iSCL=1; dtg_warn_flag = 1; end
            
            KMALLdata.EMdgmSCL(iSCL) = CFF_read_EMdgmSCL(fid, dtg_warn_flag);
            
            parsed = 1;
            
        case 'SDE'
            % '#SDE - Sensor (S) data from depth (DE) sensor'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iSDE=iSDE+1; catch, iSDE=1; dtg_warn_flag = 1; end
            
            % in progress...
            % KMALLdata.EMdgmSDE(iSDE) = CFF_read_EMdgmSDE(fid, dtg_warn_flag);
            
            parsed = 0;
            
        case 'SHI'
            % '#SHI - Sensor (S) data for height (HI)'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iSHI=iSHI+1; catch, iSHI=1; dtg_warn_flag = 1; end
            
            % in progress...
            % KMALLdata.EMdgmSHI(iSHI) = CFF_read_EMdgmSHI(fid, dtg_warn_flag);
            
            parsed = 0;
            
            
        %% --------------- COMPATIBILITY DATAGRAMS (C..) ------------------
                    
        case 'CPO'
            % '#CPO - Compatibility (C) data for position (PO)'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iCPO=iCPO+1; catch, iCPO=1; dtg_warn_flag = 1; end
            
            KMALLdata.EMdgmCPO(iCPO) = CFF_read_EMdgmCPO(fid, dtg_warn_flag);
            
            parsed = 1;
            
        case 'CHE'
            % '#CHE - Compatibility (C) data for heave (HE)'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iCHE=iCHE+1; catch, iCHE=1; dtg_warn_flag = 1; end
           
            KMALLdata.EMdgmCHE(iCHE) = CFF_read_EMdgmCHE(fid, dtg_warn_flag);
            
            parsed = 1;
            
 
        %% --------------------- FILE DATAGRAMS (F..) ---------------------
                                           
        case '#FCF - Backscatter calibration (C) file (F) datagram'
            % 'YYY'
            if ~( isempty(p.Results.OutputFields) || any(strcmp(dgm_type_code,p.Results.OutputFields)) )
                continue;
            end
            try iFCF=iFCF+1; catch, iFCF=1; dtg_warn_flag = 1; end
            
            % in progress...
            % KMALLdata.EMdgmFCF(iFCF) = CFF_read_EMdgmFCF(fid, dtg_warn_flag);
            
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


