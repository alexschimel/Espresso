function ver = CFF_get_current_fData_version()
%CFF_GET_CURRENT_FDATA_VERSION  Current version of fData.
%
%   The format of fData sometimes requires updating to implement novel
%   features. Changes in the structure of fData imply that older fData may
%   not be compatible with later versions of the code. This function
%   returns the current version of the fData format. Make sure to increment
%   it whenever we change the fData format, so that later versions of the
%   code can recognize if fData on the disk is readable or needs to be
%   reconverted. 
%
%   See also CFF_GET_FDATA_VERSION, ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

ver = '0.3';

% * YYYY-MM-DD: ver = '0.3'. Changes: ?
% * YYYY-MM-DD: ver = '0.2'. Changes: ?
% * YYYY-MM-DD: ver = '0.1'. Changes: ?
% * YYYY-MM-DD: ver = '0.0'. Changes: ?

end