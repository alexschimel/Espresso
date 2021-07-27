function fname = generate_valid_filename(str)
%GENERATE_VALID_FILENAME  One-line description
%
%   See also ESPRESSO.

%   Authors: Yoann Ladroit (NIWA, yoann.ladroit@niwa.co.nz) and Alex
%   Schimel (NIWA, alexandre.schimel@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

fname = regexprep(str,'\W','_');
fname = strrep(fname,'__','_');

end