function [classes,descr] = read_feature_xml_class(xml_file)
%READ_FEATURE_XML_CLASS  One-line description
%
%   See also ESPRESSO.

%   Authors: Yoann Ladroit (NIWA, yoann.ladroit@niwa.co.nz) and Alex
%   Schimel (NIWA, alexandre.schimel@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

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