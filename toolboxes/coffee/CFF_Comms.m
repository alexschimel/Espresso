classdef CFF_Comms < handle
    %CFF_COMMS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Type (1,:) char {mustBeMember(Type,{'', 'disp','textprogressbar','waitbar'})} = ''
        FigObj = []
        Msgs = {}
    end
    
    methods
        function obj = CFF_Comms(inputArg)
            %CFF_COMMS Construct an instance of this class
            %   Detailed explanation goes here
            if nargin == 0
                obj.Type = '';
            else
                obj.Type = inputArg;
            end
        end
        
        function start(obj,str)
            %START Summary of this method goes here
            %   Detailed explanation goes here
            
            % record start message
            obj.Msgs(end+1,:) = {datetime('now'), 'Start', str};
            
            % display
            switch obj.Type
                case 'disp'
                    dispstr = [char(string(obj.Msgs{end,1},'HH:mm:ss')) ' - ' obj.Msgs{end,2} ' - ' obj.Msgs{end,3}];
                    disp(dispstr);
                case 'textprogressbar'
                    % init textprogressbar with a string
                    textprogressbar([obj.Msgs{end,3} ': ']);
                case 'waitbar'
                    % init waitbar with title
                    obj.FigObj = waitbar(0,'');
                    obj.FigObj.Name = obj.Msgs{end,3};
                    % init interpreter for future info messages
                    obj.FigObj.Children.Title.Interpreter = 'None';
                    % init message of two line
                    set(obj.FigObj.Children.Title,'String',newline);
                    drawnow
            end
        end
        
        function step(obj,str)
            %STEP Summary of this method goes here
            %   Detailed explanation goes here
            
            % record step message
            obj.Msgs(end+1,:) = {datetime('now'), 'Step', str};
            
            switch obj.Type
                case 'disp'
                    dispstr = [char(string(obj.Msgs{end,1},'HH:mm:ss')) ' - ' obj.Msgs{end,2} ' - ' obj.Msgs{end,3}];
                    disp(dispstr);
                case 'waitbar'
                    set(obj.FigObj.Children.Title,'String',sprintf('%s\n',obj.Msgs{end,3}));
                    drawnow;
            end
        end
        
        function info(obj,str)
            %INFO Summary of this method goes here
            %   Detailed explanation goes here
            
            % record info message
            obj.Msgs(end+1,:) = {datetime('now'), 'Info', str};
            
            switch obj.Type
                case 'disp'
                    dispstr = [char(string(obj.Msgs{end,1},'HH:mm:ss')) ' - ' obj.Msgs{end,2} ' - ' obj.Msgs{end,3}];
                    disp(dispstr);
                case 'waitbar'
                    % get last step message
                    idx = find(strcmp(obj.Msgs(:,2),'Step'),1,'last');
                    if isempty(idx)
                        stepStr = '';
                    else
                        stepStr = obj.Msgs{idx,3};
                    end
                    % set waitbar title
                    set(obj.FigObj.Children.Title,'String',sprintf('%s\n%s',stepStr,obj.Msgs{end,3}));
                    drawnow;
            end
        end
        
        function error(obj,str)
            %ERROR Summary of this method goes here
            %   Detailed explanation goes here
            
            % record info message
            obj.Msgs(end+1,:) = {datetime('now'), 'Error', str};
            
            switch obj.Type
                case 'disp'
                    dispstr = [char(string(obj.Msgs{end,1},'HH:mm:ss')) ' - ' obj.Msgs{end,2} ' - ' obj.Msgs{end,3}];
                    disp(dispstr);
                case 'waitbar'
                    % get last step message
                    idx = find(strcmp(obj.Msgs(:,2),'Step'),1,'last');
                    if isempty(idx)
                        stepStr = '';
                    else
                        stepStr = obj.Msgs{idx,3};
                    end
                    % set waitbar title
                    set(obj.FigObj.Children.Title,'String',sprintf('%s\n%s',stepStr,obj.Msgs{end,3}));
                    drawnow;
            end
        end
        
        
        function finish(obj,str)
            %FINISH Summary of this method goes here
            %   Detailed explanation goes here
            
            % record finish message
            obj.Msgs(end+1,:) = {datetime('now'), 'Finish', str};
            
            switch obj.Type
                case 'disp'
                    dispstr = [char(string(obj.Msgs{end,1},'HH:mm:ss')) ' - ' obj.Msgs{end,2} ' - ' obj.Msgs{end,3}];
                    disp(dispstr);
                case 'textprogressbar'
                    % complete textprogressbar
                    textprogressbar(100);
                    if any(strcmp(obj.Msgs(:,2),'Error'))
                        % show if error messages received
                        textprogressbar([' ' obj.Msgs{end,3} '. Error messages were received:']);
                        for ii = 1:size(obj.Msgs,1)
                            dispstr = [char(string(obj.Msgs{ii,1},'HH:mm:ss')) ' - ' obj.Msgs{ii,2} ' - ' obj.Msgs{ii,3}];
                            fprintf([dispstr, newline]);
                        end
                    else
                        % normal completion
                        textprogressbar([' ' obj.Msgs{end,3}]);
                    end
                case 'waitbar'
                    % complete waitbar
                    waitbar(1,obj.FigObj,obj.Msgs{end,3});
                    pause(0.1);
                    close(obj.FigObj);
                    % show if error messages received
                    if any(strcmp(obj.Msgs(:,2),'Error'))
                        wardlgTxt = sprintf('Error messages were received:\n');
                        for ii = 1:size(obj.Msgs,1)
                            dispstr = [char(string(obj.Msgs{ii,1},'HH:mm:ss')) ' - ' obj.Msgs{ii,2} ' - ' obj.Msgs{ii,3}];
                            wardlgTxt = [wardlgTxt, newline, dispstr];
                        end
                        warndlg(wardlgTxt,'Warning');
                    end
            end
        end
          
        function progress(obj,ii,N)
            %PROGRESS Summary of this method goes here
            %   Detailed explanation goes here
            switch obj.Type
                case 'disp'
                    fprintf('#%.10g/%.10g\n',ii,N);
                case 'textprogressbar'
                    textprogressbar(100.*ii./N);
                case 'waitbar'
                    waitbar(ii./N,obj.FigObj);
            end
        end

    end
end

