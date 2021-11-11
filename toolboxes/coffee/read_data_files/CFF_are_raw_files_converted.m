function [idxConverted,idxFDataUpToDate,idxHasWCD] = CFF_are_raw_files_converted(rawFilesList)
%CFF_ARE_RAW_FILES_CONVERTED  Check if raw files are already converted.
%
%   [A,B,C] = CFF_ARE_RAW_FILES_CONVERTED(F) tests if each input file in F
%   is converted to the fData format (A=1) or not (A=0). If the converted
%   file exists, the function also tests if its version matches the 
%   current fData version as defined in CFF_GET_CURRENT_FDATA_VERSION
%   (B=1) or not (B=0). If the converted file exists, the function also
%   tests if fData fields include AT LEAST ONE field in 'WC_' or 'AP_'
%   (C=1) or not. If the converted file does not exist, the function
%   returns B=NaN and C=NaN.
%
%   See also ESPRESSO, CFF_GET_CURRENT_FDATA_VERSION

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 11-11-2021

% exit if no input
if isempty(rawFilesList)
    idxConverted = [];
    idxFDataUpToDate = [];
    idxHasWCD = [];
    return
end

% list of names of converted files, if input were converted
fDataFolders = CFF_converted_data_folder(rawFilesList);
fDataFiles = fullfile(fDataFolders,'fData.mat');
if ischar(fDataFiles)
    fDataFiles = {fDataFiles};
end
nFiles = numel(fDataFiles);

% init output
idxConverted = false(nFiles, 1);
idxFDataUpToDate = nan(nFiles, 1);
idxHasWCD = nan(nFiles, 1);

% test each file
for ii = 1:nFiles
    
    % name of converted file
    fDataFile = fDataFiles{ii};
    
    % check if converted file exists
    idxConverted(ii,1) = isfile(fDataFile);
    
    if idxConverted(ii,1)
        % check version in the file and compare with current code version
        fileVersion = CFF_get_fData_version(fDataFile);
        if strcmpi(fileVersion,CFF_get_current_fData_version)
            idxFDataUpToDate(ii,1) = 1;
        end
        % check it has water-column data in it
        matObj = matfile(fDataFile);
        fields = fieldnames(matObj);
        idxHasWCD(ii,1) = any(startsWith(fields,{'WC_','AP_'}));
    end
    
end

