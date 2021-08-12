classdef CFF_Comms < handle
    %CFF_COMMS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Type (1,:) char {mustBeMember(Type,{'', 'disp','textprogressbar','waitbar'})} = ''
        FigObj = []
        InfoMsgs = {}
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
        
        function startMsg(obj,str)
            %STARTMSG Summary of this method goes here
            %   Detailed explanation goes here
            switch obj.Type
                case 'disp'
                    disp(str);
                case 'textprogressbar'
                    % init textprogressbar with a string
                    textprogressbar([str ': ']);
                case 'waitbar'
                    obj.FigObj = waitbar(0,'');
                    obj.FigObj.Children.Title.Interpreter = 'None';
                    waitbar(0,obj.FigObj,str);
            end
        end
        
        function progrVal(obj,ii,N)
            %PROGRVAL Summary of this method goes here
            %   Detailed explanation goes here
            switch obj.Type
                case 'disp'
                    fprintf('#%.3g/%.3g\n',ii,N);
                case 'textprogressbar'
                    textprogressbar(100.*ii./N);
                case 'waitbar'
                    waitbar(ii./N,obj.FigObj);
            end
        end
        
        function infoMsg(obj,str)
            %INFOMSG Summary of this method goes here
            %   Detailed explanation goes here
            switch obj.Type
                case 'disp'
                    disp(str);
                case 'textprogressbar'
                    % save msg for later
                    obj.InfoMsgs{end+1} = str;
                case 'waitbar'
                    % save msg for later
                    obj.InfoMsgs{end+1} = str;
            end
        end
        
        function endMsg(obj,str)
            %ENDMSG Summary of this method goes here
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
                    waitbar(1,obj.FigObj,'Finishing');
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

