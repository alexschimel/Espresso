%% CFF_get_current_fData_version.m
%
% Current fData version number
%
%% Help
%
% *USE*
%
% The format of fData sometimes requires updating to implement novel
% features. Changes in the structure of fData imply that older fData may
% not be compatible with later versions of the code. This function returns
% the current version of the fData format. Make sure to increment it
% whenever we change the fData format, so that later versions of the code
% can recognize if fData on the disk is readable or needs to be
% reconverted. 
%
% *NEW FEATURES*
%
% * YYYY-MM-DD: ver = '0.3'. Changes: ?
% * YYYY-MM-DD: ver = '0.2'. Changes: ?
% * YYYY-MM-DD: ver = '0.1'. Changes: ?
% * YYYY-MM-DD: ver = '0.0'. Changes: ?
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, Alexandre Schimel NIWA. Type |help Espresso.m| for
% copyright information.

%% Function
function ver = CFF_get_current_fData_version()

ver = '0.3';

end