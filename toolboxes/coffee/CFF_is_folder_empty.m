%% CFF_is_folder_empty.m
%
% Test if input folder(s) is empty. Return 1 if so.
%
%% Help
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% *NEW FEATURES*
%
% * 2021-05-21: first version. Alex
%
% Alexandre Schimel, NGU. Type |help Espresso.m| for
% copyright information.

%% Function
function bools = CFF_is_folder_empty(folders)

if ischar(folders)
    folders = {folders};
end

bools = false(size(folders));

for ii = 1:numel(folders)
    folder = folders{ii};
    dcont = dir(folder);
    if numel(dcont)==2 && strcmp(dcont(1).name,'.') && strcmp(dcont(2).name,'..')
        bools(ii) = 1;
    end
end


