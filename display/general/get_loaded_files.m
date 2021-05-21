%% get_loaded_files.m
%
% Get list of files currently loaded in Espresso
%
%% Help
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, Alexandre Schimel NIWA. Type |help Espresso.m| for
% copyright information.

%% Function
function loaded_files = get_loaded_files(fData)

% initialize output
loaded_files = cell(1,numel(fData));

% fill output with name of files loaded
for nF = 1:numel(fData)
    [p_temp,f_temp,~] = fileparts(fData{nF}.ALLfilename{1});
    loaded_files{nF} = fullfile(p_temp,f_temp);
end

end