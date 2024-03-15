function espressoExportFolder = espresso_export_folder()
%ESPRESSO_EXPORT_FOLDER  Get Espresso default export folder
%
%   See also ESPRESSO_USER_FOLDER, ESPRESSO_CONFIG_FILE.

%   Copyright 2024-2024 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

espressoUserFolder = espresso_user_folder();
espressoExportFolder = fullfile(espressoUserFolder,'export');