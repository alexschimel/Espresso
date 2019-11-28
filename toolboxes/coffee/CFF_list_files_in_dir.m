%% CFF_list_files_in_dir.m
%
% List the files available for the app in input folder. Files are available
% only if the pair .all/.wcd exists. Also returns whether these pairs have
% been converted to .mat format.
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
% * |folder_init|: Required. escription (Information). XXX
%
% *OUTPUT VARIABLES*
%
% _This section contains bullet points of output variables with description
% and information. See input variables for template. Example below to
% replace. Delete these lines XXX._
%
% * |folders|: Description (Information). XXX
% * |files|: Description (Information). XXX
% * |converted|: Description (Information). XXX
%
% *DEVELOPMENT NOTES*
%
% _This section describes what features are temporary, needed future
% developments and paper references. Example below to replace. Delete these
% lines XXX._
%
% * research point 1. XXX
% * research point 2. XXX
%
% *NEW FEATURES*
%
% * 2018-10-11: first version.
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
% Yoann Ladroit, Alexandre Schimel, NIWA.

%% Function
function [folders,files,converted] = CFF_list_files_in_dir(folder_init, varargin)

%% input parsing
p = inputParser;
addRequired(p,'folder_init',@ischar);
addOptional(p,'warning_flag','warning_off',@(x) ischar(x) && ismember(x,{'warning_on' 'warning_off'}));
parse(p,folder_init,varargin{:})
warning_flag = p.Results.warning_flag;
clear p


%% get file names
all_files = list_data(folder_init,'*.wcd');
wcd_files = list_data(folder_init,'*.all');

s7k_files = list_data(folder_init,'*.s7k');


%% manage all/wcd pais
% take pairs of files, or at default wcd files, or at default all files
files_pair = intersect(all_files,wcd_files);
all_only = setdiff(all_files,wcd_files);
wcd_only = setdiff(wcd_files,all_files);

files_full=union(files_pair,wcd_only);
files_full=union(files_full,all_only);


s7k_files=cellfun(@(x) [x '.s7k'],s7k_files,'un',0);
%% adding s7k
files_full = union(files_full,s7k_files);


%% output
if isempty(files_full)
    
    folders   = {};
    files     = {};
    converted = [];
    
else
    
    % files we keep
    [folders,files,~] = cellfun(@fileparts,files_full,'UniformOutput',0);
    
    % list of fData files (aka, converted files)
    wc_dir = CFF_converted_data_folder(files_full);
    mat_fdata_files = fullfile(wc_dir,'fdata.mat');
    
    % boolean for whether these mat files exist
    if ischar(mat_fdata_files)
        mat_fdata_files = {mat_fdata_files};
    end
    converted = cellfun(@(x) exist(x,'file')>0,mat_fdata_files);
    
end

end

%% subfunctions %%

function files = list_data(folder_init,ext)
Filename_list = dir(fullfile(folder_init,ext));
if ~isempty(Filename_list)
    Filename_cell = {Filename_list([Filename_list(:).isdir]==0).name};
    [~,files,~] = cellfun(@fileparts,Filename_cell,'UniformOutput',0);
    folders = {Filename_list([Filename_list(:).isdir]==0).folder};
    files = fullfile(folders,files);
else
    files = {};
end

end