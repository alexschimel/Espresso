%% CFF_check_KMALLfilename.m
%
% Check that input file(s) exist(s) and are likely Kongsberg raw data files
% in the .kmall format. 
%
%% Help
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Alexandre Schimel (NGU, NIWA), Yoann Ladroit (NIWA). 
% Type |help CoFFee.m| for copyright information.

%% Function
function out = CFF_check_KMALLfilename(rawfilename)

if ischar(rawfilename)
    % single file. 
    % Check extension is valid, and that file exists.
    
    is_ext_valid = any(strcmpi(CFF_file_extension(rawfilename),{'.kmall','.kmwcd'}));
    out = isfile(rawfilename) && is_ext_valid;
    
elseif iscell(rawfilename) && numel(rawfilename)==2
    % pair of files.
    % Check that extension is a valid pair, that filenames match, and that
    % files exist.
    
    exts = CFF_file_extension(rawfilename);
    are_ext_valid_pair = all(strcmp(sort(lower(exts)),{'.kmall','.kmwcd'}));
    
    [~,filenames,~] = fileparts(rawfilename);
    do_filenames_match = strcmp(filenames{1}, filenames{2});
    
    do_both_files_exist = all(isfile(rawfilename));
    
    out = are_ext_valid_pair && do_filenames_match && do_both_files_exist;
    
else
    out = false;
end

