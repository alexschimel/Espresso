%% CFF_are_raw_files_loaded.m
%
% List the files available for the app in input folder. Files are available
% only if the pair .all/.wcd exists. Also returns whether these pairs have
% been converted to .mat format.
%
%% Help
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, Alexandre Schimel NIWA. Type |help Espresso.m| for
% copyright information.

%% Function
function idx_loaded = CFF_are_raw_files_loaded(rawfileslist, loaded_files)

if isempty(rawfileslist)
    
    idx_loaded = [];
    
elseif isempty(loaded_files)
    
    idx_loaded = false(size(rawfileslist));
    
else
    
    % filenames of loaded files
    [~,loaded_filenames,~] = cellfun(@fileparts,loaded_files,'UniformOutput',0);
    
    % filenames of raw files
    rawfileslist = CFF_onerawfileonly(rawfileslist);
    [~,raw_filenames,~] = cellfun(@fileparts,rawfileslist,'UniformOutput',0);
    
    % compare
    idx_loaded = ismember(raw_filenames,loaded_filenames);
    
end