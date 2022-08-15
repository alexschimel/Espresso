function espressoUserFolder = espresso_user_folder()
%ESPRESSO_USER_FOLDER  Get Espresso user folder
%
%   See also ESPRESSO_CONFIG_FILE, ESPRESSO.

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann Ladroit
%   (NIWA, yoann.ladroit@niwa.co.nz)
%   2022-2022; Last revision: 12-08-2022

espressoUserFolder = regexprep(userpath,'MATLAB','Espresso');