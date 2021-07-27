function out = CFF_check_KMALLfilename(rawfilename)
%CFF_CHECK_KMALLFILENAME  Check file exists and has kmall extension
%
%   Check that input file(s) exist(s) and are likely Kongsberg raw data
%   files in the .kmall format.
%
%   See also ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

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

