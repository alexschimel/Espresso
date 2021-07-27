function fdata_ver = CFF_get_fData_version(fdata_input)
%CFF_GET_FDATA_VERSION  Get the fData version of a fData structure
%
%   This function can be used with either the filepath of a fData.mat file,
%   or the fData structure itself. In the first case, we get the content of
%   the field MET_Fmt_version in fData without loading fData itself into
%   memory. 
%   Note that oldest versions of fData dit not have a version stored in it,
%   so we return the appropriate version when the field is absent, which
%   was '0.0'. 
%   If the input is a file that does not exist, returns empty
%
%   Warning: do not confuse this function with
%   "CFF_get_current_fData_version.m", which gives the latest version of
%   fData used by the converting code
%
%   See also CFF_GET_CURRENT_FDATA_VERSION, ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 24-05-2021

if ischar(fdata_input)
    
    % input is filename
    mat_fdata_file = fdata_input;

    if isfile(mat_fdata_file)
        % file exists

        % check for existence of version field (older versions of fData didn't)
        matObj = matfile(mat_fdata_file);
        try 
            fdata_ver = matObj.MET_Fmt_version;
        catch
            fdata_ver = '0.0';
        end

    else
        % file doesn't exist
        fdata_ver = '';

    end

elseif isstruct(fdata_input)
    
    % input is fData
    fData = fdata_input;
    
    try
        fdata_ver = fData.MET_Fmt_version;
    catch
        fdata_ver = '0.0';
    end
    
end
    