function update_fdata_tab(main_figure)
%UPDATE_FDATA_TAB  Updates fdata tab in Espresso Control panel
%
%   See also CREATE_FDATA_TAB, INITIALIZE_DISPLAY, ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 21-07-2021

fdata_tab_comp = getappdata(main_figure,'fdata_tab');
fdata = getappdata(main_figure,'fData');

if isempty(fdata)
    fdata_tab_comp.table.Data = {};
    return;
end

data_new = cell(numel(fdata),3);

for nF = 1:numel(fdata)
    [fold,li,~] = fileparts(fdata{nF}.ALLfilename{1});
    data_new{nF,1} = li;
    data_new{nF,2} = fold;
    data_new{nF,3} = true;
    data_new{nF,4} = fdata{nF}.ID;
end

fdata_tab_comp.table.Data = data_new;
fdata_tab_comp.selected_idx = find([data_new{:,end-1}]);
end