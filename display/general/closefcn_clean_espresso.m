%% closefcn_clean_espresso.m
%
% Callback function when Espresso's main figure is closed
%
%% Help
%
% *NEW FEATURES*
%
% * 2017-10-25: first version (Yoann Ladroit)
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, Alexandre Schimel NIWA. Type |help Espresso.m| for
% copyright information.

%% Function
function closefcn_clean_espresso(main_figure,~)

fprintf('Closing Espresso...\n');
logfile = main_figure.UserData.logfile;
% fData = getappdata(main_figure,'fData');
ext_figs = getappdata(main_figure,'ext_figs');
delete(ext_figs);
delete(main_figure);
clear fData

fprintf('...Done. Find a log of this output at %s. \n',logfile);
diary off

if isdeployed()
    pause(1); % give reader time to read that last line
end

end