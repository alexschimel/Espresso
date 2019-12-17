function fData=CFF_init_memmapfiles(fData,varargin)

def_class='int8';
def_fact=1/2;
def_nanval=intmin('int8');


def_wc_dir = CFF_converted_data_folder(fData.ALLfilename{1});

p = inputParser;


addParameter(p,'field','WC_SBP_SampleAmplitudes',@ischar);
addParameter(p,'wc_dir',def_wc_dir,@ischar);
addParameter(p,'class',def_class,@ischar);
addParameter(p,'Factor',def_fact,@isnumeric);
addParameter(p,'Nanval',def_nanval,@isnumeric);
addParameter(p,'MaxSamples',1,@isnumeric);
addParameter(p,'MaxBeams',1,@isnumeric);
addParameter(p,'ping_group_start',1,@isnumeric);
addParameter(p,'ping_group_end',1,@isnumeric);
parse(p,varargin{:});


wc_dir=p.Results.wc_dir;
field=p.Results.field;
class=p.Results.class;
Factor=p.Results.Factor;
Nanval=p.Results.Nanval;
maxNSamples_groups=p.Results.MaxSamples;
maxNBeams_sub=p.Results.MaxBeams;
ping_group_start=p.Results.ping_group_start;
ping_group_end=p.Results.ping_group_end;


file_binary=cell(1,numel(ping_group_start));
for uig=1:numel(ping_group_start)
    file_binary{uig} = fullfile(wc_dir,sprintf('%s_%.0f_%.0f.dat',field,ping_group_start(uig),ping_group_end(uig)));
end

p_field=strrep(field,'SBP','1');

fData.(sprintf('%s_Class',p_field)) = class;
fData.(sprintf('%s_Nanval',p_field)) = Nanval;
fData.(sprintf('%s_Factor',p_field)) = Factor;

switch field(1)
    case 'X'
        prefix=field(1);
    otherwise
        prefix=field(1:2);
end

fData.(sprintf('%s_n_start',prefix))=ping_group_start;
fData.(sprintf('%s_n_end',prefix))=ping_group_end;
fData.(sprintf('%s_n_maxNSamples',prefix))=maxNSamples_groups;

fileID=-ones(1,numel(ping_group_start));


switch class
    case {'int8' 'uint8'}
        nb=1;
    case {'int16' 'uint16'}
        nb=2;
    case {'int32' 'uint32'}
        nb=4;
    case {'int64' 'uint64'}
        nb=8;
    case {'single'}
        nb=4;
    case {'double'}
        nb=8;
end

if isfield(fData,field)
    for uig=1:numel(ping_group_start)
        fData.(field){uig}=[];
    end
    fData=rmfield(fData,field) ;
end

for uig=1:numel(ping_group_start)
    
    if isfile(file_binary{uig})
        delete(file_binary{uig});
    end
    
    fileID(uig) = fopen(file_binary{uig},'w+');
    
    if fileID(uig)>-1
        fwrite(fileID(uig),Nanval*ones/Factor,class,...
            nb*(maxNSamples_groups(uig)*maxNBeams_sub*(ping_group_end(uig)-ping_group_start(uig)+1)-1));
        fclose(fileID(uig));
    end
    % if we're not here, it means the file already exists and
    % already contain the data at the proper sampling. So we
    % just need to store the metadata and link to it as
    % memmapfile.
    
    fData.(field){uig} = memmapfile(file_binary{uig},'Format',{class [maxNSamples_groups(uig) maxNBeams_sub ping_group_end(uig)-ping_group_start(uig)+1] 'val'},'repeat',1,'writable',true);
end
end