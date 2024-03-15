function set_icon_espresso(fig)
%SET_ICON_ESPRESSO  Add Espresso icon to main figure
%
%   See also ESPRESSO.

%   Copyright 2017-2024 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

% find icon file
if isdeployed
    % when deployed, can't use the one packaged with the app. Must be an
    % external file. Use one in installed app
    espressoIconFile = fullfile(whereisroot(),'icon_24.png');
else
    espressoIconFile = fullfile(whereisroot(),'Espresso_resources\icon_24.png');
end

% set icon to window
if ispc
    javaFrame = get(fig,'JavaFrame');
    javaFrame.fHG2Client.setClientDockable(true);
    set(javaFrame,'GroupName','Espresso');
    javaFrame.setFigureIcon(javax.swing.ImageIcon(espressoIconFile));
end