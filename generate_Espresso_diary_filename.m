function Espresso_diary_file = generate_Espresso_diary_filename()
%FUNCTION_NAME  One-line description
%
%   Optional multiple lines of information giving more details about the
%   function.
%
%   See also ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 21-07-2021

diary_filename = sprintf('Espresso_log_%s.txt',datestr(now,'yyyymmdd_HHMMSS'));
Espresso_diary_file = fullfile(Espresso_user_folder,diary_filename);