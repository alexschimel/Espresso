function espressoConfigFile = espresso_config_file()
%ESPRESSO_CONFIG_FILE  Get Espresso config file
%
%   See also ESPRESSO_USER_FOLDER, INIT_CONFIG_FILE, ESPRESSO.

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann Ladroit
%   (NIWA, yoann.ladroit@niwa.co.nz)
%   2022-2022; Last revision: 12-08-2022

espressoUserFolder = espresso_user_folder();
espressoConfigFile = fullfile(espressoUserFolder,'config.json');