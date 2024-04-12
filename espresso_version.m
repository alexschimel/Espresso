function [ver, coffeeVer, aknowledgments] = espresso_version()
%ESPRESSO_VERSION  Get version of Espresso
%
%   Get version of Espresso.
%
%   IMPORTANT NOTE FOR DEVELOPERS: Whenever you develop/modify Espresso
%   (and perhaps CoFFee) and intend to tag that new commit on git, please
%   update this function appropriately before. 
%
%   First, finalize the new version of CoFFee, give it a new version number
%   (in CFF_coffee_version) and commit/tag it.
%   Next, do the same with Espresso. Make sure the appropriate version of
%   CoFFee is also listed in this function. Add the date. Using standard
%   semantic versioning rules aka MAJOR.MINOR.PATCH. If pre-release, follow
%   with dash, alpha/beta/rc, dot and a single version number. See info on:
%   https://semver.org/
%   https://interrupt.memfault.com/blog/release-versioning
%
%   See also IS_COFFEE_FOLDER, GET_COFFEE_VERSION, IS_COFFEE_VERSION,
%   ESPRESSO.

%   Copyright 2022-2024 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

% RUN CFF_coffee_version() TO GET THE CURRENT VERSION, BUT WRITE IT
% HARD-CODED HERE


aknowledgments = 'Alexandre Schimel (The Geological Survey of Norway), Yoann Ladroit (Kongsberg Discovery), and Sally Watson (NIWA)';

ver = '1.0.0-alpha.4'; coffeeVer = '2.0.0-alpha.17'; % 12/04/2024
% ver = '1.0.0'; coffeeVer = '2.0.0-alpha.17'; % 11/04/2024
% ver = '1.0.0-alpha.3'; coffeeVer = '2.0.0-alpha.17'; % 10/04/2024
% ver = '1.0.0-alpha.2'; coffeeVer = '2.0.0-alpha.17'; % 28/03/2024
% ver = '1.0.0-alpha.1'; coffeeVer = '2.0.0-alpha.15'; % 15/03/2024
% ver = '0.22'; coffeeVer = '2.0.0-alpha.15'; % 07/03/2024
% ver = '0.21'; coffeeVer = '2.0.0-alpha.15'; % 05/03/2024
% ver = '0.20.4'; coffeeVer = '2.0.0-alpha.15'; % 01/03/2024
% ver = '0.20.3'; coffeeVer = '2.0.0-alpha.5'; % 08/09/2022
% ver = '0.20.2'; coffeeVer = '2.0.0-alpha.4'; % 02/09/2022
% ver = '0.20.1'; coffeeVer = '2.0.0-alpha.3'; % 15/08/2022
% ver = '0.20'; coffeeVer = '2.0.0-alpha.2'; % 12/08/2022

end