%% CFF_init_memmapfiles.m
%
% Initializes data-containing memmap files
%
%% Help
%
% *USE*
%
% Create one or several empty binary files of the right size to store ONE
% type of an upcoming large data, link it as a memmap file into a fData
% field, and add info as additional fData fields. 
% This function is to be used with the proper varargin parameters
% to initialize the binary files (and link them to fData) with empty
% values, prior to reading the acoustic data and filling the binary files.
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Alexandre Schimel (NGU), Yoann Ladroit (NIWA).
% Type |help Espresso.m| for copyright information.

%% Function
function fData = CFF_init_memmapfiles(fData,varargin)

%% input parser
p = inputParser;

addParameter(p,'field','WC_SBP_SampleAmplitudes', @ischar);
addParameter(p,'wc_dir', CFF_converted_data_folder(fData.ALLfilename{1}), @ischar);
addParameter(p,'Class', 'int8', @ischar);
addParameter(p,'Factor', 1/2, @isnumeric);
addParameter(p,'Nanval', intmin('int8'), @isnumeric);
addParameter(p,'Offset', 0, @isnumeric);
addParameter(p,'MaxSamples', 1, @isnumeric);
addParameter(p,'MaxBeams', 1, @isnumeric);
addParameter(p,'ping_group_start', 1, @isnumeric);
addParameter(p,'ping_group_end', 1, @isnumeric);

parse(p,varargin{:});

wc_dir = p.Results.wc_dir;
field  = p.Results.field;
Class  = p.Results.Class;
Factor = p.Results.Factor;
Nanval = p.Results.Nanval;
Offset = p.Results.Offset;
maxNSamples_groups = p.Results.MaxSamples;
maxNBeams_sub      = p.Results.MaxBeams;
ping_group_start   = p.Results.ping_group_start;
ping_group_end     = p.Results.ping_group_end;


%% prep

% number of memmap files requested, one per group of pings
num_files = numel(ping_group_start);

% if data field already exists, delete it
if isfield(fData,field)
    for uig = 1:num_files
        fData.(field){uig} = [];
    end
    fData = rmfield(fData,field) ;
end

% number of bytes depending on class
switch Class
    case {'int8' 'uint8'}
        num_bytes = 1;
    case {'int16' 'uint16'}
        num_bytes = 2;
    case {'int32' 'uint32'}
        num_bytes = 4;
    case {'int64' 'uint64'}
        num_bytes = 8;
    case {'single'}
        num_bytes = 4;
    case {'double'}
        num_bytes = 8;
end


%% create empty binary files
for uig = 1:num_files
    
    % file name
    file_binary = fullfile(wc_dir,sprintf('%s_%.0f_%.0f.dat',field,ping_group_start(uig),ping_group_end(uig)));
    
    % sizes
    nSamples = maxNSamples_groups(uig);
    nBeams = maxNBeams_sub;
    nPings = (ping_group_end(uig)-ping_group_start(uig)+1);
    
    % create empty binary file if it does not exist
    if ~isfile(file_binary)
        
        % create and open
        fileID = fopen(file_binary,'w+');
        
        % initialize file with zeros
        total_num_elements = nSamples*nBeams*nPings;
        num_skip_bytes = num_bytes*(total_num_elements-1);
        fwrite(fileID,0,Class,num_skip_bytes);
        
        % close file
        fclose(fileID);
        
    else
        % ideally, if file already exists, we should test to see if it has
        % the right "class [nSamples nBeams nPings]" before
        % linking it after. Checking this means we should not have deleted
        % the field before.
        %
        % if it has the right size, fill it with NaNs.
        %
        % if it's not the right size, we should delete it and recreate it,
        % but problem is we can't delete it as it's memmaped in the app.
        % Anyway, something to thinks about on the day we want to consider
        % that case...
    end
    
    % memory map this binary file as a field in fData
    fData.(field){uig} = memmapfile(file_binary,...
        'Format',{Class [nSamples nBeams nPings] 'val'},...
        'repeat',1,...
        'writable',true);
    
end


%% record in fData the memmapfile info

% add or overwrite info fields
p_field = strrep(field,'SBP','1');
fData.(sprintf('%s_Class',p_field))  = Class;
fData.(sprintf('%s_Nanval',p_field)) = Nanval;
fData.(sprintf('%s_Factor',p_field)) = Factor;
fData.(sprintf('%s_Offset',p_field)) = Offset;
switch field(1)
    case 'X'
        prefix = field(1);
    otherwise
        prefix = field(1:2);
end
fData.(sprintf('%s_n_start',prefix))       = ping_group_start;
fData.(sprintf('%s_n_end',prefix))         = ping_group_end;
fData.(sprintf('%s_n_maxNSamples',prefix)) = maxNSamples_groups;

