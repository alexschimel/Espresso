function icon = get_icons_cdata(icon_dir)
%GET_ICONS_CDATA  Load icons
%
%   See also ESPRESSO.

%   Authors: Yoann Ladroit (NIWA, yoann.ladroit@niwa.co.nz) and Alex
%   Schimel (NIWA, alexandre.schimel@niwa.co.nz)
%   2017-2024

icon.pointer  = read_icon(fullfile(icon_dir,'iconModeNormal.png'));
icon.edit_bot = read_icon(fullfile(icon_dir,'iconModeFeature.png'));
icon.folder   = read_icon(fullfile(icon_dir,'iconFolder.gif'));
icon.up       = read_icon(fullfile(icon_dir,'iconArrowUp.png'));
icon.down     = read_icon(fullfile(icon_dir,'iconArrowDown.png'));

end