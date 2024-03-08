function espressoExportFolder = espresso_export_folder()
%ESPRESSO_EXPORT_FOLDER  Get Espresso default export folder
%
%   See also ESPRESSO_USER_FOLDER, ESPRESSO_CONFIG_FILE.

%   Authors: Alex Schimel 2024-2024

espressoUserFolder = espresso_user_folder();
espressoExportFolder = fullfile(espressoUserFolder,'export');