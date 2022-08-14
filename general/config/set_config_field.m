function out = set_config_field(fieldName,fieldVal)
%SET_CONFIG_FIELD  Set field in Espresso config file
%
%   See also ESPRESSO_CONFIG_FILE, INIT_CONFIG_FILE, GET_CONFIG_FIELD,
%   ESPRESSO.

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann Ladroit
%   (NIWA, yoann.ladroit@niwa.co.nz)
%   2022-2022; Last revision: 12-08-2022

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