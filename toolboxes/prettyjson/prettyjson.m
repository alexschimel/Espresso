function [less_ugly] = prettyjson(ugly)
% Makes JSON strings (relatively) pretty
% Probably inefficient

% Mostly meant for structures with simple strings and arrays;  
% gets confused and !!mangles!! JSON when strings contain [ ] { or }. 

    MAX_ARRAY_WIDTH = 80;
    TAB = '    ';
    
    ugly = strrep(ugly, '{', sprintf('{\n')); 
    ugly = strrep(ugly, '}', sprintf('\n}')); 
    ugly = strrep(ugly, ',"', sprintf(', \n"'));
    ugly = strrep(ugly, ',{', sprintf(', \n{'));

    indent = 0;
    lines = splitlines(ugly);

    for i = 1:length(lines)
        line = lines{i};
        next_indent = 0;

        % Count brackets
        open_brackets = length(strfind(line, '['));
        close_brackets = length(strfind(line, ']'));

        open_braces = length(strfind(line, '{'));
        close_braces = length(strfind(line, '}'));

        if close_brackets > open_brackets || close_braces > open_braces
            indent = indent - 1;
        end

        if open_brackets > close_brackets
            line = strrep(line, '[', sprintf('[\n'));
            next_indent = 1;
        elseif open_brackets < close_brackets
            line = strrep(line, ']', sprintf('\n]'));
            next_indent = -1;
        elseif open_brackets == close_brackets && length(line) > MAX_ARRAY_WIDTH
            first_close_bracket = strfind(line, ']');
            if first_close_bracket > MAX_ARRAY_WIDTH % Just a long array -> each element on a new line
                line = strrep(line, '[', sprintf('[\n%s', TAB)); 
                line = strrep(line, ']', sprintf('\n]')); 
                line = strrep(line, ',', sprintf(', \n%s', TAB)); % Add indents!
            else % Nested array, probably 2d, first level is not too wide -> each sub-array on a new line
                line = strrep(line, '[[', sprintf('[\n%s[', TAB)); 
                line = strrep(line, '],', sprintf('], \n%s', TAB)); % Add indents!
                line = strrep(line, ']]', sprintf(']\n]'));
            end
        end

        sublines = splitlines(line);
        for j = 1:length(sublines)
            if j > 1   % todo: dumb to do this check at every line...
                sublines{j} = sprintf('%s%s', repmat(TAB, 1, indent+next_indent), sublines{j});
            else
                sublines{j} = sprintf('%s%s', repmat(TAB, 1, indent), sublines{j});     
            end
        end

        if open_brackets > close_brackets || open_braces > close_braces 
            indent = indent + 1;
        end
        indent = indent + next_indent;
        lines{i} = strjoin(sublines, newline); 

    end

    less_ugly = strjoin(lines, newline);
end