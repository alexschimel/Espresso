function [class_cell,descr_cell] = init_feature_class()
%INIT_FEATURE_CLASS  One-line description
%
%   See also ESPRESSO.

%   Authors: Yoann Ladroit (NIWA, yoann.ladroit@niwa.co.nz) and Alex
%   Schimel (NIWA, alexandre.schimel@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

try
    
    % get the path to config
    app_path_main = whereisroot();
    config_path = fullfile(app_path_main,'config');
    
    % get list of classes from "classes.xml" file
    [class_cell,descr_cell] = read_feature_xml_class(fullfile(config_path,'classes.xml'));
    
catch err
    
    % display error message
    warning('Could not read classes.xml file in config folder. Using default classes instead.');
    disp(err.message);
    
    % use default values instead - define here
    class_cell = {' ' 'Plume' 'ShipWreck'};
    descr_cell = cell(1,numel(class_cell));
    
end


end