function out = CFF_check_S7Kfilename(file)

if ~isempty(CFF_file_extension(file))

    out = CFF_is_Reson_file(file) && exist(file,'file');
    
else

    file = CFF_get_Reson_files(file);
    
    out = exist(file{1},'file');
    
end