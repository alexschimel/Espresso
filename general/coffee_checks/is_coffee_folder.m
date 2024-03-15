function isCoffeeFolder = is_coffee_folder(folder)
%IS_COFFEE_FOLDER  Is folder a CoFFee folder?
%
%   See also ESPRESSO_VERSION, GET_COFFEE_VERSION, IS_COFFEE_VERSION,
%   ESPRESSO. 

%   Copyright 2022-2022 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

% for now, we just test the existence of a folder and of the coffee version
% function
if isfolder(folder) && exist(fullfile(folder,'CFF_coffee_version.m'),'file')
    isCoffeeFolder = true;
else
    isCoffeeFolder = false;
end

