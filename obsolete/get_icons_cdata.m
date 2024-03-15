function icon = get_icons_cdata(icon_dir)
%GET_ICONS_CDATA  Load icons
%
%   See also ESPRESSO.

%   Copyright 2017-2024 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

icon.pointer  = read_icon(fullfile(icon_dir,'iconModeNormal.png'));
icon.edit_bot = read_icon(fullfile(icon_dir,'iconModeFeature.png'));
icon.folder   = read_icon(fullfile(icon_dir,'iconFolder.gif'));
icon.up       = read_icon(fullfile(icon_dir,'iconArrowUp.png'));
icon.down     = read_icon(fullfile(icon_dir,'iconArrowDown.png'));

end