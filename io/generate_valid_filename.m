function fname = generate_valid_filename(str)
%GENERATE_VALID_FILENAME  One-line description
%
%   See also ESPRESSO.

%   Copyright 2017-2021 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

fname = regexprep(str,'\W','_');
fname = strrep(fname,'__','_');

end