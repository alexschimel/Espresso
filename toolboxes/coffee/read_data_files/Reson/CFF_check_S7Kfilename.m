function out = CFF_check_S7Kfilename(file)
%CFF_CHECK_S7KFILENAME  Check file exists and has s7k extension
%
%   See also ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

% test if filename has an extension
if ~isempty(CFF_file_extension(file))
    % Filename does have an extension
    
    % check the extension is that of a Reson file and that it exists.
    out = CFF_is_Reson_file(file) && exist(file,'file');
    
else
    % if filename doesn't have an extension, aka file root
    
    % build the full filenames
    file = CFF_get_Reson_files(file);
    
    % check that it exists
    out = exist(file{1},'file');
    
end