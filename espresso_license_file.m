function licenseFilename = espresso_license_file()
%ESPRESSO_LIENSE_FILE  get Espresso license file name
%
%   See also ESPRESSO.

%   Copyright 2024 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

licenseFilename = fullfile(whereisroot,'LICENSE');