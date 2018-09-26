%% whereisroot.m
%
% Returns root path of program
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *OUTPUT VARIABLES*
%
% * |app_path_main|: root path of program
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-10-25: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help Espresso.m| for copyright information.

%% Function
function app_path_main = whereisroot()

if isdeployed
    % Stand-alone mode.
    
    [~, result] = system('path');
    app_path_main = char(regexpi(result, 'Path=(.*?);', 'tokens', 'once'));
    
else
    % MATLAB mode.
    
    % get full path and filename for the main function
    app_path_main = fileparts(which('Espresso'));
    
end

end