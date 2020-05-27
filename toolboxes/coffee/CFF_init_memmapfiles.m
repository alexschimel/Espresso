function fData = CFF_init_memmapfiles(fData,varargin)
%CFF_INIT_MEMMAPFILES Initiliazes data-containing memmap files
%   fData = CFF_INIT_MEMMAPFILES(fData) creates a binary file of a NaN for
%   unit parameters (1 sample, 1 beam, 1 ping) and adds field in fData to
%   link it is a memmap file. It also creates the necessary parameter
%   fields in fData.
%   This function is to be used with the proper varargin parameters to
%   initialize the binary files (and link them to fData) with empty values,
%   prior to reading the acoustic data and filling the binary files


%% input parser
p = inputParser;

addParameter(p,'field','WC_SBP_SampleAmplitudes', @ischar);
addParameter(p,'wc_dir', CFF_converted_data_folder(fData.ALLfilename{1}), @ischar);
addParameter(p,'class', 'int8', @ischar);
addParameter(p,'factor', 1/2, @isnumeric);
addParameter(p,'nanval', intmin('int8'), @isnumeric);
addParameter(p,'offset', 0, @isnumeric);
addParameter(p,'MaxSamples', 1, @isnumeric);
addParameter(p,'MaxBeams', 1, @isnumeric);
addParameter(p,'ping_group_start', 1, @isnumeric);
addParameter(p,'ping_group_end', 1, @isnumeric);

parse(p,varargin{:});

wc_dir = p.Results.wc_dir;
field  = p.Results.field;
class  = p.Results.class;
factor = p.Results.factor;
nanval = p.Results.nanval;
offset = p.Results.offset;
maxNSamples_groups = p.Results.MaxSamples;
maxNBeams_sub      = p.Results.MaxBeams;
ping_group_start   = p.Results.ping_group_start;
ping_group_end     = p.Results.ping_group_end;


%% params

% add or overwrite info fields
p_field = strrep(field,'SBP','1');
fData.(sprintf('%s_Class',p_field))  = class;
fData.(sprintf('%s_Nanval',p_field)) = nanval;
fData.(sprintf('%s_Factor',p_field)) = factor;
fData.(sprintf('%s_Offset',p_field)) = offset;
switch field(1)
    case 'X'
        prefix = field(1);
    otherwise
        prefix = field(1:2);
end
fData.(sprintf('%s_n_start',prefix))       = ping_group_start;
fData.(sprintf('%s_n_end',prefix))         = ping_group_end;
fData.(sprintf('%s_n_maxNSamples',prefix)) = maxNSamples_groups;


%% prep

% number of memmap files requested
num_files = numel(ping_group_start);

% if data field already exists, delete it
if isfield(fData,field)
    for uig = 1:num_files
        fData.(field){uig} = [];
    end
    fData = rmfield(fData,field) ;
end

% number of bytes depending on class
switch class
    case {'int8' 'uint8'}
        nb = 1;
    case {'int16' 'uint16'}
        nb = 2;
    case {'int32' 'uint32'}
        nb = 4;
    case {'int64' 'uint64'}
        nb = 8;
    case {'single'}
        nb = 4;
    case {'double'}
        nb = 8;
end

% initialize filenames
file_binary = cell(1,num_files);

% initialize files' IDs
fileID = -ones(1,num_files);


%% create per file 

for uig = 1:num_files
    
    % file name
    file_binary{uig} = fullfile(wc_dir,sprintf('%s_%.0f_%.0f.dat',field,ping_group_start(uig),ping_group_end(uig)));
    
    % delete file if already exists.
    if isfile(file_binary{uig})
        delete(file_binary{uig});
    end
    
    % open file
    fileID(uig) = fopen(file_binary{uig},'w+');
    
    if fileID(uig)>-1
        
        % write file
        fwrite(fileID(uig),Nanval*ones/Factor,class,...
            nb*(maxNSamples_groups(uig)*maxNBeams_sub*(ping_group_end(uig)-ping_group_start(uig)+1)-1));
        
        % close file
        fclose(fileID(uig));
    end
    
    % memory map this binary file as a field in fData
    fData.(field){uig} = memmapfile(file_binary{uig},'Format',{class [maxNSamples_groups(uig) maxNBeams_sub ping_group_end(uig)-ping_group_start(uig)+1] 'val'},'repeat',1,'writable',true);

end

end