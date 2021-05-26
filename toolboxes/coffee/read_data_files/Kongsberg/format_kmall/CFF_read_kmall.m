%% function_name.m
%
% Function description XXX
%
%% Help
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, Alexandre Schimel NIWA. Type |help Espresso.m| for
% copyright information.

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


info.parsed(:) = 1;

% read data
KMALLdata = CFF_read_kmall_from_fileinfo(KMALLfilename{1}, info);




datagrams_parsed_idx = [];