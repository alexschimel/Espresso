%% Espresso_user_folder.m
%
% Function description XXX
%
%% Help
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, Alexandre Schimel, NIWA.
% Copyright

%% Function
function Espresso_user_folder = Espresso_user_folder

Espresso_user_folder = regexprep(userpath,'MATLAB','Espresso');