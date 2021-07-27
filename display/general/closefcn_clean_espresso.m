function closefcn_clean_espresso(main_figure,~)
%CLOSEFCN_CLEAN_ESPRESSO  Terminate Espresso session
%
%   See also ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 21-07-2021

% disp
fprintf('Closing Espresso...\n');

% delete figures
ext_figs = getappdata(main_figure,'ext_figs');
delete(ext_figs);
logfile = main_figure.UserData.logfile;
delete(main_figure);

% final disp
fprintf('Done. Find a log of this output at %s.\n\n',logfile);

% stop diary
diary off

% give reader a second to read that last line
if isdeployed()
    pause(1);
end

end