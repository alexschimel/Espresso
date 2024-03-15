function out = get_config_field(fieldName)
%GET_CONFIG_FIELD  Get value of field in Espresso config file
%
%   See also ESPRESSO_CONFIG_FILE, INIT_CONFIG_FILE, SET_CONFIG_FIELD,
%   ESPRESSO.

%   Copyright 2022-2022 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

% init fail output
out = '';

% get config file
espressoConfigFile = espresso_config_file();
if isfile(espressoConfigFile)
    % read and decode config file
    config = jsondecode(fileread(espressoConfigFile));
    % read field
    if isfield(config,fieldName)
        out = config.(fieldName);
    end
end