%% CFF_is_valid_kmall_format_extension.m
%
% Tests if input file (string, or cell array of strings) has '.kmall',
% '.KMALL', '.kmwcd' or '.KMWCD' extension 
%
%%% Help
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, Alexandre Schimel NIWA. Type |help Espresso.m| for
% copyright information.

%% Function
function bool = CFF_is_valid_kmall_format_extension(file)

if ischar(file)
    file = {file};
end

% function checking if extension is Kongsberg's
isK = @(x) any(strcmp(CFF_file_extension(x),{'.kmall','.KMALL','.kmwcd','.KMWCD'}));

bool = cellfun(isK,file);
