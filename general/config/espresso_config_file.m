function espressoConfigFile = espresso_config_file()
%ESPRESSO_CONFIG_FILE  Get Espresso config file
%
%   See also ESPRESSO_USER_FOLDER, INIT_CONFIG_FILE, ESPRESSO.

%   Copyright 2022-2022 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

espressoUserFolder = espresso_user_folder();
espressoConfigFile = fullfile(espressoUserFolder,'config.json');