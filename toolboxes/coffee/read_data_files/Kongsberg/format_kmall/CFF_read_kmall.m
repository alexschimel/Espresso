%% CFF_read_kmall.m
%
% Reads contents of one Kongsberg EM series binary data file in .kmall
% format (.kmall or .kmwcd), or a pair of .kmall/.kmwcd files, allowing
% choice on which type of datagrams to parse.
%
%% Help
%
% *INPUT VARIABLES*
%
% XXX
% 
% *NEW FEATURES*
%
% * 2021-06-01: fixed bug when requesting to read a single datagram type.
% Updated docstring (alex)
% * 2021-05-??: first version (alex)
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Alexandre Schimel (NGU), Yoann Ladroit (NIWA). 
% Type |help Espresso.m| for copyright information.

%% Function
function [KMALLdata,datagrams_parsed_idx] = CFF_read_kmall(KMALLfilename, varargin)


%% Input parsing
p = inputParser;

% ALLfilename to parse as required argument.
% Check file existence
argName = 'KMALLfilename';
argCheck = @(x) CFF_check_KMALLfilename(x);
addRequired(p,argName,argCheck);

% datagrams as optional argument.
% Check that cell array
argName = 'datagrams';
argDefault = [];
argCheck = @(x) isnumeric(x)||iscell(x)||(ischar(x)&&~strcmp(x,'datagrams')); % that last part allows the use of the couple name,param
addOptional(p,argName,argDefault,argCheck);

% now parse inputs
parse(p,KMALLfilename,varargin{:});

% and get input variables from parser
KMALLfilename      = p.Results.KMALLfilename;
datagrams_to_parse = p.Results.datagrams;


%% PREP
if ischar(KMALLfilename)
    % single file .all OR .wcd. Convert filename to cell.
    KMALLfilename = {KMALLfilename};
else
    % matching file pair .all AND .wcd.
    % make sure .wcd is listed first because this function only reads in
    % the 2nd file what it could not find in the first, and we want to only
    % grab from the .all file what is needed and couldn't be found in the
    % .wcd file.
    if strcmpi(CFF_file_extension(KMALLfilename{1}),'.kmall')
        KMALLfilename = fliplr(KMALLfilename);
    end
end


%% FIRST FILE

% Get info from first (or only) file
info = CFF_kmall_file_info(KMALLfilename{1});

if isempty(datagrams_to_parse)
    % parse all datagrams in first file
    
    info.parsed(:) = 1;
    datagrams_parsed_in_first_file = unique(info.dgm_type_code);
    datagrams_parsed_idx = [];
    
else
    % datagrams to parse are listed in input
    
    if ischar(datagrams_to_parse)
        datagrams_to_parse = {datagrams_to_parse};
    end
    
    % datagrams available
    datagrams_available = unique(info.dgm_type_code);
    
    % find which datagrams can be read here
    datagrams_parsable_idx = ismember(datagrams_to_parse,datagrams_available);
    
    % if any, read those datagrams
    if any(datagrams_parsable_idx)
        idx = ismember(info.dgm_type_code,datagrams_to_parse(datagrams_parsable_idx));
        info.parsed(idx) = 1;
    end
    datagrams_parsed_idx = datagrams_parsable_idx;
    
end

% read data
KMALLdata = CFF_read_kmall_from_fileinfo(KMALLfilename{1}, info);



%% SECOND FILE (if any)
if numel(KMALLfilename)>1
    
    % parse only if we requested to read all datagrams (in which case, the
    % second file might have datagrams not read in the first and we need to
    % grab those) OR if we requested a specific set of datagrams and didn't
    % get them all from the first file.
    if isempty(datagrams_to_parse) || ~all(datagrams_parsed_idx)
        
        % Get info in second file
        info = CFF_kmall_file_info(KMALLfilename{2});
        
        if isempty(datagrams_to_parse)
            % parse all datagrams in second file which we didn't get in the
            % first one.
            
            % datagrams in second file
            datagrams_available_in_second_file = unique(info.dgm_type_code);
            
            % those in second file that were not in first
            datagrams_to_parse_in_second_file = setdiff(datagrams_available_in_second_file,datagrams_parsed_in_first_file);
            
            % parse those
            idx = ismember(info.dgm_type_code,datagrams_to_parse_in_second_file);
            info.parsed(idx) = 1;
            
            % for output
            datagrams_parsed_idx = [];
            
        else
            % datagrams to parse are listed
            
            datagrams_available_in_second_file = unique(info.dgm_type_code);
            
            % find which remaining datagram types can be read here
            datagrams_to_parse_in_second_file_idx = ismember(datagrams_to_parse,datagrams_available_in_second_file) & ~datagrams_parsed_idx;
            
            % if any, read those datagrams
            if any(datagrams_to_parse_in_second_file_idx)
                idx = ismember(info.dgm_type_code,datagrams_to_parse(datagrams_to_parse_in_second_file_idx));
                info.parsed(idx) = 1;
            end
            datagrams_parsed_idx = datagrams_parsed_idx | datagrams_to_parse_in_second_file_idx;
            
        end
        
        % read data in second file
        KMALLdata2 = CFF_read_kmall_from_fileinfo(KMALLfilename{2}, info);
        
        % combine to data from first file
        KMALLdata = {KMALLdata KMALLdata2};
        
    end

end