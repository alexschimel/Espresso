function [S7Kdata,datagrams_parsed_idx] = CFF_read_s7k(S7Kfilename, varargin)


%% Input arguments management using inputParser

p = inputParser;

% S7Kfilename to parse as required argument.
% Check file existence
argName = 'S7Kfilename';
argCheck = @(x) CFF_check_S7Kfilename(x);
addRequired(p,argName,argCheck);

% datagrams as optional argument.
% Check that cell array
argName = 'datagrams';
argDefault = {};
argCheck = @(x) isnumeric(x)||isempty(x); % that last part allows the use of the couple name,param
addOptional(p,argName,argDefault,argCheck);


% now parse inputs
parse(p,S7Kfilename,varargin{:});

% and get input variables from parser
S7Kfilename        = p.Results.S7Kfilename;
datagrams_to_parse = p.Results.datagrams;


if isempty(CFF_file_extension(S7Kfilename))
    S7Kfilename=[S7Kfilename,'.s7k'];
end

info = CFF_s7k_file_info(S7Kfilename);

if isempty(datagrams_to_parse)
    % parse all datagrams in firt file
    info.parsed(:) = 1;
    datagrams_parsed_idx = [];
else
    % datagrams to parse are listed
    
    % datagrams available
    datagrams_available = unique(info.recordTypeIdentifier);
    
    % find which datagrams can be read here
    datagrams_parsable_idx = ismember(datagrams_to_parse,datagrams_available);
    
    % if any, read those datagrams
    if any(datagrams_parsable_idx)
        idx = ismember(info.recordTypeIdentifier,datagrams_to_parse(datagrams_parsable_idx));
        info.parsed(idx) = 1;
        datagrams_parsed_idx = datagrams_parsable_idx;
    end
    
    
end

% read data
S7Kdata = CFF_read_s7k_from_fileinfo(S7Kfilename, info);




