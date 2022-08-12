function isCoffeeFolder = is_coffee_folder(folder)
%IS_COFFEE_FOLDER  Is folder a CoFFee folder?
%
%   See also ESPRESSO_VERSION, GET_COFFEE_VERSION, IS_COFFEE_VERSION,
%   ESPRESSO. 

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann Ladroit
%   (NIWA, yoann.ladroit@niwa.co.nz) 
%   2022-2022; Last revision: 12-08-2022

% for now, we just test the existence of a folder and of the coffee version
% function
if isfolder(folder) && exist(fullfile(folder,'CFF_coffee_version.m'),'file')
    isCoffeeFolder = true;
else
    isCoffeeFolder = false;
end

