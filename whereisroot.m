function app_path_main = whereisroot()
%WHEREISROOT  Espresso root folder
%
%   Espresso root folder
%
%   See also ESPRESSO_USER_FOLDER, ESPRESSO.

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann Ladroit
%   (NIWA, yoann.ladroit@niwa.co.nz) 
%   2017-2022; Last revision: 12-08-2022

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