function update_loadedlines_tab(main_figure)
%UPDATE_LOADEDLINES_TAB  Updates Loaded Lines tab in Espresso Control panel
%
%   See also CREATE_FDATA_TAB, INITIALIZE_DISPLAY, ESPRESSO.

%   Copyright 2017-2021 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

fprintf('Updating list of loaded lines... ');

% get relevant stuff
fdata_tab_comp = getappdata(main_figure,'fdata_tab');
fData = getappdata(main_figure,'fData');

if isempty(fData)
    fdata_tab_comp.table.Data = {};
    fprintf('Done.\n');
    return;
end

% prepare table contents, without HTML tags yet
new_entry = cell(numel(fData),3);
for nF = 1:numel(fData)
    [folder,filename,~] = fileparts(fData{nF}.ALLfilename{1});
    new_entry{nF,1} = filename;
    new_entry{nF,2} = folder;
    new_entry{nF,3} = true; % selected or not
    new_entry{nF,4} = fData{nF}.ID; % line ID
end

% check which files have WC data
idxHasWCD = cellfun(@(x) any(startsWith(fieldnames(x),{'WC_','AP_'})), fData);

% add HTML tags
% raw files with WC
new_entry(idxHasWCD, 1) = cellfun(@(x) strcat('<html><FONT color="Black">',x,'</html>'),new_entry(idxHasWCD,1),'UniformOutput',0);
% files converted, but not loaded
new_entry(~idxHasWCD, 1) = cellfun(@(x) strcat('<html><FONT color="Red">',x,'</html>'),new_entry(~idxHasWCD,1),'UniformOutput',0);

% update table contents
fdata_tab_comp.table.Data = new_entry;
fdata_tab_comp.selected_idx = find([new_entry{:,end-1}]);

fprintf('Done.\n');

end