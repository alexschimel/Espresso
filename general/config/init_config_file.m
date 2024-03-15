function init_config_file()
%INIT_CONFIG_FILE  Initialize Espresso config file
%
%   See also ESPRESSO_USER_FOLDER, ESPRESSO_CONFIG_FILE, SET_CONFIG_FIELD,
%   GET_CONFIG_FIELD, WHEREISROOT, ESPRESSO.

%   Copyright 2022-2022 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

% get config file
espressoConfigFile = espresso_config_file();

% create folders if needed
if ~isfolder(fileparts(espressoConfigFile))
    mkdir(fileparts(espressoConfigFile));
end

% initialize config file with default root folder (Espresso) as
% 'coffeeFolder'. When on MATLAB, this will prompt the user for a proper
% coffee folder the first time. When deployed, this field is unused anyway.
config = struct();
config.coffeeFolder = whereisroot();
configJSON = jsonencode(config);
fid = fopen(espressoConfigFile,'w');
fprintf(fid,'%c',configJSON);
fclose(fid);