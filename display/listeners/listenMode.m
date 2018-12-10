function listenMode(~,listdata,main_figure)
if~isdeployed
    disp('ListenMode')
end

switch listdata.AffectedObject.Mode
    case 'DrawPolyFeature'
         replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',{@draw_poly_feature,main_figure},'pointer','crosshair');
    case 'Normal'     
        replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn','');
end

end