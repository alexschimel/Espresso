function set_icon_espresso(main_figure)
if ispc
    javaFrame = get(main_figure,'JavaFrame');
    javaFrame.fHG2Client.setClientDockable(true);
    set(javaFrame,'GroupName','Espresso');
    javaFrame.setFigureIcon(javax.swing.ImageIcon(fullfile(whereisroot(),'icons','Espresso.png')));
end