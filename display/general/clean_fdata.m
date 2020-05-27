%% this_function_name.m
%
% _This section contains a very short description of the function, for the
% user to know this function is part of the software and what it does for
% it. Example below to replace. Delete these lines XXX._
%
% Template of ESP3 function header. XXX
%
%% Help
%
% *USE*
%
% _This section contains a more detailed description of what the function
% does and how to use it, for the interested user to have an overall
% understanding of its function. Example below to replace. Delete these
% lines XXX._
%
% This is a text file containing the basic comment template to add at the
% start of any new ESP3 function to serve as function help. XXX
%
% *INPUT VARIABLES*
%
% _This section contains bullet points of input variables with description
% and information. Put input variable and other valid entries or defaults
% between | symbols so it shows as monospace. Information section to
% contain, in order: requirement (i.e. Required/Optional/Paramter), valid
% type (e.g. Num, Positive num, char, 1xN cell array, etc.) and default
% value if there is one (e.g. Default: '10'). Example below to replace.
% Delete these lines XXX._
%
% * |input_variable_1|: Description (Information). XXX
% * |input_variable_2|: Description (Information). XXX
% * |input_variable_3|: Description (Information). XXX
%
% *OUTPUT VARIABLES*
%
% _This section contains bullet points of output variables with description
% and information. See input variables for template. Example below to
% replace. Delete these lines XXX._
%
% * |output_variable_1|: Description (Information). XXX
% * |output_variable_2|: Description (Information). XXX
%
% *DEVELOPMENT NOTES*
%
% * alex note. Not sure where else this one is used but its call in
% create_datafiles_tab.m may be unecessary. To check XXX
%
% *NEW FEATURES*
%
% _This section contains dates and descriptions of major updates. Example
% below to replace. Delete these lines XXX._
%
% * YYYY-MM-DD: second version. Describes the update. XXX
% * YYYY-MM-DD: first version. XXX
%
% *EXAMPLE*
%
% _This section contains examples of valid function calls. Note that
% example lines start with 3 white spaces so that the publish function
% shows them correctly as matlab code. Example below to replace. Delete
% these lines XXX._
%
%   example_use_1; % comment on what this does. XXX
%   example_use_2: % comment on what this line does. XXX
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% _This last section contains at least author name and affiliation. Delete
% these lines XXX._
%
% Yoann Ladroit, Alexandre Schimel, NIWA. XXX

%% Function
function fData = clean_fdata(fData)

if ~iscell(fData)
    fData = {fData};
end

j = 0;

dname = {};

for i = 1:numel(fData)
    
    fields = fieldnames(fData{i});
    
    for ifi = 1:numel(fields)
        
        rmb = 0;
        
        if isa(fData{i}.(fields{ifi}),'memmapfile')
            
            j = j+1;
            rmb = 1;
            dname{j} = fData{i}.(fields{ifi}).Filename;
            fData{i}.(fields{ifi}) = [];
            
        elseif iscell(fData{i}.(fields{ifi}))
            
            for ic = 1:numel(fData{i}.(fields{ifi}))
                if isa(fData{i}.(fields{ifi}){ic},'memmapfile')
                    rmb = 1;
                    j = j+1;
                    dname{j} = fData{i}.(fields{ifi}){ic}.Filename;
                    fData{i}.(fields{ifi}){ic} = [];
                end
            end
            
        end
        
        if rmb > 0
            fData{i} = rmfield(fData{i},fields{ifi});
        end
    end
    
end

dname = unique(dname);

fclose all;

for id = 1:numel(dname)
    
    [folder,~,~] = fileparts(dname{id});
    
    if isfile(fullfile(folder,'fdata.mat'))
        delete(fullfile(folder,'fdata.mat'));
    end
    
    if isfile(dname{id})
        try
            fprintf('\nDeleting file %s\n',dname{id});
            delete(dname{id});
        catch
            fprintf('ERROR while deleting file %s\n',dname{id});
        end
    end
    
end
