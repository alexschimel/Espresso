function [featureClassNames,featureClassDescriptions] = get_feature_class_list()
%GET_FEATURE_CLASS_LIST  Get list of feature classes from user folder JSON
%
%   See also ESPRESSO.

%   Copyright 2017-2024 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

% JSON file with classes from user folder
classFile = fullfile(espresso_user_folder(),'feature_classes.json');

% if file does not exist, create it with default values
if ~isfile(classFile)
    % define default class names (first col) and descriptions (second col)
    defaultFeatureClasses = {...
        'unidentified','Default class';...
        'Man-made - Cray pot/float','';...
        'Man-made - Shipwreck','';...
        'Man-made - Pipeline','';...
        'Hard pinnacles','';...
        'Biomass/fish','';...
        'Turbulence / air bubbles','';...
        'Kelp - short','less than 1m above seafloor';...
        'Kelp - tall','more than 1m above seafloor';...
        'Kelp - mixed sizes','';...
        'Seeps - Solitary (a)','';...
        'Seeps - Field of seeps (b)','6 to 8 seeps well-spaced and distinct';...
        'Seeps - Field of seeps (b, extreme)','as above, extreme example';...
        'Seeps - Seep Field (c)','multiple seeps, individually indistinct';...
        'Seeps - Seep Field (c, extreme)','as above, but with few primary seeps';...
        'Seeps - Dominant seep (Class 1)','strong signature, persistent through MORE than two-thirds of the water-column';...
        'Seeps - Minor seep (Class 2)','strong signature, persistent through LESS than two-thirds of the water-column';...
        'Seeps - Dominant diffuse seep (Class 3)','diffuse signature, persistent through MORE than two-thirds of the water-column';...
        'Seeps - Minor diffuse seep (Class 4)','diffuse signature, persistent through LESS than two-thirds of the water-column'};
    
    % save as struct
    defaultFeatureClassStruct = struct();
    for ii = 1:size(defaultFeatureClasses,1)
        defaultFeatureClassStruct(ii,1).Name        = defaultFeatureClasses{ii,1};
        defaultFeatureClassStruct(ii,1).Description = defaultFeatureClasses{ii,2};
    end
    
    % encode as JSON and save to file
    defaultFeatureClassJson = jsonencode(defaultFeatureClassStruct);
    defaultFeatureClassJson = prettyjson(defaultFeatureClassJson);
    fid = fopen(classFile,'w');
    fprintf(fid,'%c',defaultFeatureClassJson);
    fclose(fid);
end

% read values from JSON file
featureClassList = jsondecode(fileread(classFile));
featureClassNames = {featureClassList(:).Name};
featureClassDescriptions = {featureClassList(:).Description};

end