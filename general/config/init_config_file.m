function init_config_file()
%INIT_CONFIG_FILE  Initialize Espresso config file
%
%   See also ESPRESSO_USER_FOLDER, ESPRESSO_CONFIG_FILE, SET_CONFIG_FIELD,
%   GET_CONFIG_FIELD, WHEREISROOT, ESPRESSO.

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann Ladroit
%   (NIWA, yoann.ladroit@niwa.co.nz)
%   2022-2022; Last revision: 12-08-2022

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