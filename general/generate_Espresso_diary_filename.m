function Espresso_diary_file = generate_Espresso_diary_filename()
%GENERATE_ESPRESSO_DIARY_FILENAME  generate new Espresso diary filename
%
%   See also ESPRESSO_USER_FOLDER, ESPRESSO.

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann Ladroit
%   (NIWA, yoann.ladroit@niwa.co.nz) 
%   2017-2022; Last revision: 12-08-2022

diary_filename = sprintf('Espresso_log_%s.txt',datestr(now,'yyyymmdd_HHMMSS'));
Espresso_diary_file = fullfile(espresso_user_folder,'logs',diary_filename);