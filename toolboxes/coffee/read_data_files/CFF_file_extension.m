%% CFF_file_extension.m
%
% Get extension of file(s)
%
%% Help
%
% *INPUT VARIABLES*
%
% * |filename|: Required. One strong filename, or cell array of string
% filenames.
%
% *OUTPUT VARIABLES*
%
% * |ext|: String filename extension, or cell array of string filenames
% extension
%
% *DEVELOPMENT NOTES*
%
% *NEW FEATURES*
%
% * 2021-05-21: extend to multiple files. Alex
% * 2018-10-11: added header. Alex
% * YYYY-MM-DD: first version. XXX
%
% *EXAMPLE*
%
%   ext = CFF_file_extension('f.mat'); % returns 'mat'
%   ext = CFF_file_extension({'f.mat', 'g.bin'}); % returns {'mat','bin'}
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Alex Schimel, Waikato University, Deakin University, NIWA, NGU.

%% Function
function ext = CFF_file_extension(filename)

if ischar(filename)
    [~,~,ext] = fileparts(filename);
    return
elseif iscell(filename)
    ext = cell(size(filename));
    for ii = 1:numel(filename)
        [~,~,ext{ii}] = fileparts(filename{ii});
    end
end


