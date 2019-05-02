%% compile_espresso.m
%
% Compiles Espresso
%
%% Help
%
% *USE*
%
% Just specify path and name of the .m file of the main function (normally
% "Espresso.m") 
%
% *EXAMPLE*
%
%  compile_espresso(pwd,'Espresso.m'); % if in the right folder
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, Alexandre Schimel, NIWA.

%% Function
function compile_espresso(root_folder,nomFunc)

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

folders{1} = fullfile(path, 'toolboxes');
folders{2} = fullfile(path, 'processing');
folders{3} = fullfile(path, 'classes');
folders{4} = fullfile(path, 'display');
folders{5} = fullfile(path, 'io');

folders(cellfun(@isempty, folders)) = [];

end