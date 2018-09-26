function update_fdata_tab(main_figure)

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

end