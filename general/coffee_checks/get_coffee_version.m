function coffeeVer = get_coffee_version(folder)
%GET_COFFEE_VERSION  Get version of CoFFee in folder
%
%   See also ESPRESSO_VERSION, IS_COFFEE_FOLDER, IS_COFFEE_VERSION,
%   ESPRESSO. 

%   Copyright 2012-2022 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

% first, check that it is a coffee folder
if ~is_coffee_folder(folder)
    coffeeVer = NaN;
    return
end

% get version of that coffee
curdir = cd;
cd(folder);
coffeeVer = CFF_coffee_version();
cd(curdir);
