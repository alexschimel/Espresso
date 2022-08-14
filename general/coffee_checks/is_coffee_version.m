function isVersionOK = is_coffee_version(folder,coffeeVerWanted)
%IS_COFFEE_VERSION  Is CoFFee version the expected version?
%
%   See also ESPRESSO_VERSION, IS_COFFEE_FOLDER, GET_COFFEE_VERSION,
%   ESPRESSO. 

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann Ladroit
%   (NIWA, yoann.ladroit@niwa.co.nz)
%   2022-2022; Last revision: 12-08-2022

% first, check that it is a coffee folder
if ~is_coffee_folder(folder)
    isVersionOK = NaN;
    return
end

% next, get version of that coffee
coffeeVerActual = get_coffee_version(folder);

% finally, comapre to expected version
if strcmp(coffeeVerActual,coffeeVerWanted)
    isVersionOK = true;
else
    isVersionOK = false;
end
