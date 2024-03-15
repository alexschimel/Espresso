function [classes,descr] = read_feature_xml_class(xml_file)
%READ_FEATURE_XML_CLASS  One-line description
%
%   See also ESPRESSO.

%   Copyright 2017-2021 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

xml_struct = parseXML(xml_file);

class_nodes = get_childs(xml_struct,'Class');

classes = cell(1,numel(class_nodes));

descr = cell(1,numel(class_nodes));

for it = 1:numel(class_nodes)
    tmp = get_node_att(class_nodes(it));
    classes{it} = tmp.name;
    descr{it} = tmp.descr;
end

end