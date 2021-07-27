function name = CFF_file_name(filename, varargin)
%CFF_FILE_NAME  Get name of file(s)
%
%   Optional argument allows returning the extension as well. See syntax
%   examples.
%
%   name = CFF_FILE_NAME(filename) returns the STRING name of the input
%   STRING filename, with no folder, and no extension. 
%   CFF_FILE_NAME('C:\my_file.bin') returns 'my_file'
%
%   name = CFF_FILE_NAME(filename, 1) returns the STRING name, with
%   extension, of the input STRING filename, with no folder.
%   CFF_FILE_NAME('C:\my_file.bin',1) returns 'my_file.bin'
%
%   names = CFF_FILE_NAME(filenames) returns the cell arrray of STRING
%   names of the input cell array of STRING filenames, with no folder.
%   CFF_file_extension({'C:\my_file.bin','C:\my_other_file.jpg'}) returns
%   {'my_file','my_other_file'}
%   CFF_file_extension({'C:\my_file.bin','C:\my_other_file.jpg'},1) returns
%   {'my_file.bin','my_other_file.jpg'}

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2021-2021; Last revision: 27-07-2021o,k.p.


% input parser
p = inputParser;
addRequired(p,'filename',@(x) ischar(x) || iscell(x));
addOptional(p,'with_extension',0,@(x) isnumeric(x) && numel(x)==1 && (x==0|x==1) );
parse(p,filename,varargin{:});
filename = p.Results.filename;
with_extension = p.Results.with_extension;
clear p

if ischar(filename)
    % single file
    [~,name,ext] = fileparts(filename);
    % add extension if requested
    if with_extension
        name = [name, ext];
    end
elseif iscell(filename)
    % cell array of files
    name = cell(size(filename));
    for ii = 1:numel(filename)
        [~,name{ii},ext] = fileparts(filename{ii});
        % add extension if requested
        if with_extension
            name{ii} = [name{ii}, ext];
        end
    end
end


