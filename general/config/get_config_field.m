function out = get_config_field(fieldName)
%GET_CONFIG_FIELD  Get value of field in Espresso config file
%
%   See also ESPRESSO_CONFIG_FILE, INIT_CONFIG_FILE, SET_CONFIG_FIELD,
%   ESPRESSO.

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann Ladroit
%   (NIWA, yoann.ladroit@niwa.co.nz)
%   2022-2022; Last revision: 12-08-2022

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