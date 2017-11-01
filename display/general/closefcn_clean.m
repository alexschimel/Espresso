%% closefcn_clean.m
%
% Close main figure
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |input_variable_1|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% * |output_variable_1|: TODO: write description and info on variable
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-10-25: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help Espresso.m| for copyright information.

%% Function
function closefcn_clean(main_figure,~)
fData=getappdata(main_figure,'fData');
ext_figs=getappdata(main_figure,'ext_figs');
delete(ext_figs);

dname=clean_fdata(fData);
delete(main_figure);
clear fData

for k=1:numel(dname)
    try
        rmdir(dname{k},'s');
        fprintf('Removed %s\n',dname{k}); 
    catch
       fprintf('Failed to remove %s\n',dname{k}); 
    end
end

end