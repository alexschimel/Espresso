%% get_icons_cdata.m
%
% Load icons
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |input_variable_1|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% * |output_variable_1|: TODO: write description and info on variable
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-10-25: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help Espresso.m| for copyright information.

%% Function
function icon = get_icons_cdata(icon_dir)

icon.folder = iconRead(fullfile(icon_dir,'folder_small.png'));

% icon.pointer = iconRead(fullfile(icon_dir,'tool_pointer.png'));
% icon.zin = iconRead(fullfile(icon_dir,'tool_zoom_in.png'));
% icon.zout = iconRead(fullfile(icon_dir,'tool_zoom_out.png'));
% icon.fplot = iconRead(fullfile(icon_dir,'freq_plot.png'));
% icon.bad_trans = iconRead(fullfile(icon_dir,'bad_trans.png'));
% icon.pan = iconRead(fullfile(icon_dir,'pan.png'));
% icon.ts_cal = iconRead(fullfile(icon_dir,'ts_cal.png'));
% icon.eba_cal = iconRead(fullfile(icon_dir,'eba_cal.png'));
% icon.edit_bot = iconRead(fullfile(icon_dir,'edit_bot.png'));
% icon.eraser = iconRead(fullfile(icon_dir,'eraser.png'));
% icon.edit_bot_spline = iconRead(fullfile(icon_dir,'edit_bot_spline.png'));
% icon.del_lay = iconRead(fullfile(icon_dir,'delete.png'));
% icon.undo = iconRead(fullfile(icon_dir,'undo.png'));
% icon.redo = icon.undo(:,(16:-1:1),:);
% icon.add = iconRead(fullfile(icon_dir,'add.png'));
% icon.undock = iconRead(fullfile(icon_dir,'undock.png'));
% icon.ruler = iconRead(fullfile(icon_dir,'ruler.png'));
% icon.create_reg = iconRead(fullfile(icon_dir,'create_reg.png'));
% icon.brush = iconRead(fullfile(icon_dir,'brush.png'));
% icon.next_lay = iconRead(fullfile(icon_dir,'greenarrowicon.gif'));
% icon.prev_lay = icon.next_lay(:,(16:-1:1),:);

end