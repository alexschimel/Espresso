%% CFF_onerawfileonly.m
%
% Simplify a raw files list to a single file per pair, for filenames
% manipulation purposes.
%
%% Help
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, Alexandre Schimel NIWA. Type |help Espresso.m| for
% copyright information.

%% Function
function rawfileslist_out = CFF_onerawfileonly(rawfileslist_in)

if ischar(rawfileslist_in)
    % single file
    rawfileslist_out = rawfileslist_in;
else
    % cell array of files
    
    % number of files, counting pairs as one
    n_files = size(rawfileslist_in,1);

    % initialize output
    rawfileslist_out = cell(n_files,1);

    % fill in output
    for ii = 1:n_files
        if iscell(rawfileslist_in{ii})
            % for pairs, select the second file
            rawfileslist_out{ii} = rawfileslist_in{ii}{2};
        else
            % for single files, simply copy
            rawfileslist_out{ii} = rawfileslist_in{ii};
        end
    end
    
end