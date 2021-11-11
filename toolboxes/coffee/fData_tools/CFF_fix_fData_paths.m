function fDataGroup = CFF_fix_fData_paths(fDataGroup, rawFiles)
%CFF_FIX_FDATA_PATHS  Fix paths in converted data if files were moved
%
%   When you convert a file to a fData.mat, you save two paths: that of the
%   source file (field ALLfilename), and the paths to the binary files
%   containing water-column data. If you then move the data to another
%   folder (both the source data, and the converted data), the paths in
%   fData are no longer correct. This fixes it.
%
%   See also ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021


% if input fData struct, turn to cell
if isstruct(fDataGroup)
    fDataGroup = {fDataGroup};
end

% size of data
if numel(fDataGroup) ~= numel(rawFiles)
    error('Number of fData structures and input raw files do not match');
end
nFiles = numel(fDataGroup);

% repeat for each file
for iF = 1:nFiles
    
    % get data for this file
    fData = fDataGroup{iF};
    rawFile = rawFiles{iF};
    
    % path to converted data
    fDataFolder = CFF_converted_data_folder(rawFile);
    fDataFile = fullfile(fDataFolder,'fData.mat');
    
    % init flag to trigger fData resave
    dirchange_flag = 0;
    
    % grab source file names in fData
    fDataSourceFile = fData.ALLfilename;
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
        dirchange_flag = 1;
    end
    
    % WCD binary files fields
    fields = fieldnames(fData);
    fields = fields(startsWith(fields,{'WC_SBP' 'AP_SBP' 'X_SBP'}));
    
    % Check path of WCD binary file(s) and fix if necessary
    for ii = 1:numel(fields)
        field = fields{ii};
        for jj = 1:numel(fData.(field))
            if ~isempty(fData.(field){jj})
                [filepathSaved,name,ext] = fileparts(fData.(field){jj}.Filename); % path in fData
                if ~strcmp(filepathSaved,fDataFolder) % compare with expected folder
                    fData.(field){jj}.Filename = fullfile(fDataFolder,[name ext]); % rename
                    dirchange_flag = 1;
                end
            end
        end
    end
    
    % saving on disk if changes have been made
    if dirchange_flag
        try
            save(fDataFile,'-struct','fData','-v7.3');
        catch
            warning('Wrong paths in fData were found and modified, but it was not possible to save the corrected fData back on the disk.');
        end
    end
    
    % save results back in fDataGroup
    fDataGroup{iF} = fData;
    
end