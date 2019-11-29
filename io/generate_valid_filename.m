function fname=generate_valid_filename(str)

fname=regexprep(str,'\W','_');
fname=strrep(fname,'__','_');

end