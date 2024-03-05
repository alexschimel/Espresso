function set_icon_espresso(main_figure)
%SET_ICON_ESPRESSO  Add Espresso icon to main figure
%
%   See also ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 21-07-2021

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
    javaFrame = get(main_figure,'JavaFrame');
    javaFrame.fHG2Client.setClientDockable(true);
    set(javaFrame,'GroupName','Espresso');
    javaFrame.setFigureIcon(javax.swing.ImageIcon(espressoIconFile));
end