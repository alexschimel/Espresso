function compile_espresso(root_folder,nomFunc)
%COMPILE_ESPRESSO  Compile Espresso into an executable
%
%   See also ESPRESSO. 

%   Copyright 2017-2022 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

folders = folders_list(root_folder);

switch computer
    case 'PCWIN'
        str{1} = sprintf('mcc  -M ''-win32'' -v -m %s ', nomFunc);
    case 'PCWIN64'
        str{1} = sprintf('mcc -v -m %s ', fullfile(root_folder,nomFunc));
    case 'GLNX86'
        str{1} = sprintf('mcc -v -m %s ', fullfile(root_folder,nomFunc));
    case 'GLNXA64'
        str{1} = sprintf('mcc -v -m %s ', fullfile(root_folder,nomFunc));
    otherwise
        str{1} = sprintf('mcc -v -m %s ', fullfile(root_folder,nomFunc));
end

for i = 1:(length(folders))
    str{end+1} = sprintf('-a %s ',folders{i});
end

str{end+1} = '-o Espresso -r icons/espresso.ico -w enable';

str_mcc = [str{:}];
disp(str_mcc);
eval(str_mcc);

end

function folders = folders_list(path)

folders{1} = fullfile(path, 'general');
folders{2} = fullfile(path, 'toolboxes');
folders{3} = fullfile(path, 'processing');
folders{4} = fullfile(path, 'classes');
folders{5} = fullfile(path, 'display');
folders{6} = fullfile(path, 'io');

folders(cellfun(@isempty, folders)) = [];

end