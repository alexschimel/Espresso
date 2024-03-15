function draw_box(~,~,main_figure,endFunction,endFunctionInputVar)
%DRAW_BOX  Interactive box drawing
%
%   Allows the user to draw a box (rectangle) on the map. Must be initiated
%   with INIT_BOX_DRAWING_MODE.

%   endFunction: function to be executed when the drawing is finished
%   (button released). This function will receive the main_figure, then the
%   box limits in X then Y, then the additional variables specified in
%   input here.
%
%   endFunctionInputVar: additional variables to pass in iput to the end
%   function 
%   
%   See also ESPRESSO.

%   Copyright 2017-2022 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

map_tab_comp = getappdata(main_figure,'Map_tab');

% get map limits
ah = map_tab_comp.map_axes;
x_lim = get(ah,'xlim');
y_lim = get(ah,'ylim');

% get pointer's current position
cp = ah.CurrentPoint;
xinit = cp(1,1);
yinit = cp(1,2);

% if pointer is not on map, exit
if xinit<x_lim(1) || xinit>x_lim(end) || yinit<y_lim(1) || yinit>y_lim(end)
    return;
end

% initialize box from pointer location
x_box = xinit;
y_box = yinit;
hp = line(ah,x_box,y_box,'color','r','linewidth',1,'Tag','reg_temp');

% replacing mouse interactions when moving the pointer, and releasing the
% button
replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2,'interaction_fcn',@wbmcb);
replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',2,'interaction_fcn',@wbucb);

    function wbmcb(~,~)
        % WindowButtonMotionFcn callback (when mouse pointer moves)

        % get box coordinates from initial position and pointer's current
        % location 
        cp = ah.CurrentPoint;
        X = [xinit,cp(1,1)];
        Y = [yinit,cp(1,2)];
        x_min = nanmin(X);
        x_max = nanmax(X);
        y_min = nanmin(Y);
        y_max = nanmax(Y);
        
        % as vertices to update line
        x_box = ([x_min, x_max, x_max, x_min, x_min]);
        y_box = ([y_max, y_max, y_min, y_min, y_max]);
        
        % update real-time box
        if isvalid(hp)
            set(hp,'XData',x_box,'YData',y_box,'Tag','reg_temp');
        else
            hp = plot(ah,x_box,x_box,'color','k','linewidth',1);
        end
        
    end

    function wbucb(main_figure,~)
        % WindowButtonUpFcn callback (when releasing button)
        
        % remove those two mouse interactions
        replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2);
        replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',2);
        
        % reset normal mouse interaction
        replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',{@move_map_cback,main_figure},'pointer','arrow');
        
        % delete real-time box
        delete(hp);
        
        % get final box coordinates
        x_min = nanmin(x_box);
        x_max = nanmax(x_box);
        y_min = nanmin(y_box);
        y_max = nanmax(y_box);
        
        % execute the end function and pass on box coordinates and unpacked
        % additional variables
        if iscell(endFunctionInputVar) && numel(endFunctionInputVar)>1
            feval(endFunction,main_figure,[x_min x_max],[y_min y_max],endFunctionInputVar{:});
        else
            feval(endFunction,main_figure,[x_min x_max],[y_min y_max],endFunctionInputVar);
        end
        
    end

end