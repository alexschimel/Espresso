function app_path_main = whereisroot()

if isdeployed % Stand-alone mode.    
    [~, result] = system('path');
    app_path_main = char(regexpi(result, 'Path=(.*?);', 'tokens', 'once'));
    
else % MATLAB mode.
    % get full path and filename for the main function
    app_path_main=fileparts(which('main'));    
end

end