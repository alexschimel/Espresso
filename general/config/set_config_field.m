function out = set_config_field(fieldName,fieldVal)
%SET_CONFIG_FIELD  Set field in Espresso config file
%
%   See also ESPRESSO_CONFIG_FILE, INIT_CONFIG_FILE, GET_CONFIG_FIELD,
%   ESPRESSO.

%   Copyright 2022-2022 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

% init fail output
out = false;

% get config file
espressoConfigFile = espresso_config_file();
if isfile(espressoConfigFile)
    % read and decode config file
    config = jsondecode(fileread(espressoConfigFile));
    % set value
    config.(fieldName) = fieldVal;
    % re-encode and re-write config file
    configJSON = jsonencode(config);
    fid = fopen(espressoConfigFile,'w');
    fprintf(fid,'%c',configJSON);
    fclose(fid);
    % success
    out = true;
end