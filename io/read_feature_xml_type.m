function [types,descr]=read_feature_xml_type(xml_file)
xml_struct=parseXML(xml_file);
type_nodes=get_childs(xml_struct,'Type');

types=cell(1,numel(type_nodes));
descr=cell(1,numel(type_nodes));
for it=1:numel(type_nodes)
    tmp=get_node_att(type_nodes(it));
    types{it}=tmp.name;
    descr{it}=tmp.descr;
end
end