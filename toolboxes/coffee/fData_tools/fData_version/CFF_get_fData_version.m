function fDataVersionList = CFF_get_fData_version(fDataInputList)
%CFF_GET_FDATA_VERSION  Get the fData version of input fData
%
%   fDataVersion = CFF_GET_FDATA_VERSION(fDataFilepath) gets the (string)
%   version of the fData mat file whose (string) filepath is specified in
%   input.
%
%   fDataVersion = CFF_GET_FDATA_VERSION(fData) gets the (string) version
%   of the input fData structure.
%
%   fDataVersionList = CFF_GET_FDATA_VERSION(fDataInputList) returns a cell
%   array where each element is the (string) version of the corresponding
%   element in the input cell array. Each element of the input cell array
%   can be either a (string) filepath to a fData mat file, or a fData
%   structure.
%
%   Note that oldest versions of fData dit not have a version stored in it,
%   so if the input or an input element is a filepath to a mat file with no
%   version field, OR a struct with no version field, the function will
%   assume this is an old fData struct and returns the corresponding old
%   version, i.e. '0.0'. However, if the input or an input element is not
%   an existing mat file, nor a struct, then the function returns empty.
%
%   WARNING: do not confuse this function with
%   "CFF_get_current_fData_version.m", which returns the latest version of
%   fData used by the converting code
%
%   See also CFF_GET_CURRENT_FDATA_VERSION, ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 23-11-2021

% single input
if ~iscell(fDataInputList)
    fDataInputList = {fDataInputList};
end

% init output
sz = size(fDataInputList);
fDataVersionList = cell(sz);

% process by input
for iF = 1:numel(fDataInputList)
    
    % get that item
    fDataInput = fDataInputList{iF};
    
    if ischar(fDataInput)
        % input is filepath
        if strcmp(CFF_file_extension(fDataInput), '.mat') && isfile(fDataInput)
            % file exists
            matObj = matfile(fDataInput);
            if isprop(matObj,'MET_Fmt_version')
                fDataVersionList{iF} = matObj.MET_Fmt_version;
            else
                fDataVersionList{iF} = '0.0';
            end
        end
    elseif isstruct(fDataInput)
        % input is fData structure
        if isfield(fDataInput,'MET_Fmt_version')
            fDataVersionList{iF} = fDataInput.MET_Fmt_version;
        else
            fDataVersionList{iF} = '0.0';
        end
    end
    
end

% return in case of single input
if numel(fDataVersionList) == 1
    fDataVersionList = fDataVersionList{1};
end