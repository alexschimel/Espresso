function coffeeVer = get_coffee_version(folder)
%GET_COFFEE_VERSION  Get version of CoFFee in folder
%
%   See also ESPRESSO_VERSION, IS_COFFEE_FOLDER, IS_COFFEE_VERSION,
%   ESPRESSO. 

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann Ladroit
%   (NIWA, yoann.ladroit@niwa.co.nz)
%   2022-2022; Last revision: 12-08-2022

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
