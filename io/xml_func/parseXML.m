function theStruct = parseXML(filename)
% PARSEXML Convert XML file to a MATLAB structure.
try   
    tree = xmlread(filename);
catch
        error('Failed to read XML file %s.',filename);
end

% Recurse over child nodes. This could run into problems
% with very deeply nested trees.
%try
    [theStruct,datatext] = parseChildNodes(tree);
    theStruct.Data=datatext;
% catch
%     error('Unable to parse XML file %s.',filename);
% end


% ----- Local function PARSECHILDNODES -----
function [children,data_text] = parseChildNodes(theNode)
% Recurse over node children.
children = [];
data_text='';
if theNode.hasChildNodes
    childNodes = theNode.getChildNodes;
    numChildNodes = childNodes.getLength;
    allocCell = cell(1, numChildNodes);
    
    children = struct(             ...
        'Name', allocCell, 'Attributes', allocCell,    ...
        'Data', allocCell, 'Children', allocCell);
     
    id_curr=0;
    for count = 1:numChildNodes
        id_curr=id_curr+1;
        theChild = childNodes.item(count-1);  
        children(id_curr) = makeStructFromNode(theChild);
        if strcmp(children(id_curr).Name,'#text')||isempty(children(id_curr).Name)
            data_text=char(children(id_curr).Data);
            children(id_curr)=[];
            id_curr=id_curr-1;
        end
    end
end




% ----- Local function MAKESTRUCTFROMNODE -----
function nodeStruct = makeStructFromNode(theNode)
% Create structure of node info.
[child,datatext]=parseChildNodes(theNode);
nodeStruct = struct(                        ...
    'Name', char(theNode.getNodeName),       ...
    'Attributes', parseAttributes(theNode),  ...
    'Data', '',                              ...
    'Children', child);

try
    nodeStruct.Data = char(theNode.getData());
catch
    nodeStruct.Data = datatext;
end

% ----- Local function PARSEATTRIBUTES -----
function attributes = parseAttributes(theNode)
% Create attributes structure.

attributes = [];
if theNode.hasAttributes
    theAttributes = theNode.getAttributes;
    numAttributes = theAttributes.getLength;
    allocCell = cell(1, numAttributes);
    attributes = struct('Name', allocCell, 'Value', ...
        allocCell);
    
    for count = 1:numAttributes
        attrib = theAttributes.item(count-1);
        attributes(count).Name = char(attrib.getName);
        tmp=str2double(attrib.getValue);
        if ~isnan(tmp)
            attributes(count).Value = tmp;
        else
            attributes(count).Value = char(attrib.getValue);
        end
    end
end