function ver = CFF_get_current_fData_version()
%CFF_GET_CURRENT_FDATA_VERSION  Current version of fData.
%
%   The format of fData sometimes requires updating to implement novel
%   features. Changes in the structure of fData imply that older fData may
%   not be compatible with later versions of the code. This function
%   returns the current version of the fData format. MAKE SURE TO MANUALLY
%   INCREMENT THE NUMBER IN THIS FUNCTION WHENEVER YOU CHANGE THE FDATA
%   FORMAT, SO THAT LATER VERSIONS OF THE CODE CAN RECOGNIZE IF FDATA ON
%   THE DISK IS READABLE OR NEEDS TO BE RECONVERTED. Add the date and a
%   quick summary of changes.
%
%   See also CFF_GET_FDATA_VERSION, ESPRESSO.

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2022; Last revision: 19-07-2022

ver = '0.3';

% * YYYY-MM-DD: ver = '0.3'. Changes: ?
% * YYYY-MM-DD: ver = '0.2'. Changes: ?
% * YYYY-MM-DD: ver = '0.1'. Changes: ?
% * YYYY-MM-DD: ver = '0.0'. Changes: ?

end