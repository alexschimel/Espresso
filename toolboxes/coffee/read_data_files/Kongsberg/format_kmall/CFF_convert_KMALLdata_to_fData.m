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
    fData.ALLfilename{iF} = KMALLdata.KMALLfilename;
    
    % now reading each type of datagram.
    % Note we only convert the datagrams if fData does not already contain
    % any.
    
    
    %% '#IIP - Installation parameters and sensor setup'
    if isfield(KMALLdata,'EMdgmIIP') && ~isfield(fData,'IP_ASCIIparameters')
        
        % Only value Espresso needs (to date) is the "sonar heading
        % offset". In installation parameters datagrams of .all files, we
        % only had one field "S1H" per head. Here we have heading values
        % for both the Tx and Rx antennae. So not sure which one we should
        % take, or the difference between the two... but for now, take the
        % value from Rx.
        
        % read ASCIIdata
        ASCIIdata = KMALLdata.EMdgmIIP(1).install_txt;
        
        % remove carriage returns, tabs and linefeed
        ASCIIdata = regexprep(ASCIIdata,char(9),'');
        ASCIIdata = regexprep(ASCIIdata,newline,'');
        ASCIIdata = regexprep(ASCIIdata,char(13),'');
        
        % read some fields
        % IP_ASCIIparameters.TRAI_TX1 = CFF_read_TRAI(ASCIIdata,'TRAI_TX1');
        % IP_ASCIIparameters.TRAI_TX2 = CFF_read_TRAI(ASCIIdata,'TRAI_TX2');
        IP_ASCIIparameters.TRAI_RX1 = CFF_read_TRAI(ASCIIdata,'TRAI_RX1');
        % IP_ASCIIparameters.TRAI_RX2 = CFF_read_TRAI(ASCIIdata,'TRAI_RX2');
        
        % record value in old field for the software to pick up
        IP_ASCIIparameters.S1H = IP_ASCIIparameters.TRAI_RX1.H;
        
        % finally store in fData
        fData.IP_ASCIIparameters = IP_ASCIIparameters;
        
    end
    
    %% '#IOP - Runtime parameters as chosen by operator'
    if isfield(KMALLdata,'EMdgmIOP') && ~isfield(fData,'Ru_1D_Date')
        
        % Here we only record the fields we need later. More fields are
        % available than those below.
        fData.Ru_1D_TransmitPowerReMaximum = KMALLdata.EMdgmIOP(1).TransmitPowerReMaximum;
        fData.Ru_1D_ReceiveBeamwidth       = KMALLdata.EMdgmIOP(1).ReceiveBeamwidth./10; % now in degrees
        
        % date and time in particular: 
        % dt = datetime(KMALLdata.EMdgmIOP(1).header.time_sec + KMALLdata.EMdgmIOP(1).header.time_nanosec.*10^-9,'ConvertFrom','posixtime');
        % fData.Ru_1D_Date                            = convertTo(dt, 'yyyymmdd');
        % fData.Ru_1D_TimeSinceMidnightInMilliseconds = milliseconds(timeofday(dt));
        
    end
    
    %% '#MRZ - Multibeam (M) raw range (R) and depth(Z) datagram'
    
    %% '#MWC - Multibeam (M) water (W) column (C) datagram'
    
    %% '#SPO - Sensor (S) data for position (PO)'
    %% '#SPO - Sensor (S) data for position (PO)'
    
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

