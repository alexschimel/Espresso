function bool = CFF_is_Reson_file(file)

if ischar(file)
    file = {file};
end

% function checking if extension is Reson's
isK = @(x) any(strcmp(CFF_file_extension(x),{'.s7k','.S7K'}));

bool = cellfun(isK,file);