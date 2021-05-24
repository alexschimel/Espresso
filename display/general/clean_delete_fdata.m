%% clean_delete_fdata.m
%
% Function description XXX
%
%% Help
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, Alexandre Schimel NIWA. Type |help Espresso.m| for
% copyright information.

%% Function
function clean_delete_fdata(wc_dir)

% if wc_dir does not exist, exit here
if ~isdir(wc_dir)
    return
end

% if wc_dir exists but is empty, delete it and exit
flag_wc_dir_empty = CFF_is_folder_empty(wc_dir);
if flag_wc_dir_empty
    rmdir(wc_dir);
    return
end

% if wc_dir exists and has contents, check it has a fdata file in it to
% ensure we're not about to erase anything if the function has been called
% by mistake on an important folder
mat_fdata_file = fullfile(wc_dir,'fdata.mat');
if ~isfile(mat_fdata_file)
    return
end

% load fData
fData = load(mat_fdata_file);

% find all memmap files, then save the binary file location and delete the
% field.
j = 0;
dname = {};
fields = fieldnames(fData);
for ifi = 1:numel(fields)
    fieldname = fields{ifi};
    
    rmb = 0;
    if isa(fData.(fieldname),'memmapfile')
        % field is a memory-mapped file
        j = j+1;
        rmb = 1;
        dname{j} = fData.(fieldname).Filename;
        fData.(fieldname) = [];
        
    elseif iscell(fData.(fieldname))
        
        for ic = 1:numel(fData.(fieldname))
            if isa(fData.(fieldname){ic},'memmapfile')
                % field is a memory-mapped file
                j = j+1;
                rmb = 1;
                dname{j} = fData.(fieldname){ic}.Filename;
                fData.(fieldname){ic} = [];
            end
        end
        
    end
    
    if rmb > 0
        fData = rmfield(fData,fieldname);
    end
end

% next delete all binary data, and the fData file itself
dname = unique(dname);
fclose all;
for id = 1:numel(dname)
    
    [folder,~,~] = fileparts(dname{id});
    
    if isfile(fullfile(folder,'fdata.mat'))
        delete(fullfile(folder,'fdata.mat'));
    end
    
    if isfile(dname{id})
        try
            %fprintf('\nDeleting file %s\n',dname{id});
            delete(dname{id});
        catch
            fprintf('ERROR while deleting file %s\n',dname{id});
        end
    end
    
end

% finally, delete the folder
rmdir(wc_dir);