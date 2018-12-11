function childs=get_childs(node,name)
    childs=[];
    for iu=1:length(node.Children)
        if strcmpi(node.Children(iu).Name,name)
        childs=[childs node.Children(iu)];
        end
    end
end