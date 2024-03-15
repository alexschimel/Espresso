function app_path_main = whereisroot()
%WHEREISROOT  Espresso root folder
%
%   Espresso root folder
%
%   See also ESPRESSO_USER_FOLDER, ESPRESSO.

%   Copyright 2017-2024 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

if isdeployed
    % Stand-alone mode
    [~, result] = system('path');
    app_path_main = char(regexpi(result, 'Path=(.*?);', 'tokens', 'once'));
else
    % MATLAB mode
    % get full path and filename for the main function
    app_path_main = fileparts(which('Espresso'));
end

end