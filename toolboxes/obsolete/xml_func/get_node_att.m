function node_atts=get_node_att(node)
if isempty(node)
    node_atts=[];
    return;
end
nb_att=length(node.Attributes);
node_atts=[];
for j=1:nb_att
    node_atts.(node.Attributes(j).Name)=node.Attributes(j).Value;
end
end