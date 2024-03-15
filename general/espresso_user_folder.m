function espressoUserFolder = espresso_user_folder()
%ESPRESSO_USER_FOLDER  Get Espresso user folder
%
%   See also ESPRESSO_CONFIG_FILE, ESPRESSO.

%   Copyright 2022-2022 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

espressoUserFolder = regexprep(userpath,'MATLAB','Espresso');