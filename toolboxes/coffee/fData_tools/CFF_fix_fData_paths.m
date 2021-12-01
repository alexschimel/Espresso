function idxPathsFixed = CFF_fix_fData_paths(rawFiles)
%CFF_FIX_FDATA_PATHS  Fix paths in converted data if files were moved
%
%   When you convert a raw data file to a fData.mat file, you save the path
%   of the source file (field ALLfilename), and the paths to the binary
%   files containing water-column data (if that data type was converted).
%   If you then move the data to another folder (both the source data, and
%   the converted data), the paths in fData are no longer correct. This
%   function fixes it. 
%
%   See also ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 01-12-2021

% number of files (or pairs of files)
nFiles = numel(rawFiles);

% init output
idxPathsFixed = nan(size(rawFiles));

% repeat for each file
for iF = 1:nFiles
    
    % get data for this file
    rawFile = rawFiles{iF};
    if ~CFF_are_raw_files_converted(rawFile)
        continue
    end
    fDataFolder = CFF_converted_data_folder(rawFile);
    fDataFile = fullfile(fDataFolder,'fData.mat');
    fDataObj = matfile(fDataFile,'Writable',true);
    
    % init flag indicating change
    idxPathsFixed(iF) = 0;
    
    % grab source file names in fData
    fDataSourceFile = fDataObj.ALLfilename;
    if ischar(fDataSourceFile)
        fDataSourceFile = {fDataSourceFile};
    end
    
    % let's only deal with cell arrays, wether single or paired files
    if ischar(rawFile)
        rawFile = {rawFile};
    end
    
    % check that input raw file(s) match fData source file(s)
    if ~isequal(sort(CFF_file_name(rawFile,1)),sort(CFF_file_name(fDataSourceFile,1)))
        error('Names of source file(s) do not match those saved in fData. Reconvert file.');
    end
    
    % check paths of source file(s) and fix if necessary
    if ~isequal(sort(rawFile),sort(fDataSourceFile))
        fData.ALLfilename = sort(rawFile);
        idxPathsFixed(iF) = 1;
    end
    
    % WCD binary files fields
    fields = properties(fDataObj);
    fields = fields(startsWith(fields,{'WC_SBP' 'AP_SBP' 'X_SBP'}));
    
    % Check path of WCD binary file(s) and fix if necessary
    for ii = 1:numel(fields)
        field = fields{ii};
        for jj = 1:numel(fData.(field))
            if ~isempty(fData.(field){jj})
                [filepathSaved,name,ext] = fileparts(fData.(field){jj}.Filename); % path in fData
                if ~strcmp(filepathSaved,fDataFolder) % compare with expected folder
                    fData.(field){jj}.Filename = fullfile(fDataFolder,[name ext]); % rename
                    idxPathsFixed(iF) = 1;
                end
            end
        end
    end
   
end