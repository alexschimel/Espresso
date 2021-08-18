classdef CFF_Comms < handle
    %CFF_COMMS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Type (1,:) char {mustBeMember(Type,{'', 'disp','textprogressbar','waitbar'})} = ''
        FigObj = []
        InfoMsgs = {}
        StartMsg = []
        StepMsgs = {}
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
            
            % set start message and time
            obj.StartMsg = {str, datetime('now')};
            
            % display
            switch obj.Type
                case 'disp'
                    dispstr = [char(string(obj.StartMsg{2},'HH:mm:ss ')) obj.StartMsg{1} ': '];
                    disp(dispstr);
                case 'textprogressbar'
                    % init textprogressbar with a string
                    textprogressbar([obj.StartMsg{1} ': ']);
                case 'waitbar'
                    % init waitbar with title
                    obj.FigObj = waitbar(0,'');
                    obj.FigObj.Name = obj.StartMsg{1};
                    % init interpreter for future info messages
                    obj.FigObj.Children.Title.Interpreter = 'None';
                    % init message of two line
                    set(obj.FigObj.Children.Title,'String',newline);
                    drawnow
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
        
        function step(obj,str)
            %STEP Summary of this method goes here
            %   Detailed explanation goes here
            
            % record step message and time
            obj.StepMsgs(end+1,1:2) = {str, datetime('now')};
            
            switch obj.Type
                case 'disp'
                    dispstr = [char(string(obj.StepMsgs{end,2},'HH:mm:ss ')) obj.StepMsgs{end,1}];
                    disp(dispstr);
                case 'waitbar'
                    set(obj.FigObj.Children.Title,'String',sprintf('%s\n',str));
                    drawnow;
            end
        end
        
        function info(obj,str)
            %INFO Summary of this method goes here
            %   Detailed explanation goes here
            
            % record info message and time
            obj.InfoMsgs(end+1,1:2) = {str, datetime('now')};
            
            switch obj.Type
                case 'disp'
                    dispstr = [char(string(obj.InfoMsgs{end,2},'HH:mm:ss ')) obj.InfoMsgs{end,1}];
                    disp(dispstr);
                case 'waitbar'
                    if isempty(obj.StepMsgs)
                        stepStr = '';
                    else
                        stepStr = obj.StepMsgs{end,1};
                    end
                    set(obj.FigObj.Children.Title,'String',sprintf('%s\n%s',stepStr,str));
                    drawnow;
            end
        end
        
        function finish(obj,str)
            %FINISH Summary of this method goes here
            %   Detailed explanation goes here
            switch obj.Type
                case 'disp'
                    disp(str);
                case 'textprogressbar'
                    % complete textprogressbar
                    textprogressbar(100);
                    if isempty(obj.InfoMsgs)
                        textprogressbar([' ' str]);
                    else
                        % throw info messages if any
                        textprogressbar([' ' str '. Messages received during progress:']);
                        for ii=1:numel(obj.InfoMsgs)
                            fprintf('* %i: %s.\n',ii,obj.InfoMsgs{ii});
                        end
                    end
                    
                case 'waitbar'
                    waitbar(1,obj.FigObj,str);
                    pause(0.1);
                    close(obj.FigObj);
                    if ~isempty(obj.InfoMsgs)
                        wardlgTxt = sprintf('Messages received:\n');
                        for ii=1:numel(obj.InfoMsgs)
                            wardlgTxt = [wardlgTxt, sprintf('* %i: %s.\n',ii,obj.InfoMsgs{ii})];
                        end
                        warndlg(wardlgTxt,'Warning');
                    end
            end
        end
        
        
    end
end

