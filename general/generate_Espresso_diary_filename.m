function Espresso_diary_file = generate_Espresso_diary_filename()
%GENERATE_ESPRESSO_DIARY_FILENAME  generate new Espresso diary filename
%
%   See also ESPRESSO_USER_FOLDER, ESPRESSO.

%   Copyright 2017-2022 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

diary_filename = sprintf('Espresso_log_%s.txt',datestr(now,'yyyymmdd_HHMMSS'));
Espresso_diary_file = fullfile(espresso_user_folder,'logs',diary_filename);