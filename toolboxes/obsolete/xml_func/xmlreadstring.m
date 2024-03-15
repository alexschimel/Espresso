function [parseResult,p] = xmlreadstring(stringToParse,varargin)
%XMLREADSTRING Modified XMLREAD function to read XML data from a string.
% Author: Luis Cantero.
% The MathWorks.

p = locGetParser(varargin);
locSetEntityResolver(p,varargin);
locSetErrorHandler(p,varargin);

% Parse and return.
parseStringBuffer = java.io.StringBufferInputStream(stringToParse);
parseResult = p.parse(parseStringBuffer);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function p = locGetParser(args)

p = [];
for i=1:length(args)
    if isa(args{i},'javax.xml.parsers.DocumentBuilderFactory')
        javaMethod('setValidating',args{i},locIsValidating(args));
        p = javaMethod('newDocumentBuilder',args{i});
        break;
    elseif isa(args{i},'javax.xml.parsers.DocumentBuilder')
        p = args{i};
        break;
    end
end

if isempty(p)
    parserFactory = javaMethod('newInstance',...
        'javax.xml.parsers.DocumentBuilderFactory');
        
    javaMethod('setValidating',parserFactory,locIsValidating(args));
    %javaMethod('setIgnoringElementContentWhitespace',parserFactory,1);
    %ignorable whitespace requires a validating parser and a content model
    p = javaMethod('newDocumentBuilder',parserFactory);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tf=locIsValidating(args)

tf=any(strcmp(args,'-validating'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function locSetEntityResolver(p,args)

for i=1:length(args)
    if isa(args{i},'org.xml.sax.EntityResolver')
        p.setEntityResolver(args{i});
        break;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function locSetErrorHandler(p,args)

for i=1:length(args)
    if isa(args{i},'org.xml.sax.ErrorHandler')
        p.setErrorHandler(args{i});
        break;
    end
end