function init_box_drawing_mode(main_figure,endFunction,endFunctionInputVar,pointerStyle)
%INIT_BOX_DRAWING_MODE Interactive mode for user to draw box on map
%   This function replaces mouse interaction so that the user can draw a
%   box on the map by clicking and holding the left button of the mouse,
%   dragging across the map, and releasing the button when the box is
%   satisfactory. See companion function DRAW_BOX
%
%   Specify in input the function (endFunction) to be executed at the end
%   of the drawing. The box limits [x_min, x_max] and [y_min y_max] will be
%   passed to the function as input variable. Note the main_figure is
%   always passed on as the first variable.
%
%   You can also specify here as a cell array other input variables
%   (endFunctionInputVar) to be passed on the function, after the box
%   limits. The cell array will be unpacked when passed to the function.
%
%   See also ESPRESSO, DRAW_BOX

%   Authors: Yoann Ladroit (NIWA, yoann.ladroit@niwa.co.nz) and Alex
%   Schimel (NIWA, alexandre.schimel@niwa.co.nz)
%   2021-2022; Last revision: 16-03-2022

replace_interaction(main_figure,'interaction','WindowButtonDownFcn',  'id',1,'interaction_fcn',{@draw_box,main_figure,endFunction,endFunctionInputVar},'pointer',pointerStyle);
replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',1,'interaction_fcn',{@disp_cursor_info,main_figure},'pointer',pointerStyle);

end

