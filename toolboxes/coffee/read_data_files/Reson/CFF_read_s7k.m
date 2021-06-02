function [S7Kdata,datagrams_parsed_idx] = CFF_read_s7k(S7Kfilename, varargin)

%% input parsing

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
argCheck = @(x) isnumeric(x)||isempty(x);
addOptional(p,argName,argDefault,argCheck);

% now parse inputs
parse(p,S7Kfilename,varargin{:});

% and get input variables from parser
S7Kfilename        = p.Results.S7Kfilename;
datagrams_to_parse = p.Results.datagrams;

if isempty(CFF_file_extension(S7Kfilename))
    S7Kfilename = [S7Kfilename,'.s7k'];
end

% get info from file
info = CFF_s7k_file_info(S7Kfilename);

if isempty(datagrams_to_parse)
    % parse all datagrams in file
    idx_to_parse = true(size(info.recordTypeIdentifier));
    datagrams_parsed_idx = [];

else
    % datagrams to parse are listed in input
    
    % datagrams available
    datagrams_available = unique(info.recordTypeIdentifier);
    
    % find which datagrams can be read here
    datagrams_parsable_idx = ismember(datagrams_to_parse,datagrams_available);
    
    % some warnings
    if ~any(datagrams_parsable_idx)
        warning('None of the needed datagrams are in this file.');
    else
        if ~all(datagrams_parsable_idx)
            warning('Some needed datagrams could not been found in this file.');
        end
    end
    
    % list datagrams to be parsed
    idx_to_parse = ismember(info.recordTypeIdentifier,datagrams_to_parse(datagrams_parsable_idx));
    datagrams_parsed_idx = datagrams_parsable_idx;
    
end

% find and remove possibly corrupted datagrams
idx_corrupted = info.syncCounter~=0;
idx_corrupted = [idx_corrupted(2:end);false]; % the possibly corrupted datagram is the one before the one with syncCounter~=0;

if any(idx_corrupted & idx_to_parse)
    warning('%i of the %i datagrams to be parsed in this file may be corrupted and will not be parsed.',sum(idx_corrupted & idx_to_parse), sum(idx_to_parse) );
end

% parsable datagrams to be parsed
info.parsed(idx_to_parse & ~idx_corrupted) = 1;
    
% read data
S7Kdata = CFF_read_s7k_from_fileinfo(S7Kfilename, info);




