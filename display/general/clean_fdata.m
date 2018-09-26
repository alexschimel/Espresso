%
% alex note. Not sure where else this one is used but its call in
% load_files_tab.m may be unecessary. To check XXX
%
function dname = clean_fdata(fData)

if ~iscell(fData)
    fData = {fData};
end

j = 0;

dname = {};

for i = 1:numel(fData)
    
    fields = fieldnames(fData{i});
    
    for ifi = 1:numel(fields)
        if isa(fData{i}.(fields{ifi}),'memmapfile')
            j = j+1;
            [dname{j},~,~] = fileparts(fData{i}.(fields{ifi}).Filename);
        end
    end
    
end

dname = unique(dname);
